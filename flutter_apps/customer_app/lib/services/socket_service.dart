import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:shared_preferences/shared_preferences.dart';

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  IO.Socket? _socket;
  bool _isConnected = false;
  String? _activeTripId; // stored so we can re-join trip room after server restart

  final _driverAssignedController = StreamController<Map<String, dynamic>>.broadcast();
  final _driverLocationController = StreamController<Map<String, dynamic>>.broadcast();
  final _tripStatusController = StreamController<Map<String, dynamic>>.broadcast();
  final _tripCancelledController = StreamController<Map<String, dynamic>>.broadcast();
  final _connectedController = StreamController<bool>.broadcast();
  final _chatMessageController = StreamController<Map<String, dynamic>>.broadcast();
  final _messageHistoryController = StreamController<Map<String, dynamic>>.broadcast();
  final _noDriversController = StreamController<Map<String, dynamic>>.broadcast();
  final _tripSearchingController = StreamController<Map<String, dynamic>>.broadcast();
  final _paymentPendingController = StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get onDriverAssigned => _driverAssignedController.stream;
  Stream<Map<String, dynamic>> get onDriverLocation => _driverLocationController.stream;
  Stream<Map<String, dynamic>> get onTripStatus => _tripStatusController.stream;
  Stream<Map<String, dynamic>> get onTripCancelled => _tripCancelledController.stream;
  Stream<bool> get onConnectionChanged => _connectedController.stream;
  Stream<Map<String, dynamic>> get onChatMessage => _chatMessageController.stream;
  Stream<Map<String, dynamic>> get onMessageHistory => _messageHistoryController.stream;
  Stream<Map<String, dynamic>> get onNoDrivers => _noDriversController.stream;
  Stream<Map<String, dynamic>> get onTripSearching => _tripSearchingController.stream;
  Stream<Map<String, dynamic>> get onPaymentPending => _paymentPendingController.stream;
  bool get isConnected => _isConnected;

  Future<void> connect(String baseUrl) async {
    if (_isConnected) return;

    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id') ?? '';
    final token = prefs.getString('auth_token') ?? '';

    if (userId.isEmpty) return;

    _socket = IO.io(
      baseUrl,
      IO.OptionBuilder()
          .setTransports(['websocket', 'polling'])
          .setQuery({'userId': userId, 'userType': 'customer', 'token': token})
          .enableAutoConnect()
          .enableReconnection()
          .setReconnectionAttempts(999)
          .setReconnectionDelay(3000)
          .build(),
    );

    _socket!.on('connect', (_) {
      _isConnected = true;
      _connectedController.add(true);
      // Re-join trip room on every connect (first connect + reconnect after restart)
      if (_activeTripId != null) {
        _socket!.emit('customer:track_trip', {'tripId': _activeTripId});
      }
    });

    // On reconnect after server restart: re-join active trip room so events resume
    _socket!.on('reconnect', (_) {
      if (_activeTripId != null) {
        _socket!.emit('customer:track_trip', {'tripId': _activeTripId});
      }
    });

    _socket!.on('disconnect', (_) {
      _isConnected = false;
      _connectedController.add(false);
    });

    // Driver assigned to my trip (socket acceptance path)
    _socket!.on('trip:driver_assigned', (data) {
      _driverAssignedController.add(Map<String, dynamic>.from(data));
    });

    // Driver accepted my trip (HTTP acceptance path)
    _socket!.on('trip:accepted', (data) {
      final payload = Map<String, dynamic>.from(data);
      payload['eventType'] = 'trip_accepted';
      _driverAssignedController.add(payload);
      // Keep status stream in sync for tracking UI updates
      _tripStatusController.add({
        'tripId': payload['tripId'],
        'status': 'accepted',
        if (payload['pickupOtp'] != null) 'otp': payload['pickupOtp'],
      });
    });

    // Real-time driver GPS location
    _socket!.on('driver:location_update', (data) {
      _driverLocationController.add(Map<String, dynamic>.from(data));
    });

    // Trip status changed (arrived, in_progress, completed, cancelled)
    _socket!.on('trip:status_update', (data) {
      _tripStatusController.add(Map<String, dynamic>.from(data));
    });

    // Some server paths emit completed directly instead of status_update
    _socket!.on('trip:completed', (data) {
      final payload = Map<String, dynamic>.from(data);
      _tripStatusController.add({
        'tripId': payload['tripId'],
        'status': 'completed',
      });
    });

    // Trip cancelled by driver
    _socket!.on('trip:cancelled', (data) {
      _tripCancelledController.add(Map<String, dynamic>.from(data));
    });

    // In-app chat message received (live)
    _socket!.on('trip:new_message', (data) {
      _chatMessageController.add(Map<String, dynamic>.from(data));
    });

    // Chat history loaded from DB on reconnect
    _socket!.on('trip:message_history', (data) {
      _messageHistoryController.add(Map<String, dynamic>.from(data));
    });

    // No drivers found — trip auto-cancelled
    _socket!.on('trip:no_drivers', (data) {
      _noDriversController.add(Map<String, dynamic>.from(data));
      // Also push as cancelled so tracking screen updates
      _tripCancelledController.add({...Map<String, dynamic>.from(data), 'reason': 'no_drivers'});
    });

    // Trip re-searching after driver rejected
    _socket!.on('trip:searching', (data) {
      _tripSearchingController.add(Map<String, dynamic>.from(data));
    });

    // Trip timeout — server gave up finding driver
    _socket!.on('trip:timeout', (data) {
      _noDriversController.add(Map<String, dynamic>.from(data));
      _tripCancelledController.add({...Map<String, dynamic>.from(data), 'reason': 'timeout'});
    });

    // Payment not yet verified — trip held at payment_pending
    _socket!.on('trip:payment_pending', (data) {
      _paymentPendingController.add(Map<String, dynamic>.from(data));
    });

    _socket!.connect();
  }

  // Start tracking a specific trip (also stored for reconnect recovery)
  void trackTrip(String tripId) {
    _activeTripId = tripId;
    if (!_isConnected) return;
    _socket!.emit('customer:track_trip', {'tripId': tripId});
  }

  void clearActiveTrip() => _activeTripId = null;

  // Cancel a trip
  void cancelTrip(String tripId) {
    if (!_isConnected) return;
    _socket!.emit('customer:cancel_trip', {'tripId': tripId});
  }

  // Send in-app chat message (persisted to DB + relayed via socket)
  void sendChatMessage({required String tripId, required String message, required String senderName}) {
    if (!_isConnected) return;
    _socket!.emit('trip:send_message', {
      'tripId': tripId,
      'message': message,
      'senderName': senderName,
      'senderType': 'customer',
    });
  }

  // Load message history from DB (call after joining trip room)
  void loadChatHistory(String tripId) {
    if (!_isConnected) return;
    _socket!.emit('trip:get_messages', {'tripId': tripId});
  }

  void disconnect() {
    _socket?.disconnect();
    _socket = null;
    _isConnected = false;
  }

  void dispose() {
    disconnect();
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
  }
}
