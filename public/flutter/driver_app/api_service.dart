import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// ================================================================
// JAGO Driver App — API Service
// Base URL: https://jagopro.org
// Auth: Bearer <token>  (stored in SharedPreferences after OTP login)
// ================================================================

const String kBaseUrl = 'https://jagopro.org';

class ApiService {
  static String? _token;

  // ── Load token from storage ──────────────────────────────────
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('driver_token');
  }

  static Future<void> saveToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('driver_token', token);
  }

  static Future<void> clearToken() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('driver_token');
  }

  static bool get isLoggedIn => _token != null;

  // ── HTTP helpers ─────────────────────────────────────────────
  static Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  static Future<Map<String, dynamic>> _post(
      String path, Map<String, dynamic> body) async {
    final res = await http.post(
      Uri.parse('$kBaseUrl$path'),
      headers: _headers,
      body: jsonEncode(body),
    );
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> _get(String path) async {
    final res = await http.get(
      Uri.parse('$kBaseUrl$path'),
      headers: _headers,
    );
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> _patch(
      String path, Map<String, dynamic> body) async {
    final res = await http.patch(
      Uri.parse('$kBaseUrl$path'),
      headers: _headers,
      body: jsonEncode(body),
    );
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  // ================================================================
  // 1. AUTHENTICATION — OTP Login
  // ================================================================

  /// Step 1 — Send OTP to driver phone number
  /// Response: { success, message, otp (dev-only) }
  static Future<Map<String, dynamic>> sendOtp(String phone) async {
    return _post('/api/app/send-otp', {
      'phone': phone,
      'userType': 'driver',
    });
  }

  /// Step 2 — Verify OTP → Get auth token
  /// [name] only needed for first-time registration
  /// Response: { success, isNew, token, user: { id, fullName, phone, walletBalance, isLocked } }
  static Future<Map<String, dynamic>> verifyOtp(
      String phone, String otp, {String? name}) async {
    final res = await _post('/api/app/verify-otp', {
      'phone': phone,
      'otp': otp,
      'userType': 'driver',
      if (name != null) 'name': name,
    });
    if (res['success'] == true && res['token'] != null) {
      await saveToken(res['token']);
    }
    return res;
  }

  // ================================================================
  // 2. DRIVER PROFILE
  // ================================================================

  /// Get driver profile, rating, wallet balance, online status
  /// Response: { id, fullName, phone, rating, walletBalance, isLocked, isOnline, stats }
  static Future<Map<String, dynamic>> getProfile() async {
    return _get('/api/app/driver/profile');
  }

  // ================================================================
  // 3. LOCATION — Update every 5–10 seconds when online
  // ================================================================

  /// Push GPS location to server (call in background timer)
  /// [heading] = compass degrees (0–360). [speed] = km/h
  static Future<void> updateLocation({
    required double lat,
    required double lng,
    double? heading,
    double? speed,
    bool isOnline = true,
  }) async {
    await _post('/api/app/driver/location', {
      'lat': lat,
      'lng': lng,
      if (heading != null) 'heading': heading,
      if (speed != null) 'speed': speed,
      'isOnline': isOnline,
    });
  }

  // ================================================================
  // 4. ONLINE / OFFLINE STATUS
  // ================================================================

  /// Go online or offline
  /// Returns 403 if wallet is locked (balance < threshold)
  /// Response: { success, isOnline } or { error, isLocked: true }
  static Future<Map<String, dynamic>> setOnlineStatus(bool isOnline) async {
    return _patch('/api/app/driver/online-status', {'isOnline': isOnline});
  }

  // ================================================================
  // 5. TRIP MANAGEMENT — Poll every 3–5 seconds when online
  // ================================================================

  /// Poll for new incoming trip assignment
  /// Response: { trip: {..., customerName, pickupAddress, destinationAddress, estimatedFare} | null }
  static Future<Map<String, dynamic>> getIncomingTrip() async {
    return _get('/api/app/driver/incoming-trip');
  }

  /// Accept incoming trip → Get pickup OTP (show to customer)
  /// Response: { success, trip, pickupOtp: "4823" }
  static Future<Map<String, dynamic>> acceptTrip(String tripId) async {
    return _post('/api/app/driver/accept-trip', {'tripId': tripId});
  }

  /// Reject / skip an assigned trip
  static Future<Map<String, dynamic>> rejectTrip(String tripId) async {
    return _post('/api/app/driver/reject-trip', {'tripId': tripId});
  }

  /// Notify server that driver arrived at pickup location
  /// Response: { success, pickupOtp }  ← display this OTP on screen
  static Future<Map<String, dynamic>> markArrived(String tripId) async {
    return _post('/api/app/driver/arrived', {'tripId': tripId});
  }

  /// Customer tells OTP → Driver enters here → Ride begins
  /// Response: { success, trip: { currentStatus: "on_the_way" } }
  static Future<Map<String, dynamic>> verifyPickupOtp(
      String tripId, String otp) async {
    return _post('/api/app/driver/verify-pickup-otp', {
      'tripId': tripId,
      'otp': otp,
    });
  }

  /// Complete trip — platform commission auto-deducted from wallet
  /// [actualFare] final amount charged to customer
  /// [actualDistance] in km
  /// Response: { success, trip, platformDeduction }
  static Future<Map<String, dynamic>> completeTrip({
    required String tripId,
    required double actualFare,
    double? actualDistance,
    double? tips,
  }) async {
    return _post('/api/app/driver/complete-trip', {
      'tripId': tripId,
      'actualFare': actualFare,
      if (actualDistance != null) 'actualDistance': actualDistance,
      if (tips != null) 'tips': tips,
    });
  }

  /// Cancel an accepted trip (only before ride starts)
  static Future<Map<String, dynamic>> cancelTrip(
      String tripId, String reason) async {
    return _post('/api/app/driver/cancel-trip', {
      'tripId': tripId,
      'reason': reason,
    });
  }

  // ================================================================
  // 6. RATINGS
  // ================================================================

  /// Rate the customer after trip
  static Future<Map<String, dynamic>> rateCustomer({
    required String tripId,
    required int rating,
    String? note,
  }) async {
    return _post('/api/app/driver/rate-customer', {
      'tripId': tripId,
      'rating': rating,
      if (note != null) 'note': note,
    });
  }

  // ================================================================
  // 7. HISTORY & WALLET
  // ================================================================

  /// Driver trip history
  /// [status] = 'completed' | 'cancelled' (optional)
  static Future<Map<String, dynamic>> getTrips({
    String? status,
    int limit = 20,
    int offset = 0,
  }) async {
    final query = <String>[];
    if (status != null) query.add('status=$status');
    query.add('limit=$limit');
    query.add('offset=$offset');
    return _get('/api/app/driver/trips?${query.join('&')}');
  }

  /// Wallet balance + payment history + lock status
  static Future<Map<String, dynamic>> getWallet() async {
    return _get('/api/app/driver/wallet');
  }

  // ================================================================
  // 8. UTILITY
  // ================================================================

  /// Register FCM push notification token
  static Future<void> registerFcmToken(String fcmToken, String deviceType) async {
    await _post('/api/app/fcm-token', {
      'fcmToken': fcmToken,
      'deviceType': deviceType,
      'appVersion': '1.0.0',
    });
  }

  /// Send SOS emergency alert
  static Future<Map<String, dynamic>> sendSos({
    required double lat,
    required double lng,
    String? tripId,
    String message = 'Need help',
  }) async {
    return _post('/api/app/sos', {
      'lat': lat,
      'lng': lng,
      if (tripId != null) 'tripId': tripId,
      'message': message,
    });
  }

  /// App startup configs (vehicle categories, settings)
  static Future<Map<String, dynamic>> getConfigs() async {
    return _get('/api/app/configs');
  }
}
