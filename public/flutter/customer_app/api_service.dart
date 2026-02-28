import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// ================================================================
// JAGO Customer App — API Service
// Base URL: https://jagopro.org
// Auth: Bearer <token>  (stored in SharedPreferences after OTP login)
// ================================================================

const String kBaseUrl = 'https://jagopro.org';

class ApiService {
  static String? _token;

  // ── Load token from storage ──────────────────────────────────
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('customer_token');
  }

  static Future<void> saveToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('customer_token', token);
  }

  static Future<void> clearToken() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('customer_token');
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

  // ================================================================
  // 1. AUTHENTICATION — OTP Login
  // ================================================================

  /// Step 1 — Send OTP to customer phone number
  /// Response: { success, message, otp (dev-only) }
  static Future<Map<String, dynamic>> sendOtp(String phone) async {
    return _post('/api/app/send-otp', {
      'phone': phone,
      'userType': 'customer',
    });
  }

  /// Step 2 — Verify OTP → Get auth token
  /// [name] only needed for first-time registration
  /// Response: { success, isNew, token, user: { id, fullName, phone, walletBalance } }
  static Future<Map<String, dynamic>> verifyOtp(
      String phone, String otp, {String? name}) async {
    final res = await _post('/api/app/verify-otp', {
      'phone': phone,
      'otp': otp,
      'userType': 'customer',
      if (name != null) 'name': name,
    });
    if (res['success'] == true && res['token'] != null) {
      await saveToken(res['token']);
    }
    return res;
  }

  // ================================================================
  // 2. CUSTOMER PROFILE
  // ================================================================

  /// Get customer profile, wallet, stats
  /// Response: { id, fullName, phone, rating, walletBalance, stats: { completedTrips, totalSpent } }
  static Future<Map<String, dynamic>> getProfile() async {
    return _get('/api/app/customer/profile');
  }

  // ================================================================
  // 3. MAP — Nearby Drivers (no auth needed)
  // ================================================================

  /// Get nearby online driver locations for map display
  /// [radiusKm] search radius in kilometers (default 5)
  /// Response: { drivers: [{ id, fullName, lat, lng, heading, rating }] }
  static Future<Map<String, dynamic>> getNearbyDrivers({
    required double lat,
    required double lng,
    double radiusKm = 5,
  }) async {
    return _get(
        '/api/app/nearby-drivers?lat=$lat&lng=$lng&radius=$radiusKm');
  }

  // ================================================================
  // 4. FARE ESTIMATE (no auth needed)
  // ================================================================

  /// Get fare estimates for all vehicle categories
  /// [distanceKm] trip distance in km
  /// Response: { fares: [{ vehicleName, baseFare, farePerKm, estimatedFare }], distanceKm }
  static Future<Map<String, dynamic>> estimateFare({
    required double pickupLat,
    required double pickupLng,
    required double destLat,
    required double destLng,
    required double distanceKm,
  }) async {
    return _post('/api/app/customer/estimate-fare', {
      'pickupLat': pickupLat,
      'pickupLng': pickupLng,
      'destLat': destLat,
      'destLng': destLng,
      'distanceKm': distanceKm,
    });
  }

  // ================================================================
  // 5. BOOK RIDE
  // ================================================================

  /// Book a ride — auto-assigns nearest available driver
  /// [paymentMethod] = 'cash' | 'wallet' | 'online'
  /// [vehicleCategoryId] from getConfigs()
  /// Response: {
  ///   success, trip: { id, refId, currentStatus: 'driver_assigned' | 'searching' },
  ///   driver: { id, fullName, lat, lng } | null
  /// }
  static Future<Map<String, dynamic>> bookRide({
    required String pickupAddress,
    required double pickupLat,
    required double pickupLng,
    required String destinationAddress,
    required double destinationLat,
    required double destinationLng,
    required String vehicleCategoryId,
    required double estimatedFare,
    required double estimatedDistance,
    String paymentMethod = 'cash',
  }) async {
    return _post('/api/app/customer/book-ride', {
      'pickupAddress': pickupAddress,
      'pickupLat': pickupLat,
      'pickupLng': pickupLng,
      'destinationAddress': destinationAddress,
      'destinationLat': destinationLat,
      'destinationLng': destinationLng,
      'vehicleCategoryId': vehicleCategoryId,
      'estimatedFare': estimatedFare,
      'estimatedDistance': estimatedDistance,
      'paymentMethod': paymentMethod,
    });
  }

  // ================================================================
  // 6. ACTIVE TRIP — Poll every 5 seconds during a ride
  // ================================================================

  /// Get active trip + driver live location
  /// Call this every 5 seconds after booking
  ///
  /// Trip Status Flow:
  ///   searching → driver_assigned → accepted → arrived → on_the_way → completed
  ///
  /// Response: {
  ///   trip: {
  ///     id, currentStatus,
  ///     driverName, driverLat, driverLng,   ← for map marker
  ///     pickupOtpVisible: "4823"            ← only when status == 'arrived'
  ///   } | null
  /// }
  static Future<Map<String, dynamic>> getActiveTrip() async {
    return _get('/api/app/customer/active-trip');
  }

  /// Track a specific trip by ID
  /// Response: { currentStatus, driverLat, driverLng, ... }
  static Future<Map<String, dynamic>> trackTrip(String tripId) async {
    return _get('/api/app/customer/track-trip/$tripId');
  }

  // ================================================================
  // 7. CANCEL TRIP
  // ================================================================

  /// Cancel trip (only allowed before status is 'on_the_way')
  static Future<Map<String, dynamic>> cancelTrip(
      String tripId, String reason) async {
    return _post('/api/app/customer/cancel-trip', {
      'tripId': tripId,
      'reason': reason,
    });
  }

  // ================================================================
  // 8. RATINGS
  // ================================================================

  /// Rate the driver after trip
  static Future<Map<String, dynamic>> rateDriver({
    required String tripId,
    required int rating,
    String? review,
  }) async {
    return _post('/api/app/customer/rate-driver', {
      'tripId': tripId,
      'rating': rating,
      if (review != null) 'review': review,
    });
  }

  // ================================================================
  // 9. TRIP HISTORY
  // ================================================================

  /// Customer trip history
  static Future<Map<String, dynamic>> getTrips({
    int limit = 20,
    int offset = 0,
  }) async {
    return _get('/api/app/customer/trips?limit=$limit&offset=$offset');
  }

  // ================================================================
  // 10. UTILITY
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

  /// App startup configs — call once on app launch, cache locally
  /// Response: { vehicleCategories, cancellationReasons, configs }
  static Future<Map<String, dynamic>> getConfigs() async {
    return _get('/api/app/configs');
  }
}
