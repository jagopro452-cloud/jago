import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

// ─────────────────────────────────────────────────────────────────────────────
// BACKGROUND / TERMINATED STATE HANDLER
// Top-level function — runs in a separate Dart isolate when app is killed.
// Server sends data-only FCM (no `notification` key) so this fires every time.
// ─────────────────────────────────────────────────────────────────────────────
@pragma('vm:entry-point')
Future<void> firebaseBackgroundMessageHandler(RemoteMessage message) async {
  await Firebase.initializeApp();

  final type = message.data['type'] ?? '';
  final isTrip   = type == 'new_trip';
  final isParcel = type == 'new_parcel';
  if (!isTrip && !isParcel) return;

  debugPrint('[FCM-BG] 📩 type=$type — showing full-screen alert');

  // ── Persist for HomeScreen to pick up on next resume ─────────────────────
  try {
    final prefs = await SharedPreferences.getInstance();
    if (isTrip)   await prefs.setString('pending_trip_data',   jsonEncode(message.data));
    if (isParcel) await prefs.setString('pending_parcel_data', jsonEncode(message.data));
  } catch (_) {}

  // ── Show full-screen intent notification ─────────────────────────────────
  final plugin = FlutterLocalNotificationsPlugin();
  const initSettings = InitializationSettings(
    android: AndroidInitializationSettings('@mipmap/ic_launcher'),
  );
  await plugin.initialize(initSettings);

  // Ensure channel exists (may be first launch)
  final androidPlugin =
      plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
  await androidPlugin?.createNotificationChannel(const AndroidNotificationChannel(
    'trip_alerts',
    'Trip Alerts',
    description: 'Incoming ride and parcel requests — full-screen alert',
    importance: Importance.max,
    playSound: true,
    sound: RawResourceAndroidNotificationSound('trip_alert'),
    enableVibration: true,
    showBadge: true,
  ));

  // Build notification content from data payload
  final title = message.data['title']
      ?? (isParcel ? '📦 New Parcel Delivery!' : '🚗 New Ride Request!');
  final body  = message.data['body']
      ?? (isTrip
          ? '${message.data['customerName'] ?? 'Customer'} • ₹${message.data['estimatedFare'] ?? '0'} • ${message.data['pickupAddress'] ?? 'Pickup'}'
          : '${message.data['pickupAddress'] ?? 'Pickup'} • ₹${message.data['totalFare'] ?? '0'}');

  await plugin.show(
    isParcel ? 43 : 42,
    title,
    body,
    NotificationDetails(
      android: AndroidNotificationDetails(
        'trip_alerts',
        'Trip Alerts',
        channelDescription: 'Incoming ride and parcel requests',
        importance: Importance.max,
        priority: Priority.max,
        playSound: true,
        sound: const RawResourceAndroidNotificationSound('trip_alert'),
        enableVibration: true,
        // Rapido-style vibration: long bursts
        vibrationPattern: Int64List.fromList([0, 500, 200, 700, 200, 500, 200, 700, 200, 500]),
        icon: '@mipmap/ic_launcher',
        // ── THE KEY FLAGS ────────────────────────────────────────────────────
        fullScreenIntent: true,          // Shows over lock screen / other apps
        autoCancel: false,               // Stays until driver responds
        ongoing: true,                   // Can't be swiped away
        category: AndroidNotificationCategory.call, // Treated as incoming call
        visibility: NotificationVisibility.public,  // Show on lock screen
        timeoutAfter: 40000,             // Auto-dismiss after 40s (matches countdown)
      ),
    ),
    payload: jsonEncode(message.data),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// BACKGROUND NOTIFICATION TAP (top-level, for when app is not running)
// ─────────────────────────────────────────────────────────────────────────────
@pragma('vm:entry-point')
void _onBackgroundNotifTap(NotificationResponse response) {
  // Data is stored in SharedPrefs — HomeScreen reads it on init.
  // No navigation here because Flutter engine isn't running yet.
}

// ─────────────────────────────────────────────────────────────────────────────
// FCM SERVICE (singleton)
// ─────────────────────────────────────────────────────────────────────────────
class FcmService {
  static final FcmService _instance = FcmService._internal();
  factory FcmService() => _instance;
  FcmService._internal();

  final FlutterLocalNotificationsPlugin _localNotif = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  // ── Stream for foreground messages → HomeScreen shows IncomingTripSheet directly
  final _foregroundAlertController =
      StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get onForegroundAlert =>
      _foregroundAlertController.stream;

  // ── Initialize once (called from main()) ─────────────────────────────────
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    final messaging = FirebaseMessaging.instance;

    // Request permission (Android 13+, iOS)
    await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      criticalAlert: true,
    );

    // Allow foreground FCM to trigger onMessage (we handle it ourselves)
    await messaging.setForegroundNotificationPresentationOptions(
      alert: false, badge: true, sound: false,
    );

    // ── Android notification channels ──────────────────────────────────────
    const tripAlertChannel = AndroidNotificationChannel(
      'trip_alerts',
      'Trip Alerts',
      description: 'Full-screen incoming ride and parcel alerts',
      importance: Importance.max,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('trip_alert'),
      enableVibration: true,
      showBadge: true,
    );
    const tripUpdateChannel = AndroidNotificationChannel(
      'trip_updates',
      'Trip Updates',
      description: 'Status updates for active trips',
      importance: Importance.high,
    );

    final androidPlugin = _localNotif
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(tripAlertChannel);
    await androidPlugin?.createNotificationChannel(tripUpdateChannel);
    await androidPlugin?.requestExactAlarmsPermission();

    // ── Local notifications init ────────────────────────────────────────────
    const initSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );
    await _localNotif.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onLocalNotifTap,
      onDidReceiveBackgroundNotificationResponse: _onBackgroundNotifTap,
    );

    // ── Register handlers ───────────────────────────────────────────────────
    FirebaseMessaging.onBackgroundMessage(firebaseBackgroundMessageHandler);
    FirebaseMessaging.onMessage.listen(_onForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_onNotificationOpened);

    // App launched from terminated state via notification tap
    final initialMsg = await messaging.getInitialMessage();
    if (initialMsg != null) _handleMessageData(initialMsg.data);

    // Save FCM token
    await _saveFcmToken();
    messaging.onTokenRefresh.listen((token) => _saveTokenToServer(token));
  }

  // ── FOREGROUND MESSAGE ─────────────────────────────────────────────────────
  // App is in foreground: emit to stream so HomeScreen shows IncomingTripSheet.
  // Skip the system notification — the in-app sheet IS the notification.
  void _onForegroundMessage(RemoteMessage message) {
    final type = message.data['type'] ?? '';
    debugPrint('[FCM-FG] 📩 type=$type');

    if (type == 'new_trip' || type == 'new_parcel') {
      // Emit directly to HomeScreen's listener
      _foregroundAlertController.add(Map<String, dynamic>.from(message.data));
      return;
    }

    // Non-alert messages (trip_completed, trip_cancelled, etc.) → show notification
    _showUpdateNotification(
      title: message.notification?.title ?? message.data['title'] ?? 'JAGO Pro Pilot',
      body:  message.notification?.body  ?? message.data['body']  ?? '',
      data:  message.data,
    );
  }

  // ── NOTIFICATION TAP (app in background) ──────────────────────────────────
  void _onNotificationOpened(RemoteMessage message) {
    _handleMessageData(message.data);
  }

  // Stores pending data AND emits so HomeScreen can respond immediately
  void _handleMessageData(Map<String, dynamic> data) {
    final type = data['type'] ?? '';
    if (type == 'new_trip' || type == 'new_parcel') {
      _persistPending(data);
      // Also push to stream in case HomeScreen is mounted and listening
      _foregroundAlertController.add(Map<String, dynamic>.from(data));
    }
  }

  // ── LOCAL NOTIFICATION TAP (from our own full-screen notification) ────────
  void _onLocalNotifTap(NotificationResponse response) {
    if (response.payload == null) return;
    try {
      final data = jsonDecode(response.payload!) as Map<String, dynamic>;
      _persistPending(data);
      // Emit to stream — if HomeScreen is mounted it will show IncomingTripSheet
      _foregroundAlertController.add(data);
    } catch (_) {}
  }

  // ── Show trip/parcel alert (foreground, when app is visible) ────────────
  Future<void> showFullScreenAlert({
    required String title,
    required String body,
    required Map<String, dynamic> data,
    bool isParcel = false,
  }) async {
    await _localNotif.show(
      isParcel ? 43 : 42,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'trip_alerts',
          'Trip Alerts',
          importance: Importance.max,
          priority: Priority.max,
          playSound: true,
          sound: const RawResourceAndroidNotificationSound('trip_alert'),
          enableVibration: true,
          vibrationPattern: Int64List.fromList([0, 500, 200, 700, 200, 500, 200, 700]),
          icon: '@mipmap/ic_launcher',
          fullScreenIntent: true,
          autoCancel: false,
          ongoing: true,
          category: AndroidNotificationCategory.call,
          visibility: NotificationVisibility.public,
          timeoutAfter: 40000,
        ),
      ),
      payload: jsonEncode(data),
    );
  }

  // ── Show non-alert update notification (completed, cancelled, etc.) ───────
  void _showUpdateNotification({
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) {
    _localNotif.show(
      title.hashCode.abs() % 1000 + 100,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'trip_updates',
          'Trip Updates',
          importance: Importance.high,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
          autoCancel: true,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: data != null ? jsonEncode(data) : null,
    );
  }

  // ── Dismiss active trip/parcel notifications ─────────────────────────────
  Future<void> dismissTripNotification() async {
    try {
      await _localNotif.cancel(42); // trip
      await _localNotif.cancel(43); // parcel
    } catch (_) {}
  }

  // ── Persist pending trip/parcel data for HomeScreen to consume ──────────
  Future<void> _persistPending(Map<String, dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final type = data['type'] ?? '';
      if (type == 'new_trip')   await prefs.setString('pending_trip_data',   jsonEncode(data));
      if (type == 'new_parcel') await prefs.setString('pending_parcel_data', jsonEncode(data));
    } catch (_) {}
  }

  // ── FCM Token management ─────────────────────────────────────────────────
  Future<void> _saveFcmToken() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null) {
        debugPrint('[FCM-PILOT] ❌ getToken() returned null');
        return;
      }
      debugPrint('[FCM-PILOT] 🔑 Token: ${token.substring(0, 20)}...');
      await _saveTokenToServer(token);
    } catch (e) {
      debugPrint('[FCM-PILOT] ❌ getToken() threw: $e');
    }
  }

  Future<void> _saveTokenToServer(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final authToken = prefs.getString('auth_token');
      if (authToken == null) return;
      final res = await http.post(
        Uri.parse(ApiConfig.fcmToken),
        headers: {
          'Authorization': 'Bearer $authToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'fcmToken': token, 'platform': 'android', 'userType': 'driver'}),
      ).timeout(const Duration(seconds: 10));
      if (res.statusCode == 200 || res.statusCode == 201) {
        debugPrint('[FCM-PILOT] ✅ Token saved');
      }
    } catch (e) {
      debugPrint('[FCM-PILOT] ❌ Token save failed: $e');
    }
  }

  Future<void> onLoginSuccess() async {
    debugPrint('[FCM-PILOT] 🔄 Re-saving token after login...');
    await _saveFcmToken();
  }
}
