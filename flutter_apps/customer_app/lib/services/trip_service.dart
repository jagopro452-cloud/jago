import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'auth_service.dart';

class TripService {
  static Future<Map<String, dynamic>> estimateFare({
    required double pickupLat,
    required double pickupLng,
    required double destLat,
    required double destLng,
  }) async {
    final res = await http.post(Uri.parse(ApiConfig.estimateFare),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'pickupLat': pickupLat, 'pickupLng': pickupLng, 'destLat': destLat, 'destLng': destLng}));
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> bookRide({
    required String pickupAddress,
    required double pickupLat,
    required double pickupLng,
    required String destAddress,
    required double destLat,
    required double destLng,
    required String vehicleCategoryId,
    required double estimatedFare,
    required double estimatedDistance,
    required String paymentMethod,
  }) async {
    final headers = await AuthService.getHeaders();
    final res = await http.post(Uri.parse(ApiConfig.bookRide),
      headers: headers,
      body: jsonEncode({
        'pickupAddress': pickupAddress, 'pickupLat': pickupLat, 'pickupLng': pickupLng,
        'destinationAddress': destAddress, 'destinationLat': destLat, 'destinationLng': destLng,
        'vehicleCategoryId': vehicleCategoryId, 'estimatedFare': estimatedFare,
        'estimatedDistance': estimatedDistance, 'paymentMethod': paymentMethod,
      }));
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> getActiveTrip() async {
    final headers = await AuthService.getHeaders();
    final res = await http.get(Uri.parse(ApiConfig.activeTrip), headers: headers);
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> trackTrip(String tripId) async {
    final headers = await AuthService.getHeaders();
    final res = await http.get(Uri.parse('${ApiConfig.trackTrip}/$tripId'), headers: headers);
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> cancelTrip(String tripId, String reason) async {
    final headers = await AuthService.getHeaders();
    final res = await http.post(Uri.parse(ApiConfig.cancelTrip),
      headers: headers,
      body: jsonEncode({'tripId': tripId, 'reason': reason}));
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> rateDriver({required String tripId, required double rating, String? review}) async {
    final headers = await AuthService.getHeaders();
    final res = await http.post(Uri.parse(ApiConfig.rateDriver),
      headers: headers,
      body: jsonEncode({'tripId': tripId, 'rating': rating, 'review': review ?? ''}));
    return jsonDecode(res.body);
  }

  static Future<List<dynamic>> getTripHistory() async {
    try {
      final headers = await AuthService.getHeaders();
      final res = await http.get(Uri.parse(ApiConfig.trips), headers: headers);
      final data = jsonDecode(res.body);
      return data['trips'] ?? data['data'] ?? [];
    } catch (_) { return []; }
  }

  static Future<Map<String, dynamic>> getWallet() async {
    final headers = await AuthService.getHeaders();
    final res = await http.get(Uri.parse(ApiConfig.wallet), headers: headers);
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> rechargeWallet({required double amount, required String paymentRef, String paymentMethod = 'upi'}) async {
    final headers = await AuthService.getHeaders();
    final res = await http.post(Uri.parse(ApiConfig.walletRecharge),
      headers: headers,
      body: jsonEncode({'amount': amount, 'paymentRef': paymentRef, 'paymentMethod': paymentMethod}));
    return jsonDecode(res.body);
  }

  static Future<List<dynamic>> getSavedPlaces() async {
    final headers = await AuthService.getHeaders();
    final res = await http.get(Uri.parse(ApiConfig.savedPlaces), headers: headers);
    final data = jsonDecode(res.body);
    return data['data'] ?? [];
  }

  static Future<Map<String, dynamic>> addSavedPlace({required String label, required String address, required double lat, required double lng}) async {
    final headers = await AuthService.getHeaders();
    final res = await http.post(Uri.parse(ApiConfig.savedPlaces),
      headers: headers,
      body: jsonEncode({'label': label, 'address': address, 'lat': lat, 'lng': lng}));
    return jsonDecode(res.body);
  }

  static Future<void> deleteSavedPlace(String id) async {
    final headers = await AuthService.getHeaders();
    await http.delete(Uri.parse('${ApiConfig.savedPlaces}/$id'), headers: headers);
  }

  static Future<Map<String, dynamic>> applyCoupon({required String code, required double fareAmount}) async {
    final headers = await AuthService.getHeaders();
    final res = await http.post(Uri.parse(ApiConfig.applyCoupon),
      headers: headers,
      body: jsonEncode({'code': code, 'fareAmount': fareAmount}));
    return jsonDecode(res.body);
  }

  static Future<List<dynamic>> getNearbyDrivers({required double lat, required double lng}) async {
    try {
      final res = await http.get(Uri.parse('${ApiConfig.nearbyDrivers}?lat=$lat&lng=$lng'));
      final data = jsonDecode(res.body);
      return data['drivers'] ?? [];
    } catch (_) { return []; }
  }
}
