import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

import 'auth_service.dart';
import 'auth_token_notifier.dart';

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  IO.Socket? _socket;
  bool _isConnected = false;
  String? _activeTripId;
  String? _activeParcelId;
  StreamSubscription<AuthTokenEvent>? _authTokenSubscription;
  Future<void>? _connectFuture;
  bool _authRecoveryInFlight = false;
  String? _baseUrl;
  String? _socketToken;
  String? _socketUserId;
  int _socketEpoch = 0;

  final _driverAssignedController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _driverLocationController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _tripStatusController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _tripCancelledController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _connectedController = StreamController<bool>.broadcast();
  final _chatMessageController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _messageHistoryController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _noDriversController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _tripSearchingController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _paymentPendingController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _poolStatusController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _poolSeatUpdateController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _parcelStatusController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _parcelLocationController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _configUpdatedController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _callIncomingController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _callOfferController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _callAnswerController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _callIceController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _callEndedController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _callRejectedController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _callErrorController =
      StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get onDriverAssigned =>
      _driverAssignedController.stream;
  Stream<Map<String, dynamic>> get onDriverLocation =>
      _driverLocationController.stream;
  Stream<Map<String, dynamic>> get onTripStatus => _tripStatusController.stream;
  Stream<Map<String, dynamic>> get onTripCancelled =>
      _tripCancelledController.stream;
  Stream<bool> get onConnectionChanged => _connectedController.stream;
  Stream<Map<String, dynamic>> get onChatMessage =>
      _chatMessageController.stream;
  Stream<Map<String, dynamic>> get onMessageHistory =>
      _messageHistoryController.stream;
  Stream<Map<String, dynamic>> get onNoDrivers => _noDriversController.stream;
  Stream<Map<String, dynamic>> get onTripSearching =>
      _tripSearchingController.stream;
  Stream<Map<String, dynamic>> get onPaymentPending =>
      _paymentPendingController.stream;
  Stream<Map<String, dynamic>> get onPoolStatus => _poolStatusController.stream;
  Stream<Map<String, dynamic>> get onPoolSeatUpdate =>
      _poolSeatUpdateController.stream;
  Stream<Map<String, dynamic>> get onParcelStatus =>
      _parcelStatusController.stream;
  Stream<Map<String, dynamic>> get onParcelLocation =>
      _parcelLocationController.stream;
  Stream<Map<String, dynamic>> get onConfigUpdated =>
      _configUpdatedController.stream;
  Stream<Map<String, dynamic>> get onCallIncoming =>
      _callIncomingController.stream;
  Stream<Map<String, dynamic>> get onCallOffer => _callOfferController.stream;
  Stream<Map<String, dynamic>> get onCallAnswer => _callAnswerController.stream;
  Stream<Map<String, dynamic>> get onCallIce => _callIceController.stream;
  Stream<Map<String, dynamic>> get onCallEnded => _callEndedController.stream;
  Stream<Map<String, dynamic>> get onCallRejected =>
      _callRejectedController.stream;
  Stream<Map<String, dynamic>> get onCallError => _callErrorController.stream;
  bool get isConnected => _isConnected;

  void _socketLog(String event, Map<String, Object?> data) {
    try {
      debugPrint('[SOCKET_EVENT] ${jsonEncode({
        'event': event,
        'ts': DateTime.now().toIso8601String(),
        'userType': 'customer',
        ...data,
      })}');
    } catch (_) {
      debugPrint('[SOCKET_EVENT] $event');
    }
  }

  void _safeAdd<T>(StreamController<T> controller, T value) {
    if (!controller.isClosed) controller.add(value);
  }

  void _emitConnected(bool value) {
    _isConnected = value;
    _safeAdd(_connectedController, value);
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
    _emitConnected(false);
    if (socket == null) return;
    try {
      socket.dispose();
    } catch (_) {
      try {
        socket.disconnect();
      } catch (_) {}
    }
    _socketLog('SOCKET_DISCONNECT', {'reason': reason});
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

  void _emitTrackTrip(String tripId) {
    final socket = _socket;
    if (socket != null && (_isConnected || socket.connected)) {
      socket.emit('customer:track_trip', {'tripId': tripId});
      _socketLog('SOCKET_ROOM_JOIN', {'roomType': 'trip', 'tripId': tripId});
    }
  }

  void _emitTrackParcel(String orderId) {
    final socket = _socket;
    if (socket != null && (_isConnected || socket.connected)) {
      socket.emit('customer:track_parcel', {'orderId': orderId});
      _socketLog('SOCKET_ROOM_JOIN', {
        'roomType': 'parcel',
        'orderId': orderId,
      });
    }
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
      final refreshed = await AuthService.tryRefreshSession();
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
      if (_activeTripId != null) _emitTrackTrip(_activeTripId!);
      if (_activeParcelId != null) _emitTrackParcel(_activeParcelId!);
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
          .setQuery({'userId': userId, 'userType': 'customer', 'token': token})
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

    void restoreRooms(String source) {
      if (socketEpoch != _socketEpoch) return;
      if (_activeTripId != null) _emitTrackTrip(_activeTripId!);
      if (_activeParcelId != null) _emitTrackParcel(_activeParcelId!);
      _socketLog('SOCKET_ROOM_JOIN', {
        'source': source,
        if (_activeTripId != null) 'tripId': _activeTripId,
        if (_activeParcelId != null) 'orderId': _activeParcelId,
      });
    }

    bind('connect', (_) {
      if (socketEpoch != _socketEpoch) return;
      _emitConnected(true);
      _socketLog('SOCKET_AUTH_SUCCESS', {'socketEpoch': socketEpoch});
      _socketLog('SOCKET_CONNECT', {'socketEpoch': socketEpoch});
      restoreRooms('connect');
    });

    bind('reconnect', (attempt) {
      if (socketEpoch != _socketEpoch) return;
      _emitConnected(true);
      _socketLog('SOCKET_RECONNECT', {'attempt': attempt});
      restoreRooms('reconnect');
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
      _emitConnected(false);
      _socketLog('SOCKET_RECONNECT_FAILED', {
        'phase': 'exhausted',
        'error': err?.toString(),
      });
    });

    bind('disconnect', (reason) {
      if (socketEpoch != _socketEpoch) return;
      _emitConnected(false);
      _socketLog('SOCKET_DISCONNECT', {'reason': reason?.toString()});
    });

    bind('connect_error', (err) {
      _emitConnected(false);
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

    bind('error', (err) {
      _emitConnected(false);
      _socketLog('SOCKET_RECONNECT_FAILED', {
        'phase': 'socket_error',
        'error': err?.toString(),
      });
    });

    bind('auth:error', (data) => _handleAuthFailure(data, 'auth:error'));

    bind('trip:driver_assigned', (data) {
      _safeAdd(_driverAssignedController, Map<String, dynamic>.from(data));
    });

    bind('trip:accepted', (data) {
      final payload = Map<String, dynamic>.from(data);
      if (!_matchesActiveTrip(payload)) return;
      payload['driver'] = payload['driver'] is Map<String, dynamic>
          ? Map<String, dynamic>.from(payload['driver'])
          : {
              'id': payload['driverId'],
              'fullName': payload['driverName'],
              'phone': payload['driverPhone'],
              'rating': payload['driverRating'],
              'photo': payload['driverPhoto'],
              'vehicleNumber': payload['driverVehicleNumber'],
              'vehicleModel': payload['driverVehicleModel'],
              'vehicleCategory': payload['vehicleName'],
              'lat': payload['lat'],
              'lng': payload['lng'],
            };
      payload['eventType'] = 'trip_accepted';
      _safeAdd(_driverAssignedController, payload);
      _safeAdd(_tripStatusController, {
        'tripId': payload['tripId'],
        'status': 'accepted',
        if (payload['pickupOtp'] != null) 'otp': payload['pickupOtp'],
      });
    });

    bind('driver:location_update', (data) {
      _safeAdd(_driverLocationController, Map<String, dynamic>.from(data));
    });

    bind('trip:status_update', (data) {
      if (data == null) return;
      try {
        final payload = Map<String, dynamic>.from(data);
        if (!_matchesActiveTrip(payload)) return;
        final status =
            (payload['status'] ?? payload['currentStatus'] ?? '').toString();
        if (status == 'completed' || status == 'cancelled') {
          final tripId = _activeTripId ?? _eventTripId(payload);
          if (tripId.isNotEmpty) stopTrackingTrip(tripId);
        }
        _safeAdd(_tripStatusController, payload);
      } catch (e) {
        _socketLog('SOCKET_RECONNECT_FAILED', {
          'reason': 'trip_status_parse_failed',
          'error': e.toString(),
        });
      }
    });

    bind('trip:completed', (data) {
      if (data == null) return;
      try {
        final payload = Map<String, dynamic>.from(data);
        if (!_matchesActiveTrip(payload)) return;
        final tripId = _activeTripId ?? _eventTripId(payload);
        if (tripId.isNotEmpty) stopTrackingTrip(tripId);
        _safeAdd(_tripStatusController, {
          'tripId': payload['tripId'],
          'status': 'completed',
          if (payload['walletPendingAmount'] != null)
            'walletPendingAmount': payload['walletPendingAmount'],
          if (payload['walletPaidAmount'] != null)
            'walletPaidAmount': payload['walletPaidAmount'],
          if (payload['requiresCashPayment'] != null)
            'requiresCashPayment': payload['requiresCashPayment'],
          if (payload['fare'] != null) 'fare': payload['fare'],
          if (payload['userPayable'] != null)
            'userPayable': payload['userPayable'],
        });
      } catch (e) {
        _socketLog('SOCKET_RECONNECT_FAILED', {
          'reason': 'trip_completed_parse_failed',
          'error': e.toString(),
        });
      }
    });

    bind('trip:cancelled', (data) {
      final payload = Map<String, dynamic>.from(data);
      if (!_matchesActiveTrip(payload)) return;
      final tripId = _activeTripId ?? _eventTripId(payload);
      if (tripId.isNotEmpty) stopTrackingTrip(tripId);
      _safeAdd(_tripCancelledController, payload);
    });

    bind('trip:new_message', (data) {
      _safeAdd(_chatMessageController, Map<String, dynamic>.from(data));
    });
    bind('trip:message_history', (data) {
      _safeAdd(_messageHistoryController, Map<String, dynamic>.from(data));
    });
    bind('trip:no_drivers', (data) {
      final payload = Map<String, dynamic>.from(data);
      if (!_matchesActiveTrip(payload)) return;
      final tripId = _activeTripId ?? _eventTripId(payload);
      if (tripId.isNotEmpty) stopTrackingTrip(tripId);
      _safeAdd(_noDriversController, payload);
    });
    bind('trip:searching', (data) {
      final payload = Map<String, dynamic>.from(data);
      if (!_matchesActiveTrip(payload)) return;
      _safeAdd(_tripSearchingController, payload);
    });
    bind('trip:timeout', (data) {
      final payload = Map<String, dynamic>.from(data);
      if (!_matchesActiveTrip(payload)) return;
      final tripId = _activeTripId ?? _eventTripId(payload);
      if (tripId.isNotEmpty) stopTrackingTrip(tripId);
      _safeAdd(_noDriversController, payload);
    });
    bind('trip:payment_pending', (data) {
      _safeAdd(_paymentPendingController, Map<String, dynamic>.from(data));
    });
    bind('pool:status', (data) {
      _safeAdd(_poolStatusController, Map<String, dynamic>.from(data));
    });
    bind('pool:seat_update', (data) {
      _safeAdd(_poolSeatUpdateController, Map<String, dynamic>.from(data));
    });
    bind('parcel:status', (data) {
      _safeAdd(_parcelStatusController, Map<String, dynamic>.from(data));
    });
    bind('parcel:location', (data) {
      _safeAdd(_parcelLocationController, Map<String, dynamic>.from(data));
    });
    bind('config:updated', (data) {
      _safeAdd(_configUpdatedController, Map<String, dynamic>.from(data));
    });
    bind('call:incoming', (data) {
      _safeAdd(_callIncomingController, Map<String, dynamic>.from(data));
    });
    bind('call:offer', (data) {
      _safeAdd(_callOfferController, Map<String, dynamic>.from(data));
    });
    bind('call:answer', (data) {
      _safeAdd(_callAnswerController, Map<String, dynamic>.from(data));
    });
    bind('call:ice', (data) {
      _safeAdd(_callIceController, Map<String, dynamic>.from(data));
    });
    bind('call:ended', (data) {
      _safeAdd(_callEndedController, Map<String, dynamic>.from(data));
    });
    bind('call:rejected', (data) {
      _safeAdd(_callRejectedController, Map<String, dynamic>.from(data));
    });
    bind('call:error', (data) {
      _safeAdd(_callErrorController, Map<String, dynamic>.from(data));
    });

    _socketLog('SOCKET_CONNECT', {'phase': 'connecting'});
    socket.connect();
  }

  void trackTrip(String tripId) {
    _activeTripId = tripId;
    _emitTrackTrip(tripId);
  }

  void stopTrackingTrip(String tripId) {
    final socket = _socket;
    if (socket != null && socket.connected) {
      socket.emit('customer:leave_trip', {'tripId': tripId});
      _socketLog('SOCKET_ROOM_LEAVE', {'roomType': 'trip', 'tripId': tripId});
    }
    if (_activeTripId == tripId || tripId.isEmpty) {
      _activeTripId = null;
    }
  }

  void trackParcel(String orderId) {
    _activeParcelId = orderId;
    _emitTrackParcel(orderId);
  }

  void stopTrackingParcel(String orderId) {
    final socket = _socket;
    if (socket != null && socket.connected) {
      socket.emit('customer:leave_parcel', {'orderId': orderId});
      _socketLog('SOCKET_ROOM_LEAVE', {
        'roomType': 'parcel',
        'orderId': orderId,
      });
    }
    if (_activeParcelId == orderId || orderId.isEmpty) {
      _activeParcelId = null;
    }
  }

  void cancelTrip(String tripId) {
    if (!_isConnected || _socket == null) return;
    _socket!.emit('customer:cancel_trip', {'tripId': tripId});
  }

  void sendChatMessage({
    required String tripId,
    required String message,
    required String senderName,
  }) {
    if (!_isConnected || _socket == null) return;
    _socket!.emit('trip:send_message', {
      'tripId': tripId,
      'message': message,
      'senderName': senderName,
      'senderType': 'customer',
    });
  }

  void loadChatHistory(String tripId) {
    if (!_isConnected || _socket == null) return;
    _socket!.emit('trip:get_messages', {'tripId': tripId});
  }

  void initiateCall({
    required String targetUserId,
    required String tripId,
    required String callerName,
  }) {
    if (!_isConnected || _socket == null) return;
    _socket!.emit('call:initiate', {
      'targetUserId': targetUserId,
      'tripId': tripId,
      'callerName': callerName,
    });
  }

  void sendCallOffer({
    required String targetUserId,
    required String tripId,
    required dynamic sdp,
  }) {
    if (!_isConnected || _socket == null) return;
    _socket!.emit('call:offer', {
      'targetUserId': targetUserId,
      'tripId': tripId,
      'sdp': sdp,
    });
  }

  void sendCallAnswer({
    required String targetUserId,
    required String tripId,
    required dynamic sdp,
  }) {
    if (!_isConnected || _socket == null) return;
    _socket!.emit('call:answer', {
      'targetUserId': targetUserId,
      'tripId': tripId,
      'sdp': sdp,
    });
  }

  void sendIceCandidate({
    required String targetUserId,
    required String tripId,
    required dynamic candidate,
  }) {
    if (!_isConnected || _socket == null) return;
    _socket!.emit('call:ice', {
      'targetUserId': targetUserId,
      'tripId': tripId,
      'candidate': candidate,
    });
  }

  void endCall({required String targetUserId, String? tripId, int? durationSec}) {
    if (!_isConnected || _socket == null) return;
    _socket!.emit('call:end', {
      'targetUserId': targetUserId,
      if (tripId != null) 'tripId': tripId,
      if (durationSec != null) 'durationSec': durationSec,
    });
  }

  void rejectCall({required String targetUserId, String? tripId}) {
    if (!_isConnected || _socket == null) return;
    _socket!.emit('call:reject', {
      'targetUserId': targetUserId,
      if (tripId != null) 'tripId': tripId,
    });
  }

  void disconnect({String reason = 'manual'}) {
    _disposeSocket(reason);
  }

  void dispose() {
    _authTokenSubscription?.cancel();
    _authTokenSubscription = null;
    disconnect(reason: 'service_dispose');
    _driverAssignedController.close();
    _driverLocationController.close();
    _tripStatusController.close();
    _tripCancelledController.close();
    _connectedController.close();
    _chatMessageController.close();
    _messageHistoryController.close();
    _noDriversController.close();
    _tripSearchingController.close();
    _paymentPendingController.close();
    _poolStatusController.close();
    _poolSeatUpdateController.close();
    _parcelStatusController.close();
    _parcelLocationController.close();
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
