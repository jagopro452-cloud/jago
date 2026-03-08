import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'auth_service.dart';

class LocationService {
  static Future<bool> requestPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  static Future<Position?> getCurrentPosition() async {
    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
    } catch (_) {
      return null;
    }
  }

  static Stream<Position> getLocationStream() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    );
  }

  static Future<void> updateLocation({
    required double lat,
    required double lng,
    double heading = 0,
    double speed = 0,
    bool isOnline = true,
  }) async {
    try {
      final headers = await AuthService.getHeaders();
      await http.post(
        Uri.parse(ApiConfig.driverLocation),
        headers: headers,
        body: jsonEncode({
          'lat': lat,
          'lng': lng,
          'heading': heading,
          'speed': speed,
          'isOnline': isOnline,
        }),
      );
    } catch (_) {}
  }

  static Future<Map<String, dynamic>> setOnlineStatus(bool isOnline) async {
    final headers = await AuthService.getHeaders();
    final res = await http.patch(
      Uri.parse(ApiConfig.driverOnlineStatus),
      headers: headers,
      body: jsonEncode({'isOnline': isOnline}),
    );
    return jsonDecode(res.body);
  }
}
