import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:get/get.dart';
import 'package:jago_pilot_app/features/call/domain/repositories/call_repository.dart';

enum CallState { idle, connecting, ringing, active, ended, error }

class CallController extends GetxController {
  final CallRepository callRepository;
  CallController({required this.callRepository});

  CallState _callState = CallState.idle;
  CallState get callState => _callState;

  String? _currentCallId;
  String? get currentCallId => _currentCallId;

  String? _calleeDisplayName;
  String? get calleeDisplayName => _calleeDisplayName;

  String? _callerDisplayName;
  String? get callerDisplayName => _callerDisplayName;

  bool _isMuted = false;
  bool get isMuted => _isMuted;

  bool _isSpeaker = false;
  bool get isSpeaker => _isSpeaker;

  int _callDuration = 0;
  int get callDuration => _callDuration;

  bool _isIncoming = false;
  bool get isIncoming => _isIncoming;

  String? _incomingCallId;
  String? _incomingCallerName;
  String? _incomingTripId;

  String? _currentUserId;
  String? _currentUserType;

  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  Timer? _pollTimer;
  Timer? _incomingPollTimer;
  Timer? _callDurationTimer;
  String? _lastSignalId;

  static const List<Map<String, dynamic>> _iceServers = [
    {'urls': 'stun:stun.l.google.com:19302'},
    {'urls': 'stun:stun1.l.google.com:19302'},
    {'urls': 'stun:stun2.l.google.com:19302'},
  ];

  void initCalling({required String userId, required String userType}) {
    _currentUserId = userId;
    _currentUserType = userType;
    _startIncomingPoll();
  }

  void disposeCalling() {
    _stopIncomingPoll();
    _cleanup();
  }

