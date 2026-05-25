import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import 'auth_service.dart';
import 'auth_token_notifier.dart';

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  IO.Socket? _socket;
  bool _isConnected = false;
  bool _wasOnline = false;
  double? _lastLat;
  double? _lastLng;
  String? _activeTripId; // tracks current trip for room rejoin on reconnect
  DateTime? _lastLocationSentAt; // for auto-offline detection
  Timer? _heartbeatTimer;
  bool _appInBackground = false;
  StreamSubscription<AuthTokenEvent>? _authTokenSubscription;
  Future<void>? _connectFuture;
  bool _authRecoveryInFlight = false;
  String? _baseUrl;
  String? _socketToken;
  String? _socketUserId;
  int _socketEpoch = 0;

  final _newTripController = StreamController<Map<String, dynamic>>.broadcast();
  final _tripCancelledController = StreamController<Map<String, dynamic>>.broadcast();
  final _tripStatusController = StreamController<Map<String, dynamic>>.broadcast();
  final _connectedController = StreamController<bool>.broadcast();
  final _tripTakenController = StreamController<Map<String, dynamic>>.broadcast();
  final _tripTimeoutController = StreamController<Map<String, dynamic>>.broadcast();
  final _chatMessageController = StreamController<Map<String, dynamic>>.broadcast();
  final _messageHistoryController = StreamController<Map<String, dynamic>>.broadcast();
  final _noDriversController = StreamController<Map<String, dynamic>>.broadcast();
  final _newParcelController = StreamController<Map<String, dynamic>>.broadcast();
  final _walletRechargedController = StreamController<Map<String, dynamic>>.broadcast();
  final _walletUpdatedController = StreamController<Map<String, dynamic>>.broadcast();
  final _poolNewPassengerController = StreamController<Map<String, dynamic>>.broadcast();
  final _poolSeatUpdateController = StreamController<Map<String, dynamic>>.broadcast();
  final _poolPassengerCancelledController = StreamController<Map<String, dynamic>>.broadcast();
  final _configUpdatedController = StreamController<Map<String, dynamic>>.broadcast();
  final _callIncomingController = StreamController<Map<String, dynamic>>.broadcast();
  final _callOfferController = StreamController<Map<String, dynamic>>.broadcast();
  final _callAnswerController = StreamController<Map<String, dynamic>>.broadcast();
  final _callIceController = StreamController<Map<String, dynamic>>.broadcast();
  final _callEndedController = StreamController<Map<String, dynamic>>.broadcast();
  final _callRejectedController = StreamController<Map<String, dynamic>>.broadcast();
  final _callErrorController = StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get onNewTrip => _newTripController.stream;
  Stream<Map<String, dynamic>> get onTripCancelled => _tripCancelledController.stream;
  Stream<Map<String, dynamic>> get onTripStatus => _tripStatusController.stream;
  Stream<bool> get onConnectionChanged => _connectedController.stream;
  Stream<Map<String, dynamic>> get onTripTaken => _tripTakenController.stream;
  Stream<Map<String, dynamic>> get onTripTimeout => _tripTimeoutController.stream;
  Stream<Map<String, dynamic>> get onChatMessage => _chatMessageController.stream;
  Stream<Map<String, dynamic>> get onMessageHistory => _messageHistoryController.stream;
  Stream<Map<String, dynamic>> get onNoDrivers => _noDriversController.stream;
  Stream<Map<String, dynamic>> get onNewParcel => _newParcelController.stream;
  Stream<Map<String, dynamic>> get onWalletRecharged => _walletRechargedController.stream;
  Stream<Map<String, dynamic>> get onWalletUpdated => _walletUpdatedController.stream;
  Stream<Map<String, dynamic>> get onPoolNewPassenger => _poolNewPassengerController.stream;
  Stream<Map<String, dynamic>> get onPoolSeatUpdate => _poolSeatUpdateController.stream;
  Stream<Map<String, dynamic>> get onPoolPassengerCancelled => _poolPassengerCancelledController.stream;
  Stream<Map<String, dynamic>> get onConfigUpdated => _configUpdatedController.stream;
  Stream<Map<String, dynamic>> get onCallIncoming => _callIncomingController.stream;
  Stream<Map<String, dynamic>> get onCallOffer => _callOfferController.stream;
  Stream<Map<String, dynamic>> get onCallAnswer => _callAnswerController.stream;
  Stream<Map<String, dynamic>> get onCallIce => _callIceController.stream;
  Stream<Map<String, dynamic>> get onCallEnded => _callEndedController.stream;
  Stream<Map<String, dynamic>> get onCallRejected => _callRejectedController.stream;
  Stream<Map<String, dynamic>> get onCallError => _callErrorController.stream;
  bool get isConnected => _isConnected;

  void _socketLog(String event, Map<String, Object?> data) {
    try {
      debugPrint('[SOCKET_EVENT] ${jsonEncode({
        'event': event,
        'ts': DateTime.now().toIso8601String(),
        'userType': 'driver',
        ...data,
      })}');
    } catch (_) {
      debugPrint('[SOCKET_EVENT] $event');
    }
  }

  void _bindAuthTokenListener() {
    _authTokenSubscription ??=
        AuthTokenNotifier.instance.changes.listen((event) {
      if (event.reason == 'session_cleared') {
        disconnect(reason: 'auth_session_cleared');
        return;
      }
      reconnectWithLatestToken(reason: 'auth_token_${event.reason}');
    });
  }

  void _disposeSocket(String reason) {
    final socket = _socket;
    _socket = null;
    _socketToken = null;
    _socketUserId = null;
    _isConnected = false;
    if (socket != null) {
      try {
        socket.dispose();
      } catch (_) {
        try {
          socket.disconnect();
        } catch (_) {}
      }
      _socketLog('SOCKET_DISCONNECT', {'reason': reason});
    }
    _connectedController.add(false);
  }

  Future<void> reconnectWithLatestToken({String reason = 'manual'}) async {
    final baseUrl = _baseUrl;
    if (baseUrl == null || baseUrl.isEmpty) return;
    _socketLog('SOCKET_RECONNECT', {'reason': reason});
    _disposeSocket(reason);
    await connect(baseUrl);
  }

  Future<Map<String, String>> _loadSocketIdentity() async {
    final prefs = await SharedPreferences.getInstance();
    var userId = prefs.getString('user_id') ?? '';
    final token = prefs.getString('auth_token') ?? '';

    if (userId.isEmpty) {
      final userJson = prefs.getString('user_data') ?? '';
      if (userJson.isNotEmpty) {
        try {
          final user = jsonDecode(userJson) as Map<String, dynamic>;
          final recovered = user['id']?.toString() ??
              user['userId']?.toString() ??
              user['user_id']?.toString() ??
              '';
          if (recovered.isNotEmpty) {
            await prefs.setString('user_id', recovered);
            userId = recovered;
          }
        } catch (e) {
          _socketLog('SOCKET_AUTH_FAIL', {
            'reason': 'user_id_recovery_failed',
            'error': e.toString(),
          });
        }
      }
    }

    return {'userId': userId, 'token': token};
  }

  void setAppInBackground(bool value) {
    _appInBackground = value;
  }

  String _eventTripId(Map<String, dynamic> data) {
    final direct = data['tripId'] ?? data['trip_id'] ?? data['id'];
    if (direct != null && direct.toString().isNotEmpty) {
      return direct.toString();
    }
    final trip = data['trip'];
    if (trip is Map) {
      final nested = trip['tripId'] ?? trip['trip_id'] ?? trip['id'];
      if (nested != null && nested.toString().isNotEmpty) {
        return nested.toString();
      }
    }
    return '';
  }

  bool _matchesActiveTrip(Map<String, dynamic> data) {
    final activeTripId = _activeTripId;
    if (activeTripId == null || activeTripId.isEmpty) return true;
    final eventTripId = _eventTripId(data);
    return eventTripId.isNotEmpty && eventTripId == activeTripId;
  }

  void _emitActiveTripRejoin() {
    final tripId = _activeTripId;
    if (tripId != null && _isConnected && _socket != null) {
      _socket!.emit('driver:rejoin_trip', {'tripId': tripId});
    }
  }

  void ackAlertDisplayed(Map<String, dynamic> data, String source) {
    if (!_isConnected || _socket == null) return;
    final tripId = (data['tripId'] ?? data['trip_id'] ?? data['id'] ?? '').toString();
    final orderId = (data['orderId'] ?? data['order_id'] ?? '').toString();
    final bookingTraceId = (data['bookingTraceId'] ?? data['booking_trace_id'] ?? tripId).toString();
    _socket!.emit('driver:alert_displayed', {
      'tripId': tripId.isEmpty ? null : tripId,
      'orderId': orderId.isEmpty ? null : orderId,
      'bookingTraceId': bookingTraceId.isEmpty ? null : bookingTraceId,
      'source': source,
      'channel': 'driver_socket',
      'displayedAt': DateTime.now().toIso8601String(),
    });
  }

  Future<void> _handleAuthFailure(dynamic data, String source) async {
    if (_authRecoveryInFlight) {
      _socketLog('SOCKET_RECONNECT_FAILED', {
        'reason': 'auth_recovery_already_running',
        'source': source,
      });
      return;
    }
    _authRecoveryInFlight = true;
    _socketLog('SOCKET_AUTH_FAIL', {
      'source': source,
      'reason': data is Map ? data['message']?.toString() : data?.toString(),
    });
    try {
      final refreshed = await AuthService.refreshOnce();
      if (!refreshed) {
        _disposeSocket('auth_refresh_failed');
        return;
      }
      await reconnectWithLatestToken(reason: 'auth_refresh_success');
    } finally {
      _authRecoveryInFlight = false;
    }
  }

  Future<void> connect(String baseUrl) async {
    _baseUrl = baseUrl;
    _bindAuthTokenListener();
    final existingConnect = _connectFuture;
    if (existingConnect != null) {
      await existingConnect;
      return;
    }

    _connectFuture = _connectInternal(baseUrl);
    try {
      await _connectFuture;
    } finally {
      _connectFuture = null;
    }
  }

  Future<void> _connectInternal(String baseUrl) async {
    final identity = await _loadSocketIdentity();
    final userId = identity['userId'] ?? '';
    final token = identity['token'] ?? '';

    _socketLog('SOCKET_AUTH_START', {
      'hasUserId': userId.isNotEmpty,
      'hasToken': token.isNotEmpty,
    });

    if (userId.isEmpty || token.isEmpty) {
      _socketLog('SOCKET_AUTH_FAIL', {
        'reason': userId.isEmpty ? 'missing_user_id' : 'missing_token',
      });
      _disposeSocket('missing_socket_identity');
      return;
    }

    if (_socket?.connected == true &&
        _socketToken == token &&
        _socketUserId == userId) {
      _socketLog('SOCKET_DUPLICATE_LISTENER_BLOCKED', {
        'reason': 'already_connected_same_identity',
      });
      if (_wasOnline) {
        _socket!.emit('driver:online', {
          'isOnline': true,
          if (_lastLat != null) 'lat': _lastLat,
          if (_lastLng != null) 'lng': _lastLng,
        });
      }
      _emitActiveTripRejoin();
      return;
    }

    if (_socket != null) {
      _disposeSocket('identity_changed_or_stale_socket');
    }

    final socketEpoch = ++_socketEpoch;
    _socketToken = token;
    _socketUserId = userId;

    final socket = IO.io(
      baseUrl,
      IO.OptionBuilder()
          .setTransports(['websocket', 'polling'])
          .setQuery({'userId': userId, 'userType': 'driver', 'token': token})
          .setAuth({'token': token})
          .disableAutoConnect()
          .enableForceNew()
          .enableReconnection()
          .setReconnectionAttempts(20)
          .setReconnectionDelay(1000)
          .setReconnectionDelayMax(30000)
          .setRandomizationFactor(0.5)
          .setTimeout(20000)
          .build(),
    );
    _socket = socket;

    void bind(String event, Function(dynamic) handler) {
      socket.off(event);
      socket.on(event, handler);
    }

    void restoreRoomsAndState(String source) {
      if (socketEpoch != _socketEpoch) return;
      if (_wasOnline) {
        socket.emit('driver:online', {
          'isOnline': true,
          if (_lastLat != null) 'lat': _lastLat,
          if (_lastLng != null) 'lng': _lastLng,
        });
      }
      if (_activeTripId != null) {
        _emitActiveTripRejoin();
        if (_lastLat != null && _lastLng != null) {
          socket.emit('driver:location', {
            'lat': _lastLat,
            'lng': _lastLng,
            'heading': 0,
            'speed': 0,
          });
        }
      }
      _socketLog('SOCKET_ROOM_JOIN', {
        'source': source,
        if (_activeTripId != null) 'tripId': _activeTripId,
      });
    }

    bind('connect', (_) {
      if (socketEpoch != _socketEpoch) return;
      _isConnected = true;
      _connectedController.add(true);
      _socketLog('SOCKET_AUTH_SUCCESS', {'socketEpoch': socketEpoch});
      _socketLog('SOCKET_CONNECT', {'socketEpoch': socketEpoch});
      restoreRoomsAndState('connect');
    });

    // On reconnect after server restart: restore online status so driver stays visible
    bind('reconnect', (attempt) {
      if (socketEpoch != _socketEpoch) return;
      _isConnected = true;
      _connectedController.add(true);
      _socketLog('SOCKET_RECONNECT', {'attempt': attempt});
      restoreRoomsAndState('reconnect');
    });

    bind('reconnect_attempt', (attempt) {
      _socketLog('SOCKET_RECONNECT', {
        'attempt': attempt,
        'phase': 'attempt',
      });
    });

    bind('reconnect_error', (err) {
      _socketLog('SOCKET_RECONNECT_FAILED', {
        'phase': 'reconnect_error',
        'error': err?.toString(),
      });
    });

    bind('reconnect_failed', (err) {
      _isConnected = false;
      _connectedController.add(false);
      _socketLog('SOCKET_RECONNECT_FAILED', {
        'phase': 'exhausted',
        'error': err?.toString(),
      });
    });

    bind('connect_error', (err) {
      _isConnected = false;
      _connectedController.add(false);
      final errorText = err?.toString() ?? '';
      _socketLog('SOCKET_AUTH_FAIL', {
        'source': 'connect_error',
        'error': errorText,
      });
      if (errorText.toLowerCase().contains('auth') ||
          errorText.toLowerCase().contains('token') ||
          errorText.toLowerCase().contains('unauthorized')) {
        _handleAuthFailure(errorText, 'connect_error');
      }
    });

    bind('auth:error', (data) {
      _handleAuthFailure(data, 'auth:error');
    });

    bind('disconnect', (reason) {
      if (socketEpoch != _socketEpoch) return;
      _isConnected = false;
      _connectedController.add(false);
      _socketLog('SOCKET_DISCONNECT', {'reason': reason?.toString()});
    });

    bind('trip:new_request', (data) {
      _newTripController.add(Map<String, dynamic>.from(data));
    });

    bind('trip:cancelled', (data) {
      final payload = Map<String, dynamic>.from(data);
      if (!_matchesActiveTrip(payload)) return;
      setActiveTrip(null);
      _tripCancelledController.add(payload);
    });

    bind('trip:status_update', (data) {
      final payload = Map<String, dynamic>.from(data);
      if (!_matchesActiveTrip(payload)) return;
      final status =
          (payload['status'] ?? payload['currentStatus'] ?? '').toString();
      if (status == 'completed' || status == 'cancelled') {
        setActiveTrip(null);
      }
      _tripStatusController.add(payload);
    });

    bind('trip:request_taken', (data) {
      _tripTakenController.add(Map<String, dynamic>.from(data));
    });

    // Backend emits 'trip:offer_timeout' when driver doesn't respond in time
    bind('trip:offer_timeout', (data) {
      _tripTimeoutController.add(Map<String, dynamic>.from(data));
    });
    // Also handle legacy event name
    bind('trip:timeout', (data) {
      _tripTimeoutController.add(Map<String, dynamic>.from(data));
    });

    // In-app chat message received (live)
    bind('trip:new_message', (data) {
      _chatMessageController.add(Map<String, dynamic>.from(data));
    });

    // Chat history loaded from DB on reconnect
    bind('trip:message_history', (data) {
      _messageHistoryController.add(Map<String, dynamic>.from(data));
    });

    // No available drivers found within all reassignment rounds
    bind('trip:no_drivers', (data) {
      _noDriversController.add(Map<String, dynamic>.from(data));
    });

    // Parcel delivery request
    bind('parcel:new_request', (data) {
      _newParcelController.add(Map<String, dynamic>.from(data));
    });

    // Wallet recharged (after Razorpay payment verified)
    bind('wallet:recharged', (data) {
      final payload = Map<String, dynamic>.from(data);
      _walletRechargedController.add(payload);
      _walletUpdatedController.add(payload);
    });
    bind('wallet:updated', (data) {
      _walletUpdatedController.add(Map<String, dynamic>.from(data));
    });
    bind('pool:new_passenger', (data) {
      _poolNewPassengerController.add(Map<String, dynamic>.from(data));
    });
    bind('pool:seat_update', (data) {
      _poolSeatUpdateController.add(Map<String, dynamic>.from(data));
    });
    bind('pool:passenger_cancelled', (data) {
      _poolPassengerCancelledController.add(Map<String, dynamic>.from(data));
    });
    bind('config:updated', (data) {
      _configUpdatedController.add(Map<String, dynamic>.from(data));
    });

    // ── WebRTC Call Signaling ──────────────────────────────────
    bind('call:incoming', (data) {
      _callIncomingController.add(Map<String, dynamic>.from(data));
    });
    bind('call:offer', (data) {
      _callOfferController.add(Map<String, dynamic>.from(data));
    });
    bind('call:answer', (data) {
      _callAnswerController.add(Map<String, dynamic>.from(data));
    });
    bind('call:ice', (data) {
      _callIceController.add(Map<String, dynamic>.from(data));
    });
    bind('call:ended', (data) {
      _callEndedController.add(Map<String, dynamic>.from(data));
    });
    bind('call:rejected', (data) {
      _callRejectedController.add(Map<String, dynamic>.from(data));
    });
    bind('call:error', (data) {
      _callErrorController.add(Map<String, dynamic>.from(data));
    });

    // Ping/pong: server pings driver to confirm still active; auto-respond immediately.
    // If driver misses 3 consecutive pings the server applies a penalty automatically.
    bind('system:ping_request', (data) {
      if (_isConnected) {
        socket.emit('system:ping_response', {
          'driverId': userId,
          if (data is Map && data['pingId'] != null) 'pingId': data['pingId'],
          if (data is Map && data['tripId'] != null) 'tripId': data['tripId'],
        });
      }
    });
    bind('ping_request', (data) {
      if (_isConnected) {
        socket.emit('ping_response', {
          'driverId': userId,
          if (data is Map && data['pingId'] != null) 'pingId': data['pingId'],
          if (data is Map && data['tripId'] != null) 'tripId': data['tripId'],
        });
      }
    });

    _socketLog('SOCKET_CONNECT', {'phase': 'connecting'});
    socket.connect();
    _startHeartbeat();
  }

  /// Heartbeat: if driver is online but no location sent for 15s → auto-offline.
  /// Prevents ghost-online drivers who have GPS failures.
  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (!_wasOnline) return;
      if (_appInBackground || _activeTripId != null) return;
      final last = _lastLocationSentAt;
      if (last == null) return;
      final stale = DateTime.now().difference(last).inSeconds >= 15;
      if (stale && _isConnected) {
        // GPS failed or app went background — mark driver offline
        _socket!.emit('driver:online', {'isOnline': false});
        _wasOnline = false;
      }
    });
  }

  /// Call when driver enters/exits a trip so socket can rejoin room on reconnect.
  /// Also joins the room immediately if connected.
  void setActiveTrip(String? tripId) {
    final normalized = tripId?.trim();
    final previousTripId = _activeTripId;
    _activeTripId = (normalized == null || normalized.isEmpty) ? null : normalized;
    if (previousTripId != null &&
        previousTripId.isNotEmpty &&
        previousTripId != _activeTripId &&
        _isConnected &&
        _socket != null) {
      _socket!.emit('driver:leave_trip', {'tripId': previousTripId});
      _socketLog('SOCKET_ROOM_LEAVE', {'tripId': previousTripId});
    }
    if (_activeTripId != null && previousTripId != _activeTripId) {
      _emitActiveTripRejoin();
    }
  }

  void sendLocation({
    required double lat,
    required double lng,
    double heading = 0,
    double speed = 0,
    int? remainingDistanceMeters,
    int? etaSeconds,
  }) {
    _lastLat = lat;
    _lastLng = lng;
    _lastLocationSentAt = DateTime.now();
    if (_isConnected) {
      _socket!.emit('driver:location', {
        'lat': lat,
        'lng': lng,
        'heading': heading,
        'speed': speed,
        if (remainingDistanceMeters != null) 'remainingDistanceMeters': remainingDistanceMeters,
        if (etaSeconds != null) 'etaSeconds': etaSeconds,
      });
      return;
    }
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
    } catch (e) {
      _socketLog('SOCKET_RECONNECT_FAILED', {
        'reason': 'location_http_fallback_failed',
        'error': e.toString(),
      });
    }
  }

  void setOnlineStatus({required bool isOnline, double? lat, double? lng}) {
    _wasOnline = isOnline;
    if (lat != null) _lastLat = lat;
    if (lng != null) _lastLng = lng;
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
    } catch (e) {
      _socketLog('SOCKET_RECONNECT_FAILED', {
        'reason': 'online_http_fallback_failed',
        'error': e.toString(),
      });
    }
  }

  Future<bool> acceptTrip(String tripId) async {
    if (!_isConnected) return false;
    final completer = Completer<bool>();

    // Safe complete guard — prevents double-completion race between ack and once listeners
    void safeComplete(bool value) {
      if (!completer.isCompleted) completer.complete(value);
    }

    _socket!.emitWithAck('driver:accept_trip', {'tripId': tripId}, ack: (data) {
      if (data is Map && data['ok'] == false) {
        safeComplete(false);
        return;
      }
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

  void sendCallOffer({required String targetUserId, required String tripId, required dynamic sdp}) {
    if (!_isConnected) return;
    _socket!.emit('call:offer', {'targetUserId': targetUserId, 'tripId': tripId, 'sdp': sdp});
  }

  void sendCallAnswer({required String targetUserId, required String tripId, required dynamic sdp}) {
    if (!_isConnected) return;
    _socket!.emit('call:answer', {'targetUserId': targetUserId, 'tripId': tripId, 'sdp': sdp});
  }

  void sendIceCandidate({required String targetUserId, required String tripId, required dynamic candidate}) {
    if (!_isConnected) return;
    _socket!.emit('call:ice', {'targetUserId': targetUserId, 'tripId': tripId, 'candidate': candidate});
  }

  void endCall({required String targetUserId, String? tripId, int? durationSec}) {
    if (!_isConnected) return;
    _socket!.emit('call:end', {'targetUserId': targetUserId, if (tripId != null) 'tripId': tripId, if (durationSec != null) 'durationSec': durationSec});
  }

  void rejectCall({required String targetUserId, String? tripId}) {
    if (!_isConnected) return;
    _socket!.emit('call:reject', {'targetUserId': targetUserId, if (tripId != null) 'tripId': tripId});
  }

  void disconnect({String reason = 'manual'}) {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    _disposeSocket(reason);
  }

  void dispose() {
    _authTokenSubscription?.cancel();
    _authTokenSubscription = null;
    disconnect(reason: 'service_dispose');
    _newTripController.close();
    _tripCancelledController.close();
    _tripStatusController.close();
    _connectedController.close();
    _tripTakenController.close();
    _tripTimeoutController.close();
    _chatMessageController.close();
    _messageHistoryController.close();
    _newParcelController.close();
    _noDriversController.close();
    _walletRechargedController.close();
    _walletUpdatedController.close();
    _poolNewPassengerController.close();
    _poolSeatUpdateController.close();
    _poolPassengerCancelledController.close();
    _configUpdatedController.close();
    _callIncomingController.close();
    _callOfferController.close();
    _callAnswerController.close();
    _callIceController.close();
    _callEndedController.close();
    _callRejectedController.close();
    _callErrorController.close();
  }
}
