import 'dart:convert';
import 'dart:typed_data';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

// Background message handler — must be top-level function
@pragma('vm:entry-point')
Future<void> firebaseBackgroundMessageHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  // ignore: avoid_print
  print('[FCM-PILOT-BG] 📩 Background message received — type: ${message.data['type']} tripId: ${message.data['tripId']}');

  if (message.data['type'] == 'new_trip') {
    // ignore: avoid_print
    print('[FCM-PILOT-BG] 🚗 new_trip received — showing alarm notification');
    // Store pending trip for when app opens
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('pending_trip_data', jsonEncode(message.data));
    } catch (_) {}

    // Show a full-screen local notification (alarm-style)
    final plugin = FlutterLocalNotificationsPlugin();
    const initSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    );
    await plugin.initialize(initSettings);

    final customerName = message.data['customerName'] ?? 'Customer';
    final pickupAddress = message.data['pickupAddress'] ?? 'Pickup';
    final fare = message.data['estimatedFare'] ?? '0';

    await plugin.show(
      42,
      '🚗 New Ride Request!',
      '$customerName • ₹$fare • $pickupAddress',
      NotificationDetails(
        android: AndroidNotificationDetails(
          'trip_alerts',
          'Trip Alerts',
          channelDescription: 'Incoming ride requests',
          importance: Importance.max,
          priority: Priority.max,
          playSound: true,
          enableVibration: true,
          vibrationPattern: Int64List.fromList([0, 500, 200, 700, 200, 500, 200, 700]),
          icon: '@mipmap/ic_launcher',
          fullScreenIntent: true,
          autoCancel: false,
          ongoing: true,
          category: AndroidNotificationCategory.call,
          visibility: NotificationVisibility.public,
          timeoutAfter: 30000,
        ),
      ),
      payload: jsonEncode(message.data),
    );
  }
}

class FcmService {
  static final FcmService _instance = FcmService._internal();
  factory FcmService() => _instance;
  FcmService._internal();

