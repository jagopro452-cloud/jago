import 'dart:convert';
import 'dart:typed_data';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

// Background message handler — must be top-level function
@pragma('vm:entry-point')
Future<void> firebaseBackgroundMessageHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  // Background trip alert handled by FCM data payload — app processes on resume
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

    // Android local notification channel — High priority for trip alerts
    const AndroidNotificationChannel tripAlertChannel = AndroidNotificationChannel(
      'trip_alerts',
      'Trip Alerts',
      description: 'Incoming ride requests and trip updates',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
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
      onDidReceiveNotificationResponse: _onLocalNotifTap);

    // Background message handler
    FirebaseMessaging.onBackgroundMessage(firebaseBackgroundMessageHandler);

    // Foreground messages — show local notification
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
      if (token != null) await _saveTokenToServer(token);
    } catch (_) {}
  }

  Future<void> _saveTokenToServer(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final authToken = prefs.getString('auth_token');
      if (authToken == null) return;

      await http.post(Uri.parse(ApiConfig.fcmToken),
        headers: {
          'Authorization': 'Bearer $authToken',
          'Content-Type': 'application/json'
        },
        body: jsonEncode({
          'fcmToken': token,
          'platform': 'android',
          'userType': 'driver',
        }));
    } catch (_) {}
  }

  // Called when logged in (after getting auth token)
  Future<void> onLoginSuccess() async {
    await _saveFcmToken();
  }

  void _onForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    final isTrip = message.data['type'] == 'new_trip';
    _localNotif.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          isTrip ? 'trip_alerts' : 'trip_updates',
          isTrip ? 'Trip Alerts' : 'Trip Updates',
          channelDescription: isTrip ? 'Incoming ride requests' : 'Trip status updates',
          importance: isTrip ? Importance.max : Importance.high,
          priority: isTrip ? Priority.max : Priority.high,
          playSound: true,
          enableVibration: true,
          vibrationPattern: isTrip ? Int64List.fromList([0, 500, 200, 500, 200, 500]) : null,
          icon: '@mipmap/ic_launcher',
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
    // Data handled by home_screen when app opens
    // Trip data stored in SharedPreferences for home screen to pick up
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
}
