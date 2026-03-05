import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/trip_model.dart';
import 'auth_service.dart';

class TripService {
  static Future<Map<String, dynamic>> getIncomingTrip() async {
    try {
      final headers = await AuthService.getHeaders();
      final res = await http.get(Uri.parse(ApiConfig.driverIncomingTrip), headers: headers);
      return jsonDecode(res.body);
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> acceptTrip(String tripId) async {
    final headers = await AuthService.getHeaders();
    final res = await http.post(
      Uri.parse(ApiConfig.driverAcceptTrip),
      headers: headers,
      body: jsonEncode({'tripId': tripId}),
    );
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> rejectTrip(String tripId) async {
    final headers = await AuthService.getHeaders();
    final res = await http.post(
      Uri.parse(ApiConfig.driverRejectTrip),
      headers: headers,
      body: jsonEncode({'tripId': tripId}),
    );
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> markArrived(String tripId) async {
    final headers = await AuthService.getHeaders();
    final res = await http.post(
      Uri.parse(ApiConfig.driverArrived),
      headers: headers,
      body: jsonEncode({'tripId': tripId}),
    );
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> verifyPickupOtp(String tripId, String otp) async {
    final headers = await AuthService.getHeaders();
    final res = await http.post(
      Uri.parse(ApiConfig.driverVerifyOtp),
      headers: headers,
      body: jsonEncode({'tripId': tripId, 'otp': otp}),
    );
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> completeTrip({
    required String tripId,
    required double actualFare,
    required double actualDistance,
    double tips = 0,
  }) async {
    final headers = await AuthService.getHeaders();
    final res = await http.post(
      Uri.parse(ApiConfig.driverCompleteTrip),
      headers: headers,
      body: jsonEncode({
        'tripId': tripId,
        'actualFare': actualFare,
        'actualDistance': actualDistance,
        'tips': tips,
      }),
    );
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> cancelTrip(String tripId, String reason) async {
    final headers = await AuthService.getHeaders();
    final res = await http.post(
      Uri.parse(ApiConfig.driverCancelTrip),
      headers: headers,
      body: jsonEncode({'tripId': tripId, 'reason': reason}),
    );
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> rateCustomer({
    required String tripId,
    required double rating,
    String? review,
  }) async {
    final headers = await AuthService.getHeaders();
    final res = await http.post(
      Uri.parse(ApiConfig.driverRateCustomer),
      headers: headers,
      body: jsonEncode({'tripId': tripId, 'rating': rating, 'review': review ?? ''}),
    );
    return jsonDecode(res.body);
  }

  static Future<List<TripModel>> getTripHistory() async {
    try {
      final headers = await AuthService.getHeaders();
      final res = await http.get(Uri.parse(ApiConfig.driverTrips), headers: headers);
      final data = jsonDecode(res.body);
      final list = data['trips'] ?? data['data'] ?? [];
      return (list as List).map((t) => TripModel.fromJson(t)).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<Map<String, dynamic>> getWallet() async {
    final headers = await AuthService.getHeaders();
    final res = await http.get(Uri.parse(ApiConfig.driverWallet), headers: headers);
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> getEarnings(String period) async {
    final headers = await AuthService.getHeaders();
    final res = await http.get(
      Uri.parse('${ApiConfig.driverEarnings}?period=$period'),
      headers: headers,
    );
    return jsonDecode(res.body);
  }
}
