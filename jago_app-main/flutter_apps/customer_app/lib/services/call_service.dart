import 'dart:async';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:permission_handler/permission_handler.dart';
import 'socket_service.dart';

/// Real audio-only WebRTC call service.
/// Public API is preserved so the existing premium call UI stays unchanged.
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
  RTCSessionDescription? _pendingRemoteOffer;
  bool _hasRemoteDescription = false;
  Timer? _outgoingCallTimer;

  final _remoteStreamController = StreamController<dynamic>.broadcast();
  final _callStateController = StreamController<CallState>.broadcast();

  Stream<dynamic> get onRemoteStream => _remoteStreamController.stream;
  Stream<CallState> get onCallState => _callStateController.stream;

  CallState _state = CallState.idle;
  CallState get state => _state;

  final List<StreamSubscription> _subs = [];

  static const String _turnUrl = String.fromEnvironment('WEBRTC_TURN_URL', defaultValue: '');
  static const String _turnUsername = String.fromEnvironment('WEBRTC_TURN_USERNAME', defaultValue: '');
  static const String _turnCredential = String.fromEnvironment('WEBRTC_TURN_CREDENTIAL', defaultValue: '');

  void init() {
    if (_subs.isNotEmpty) return;
    _subs.add(_socket.onCallIncoming.listen(_handleIncoming));
    _subs.add(_socket.onCallOffer.listen(_handleOffer));
    _subs.add(_socket.onCallAnswer.listen(_handleAnswer));
    _subs.add(_socket.onCallIce.listen(_handleIce));
    _subs.add(_socket.onCallEnded.listen((_) => hangUp(notifyRemote: false)));
    _subs.add(_socket.onCallRejected.listen((_) => _onCallRejected()));
  }

  Future<void> startCall({
    required String targetUserId,
    required String tripId,
    required String callerName,
  }) async {
    if (_state != CallState.idle) return;
    if (!await _ensureMicrophonePermission()) {
      _setState(CallState.micPermissionDenied);
      Future.delayed(const Duration(seconds: 3), () {
        if (_state == CallState.micPermissionDenied) _setState(CallState.idle);
      });
      return;
    }

    _isCaller = true;
    activeCallTargetId = targetUserId;
    activeCallTripId = tripId;
    _setState(CallState.outgoing);

    await _createPeerConnection();
    await _ensureLocalStream();

    _socket.initiateCall(
      targetUserId: targetUserId,
      tripId: tripId,
      callerName: callerName,
    );

    final offer = await _peerConnection!.createOffer({
      'offerToReceiveAudio': true,
      'offerToReceiveVideo': false,
    });
    await _peerConnection!.setLocalDescription(offer);
    _socket.sendCallOffer(
      targetUserId: targetUserId,
      tripId: tripId,
      sdp: {'type': offer.type, 'sdp': offer.sdp},
    );

    // Auto-hangup after 45 seconds if peer doesn't answer
    _outgoingCallTimer?.cancel();
    _outgoingCallTimer = Timer(const Duration(seconds: 45), () {
      if (_state == CallState.outgoing) {
        hangUp(notifyRemote: true);
      }
    });
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
    if (!await _ensureMicrophonePermission()) {
      rejectIncomingCall();
      return;
    }

    _isCaller = false;
    activeCallTargetId = callerId;
    activeCallTripId = tripId;
    await acceptIncomingCall();
  }

  Future<void> acceptIncomingCall() async {
    if (activeCallTargetId == null || activeCallTripId == null) return;
    await _createPeerConnection();
    await _ensureLocalStream();

    if (_pendingRemoteOffer != null && !_hasRemoteDescription) {
      await _peerConnection!.setRemoteDescription(_pendingRemoteOffer!);
      _hasRemoteDescription = true;
    }

    final answer = await _peerConnection!.createAnswer({
      'offerToReceiveAudio': true,
      'offerToReceiveVideo': false,
    });
    await _peerConnection!.setLocalDescription(answer);
    _socket.sendCallAnswer(
      targetUserId: activeCallTargetId!,
      tripId: activeCallTripId!,
      sdp: {'type': answer.type, 'sdp': answer.sdp},
    );

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

  Future<void> hangUp({bool notifyRemote = true}) async {
    _outgoingCallTimer?.cancel();
    _outgoingCallTimer = null;
    if (notifyRemote && activeCallTargetId != null) {
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
    await Helper.setSpeakerphoneOn(enabled);
  }

  Future<void> _createPeerConnection() async {
    if (_peerConnection != null) return;
    final iceServers = <Map<String, dynamic>>[
      {'urls': ['stun:stun.l.google.com:19302', 'stun:stun1.l.google.com:19302']},
    ];
    if (_turnUrl.isNotEmpty) {
      iceServers.add({
        'urls': [_turnUrl],
        if (_turnUsername.isNotEmpty) 'username': _turnUsername,
        if (_turnCredential.isNotEmpty) 'credential': _turnCredential,
      });
    }

    _peerConnection = await createPeerConnection({
      'iceServers': iceServers,
      'sdpSemantics': 'unified-plan',
    });

    _peerConnection!.onIceCandidate = (candidate) {
      if (candidate.candidate == null || activeCallTargetId == null || activeCallTripId == null) return;
      _socket.sendIceCandidate(
        targetUserId: activeCallTargetId!,
        tripId: activeCallTripId!,
        candidate: {
          'candidate': candidate.candidate,
          'sdpMid': candidate.sdpMid,
          'sdpMLineIndex': candidate.sdpMLineIndex,
        },
      );
    };

    _peerConnection!.onTrack = (event) {
      if (event.streams.isNotEmpty) {
        _remoteStream = event.streams.first;
        _remoteStreamController.add(_remoteStream);
      }
    };

    _peerConnection!.onConnectionState = (state) {
      if (state == RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
        _callStartTime ??= DateTime.now();
        _setState(CallState.connected);
      } else if (state == RTCPeerConnectionState.RTCPeerConnectionStateDisconnected ||
          state == RTCPeerConnectionState.RTCPeerConnectionStateFailed ||
          state == RTCPeerConnectionState.RTCPeerConnectionStateClosed) {
        if (_state != CallState.idle) {
          hangUp(notifyRemote: false);
        }
      }
    };
  }

  Future<void> _ensureLocalStream() async {
    if (_localStream != null) return;
    _localStream = await navigator.mediaDevices.getUserMedia({
      'audio': {
        'echoCancellation': true,
        'noiseSuppression': true,
        'autoGainControl': true,
      },
      'video': false,
    });
    for (final track in _localStream!.getAudioTracks()) {
      await _peerConnection?.addTrack(track, _localStream!);
      track.enabled = !_isMuted;
    }
    if (_isSpeakerphone) {
      await Helper.setSpeakerphoneOn(true);
    }
  }

  Future<bool> _ensureMicrophonePermission() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  void _handleIncoming(Map<String, dynamic> data) {
    if (_state == CallState.connected || _state == CallState.outgoing) return;
    activeCallTargetId = (data['callerId'] ?? data['senderId'] ?? data['userId'])?.toString();
    activeCallTripId = data['tripId']?.toString();
    _pendingRemoteOffer = null;
    _setState(CallState.incoming);
  }

  Future<void> _handleOffer(Map<String, dynamic> data) async {
    if (_state == CallState.connected || _state == CallState.outgoing) return;
    activeCallTargetId = data['callerId']?.toString();
    activeCallTripId = data['tripId']?.toString();
    final sdp = Map<String, dynamic>.from(data['sdp'] as Map? ?? const {});
    final type = (sdp['type'] ?? '').toString();
    final description = (sdp['sdp'] ?? '').toString();
    if (type.isEmpty || description.isEmpty) return;
    _pendingRemoteOffer = RTCSessionDescription(description, type);
    _setState(CallState.incoming);
  }

  Future<void> _handleAnswer(Map<String, dynamic> data) async {
    if (_state != CallState.outgoing || _peerConnection == null) return;
    _outgoingCallTimer?.cancel();
    _outgoingCallTimer = null;
    final sdp = Map<String, dynamic>.from(data['sdp'] as Map? ?? const {});
    final type = (sdp['type'] ?? '').toString();
    final description = (sdp['sdp'] ?? '').toString();
    if (type.isEmpty || description.isEmpty) return;
    await _peerConnection!.setRemoteDescription(RTCSessionDescription(description, type));
    _hasRemoteDescription = true;
    _callStartTime = DateTime.now();
    _setState(CallState.connected);
  }

  Future<void> _handleIce(Map<String, dynamic> data) async {
    if (_peerConnection == null) return;
    final candidate = Map<String, dynamic>.from(data['candidate'] as Map? ?? const {});
    final value = candidate['candidate']?.toString();
    if (value == null || value.isEmpty) return;
    await _peerConnection!.addCandidate(
      RTCIceCandidate(
        value,
        candidate['sdpMid']?.toString(),
        candidate['sdpMLineIndex'] is int
            ? candidate['sdpMLineIndex'] as int
            : int.tryParse('${candidate['sdpMLineIndex'] ?? ''}'),
      ),
    );
  }

  void _onCallRejected() {
    _cleanup();
    _setState(CallState.rejected);
    Future.delayed(const Duration(seconds: 2), () {
      if (_state == CallState.rejected) _setState(CallState.idle);
    });
  }

  void _setState(CallState s) {
    _state = s;
    _callStateController.add(s);
  }

  void _cleanup() {
    _pendingRemoteOffer = null;
    _remoteStreamController.add(null);
    _remoteStream?.dispose();
    _remoteStream = null;
    for (final track in _localStream?.getTracks() ?? const <MediaStreamTrack>[]) {
      track.stop();
    }
    _localStream?.dispose();
    _localStream = null;
    _peerConnection?.close();
    _peerConnection = null;
    _hasRemoteDescription = false;
    activeCallTargetId = null;
    activeCallTripId = null;
    _callStartTime = null;
    _isMuted = false;
    _isSpeakerphone = false;
  }

  void dispose() {
    _outgoingCallTimer?.cancel();
    _outgoingCallTimer = null;
    for (final s in _subs) {
      s.cancel();
    }
    _subs.clear();
    _cleanup();
    _remoteStreamController.close();
    _callStateController.close();
  }
}

enum CallState { idle, outgoing, incoming, connected, rejected, micPermissionDenied }
