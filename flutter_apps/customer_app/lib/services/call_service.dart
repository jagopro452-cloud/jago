import 'dart:async';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'socket_service.dart';

/// WebRTC peer-to-peer call service (customer side).
/// Uses the server's socket signaling relay for offer/answer/ICE exchange.
class CallService {
  static final CallService _instance = CallService._internal();
  factory CallService() => _instance;
  CallService._internal();

  final SocketService _socket = SocketService();

  RTCPeerConnection? _pc;
  MediaStream? _localStream;
  MediaStream? _remoteStream;

  String? activeCallTripId;
  String? activeCallTargetId;
  bool _isCaller = false;
  DateTime? _callStartTime;

  final _remoteStreamController = StreamController<MediaStream?>.broadcast();
  final _callStateController = StreamController<CallState>.broadcast();

  Stream<MediaStream?> get onRemoteStream => _remoteStreamController.stream;
  Stream<CallState> get onCallState => _callStateController.stream;

  CallState _state = CallState.idle;
  CallState get state => _state;

  final List<StreamSubscription> _subs = [];

  static const Map<String, dynamic> _rtcConfig = {
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'},
      {'urls': 'stun:stun1.l.google.com:19302'},
    ],
  };

  void init() {
    if (_subs.isNotEmpty) return;
    _subs.add(_socket.onCallOffer.listen(_handleOffer));
    _subs.add(_socket.onCallAnswer.listen(_handleAnswer));
    _subs.add(_socket.onCallIce.listen(_handleIce));
    _subs.add(_socket.onCallEnded.listen((_) => hangUp()));
    _subs.add(_socket.onCallRejected.listen((_) => _onCallRejected()));
  }

  /// Start an outgoing call to the target user.
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

    _socket.initiateCall(
      targetUserId: targetUserId,
      tripId: tripId,
      callerName: callerName,
    );

    await _createPeerConnection();
    await _startLocalAudio();

    final offer = await _pc!.createOffer();
    await _pc!.setLocalDescription(offer);
    _socket.sendCallOffer(
      targetUserId: targetUserId,
      sdp: {'type': offer.type, 'sdp': offer.sdp},
    );
  }

  /// Accept an incoming call.
  Future<void> acceptCall({
    required String callerId,
    required String tripId,
  }) async {
    if (_state != CallState.incoming) return;
    _isCaller = false;
    activeCallTargetId = callerId;
    activeCallTripId = tripId;
    _setState(CallState.connected);
    _callStartTime = DateTime.now();
    // Offer should already be set as remote description from _handleOffer
  }

  /// Reject an incoming call.
  void rejectIncomingCall() {
    if (activeCallTargetId != null) {
      _socket.rejectCall(targetUserId: activeCallTargetId!, tripId: activeCallTripId);
    }
    _cleanup();
    _setState(CallState.idle);
  }

  /// Hang up the current call.
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

  // ── Private helpers ───────────────────────────────────────────────────────

  Future<void> _createPeerConnection() async {
    _pc = await createPeerConnection(_rtcConfig);

    _pc!.onIceCandidate = (candidate) {
      if (activeCallTargetId != null) {
        _socket.sendIceCandidate(
          targetUserId: activeCallTargetId!,
          candidate: candidate.toMap(),
        );
      }
    };

    _pc!.onTrack = (event) {
      if (event.streams.isNotEmpty) {
        _remoteStream = event.streams[0];
        _remoteStreamController.add(_remoteStream);
      }
    };

    _pc!.onConnectionState = (state) {
      if (state == RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
        _callStartTime ??= DateTime.now();
        _setState(CallState.connected);
      } else if (state == RTCPeerConnectionState.RTCPeerConnectionStateDisconnected ||
                 state == RTCPeerConnectionState.RTCPeerConnectionStateFailed) {
        hangUp();
      }
    };
  }

  Future<void> _startLocalAudio() async {
    _localStream = await navigator.mediaDevices.getUserMedia({'audio': true, 'video': false});
    for (final track in _localStream!.getAudioTracks()) {
      await _pc!.addTrack(track, _localStream!);
    }
  }

  Future<void> _handleOffer(Map<String, dynamic> data) async {
    if (_state == CallState.connected || _state == CallState.outgoing) return;
    final sdp = data['sdp'];
    if (sdp == null) return;
    activeCallTargetId = data['callerId']?.toString();

    await _createPeerConnection();
    await _startLocalAudio();

    await _pc!.setRemoteDescription(RTCSessionDescription(sdp['sdp'], sdp['type']));

    final answer = await _pc!.createAnswer();
    await _pc!.setLocalDescription(answer);

    if (activeCallTargetId != null) {
      _socket.sendCallAnswer(
        targetUserId: activeCallTargetId!,
        sdp: {'type': answer.type, 'sdp': answer.sdp},
      );
    }
    _callStartTime = DateTime.now();
    _setState(CallState.connected);
  }

  Future<void> _handleAnswer(Map<String, dynamic> data) async {
    final sdp = data['sdp'];
    if (sdp == null || _pc == null) return;
    await _pc!.setRemoteDescription(RTCSessionDescription(sdp['sdp'], sdp['type']));
    _callStartTime = DateTime.now();
    _setState(CallState.connected);
  }

  Future<void> _handleIce(Map<String, dynamic> data) async {
    final c = data['candidate'];
    if (c == null || _pc == null) return;
    await _pc!.addCandidate(RTCIceCandidate(c['candidate'], c['sdpMid'], c['sdpMLineIndex']));
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
    _localStream?.getTracks().forEach((t) => t.stop());
    _localStream?.dispose();
    _localStream = null;
    _remoteStream = null;
    _remoteStreamController.add(null);
    _pc?.close();
    _pc = null;
    activeCallTargetId = null;
    activeCallTripId = null;
    _callStartTime = null;
  }

  void dispose() {
    for (final s in _subs) { s.cancel(); }
    _subs.clear();
    _cleanup();
    _remoteStreamController.close();
    _callStateController.close();
  }
}

enum CallState { idle, outgoing, incoming, connected, rejected }
