import 'dart:async';

import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:permission_handler/permission_handler.dart';

import 'socket_service.dart';

/// Real in-app audio call service backed by WebRTC + socket signaling.
class CallService {
  static final CallService _instance = CallService._internal();
  factory CallService() => _instance;
  CallService._internal();

  final SocketService _socket = SocketService();

  String? activeCallTripId;
  String? activeCallTargetId;
  bool _isCaller = false;
  DateTime? _callStartTime;

  bool _isMuted = false;
  bool _isSpeakerphone = false;

  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  MediaStream? _remoteStream;
  Map<String, dynamic>? _pendingOffer;
  final List<RTCIceCandidate> _pendingRemoteCandidates = [];

  final _remoteStreamController = StreamController<dynamic>.broadcast();
  final _callStateController = StreamController<CallState>.broadcast();

  Stream<dynamic> get onRemoteStream => _remoteStreamController.stream;
  Stream<CallState> get onCallState => _callStateController.stream;

  CallState _state = CallState.idle;
  CallState get state => _state;

  final List<StreamSubscription> _subs = [];

  static const Map<String, dynamic> _rtcConfig = {
    'iceServers': [
      {
        'urls': [
          'stun:stun.l.google.com:19302',
          'stun:stun1.l.google.com:19302',
        ],
      },
    ],
    'sdpSemantics': 'unified-plan',
  };

  void init() {
    if (_subs.isNotEmpty) return;
    _subs.add(_socket.onCallIncoming.listen(_handleIncoming));
    _subs.add(_socket.onCallOffer.listen(_handleOffer));
    _subs.add(_socket.onCallAnswer.listen(_handleAnswer));
    _subs.add(_socket.onCallIce.listen(_handleIce));
    _subs.add(_socket.onCallEnded.listen((_) => _handleRemoteEnded()));
    _subs.add(_socket.onCallRejected.listen((_) => _onCallRejected()));
  }

  Future<void> startCall({
    required String targetUserId,
    required String tripId,
    required String callerName,
  }) async {
    if (_state != CallState.idle) return;
    _isCaller = true;
    activeCallTargetId = targetUserId;
    activeCallTripId = tripId;
    _setState(CallState.outgoing);

    await _ensurePeerConnection();
    final pc = _peerConnection;
    if (pc == null) {
      _setState(CallState.idle);
      throw Exception('Could not prepare audio calling.');
    }

    _socket.initiateCall(
      targetUserId: targetUserId,
      tripId: tripId,
      callerName: callerName,
    );

    final offer = await pc.createOffer({
      'offerToReceiveAudio': 1,
      'offerToReceiveVideo': 0,
    });
    await pc.setLocalDescription(offer);
    _socket.sendCallOffer(
      targetUserId: targetUserId,
      sdp: {
        'type': offer.type,
        'sdp': offer.sdp,
        'tripId': tripId,
      },
    );
  }

  Future<void> acceptCall({
    required String callerId,
    required String tripId,
  }) async {
    if (_state == CallState.idle && callerId.isNotEmpty) {
      activeCallTargetId = callerId;
      activeCallTripId = tripId;
      _setState(CallState.incoming);
    }

    if (_state != CallState.incoming) return;
    _isCaller = false;
    activeCallTargetId = callerId;
    activeCallTripId = tripId;
    await acceptIncomingCall();
  }

  Future<void> acceptIncomingCall() async {
    if (_pendingOffer == null) return;

    await _ensurePeerConnection();
    final pc = _peerConnection;
    if (pc == null || activeCallTargetId == null) {
      throw Exception('Could not prepare incoming call audio.');
    }

    final offer = Map<String, dynamic>.from(_pendingOffer!['sdp'] as Map);
    await pc.setRemoteDescription(
      RTCSessionDescription(
        offer['sdp']?.toString(),
        offer['type']?.toString(),
      ),
    );
    await _flushPendingIceCandidates();

    final answer = await pc.createAnswer({
      'offerToReceiveAudio': 1,
      'offerToReceiveVideo': 0,
    });
    await pc.setLocalDescription(answer);
    _socket.sendCallAnswer(
      targetUserId: activeCallTargetId!,
      sdp: {
        'type': answer.type,
        'sdp': answer.sdp,
        'tripId': activeCallTripId,
      },
    );

    _pendingOffer = null;
    _callStartTime = DateTime.now();
    _setState(CallState.connected);
  }

  void rejectIncomingCall() {
    if (activeCallTargetId != null) {
      _socket.rejectCall(
        targetUserId: activeCallTargetId!,
        tripId: activeCallTripId,
      );
    }
    _cleanup();
    _setState(CallState.idle);
  }

  Future<void> hangUp() async {
    if (activeCallTargetId != null) {
      int? dur;
      if (_callStartTime != null) {
        dur = DateTime.now().difference(_callStartTime!).inSeconds;
      }
      _socket.endCall(
        targetUserId: activeCallTargetId!,
        tripId: activeCallTripId,
        durationSec: dur,
      );
    }
    _cleanup();
    _setState(CallState.idle);
  }

  void setMuted(bool muted) {
    _isMuted = muted;
    for (final track in _localStream?.getAudioTracks() ?? const <MediaStreamTrack>[]) {
      track.enabled = !muted;
    }
  }

  Future<void> setSpeakerphone(bool enabled) async {
    _isSpeakerphone = enabled;
    try {
      await Helper.setSpeakerphoneOn(enabled);
    } catch (_) {}
  }

  Future<void> _handleIncoming(Map<String, dynamic> data) async {
    if (_state == CallState.connected || _state == CallState.outgoing) return;
    activeCallTargetId = (data['callerId'] ?? data['senderId'] ?? data['userId'])?.toString();
    activeCallTripId = data['tripId']?.toString();
    _setState(CallState.incoming);
  }