  void _startIncomingPoll() {
    _stopIncomingPoll();
    _incomingPollTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      if (_callState != CallState.idle || _currentUserId == null) return;
      try {
        final response = await callRepository.pollIncoming(userId: _currentUserId!);
        if (response.statusCode == 200 && response.body != null) {
          final data = response.body;
          if (data['incoming'] != null) {
            _handleIncomingCall(data['incoming']);
          }
        }
      } catch (e) {
        if (kDebugMode) print('Incoming poll error: $e');
      }
    });
  }

  void _stopIncomingPoll() {
    _incomingPollTimer?.cancel();
    _incomingPollTimer = null;
  }

  void _handleIncomingCall(Map<String, dynamic> callData) {
    _isIncoming = true;
    _incomingCallId = callData['id']?.toString();
    _incomingCallerName = callData['caller_name'] ?? 'Unknown';
    _incomingTripId = callData['trip_request_id']?.toString();
    _callState = CallState.ringing;
    update();
  }

  Future<bool> startCall({
    required String tripRequestId,
    required String calleeType,
    required String calleeId,
    String? displayName,
  }) async {
    if (_currentUserId == null || _currentUserType == null) return false;
    if (_callState != CallState.idle) return false;

    _calleeDisplayName = displayName ?? 'Unknown';
    _isIncoming = false;
    _callState = CallState.connecting;
    update();

    try {
      final response = await callRepository.startCall(
        tripRequestId: tripRequestId,
        callerType: _currentUserType!,
        callerId: _currentUserId!,
        calleeType: calleeType,
        calleeId: calleeId,
      );

      if (response.statusCode != 200) {
        final error = response.body?['error'] ?? 'Failed to start call';
        _callState = CallState.error;
        update();
        Future.delayed(const Duration(seconds: 2), () {
          _callState = CallState.idle;
          update();
        });
        return false;
      }

      _currentCallId = response.body['call_id']?.toString();

      _localStream = await navigator.mediaDevices.getUserMedia({'audio': true, 'video': false});

      await _createPeerConnection();

      final offer = await _peerConnection!.createOffer();
      await _peerConnection!.setLocalDescription(offer);

      await callRepository.sendSignal(
        callId: _currentCallId!,
        senderType: _currentUserType!,
        senderId: _currentUserId!,
        signalType: 'offer',
        payload: jsonEncode({'sdp': offer.sdp, 'type': offer.type}),
      );

      _callState = CallState.ringing;
      _startSignalPolling();
      update();
      return true;
    } catch (e) {
      if (kDebugMode) print('Start call error: $e');
      _callState = CallState.error;
      update();
      Future.delayed(const Duration(seconds: 2), () {
        _cleanup();
        update();
      });
      return false;
    }
  }

  Future<void> acceptIncomingCall() async {
    if (_incomingCallId == null || _currentUserId == null) return;

    _currentCallId = _incomingCallId;
    _calleeDisplayName = _incomingCallerName;
    _callState = CallState.connecting;
    update();

    try {
      _localStream = await navigator.mediaDevices.getUserMedia({'audio': true, 'video': false});
      await _createPeerConnection();

      final pollResponse = await callRepository.pollSignals(
        callId: _currentCallId!,
        listenerId: _currentUserId!,
      );

      if (pollResponse.statusCode == 200 && pollResponse.body['signals'] != null) {
        final signals = pollResponse.body['signals'] as List;
        for (final signal in signals) {
          if (signal['signal_type'] == 'offer') {
            final payload = signal['payload'] is String ? jsonDecode(signal['payload']) : signal['payload'];
            await _peerConnection!.setRemoteDescription(
              RTCSessionDescription(payload['sdp'], payload['type']),
            );
            break;
          }
        }
      }

      final answer = await _peerConnection!.createAnswer();
      await _peerConnection!.setLocalDescription(answer);

      await callRepository.sendSignal(
        callId: _currentCallId!,
        senderType: _currentUserType!,
        senderId: _currentUserId!,
        signalType: 'answer',
        payload: jsonEncode({'sdp': answer.sdp, 'type': answer.type}),
      );

      _callState = CallState.active;
      _startCallTimer();
      _startSignalPolling();
      update();
    } catch (e) {
      if (kDebugMode) print('Accept call error: $e');
      _callState = CallState.error;
      update();
      Future.delayed(const Duration(seconds: 2), () {
        _cleanup();
        update();
      });
    }
  }

  Future<void> rejectIncomingCall() async {
    if (_incomingCallId == null || _currentUserId == null) return;

    try {
      await callRepository.sendSignal(
        callId: _incomingCallId!,
        senderType: _currentUserType!,
        senderId: _currentUserId!,
        signalType: 'reject',
        payload: '{}',
      );
    } catch (e) {
      if (kDebugMode) print('Reject call error: $e');
    }

    _cleanup();
    update();
  }

  Future<void> hangUp() async {
    if (_currentCallId == null || _currentUserId == null) return;

    try {
      await callRepository.sendSignal(
        callId: _currentCallId!,
        senderType: _currentUserType!,
        senderId: _currentUserId!,
        signalType: 'bye',
        payload: '{}',
      );
    } catch (e) {
      if (kDebugMode) print('Hang up error: $e');
    }

    _callState = CallState.ended;
    update();
    Future.delayed(const Duration(seconds: 1), () {
      _cleanup();
      update();
    });
  }

  void toggleMute() {
    _isMuted = !_isMuted;
    if (_localStream != null) {
      for (final track in _localStream!.getAudioTracks()) {
        track.enabled = !_isMuted;
      }
    }
    update();
  }

  void toggleSpeaker() {
    _isSpeaker = !_isSpeaker;
    if (_localStream != null) {
      for (final track in _localStream!.getAudioTracks()) {
        Helper.setSpeakerphoneOn(_isSpeaker);
      }
    }
    update();
  }

  String get formattedDuration {
    final minutes = (_callDuration ~/ 60).toString().padLeft(2, '0');
    final seconds = (_callDuration % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  Future<void> _createPeerConnection() async {
    _peerConnection = await createPeerConnection({
      'iceServers': _iceServers,
    });

    _localStream!.getTracks().forEach((track) {
      _peerConnection!.addTrack(track, _localStream!);
    });

    _peerConnection!.onIceCandidate = (candidate) {
      if (_currentCallId != null && _currentUserId != null) {
        callRepository.sendSignal(
          callId: _currentCallId!,
          senderType: _currentUserType!,
          senderId: _currentUserId!,
          signalType: 'ice',
          payload: jsonEncode(candidate.toMap()),
        );
      }
    };

    _peerConnection!.onConnectionState = (state) {
      if (state == RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
        if (_callState != CallState.active) {
          _callState = CallState.active;
          _startCallTimer();
          update();
        }
      } else if (state == RTCPeerConnectionState.RTCPeerConnectionStateDisconnected ||
          state == RTCPeerConnectionState.RTCPeerConnectionStateFailed) {
        hangUp();
      }
    };
  }

  void _startSignalPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
      if (_currentCallId == null || _currentUserId == null) return;
      try {
        final response = await callRepository.pollSignals(
          callId: _currentCallId!,
          listenerId: _currentUserId!,
          after: _lastSignalId,
        );

        if (response.statusCode == 200 && response.body['signals'] != null) {
          final signals = response.body['signals'] as List;
          for (final signal in signals) {
            _lastSignalId = signal['created_at']?.toString();
            await _handleSignal(signal);
          }
        }
      } catch (e) {
        if (kDebugMode) print('Poll error: $e');
      }
    });
  }

  Future<void> _handleSignal(Map<String, dynamic> signal) async {
    final type = signal['signal_type'];
    final payload = signal['payload'] is String ? jsonDecode(signal['payload']) : signal['payload'];

    switch (type) {
      case 'answer':
        if (_peerConnection != null) {
          await _peerConnection!.setRemoteDescription(
            RTCSessionDescription(payload['sdp'], payload['type']),
          );
        }
        break;
      case 'ice':
        if (_peerConnection != null && payload != null) {
          await _peerConnection!.addCandidate(
            RTCIceCandidate(
              payload['candidate'],
              payload['sdpMid'],
              payload['sdpMLineIndex'],
            ),
          );
        }
        break;
      case 'bye':
      case 'reject':
        _callState = CallState.ended;
        update();
        Future.delayed(const Duration(seconds: 1), () {
          _cleanup();
          update();
        });
        break;
    }
  }

  void _startCallTimer() {
    _callDuration = 0;
    _callDurationTimer?.cancel();
    _callDurationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _callDuration++;
      update();
    });
  }

  void _cleanup() {
    _pollTimer?.cancel();
    _pollTimer = null;
    _callDurationTimer?.cancel();
    _callDurationTimer = null;
    _lastSignalId = null;

    _localStream?.getTracks().forEach((track) => track.stop());
    _localStream?.dispose();
    _localStream = null;

    _peerConnection?.close();
    _peerConnection = null;

    _currentCallId = null;
    _calleeDisplayName = null;
    _callerDisplayName = null;
    _incomingCallId = null;
    _incomingCallerName = null;
    _incomingTripId = null;
    _isIncoming = false;
    _isMuted = false;
    _isSpeaker = false;
    _callDuration = 0;
    _callState = CallState.idle;
  }

  @override
  void onClose() {
    disposeCalling();
    super.onClose();
  }
}