  final FlutterLocalNotificationsPlugin _localNotif = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  // ── Call this once in main() after Firebase.initializeApp() ─────────────────
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    // Request notification permission (iOS + Android 13+)
    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      criticalAlert: true,
    );

    // Deliver foreground FCM notifications too
    await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // Android local notification channel — max priority trip alerts
    const AndroidNotificationChannel tripAlertChannel = AndroidNotificationChannel(
      'trip_alerts',
      'Trip Alerts',
      description: 'Incoming ride requests and trip updates',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      showBadge: true,
    );

    const AndroidNotificationChannel tripUpdateChannel = AndroidNotificationChannel(
      'trip_updates',
      'Trip Updates',
      description: 'Status updates for active trips',
      importance: Importance.high,
    );

    final plugin = _localNotif.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await plugin?.createNotificationChannel(tripAlertChannel);
    await plugin?.createNotificationChannel(tripUpdateChannel);

    // Request exact alarm permission on Android 12+
    await plugin?.requestExactAlarmsPermission();

    // Initialize local notifications
    const initSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );
    await _localNotif.initialize(initSettings,
      onDidReceiveNotificationResponse: _onLocalNotifTap,
      onDidReceiveBackgroundNotificationResponse: _onBackgroundNotifTap);

    // Background message handler
    FirebaseMessaging.onBackgroundMessage(firebaseBackgroundMessageHandler);

    // Foreground messages — show local notification with full alarm
    FirebaseMessaging.onMessage.listen(_onForegroundMessage);

    // App opened from notification (background → foreground)
    FirebaseMessaging.onMessageOpenedApp.listen(_onNotificationOpened);

    // App launched from terminated state via notification
    final initialMsg = await messaging.getInitialMessage();
    if (initialMsg != null) _handleMessage(initialMsg);

    // Get token and save
    await _saveFcmToken();

    // Refresh token if it changes
    messaging.onTokenRefresh.listen((token) => _saveTokenToServer(token));
  }

  Future<void> _saveFcmToken() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null) {
        debugPrint('[FCM-PILOT] ❌ getToken() returned null — Firebase not ready?');
        return;
      }
      debugPrint('[FCM-PILOT] 🔑 Token obtained: ${token.substring(0, 20)}...');
      await _saveTokenToServer(token);
    } catch (e) {
      debugPrint('[FCM-PILOT] ❌ getToken() threw: $e');
    }
  }

  Future<void> _saveTokenToServer(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final authToken = prefs.getString('auth_token');
      if (authToken == null) {
        debugPrint('[FCM-PILOT] ⚠️  No auth_token in prefs — token NOT saved to server (login first)');
        return;
      }
      debugPrint('[FCM-PILOT] 📤 Saving token to server: ${token.substring(0, 20)}...');
      final res = await http.post(
        Uri.parse(ApiConfig.fcmToken),
        headers: {
          'Authorization': 'Bearer $authToken',
          'Content-Type': 'application/json'
        },
        body: jsonEncode({
          'fcmToken': token,
          'platform': 'android',
          'userType': 'driver',
        }),
      ).timeout(const Duration(seconds: 10));
      if (res.statusCode == 200 || res.statusCode == 201) {
        debugPrint('[FCM-PILOT] ✅ Token saved to server (HTTP ${res.statusCode})');
      } else {
        debugPrint('[FCM-PILOT] ⚠️  Server rejected token: HTTP ${res.statusCode} — ${res.body}');
      }
    } catch (e) {
      debugPrint('[FCM-PILOT] ❌ Token save failed: $e');
    }
  }

  // Called when logged in (after getting auth token)
  Future<void> onLoginSuccess() async {
    debugPrint('[FCM-PILOT] 🔄 onLoginSuccess — refreshing FCM token...');
    await _saveFcmToken();
  }

  void _onForegroundMessage(RemoteMessage message) {
    final isTrip = message.data['type'] == 'new_trip';

    final customerName = message.data['customerName'] ?? 'Customer';
    final pickupAddress = message.data['pickupAddress'] ?? 'Pickup';
    final fare = message.data['estimatedFare'] ?? '0';

    _localNotif.show(
      message.hashCode,
      isTrip ? '🚗 New Ride Request!' : (message.notification?.title ?? 'JAGO Pro Pilot'),
      isTrip
        ? '$customerName • ₹$fare • $pickupAddress'
        : (message.notification?.body ?? ''),
      NotificationDetails(
        android: AndroidNotificationDetails(
          isTrip ? 'trip_alerts' : 'trip_updates',
          isTrip ? 'Trip Alerts' : 'Trip Updates',
          channelDescription: isTrip ? 'Incoming ride requests' : 'Trip status updates',
          importance: isTrip ? Importance.max : Importance.high,
          priority: isTrip ? Priority.max : Priority.high,
          playSound: true,
          enableVibration: true,
          vibrationPattern: isTrip
            ? Int64List.fromList([0, 600, 200, 600, 200, 600, 200, 600])
            : null,
          icon: '@mipmap/ic_launcher',
          fullScreenIntent: isTrip,
          autoCancel: !isTrip,
          ongoing: isTrip,
          category: isTrip ? AndroidNotificationCategory.call : null,
          visibility: NotificationVisibility.public,
          timeoutAfter: isTrip ? 30000 : null,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: jsonEncode(message.data),
    );
  }

  void _onNotificationOpened(RemoteMessage message) {
    _handleMessage(message);
  }

  void _handleMessage(RemoteMessage message) {
    _storePendingTripData(message.data);
  }

  Future<void> _storePendingTripData(Map<String, dynamic> data) async {
    if (data['type'] == 'new_trip') {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('pending_trip_data', jsonEncode(data));
    }
  }

  void _onLocalNotifTap(NotificationResponse response) {
    if (response.payload != null) {
      try {
        final data = jsonDecode(response.payload!);
        _storePendingTripData(Map<String, dynamic>.from(data));
      } catch (_) {}
    }
  }

  // Dismiss ongoing trip notification (call when driver accepts/rejects)
  Future<void> dismissTripNotification() async {
    try {
      await _localNotif.cancel(42);
    } catch (_) {}
  }
}

@pragma('vm:entry-point')
void _onBackgroundNotifTap(NotificationResponse response) {
  // Background tap handled when app opens
}
