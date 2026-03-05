import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

// Background message handler — top-level function required by Firebase
@pragma('vm:entry-point')
Future<void> firebaseBackgroundMessageHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

class FcmService {
  static final FcmService _instance = FcmService._internal();
  factory FcmService() => _instance;
  FcmService._internal();

  final FlutterLocalNotificationsPlugin _localNotif = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    // Request permission
    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Android notification channels
    const AndroidNotificationChannel driverChannel = AndroidNotificationChannel(
      'trip_updates',
      'Trip Updates',
      description: 'Driver assignment, arrival, and trip status updates',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );

    await _localNotif
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(driverChannel);

    // Init local notifications
    const initSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );
    await _localNotif.initialize(initSettings,
      onDidReceiveNotificationResponse: _onNotifTap);

    // Register background handler
    FirebaseMessaging.onBackgroundMessage(firebaseBackgroundMessageHandler);

    // Foreground notifications
    FirebaseMessaging.onMessage.listen(_onForegroundMessage);

    // App opened from background notification
    FirebaseMessaging.onMessageOpenedApp.listen(_onNotificationOpened);

    // App launched from terminated notification
    final initial = await messaging.getInitialMessage();
    if (initial != null) _handleMessage(initial);

    // Save token
    await _saveFcmToken();
    messaging.onTokenRefresh.listen(_saveTokenToServer);
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
          'userType': 'customer',
        }));
    } catch (_) {}
  }

  // Call after successful login
  Future<void> onLoginSuccess() async {
    await _saveFcmToken();
  }

  void _onForegroundMessage(RemoteMessage message) {
    final notif = message.notification;
    if (notif == null) return;

    final type = message.data['type'] ?? '';
    String channelId = 'trip_updates';
    Importance importance = Importance.high;
    if (type == 'driver_arrived' || type == 'trip_accepted') {
      importance = Importance.max;
    }

    _localNotif.show(
      notif.hashCode,
      notif.title,
      notif.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          'Trip Updates',
          importance: importance,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
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

  void _onNotificationOpened(RemoteMessage message) => _handleMessage(message);

  void _handleMessage(RemoteMessage message) {
    final data = message.data;
    final type = data['type'] ?? '';
    if (type == 'trip_accepted' || type == 'driver_arrived' ||
        type == 'trip_completed' || type == 'trip_cancelled') {
      _storePendingNotification(data);
    }
  }

  Future<void> _storePendingNotification(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('pending_notification', jsonEncode(data));
  }

  void _onNotifTap(NotificationResponse response) {
    if (response.payload != null) {
      try {
        final data = jsonDecode(response.payload!);
        _storePendingNotification(Map<String, dynamic>.from(data));
      } catch (_) {}
    }
  }
}
