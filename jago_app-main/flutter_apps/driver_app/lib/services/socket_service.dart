import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import 'active_ride_persistence_service.dart';

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  IO.Socket? _socket;
  bool _isConnected = false;
  bool _wasOnline = false;
  double? _lastLat;
  double? _lastLng;
  double _lastHeading = 0;
  double _lastSpeed = 0;
  String? _activeTripId; // tracks current trip for room rejoin on reconnect
  DateTime? _lastLocationSentAt; // for auto-offline detection
  Timer? _heartbeatTimer;
  int _lastTripEventAtMs = 0;
  String _lastTripStateVersion = '';
  final List<Map<String, dynamic>> _pendingLocationPayloads = [];

  final _newTripController = StreamController<Map<String, dynamic>>.broadcast();
  final _tripCancelledController = StreamController<Map<String, dynamic>>.broadcast();
  final _tripStatusController = StreamController<Map<String, dynamic>>.broadcast();
  final _tripRecoveredController = StreamController<Map<String, dynamic>>.broadcast();
  final _connectedController = StreamController<bool>.broadcast();
  final _tripTakenController = StreamController<Map<String, dynamic>>.broadcast();
  final _tripTimeoutController = StreamController<Map<String, dynamic>>.broadcast();
  final _chatMessageController = StreamController<Map<String, dynamic>>.broadcast();
  final _messageHistoryController = StreamController<Map<String, dynamic>>.broadcast();
  final _noDriversController = StreamController<Map<String, dynamic>>.broadcast();
  final _newParcelController = StreamController<Map<String, dynamic>>.broadcast();
  final _walletRechargedController = StreamController<Map<String, dynamic>>.broadcast();
  final _callIncomingController = StreamController<Map<String, dynamic>>.broadcast();
  final _callOfferController = StreamController<Map<String, dynamic>>.broadcast();
  final _callAnswerController = StreamController<Map<String, dynamic>>.broadcast();
  final _callIceController = StreamController<Map<String, dynamic>>.broadcast();
  final _callEndedController = StreamController<Map<String, dynamic>>.broadcast();
  final _callRejectedController = StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get onNewTrip => _newTripController.stream;
  Stream<Map<String, dynamic>> get onTripCancelled => _tripCancelledController.stream;
  Stream<Map<String, dynamic>> get onTripStatus => _tripStatusController.stream;
  Stream<Map<String, dynamic>> get onTripRecovered => _tripRecoveredController.stream;
  Stream<bool> get onConnectionChanged => _connectedController.stream;
  Stream<Map<String, dynamic>> get onTripTaken => _tripTakenController.stream;
  Stream<Map<String, dynamic>> get onTripTimeout => _tripTimeoutController.stream;
  Stream<Map<String, dynamic>> get onChatMessage => _chatMessageController.stream;
  Stream<Map<String, dynamic>> get onMessageHistory => _messageHistoryController.stream;
  Stream<Map<String, dynamic>> get onNoDrivers => _noDriversController.stream;
  Stream<Map<String, dynamic>> get onNewParcel => _newParcelController.stream;
  Stream<Map<String, dynamic>> get onWalletRecharged => _walletRechargedController.stream;
  Stream<Map<String, dynamic>> get onCallIncoming => _callIncomingController.stream;
  Stream<Map<String, dynamic>> get onCallOffer => _callOfferController.stream;
  Stream<Map<String, dynamic>> get onCallAnswer => _callAnswerController.stream;
  Stream<Map<String, dynamic>> get onCallIce => _callIceController.stream;
  Stream<Map<String, dynamic>> get onCallEnded => _callEndedController.stream;
  Stream<Map<String, dynamic>> get onCallRejected => _callRejectedController.stream;
  bool get isConnected => _isConnected;

  Future<void> connect(String baseUrl) async {
    if (_socket?.connected == true) return;

    final prefs = await SharedPreferences.getInstance();
    var userId = prefs.getString('user_id') ?? '';
    final token = prefs.getString('auth_token') ?? '';

    // Recovery: existing installs before the user_id fix may have empty user_id.
    // Attempt to extract it from the saved user JSON so they don't need to reinstall.
    if (userId.isEmpty) {
      final userJson = prefs.getString('user_data') ?? '';
      if (userJson.isNotEmpty) {
        try {
          final user = jsonDecode(userJson) as Map<String, dynamic>;
          final recovered = user['id']?.toString() ??
              user['userId']?.toString() ??
              user['user_id']?.toString() ?? '';
          if (recovered.isNotEmpty) {
            await prefs.setString('user_id', recovered);
            userId = recovered;
          }
        } catch (_) {}
      }
    }

    if (userId.isEmpty) return;

    final persistedTracking = await ActiveRidePersistenceService.loadTrackingContext();
    _activeTripId ??= persistedTracking['tripId']?.toString();
    _wasOnline = persistedTracking['wasOnline'] == true || _wasOnline;
    _lastLat ??= persistedTracking['lastLat'] as double?;
    _lastLng ??= persistedTracking['lastLng'] as double?;
    _lastHeading = (persistedTracking['heading'] as double?) ?? _lastHeading;
    _lastSpeed = (persistedTracking['speed'] as double?) ?? _lastSpeed;

    _socket = IO.io(
      baseUrl,
      IO.OptionBuilder()
          .setTransports(['websocket', 'polling'])
          .setQuery({'userId': userId, 'userType': 'driver', 'token': token})
          .enableAutoConnect()
          .enableReconnection()
          .setReconnectionAttempts(999)
          .setReconnectionDelay(3000)
          .build(),
    );

    _socket!.on('connect', (_) {
      _isConnected = true;
      _connectedController.add(true);
      _restoreDriverRuntimeState();
    });

    // On reconnect after server restart: restore online status so driver stays visible
    _socket!.on('reconnect', (_) {
      _restoreDriverRuntimeState();
    });

    _socket!.on('disconnect', (_) {
      _isConnected = false;
      _connectedController.add(false);
    });

    _socket!.on('trip:new_request', (data) {
      _newTripController.add(Map<String, dynamic>.from(data));
    });

    _socket!.on('trip:cancelled', (data) {
      _tripCancelledController.add(Map<String, dynamic>.from(data));
    });

    _socket!.on('trip:status_update', (data) {
      final payload = Map<String, dynamic>.from(data);
      if (_isStaleTripPayload(payload)) {
        return;
      }
      _rememberTripPayload(payload);
      _tripStatusController.add(payload);
    });

    _socket!.on('trip:recovered', (data) {
      final payload = Map<String, dynamic>.from(data);
      if (_isStaleTripPayload(payload)) {
        return;
      }
      _rememberTripPayload(payload);
      _tripRecoveredController.add(payload);
      _tripStatusController.add(payload);
    });

    _socket!.on('trip:request_taken', (data) {
      _tripTakenController.add(Map<String, dynamic>.from(data));
    });

    // Backend emits 'trip:offer_timeout' when driver doesn't respond in time
    _socket!.on('trip:offer_timeout', (data) {
      _tripTimeoutController.add(Map<String, dynamic>.from(data));
    });
    // Also handle legacy event name
    _socket!.on('trip:timeout', (data) {
      _tripTimeoutController.add(Map<String, dynamic>.from(data));
    });

    // In-app chat message received (live)
    _socket!.on('trip:new_message', (data) {
      _chatMessageController.add(Map<String, dynamic>.from(data));
    });

    // Chat history loaded from DB on reconnect
    _socket!.on('trip:message_history', (data) {
      _messageHistoryController.add(Map<String, dynamic>.from(data));
    });

    // No available drivers found within all reassignment rounds
    _socket!.on('trip:no_drivers', (data) {
      _noDriversController.add(Map<String, dynamic>.from(data));
    });

    // Parcel delivery request
    _socket!.on('parcel:new_request', (data) {
      _newParcelController.add(Map<String, dynamic>.from(data));
    });

    // Wallet recharged (after Razorpay payment verified)
    _socket!.on('wallet:recharged', (data) {
      _walletRechargedController.add(Map<String, dynamic>.from(data));
    });

    // ── WebRTC Call Signaling ──────────────────────────────────
    _socket!.on('call:incoming', (data) {
      _callIncomingController.add(Map<String, dynamic>.from(data));
    });
    _socket!.on('call:offer', (data) {
      _callOfferController.add(Map<String, dynamic>.from(data));
    });
    _socket!.on('call:answer', (data) {
      _callAnswerController.add(Map<String, dynamic>.from(data));
    });
    _socket!.on('call:ice', (data) {
      _callIceController.add(Map<String, dynamic>.from(data));
    });
    _socket!.on('call:ended', (data) {
      _callEndedController.add(Map<String, dynamic>.from(data));
    });
    _socket!.on('call:rejected', (data) {
      _callRejectedController.add(Map<String, dynamic>.from(data));
    });

    // Ping/pong: server pings driver to confirm still active; auto-respond immediately.
    // If driver misses 3 consecutive pings the server applies a penalty automatically.
    _socket!.on('ping_request', (data) {
      if (_isConnected) {
        _socket!.emit('ping_response', {
          'driverId': userId,
          if (data is Map && data['pingId'] != null) 'pingId': data['pingId'],
        });
      }
    });

    _socket!.connect();
    _startHeartbeat();
  }

  /// Heartbeat: if driver is online but no location sent for 15s → auto-offline.
  /// Prevents ghost-online drivers who have GPS failures.
  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (!_wasOnline) return;
      final last = _lastLocationSentAt;
      if (last == null) return;
      final stale = DateTime.now().difference(last).inSeconds >= 15;
      if (stale &&
          _isConnected &&
          _activeTripId != null &&
          _lastLat != null &&
          _lastLng != null) {
        _postLocationViaHttp(
          lat: _lastLat!,
          lng: _lastLng!,
          heading: _lastHeading,
          speed: _lastSpeed,
        );
        _socket?.emit('driver:rejoin_trip', {'tripId': _activeTripId});
        return;
      }
      if (stale && _isConnected) {
        // GPS failed or app went background — mark driver offline
        _socket!.emit('driver:online', {'isOnline': false});
        _wasOnline = false;
        ActiveRidePersistenceService.updateTrackingHeartbeat(wasOnline: false);
      }
    });
  }

  /// Call when driver enters/exits a trip so socket can rejoin room on reconnect.
  /// Also joins the room immediately if connected.
  void setActiveTrip(String? tripId) {
    _activeTripId = tripId;
    if (tripId == null || tripId.isEmpty) {
      ActiveRidePersistenceService.clearActiveRide();
    } else {
      ActiveRidePersistenceService.updateTrackingHeartbeat(
        tripId: tripId,
        wasOnline: _wasOnline,
        lat: _lastLat,
        lng: _lastLng,
      );
    }
    if (tripId != null && _isConnected && _socket != null) {
      _socket!.emit('driver:rejoin_trip', {'tripId': tripId});
    }
  }

  void sendLocation({required double lat, required double lng, double heading = 0, double speed = 0}) {
    _lastLat = lat;
    _lastLng = lng;
    _lastHeading = heading;
    _lastSpeed = speed;
    _lastLocationSentAt = DateTime.now();
    final payload = {
      'lat': lat,
      'lng': lng,
      'heading': heading,
      'speed': speed,
    };
    ActiveRidePersistenceService.updateTrackingHeartbeat(
      tripId: _activeTripId,
      lat: lat,
      lng: lng,
      heading: heading,
      speed: speed,
      wasOnline: _wasOnline,
    );
    if (_isConnected) {
      _socket!.emit('driver:location', payload);
      return;
    }
    if (_pendingLocationPayloads.length >= 8) {
      _pendingLocationPayloads.removeAt(0);
    }
    _pendingLocationPayloads.add(payload);
    _postLocationViaHttp(
      lat: lat,
      lng: lng,
      heading: heading,
      speed: speed,
    );
  }

  Future<void> _postLocationViaHttp({
    required double lat,
    required double lng,
    double heading = 0,
    double speed = 0,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null || token.isEmpty) return;
      await http.post(
        Uri.parse(ApiConfig.driverLocation),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'lat': lat,
          'lng': lng,
          'heading': heading,
          'speed': speed,
          'isOnline': _wasOnline,
        }),
      ).timeout(const Duration(seconds: 10));
    } catch (_) {}
  }

  void setOnlineStatus({required bool isOnline, double? lat, double? lng}) {
    _wasOnline = isOnline;
    if (lat != null) _lastLat = lat;
    if (lng != null) _lastLng = lng;
    ActiveRidePersistenceService.updateTrackingHeartbeat(
      tripId: _activeTripId,
      wasOnline: isOnline,
      lat: _lastLat,
      lng: _lastLng,
    );
    if (_isConnected) {
      _socket!.emit('driver:online', {
        'isOnline': isOnline,
        if (lat != null) 'lat': lat,
        if (lng != null) 'lng': lng,
      });
    } else {
      // Socket not connected — use HTTP fallback so go-online always works
      _setOnlineViaHttp(isOnline: isOnline, lat: lat, lng: lng);
    }
  }

  Future<void> _setOnlineViaHttp({required bool isOnline, double? lat, double? lng}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) return;
      await http.patch(
        Uri.parse(ApiConfig.driverOnlineStatus),
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
        body: jsonEncode({
          'isOnline': isOnline,
          if (lat != null) 'lat': lat,
          if (lng != null) 'lng': lng,
        }),
      ).timeout(const Duration(seconds: 10));
    } catch (_) {}
  }

  Future<bool> acceptTrip(String tripId) async {
    if (!_isConnected) return false;
    final completer = Completer<bool>();

    // Safe complete guard — prevents double-completion race between ack and once listeners
    void safeComplete(bool value) {
      if (!completer.isCompleted) completer.complete(value);
    }

    _socket!.emitWithAck('driver:accept_trip', {'tripId': tripId}, ack: (data) {
      safeComplete(true);
    });
    _socket!.once('driver:accept_trip_ok', (_) => safeComplete(true));
    _socket!.once('driver:accept_trip_error', (_) => safeComplete(false));

    return completer.future.timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        safeComplete(false);
        return false;
      },
    );
  }

  void updateTripStatus(String tripId, String status, {String? otp}) {
    if (!_isConnected) return;
    _socket!.emit('driver:trip_status', {
      'tripId': tripId,
      'status': status,
      if (otp != null) 'otp': otp,
    });
  }

  // Send in-app chat message (persisted to DB + relayed via socket)
  void sendChatMessage({required String tripId, required String message, required String senderName}) {
    if (!_isConnected) return;
    _socket!.emit('trip:send_message', {
      'tripId': tripId,
      'message': message,
      'senderName': senderName,
      'senderType': 'driver',
    });
  }

  // Load message history from DB (call after joining trip room)
  void loadChatHistory(String tripId) {
    if (!_isConnected) return;
    _socket!.emit('trip:get_messages', {'tripId': tripId});
  }

  // ── WebRTC Call Methods ──────────────────────────────────
  void initiateCall({required String targetUserId, required String tripId, required String callerName}) {
    if (!_isConnected) return;
    _socket!.emit('call:initiate', {'targetUserId': targetUserId, 'tripId': tripId, 'callerName': callerName});
  }

  void sendCallOffer({required String targetUserId, required dynamic sdp}) {
    if (!_isConnected) return;
    _socket!.emit('call:offer', {'targetUserId': targetUserId, 'sdp': sdp});
  }

  void sendCallAnswer({required String targetUserId, required dynamic sdp}) {
    if (!_isConnected) return;
    _socket!.emit('call:answer', {'targetUserId': targetUserId, 'sdp': sdp});
  }

  void sendIceCandidate({required String targetUserId, required dynamic candidate}) {
    if (!_isConnected) return;
    _socket!.emit('call:ice', {'targetUserId': targetUserId, 'candidate': candidate});
  }

  void endCall({required String targetUserId, String? tripId, int? durationSec}) {
    if (!_isConnected) return;
    _socket!.emit('call:end', {'targetUserId': targetUserId, if (tripId != null) 'tripId': tripId, if (durationSec != null) 'durationSec': durationSec});
  }

  void rejectCall({required String targetUserId, String? tripId}) {
    if (!_isConnected) return;
    _socket!.emit('call:reject', {'targetUserId': targetUserId, if (tripId != null) 'tripId': tripId});
  }

  void disconnect() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    _socket?.disconnect();
    _socket = null;
    _isConnected = false;
  }

  void dispose() {
    disconnect();
    _newTripController.close();
    _tripCancelledController.close();
    _tripStatusController.close();
    _tripRecoveredController.close();
    _connectedController.close();
    _tripTakenController.close();
    _tripTimeoutController.close();
    _chatMessageController.close();
    _messageHistoryController.close();
    _newParcelController.close();
    _noDriversController.close();
    _walletRechargedController.close();
    _callIncomingController.close();
    _callOfferController.close();
    _callAnswerController.close();
    _callIceController.close();
    _callEndedController.close();
    _callRejectedController.close();
  }

  int? _parseTimestampMs(dynamic value) {
    final raw = value?.toString();
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw)?.millisecondsSinceEpoch;
  }

  bool _isStaleTripPayload(Map<String, dynamic> payload) {
    final nextStateVersion = payload['stateVersion']?.toString() ?? '';
    final nextEventAt = _parseTimestampMs(payload['serverTimestamp']);
    if (nextStateVersion.isNotEmpty &&
        _lastTripStateVersion.isNotEmpty &&
        nextStateVersion == _lastTripStateVersion &&
        nextEventAt != null &&
        nextEventAt <= _lastTripEventAtMs) {
      return true;
    }
    if (nextEventAt != null && nextEventAt < _lastTripEventAtMs) {
      return true;
    }
    return false;
  }

  void _rememberTripPayload(Map<String, dynamic> payload) {
    final nextStateVersion = payload['stateVersion']?.toString() ?? '';
    final nextEventAt = _parseTimestampMs(payload['serverTimestamp']);
    if (nextStateVersion.isNotEmpty) {
      _lastTripStateVersion = nextStateVersion;
    }
    if (nextEventAt != null) {
      _lastTripEventAtMs = nextEventAt;
    }
  }

  void _restoreDriverRuntimeState() {
    if (!_isConnected || _socket == null) return;
    if (_wasOnline) {
      _socket!.emit('driver:online', {
        'isOnline': true,
        if (_lastLat != null) 'lat': _lastLat,
        if (_lastLng != null) 'lng': _lastLng,
      });
    }
    if (_activeTripId != null) {
      _socket!.emit('driver:rejoin_trip', {'tripId': _activeTripId});
    }
    if (_pendingLocationPayloads.isNotEmpty) {
      for (final payload in List<Map<String, dynamic>>.from(_pendingLocationPayloads)) {
        _socket!.emit('driver:location', payload);
      }
      _pendingLocationPayloads.clear();
      return;
    }
    if (_lastLat != null && _lastLng != null) {
      _socket!.emit('driver:location', {
        'lat': _lastLat,
        'lng': _lastLng,
        'heading': _lastHeading,
        'speed': _lastSpeed,
      });
    }
  }
}