  Future<void> _handleOffer(Map<String, dynamic> data) async {
    if (_state == CallState.connected || _state == CallState.outgoing) return;
    activeCallTargetId = data['callerId']?.toString();
    activeCallTripId = data['tripId']?.toString() ??
        (data['sdp'] is Map ? (data['sdp']['tripId']?.toString()) : null);
    _pendingOffer = Map<String, dynamic>.from(data);
    _setState(CallState.incoming);
  }

  Future<void> _handleAnswer(Map<String, dynamic> data) async {
    if (_state != CallState.outgoing) return;
    final pc = _peerConnection;
    if (pc == null) return;

    final answer = Map<String, dynamic>.from(data['sdp'] as Map);
    await pc.setRemoteDescription(
      RTCSessionDescription(
        answer['sdp']?.toString(),
        answer['type']?.toString(),
      ),
    );
    await _flushPendingIceCandidates();
    _callStartTime = DateTime.now();
    _setState(CallState.connected);
  }

  Future<void> _handleIce(Map<String, dynamic> data) async {
    final rawCandidate = data['candidate'];
    if (rawCandidate is! Map) return;
    final candidate = RTCIceCandidate(
      rawCandidate['candidate']?.toString(),
      rawCandidate['sdpMid']?.toString(),
      rawCandidate['sdpMLineIndex'] is int
          ? rawCandidate['sdpMLineIndex'] as int
          : int.tryParse(rawCandidate['sdpMLineIndex']?.toString() ?? ''),
    );

    if (_peerConnection == null) {
      _pendingRemoteCandidates.add(candidate);
      return;
    }

    final remoteDescription = await _peerConnection!.getRemoteDescription();
    if (remoteDescription == null) {
      _pendingRemoteCandidates.add(candidate);
      return;
    }

    await _peerConnection!.addCandidate(candidate);
  }

  void _handleRemoteEnded() {
    _cleanup();
    _setState(CallState.idle);
  }

  void _onCallRejected() {
    _cleanup();
    _setState(CallState.rejected);
    Future.delayed(const Duration(seconds: 2), () {
      if (_state == CallState.rejected) _setState(CallState.idle);
    });
  }

  Future<void> _ensurePeerConnection() async {
    if (_peerConnection != null) return;
    await _ensureMicrophonePermission();

    _localStream ??= await navigator.mediaDevices.getUserMedia({
      'audio': {
        'echoCancellation': true,
        'noiseSuppression': true,
        'autoGainControl': true,
      },
      'video': false,
    });

    final pc = await createPeerConnection(_rtcConfig);
    _peerConnection = pc;

    for (final track in _localStream!.getTracks()) {
      await pc.addTrack(track, _localStream!);
    }

    pc.onTrack = (event) {
      if (event.streams.isNotEmpty) {
        _remoteStream = event.streams.first;
        _remoteStreamController.add(_remoteStream);
      }
    };

    pc.onIceCandidate = (candidate) {
      if (candidate.candidate == null || activeCallTargetId == null) return;
      _socket.sendIceCandidate(
        targetUserId: activeCallTargetId!,
        candidate: {
          'candidate': candidate.candidate,
          'sdpMid': candidate.sdpMid,
          'sdpMLineIndex': candidate.sdpMLineIndex,
        },
      );
    };

    pc.onConnectionState = (state) {
      if (state == RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
        if (_state != CallState.connected) {
          _callStartTime ??= DateTime.now();
          _setState(CallState.connected);
        }
      }

      if (state == RTCPeerConnectionState.RTCPeerConnectionStateDisconnected ||
          state == RTCPeerConnectionState.RTCPeerConnectionStateFailed ||
          state == RTCPeerConnectionState.RTCPeerConnectionStateClosed) {
        if (_state != CallState.idle && _state != CallState.rejected) {
          _cleanup();
          _setState(CallState.idle);
        }
      }
    };

    if (_isMuted) {
      setMuted(true);
    }
    if (_isSpeakerphone) {
      await setSpeakerphone(true);
    }
  }

  Future<void> _flushPendingIceCandidates() async {
    if (_peerConnection == null) return;
    final remoteDescription = await _peerConnection!.getRemoteDescription();
    if (remoteDescription == null) return;

    while (_pendingRemoteCandidates.isNotEmpty) {
      final candidate = _pendingRemoteCandidates.removeAt(0);
      await _peerConnection!.addCandidate(candidate);
    }
  }

  Future<void> _ensureMicrophonePermission() async {
    final status = await Permission.microphone.request();
    if (!status.isGranted) {
      throw Exception('Microphone permission is required for calls.');
    }
  }

  void _setState(CallState s) {
    _state = s;
    _callStateController.add(s);
  }

  void _cleanup() {
    for (final track in _localStream?.getTracks() ?? const <MediaStreamTrack>[]) {
      track.stop();
    }
    _localStream?.dispose();
    _localStream = null;
    _remoteStream?.dispose();
    _remoteStream = null;
    _peerConnection?.close();
    _peerConnection = null;
    _pendingOffer = null;
    _pendingRemoteCandidates.clear();
    activeCallTargetId = null;
    activeCallTripId = null;
    _callStartTime = null;
    _isMuted = false;
    _isSpeakerphone = false;
    _remoteStreamController.add(null);
  }

  void dispose() {
    for (final s in _subs) {
      s.cancel();
    }
    _subs.clear();
    _cleanup();
    _remoteStreamController.close();
    _callStateController.close();
  }
}

enum CallState { idle, outgoing, incoming, connected, rejected }
