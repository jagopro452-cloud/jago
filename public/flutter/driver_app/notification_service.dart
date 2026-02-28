import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'api_service.dart';

// ================================================================
// JAGO Driver App — Push Notification + Sound Alert Service
//
// pubspec.yaml lo add cheyandi:
//   firebase_messaging: ^14.9.0
//   flutter_local_notifications: ^17.0.0
//   audioplayers: ^6.0.0
// ================================================================

// Background message handler — MUST be top-level function
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('[FCM Background] ${message.notification?.title}: ${message.notification?.body}');
  // Show local notification even when app is in background
  await NotificationService.showLocalNotification(message);
}

class NotificationService {
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  static final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  // ── Notification channels (Android) ────────────────────────────────────────
  static const _tripAlertChannel = AndroidNotificationChannel(
    'trip_alerts',
    'New Trip Alerts',
    description: 'Sound alert when a new ride is assigned',
    importance: Importance.max,
    playSound: true,
    sound: RawResourceAndroidNotificationSound('trip_alert'), // assets/raw/trip_alert.mp3
    enableVibration: true,
    vibrationPattern: [0, 500, 200, 500, 200, 500],
  );

  static const _tripUpdateChannel = AndroidNotificationChannel(
    'trip_updates',
    'Trip Status Updates',
    description: 'Trip status changes (accepted, arrived, completed)',
    importance: Importance.high,
    playSound: true,
  );

  // Callback for incoming trip — set from your main screen
  static void Function(Map<String, dynamic> data)? onNewTripReceived;
  static void Function(Map<String, dynamic> data)? onTripCancelled;

  // ── Setup ──────────────────────────────────────────────────────────────────
  static Future<void> initialize() async {
    // 1. Request permissions
    await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      criticalAlert: true, // iOS critical alerts (bypasses silent mode)
    );

    // 2. Create Android notification channels
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_tripAlertChannel);
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_tripUpdateChannel);

    // 3. Initialize local notifications
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    await _localNotifications.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // 4. Background handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // 5. Foreground handler (app is open)
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // 6. App opened from notification
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationOpened);

    // 7. Register FCM token with JAGO server
    await _registerToken();

    // 8. Token refresh listener
    _fcm.onTokenRefresh.listen((newToken) async {
      await ApiService.registerFcmToken(newToken, 'android');
    });
  }

  // ── Register FCM token with server ────────────────────────────────────────
  static Future<void> _registerToken() async {
    try {
      final token = await _fcm.getToken();
      if (token != null && ApiService.isLoggedIn) {
        await ApiService.registerFcmToken(token, 'android');
        debugPrint('[FCM] Token registered: ${token.substring(0, 20)}...');
      }
    } catch (e) {
      debugPrint('[FCM] Token registration failed: $e');
    }
  }

  // ── Handle foreground message (app is open) ───────────────────────────────
  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    debugPrint('[FCM Foreground] ${message.notification?.title}');
    final data = message.data;

    // New trip — trigger callback so screen can show alert dialog
    if (data['type'] == 'new_trip') {
      onNewTripReceived?.call(data);
      // Also show heads-up notification with sound
      await showLocalNotification(message, channelId: 'trip_alerts');
    } else if (data['type'] == 'trip_cancelled') {
      onTripCancelled?.call(data);
      await showLocalNotification(message, channelId: 'trip_updates');
    } else {
      await showLocalNotification(message);
    }
  }

  // ── Handle notification tap ───────────────────────────────────────────────
  static void _handleNotificationOpened(RemoteMessage message) {
    debugPrint('[FCM] App opened from notification: ${message.data}');
    // Navigate to relevant screen based on data['type']
  }

  static void _onNotificationTapped(NotificationResponse response) {
    debugPrint('[FCM] Notification tapped: ${response.payload}');
  }

  // ── Show local notification ───────────────────────────────────────────────
  static Future<void> showLocalNotification(RemoteMessage message, {String channelId = 'trip_updates'}) async {
    final notification = message.notification;
    if (notification == null) return;

    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelId == 'trip_alerts' ? 'New Trip Alerts' : 'Trip Updates',
      importance: channelId == 'trip_alerts' ? Importance.max : Importance.high,
      priority: channelId == 'trip_alerts' ? Priority.max : Priority.high,
      playSound: true,
      sound: channelId == 'trip_alerts'
          ? const RawResourceAndroidNotificationSound('trip_alert')
          : null,
      enableVibration: true,
      ticker: notification.title,
      fullScreenIntent: channelId == 'trip_alerts', // Full-screen for new trips
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      notification.title,
      notification.body,
      NotificationDetails(android: androidDetails),
      payload: message.data.toString(),
    );
  }
}

// ── How to use in Driver App ──────────────────────────────────────────────────
// 
// 1. main.dart lo:
//
//   void main() async {
//     WidgetsFlutterBinding.ensureInitialized();
//     await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
//     await ApiService.init();
//     await NotificationService.initialize();
//     runApp(MyApp());
//   }
//
// 2. HomeScreen State lo:
//
//   @override
//   void initState() {
//     super.initState();
//     // Set up new trip callback — shows alert dialog with sound
//     NotificationService.onNewTripReceived = (data) {
//       _showNewTripDialog(data);
//     };
//   }
//
//   void _showNewTripDialog(Map data) {
//     showDialog(context: context, builder: (_) => AlertDialog(
//       title: Text('🚗 New Ride!'),
//       content: Text('${data['customerName']} — ${data['pickupAddress']}\n₹${data['estimatedFare']}'),
//       actions: [
//         TextButton(onPressed: () { Navigator.pop(context); ApiService.rejectTrip(data['tripId']); }, child: Text('Reject')),
//         ElevatedButton(onPressed: () { Navigator.pop(context); ApiService.acceptTrip(data['tripId']); }, child: Text('Accept')),
//       ],
//     ));
//   }
