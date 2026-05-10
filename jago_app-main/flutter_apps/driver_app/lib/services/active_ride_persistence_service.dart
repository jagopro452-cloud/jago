import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class ActiveRidePersistenceService {
  static const _activeTripSnapshotKey = 'driver_active_trip_snapshot_v1';
  static const _activeTripIdKey = 'driver_active_trip_id_v1';
  static const _activeTripStatusKey = 'driver_active_trip_status_v1';
  static const _activeTripUpdatedAtKey = 'driver_active_trip_updated_at_v1';
  static const _lastLatKey = 'driver_active_trip_last_lat_v1';
  static const _lastLngKey = 'driver_active_trip_last_lng_v1';
  static const _lastHeadingKey = 'driver_active_trip_last_heading_v1';
  static const _lastSpeedKey = 'driver_active_trip_last_speed_v1';
  static const _wasOnlineKey = 'driver_active_trip_was_online_v1';

  static bool _isRecoverableStatus(String status) {
    return const {
      'driver_assigned',
      'accepted',
      'arrived',
      'waiting',
      'otp_pending',
      'otp_verified',
      'in_progress',
      'on_the_way',
      'heading_to_destination',
      'heading_to_pickup',
    }.contains(status.trim());
  }

  static String _resolveStatus(Map<String, dynamic> trip) {
    return (trip['canonicalState'] ??
            trip['currentStatus'] ??
            trip['current_status'] ??
            trip['status'] ??
            '')
        .toString();
  }

  static String _resolveTripId(Map<String, dynamic> trip) {
    return (trip['id'] ?? trip['tripId'] ?? '').toString();
  }

  static Future<void> persistActiveRide(
    Map<String, dynamic> trip, {
    double? lastLat,
    double? lastLng,
    double? heading,
    double? speed,
    bool? wasOnline,
  }) async {
    final tripId = _resolveTripId(trip);
    final status = _resolveStatus(trip);
    if (tripId.isEmpty || !_isRecoverableStatus(status)) {
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_activeTripSnapshotKey, jsonEncode(trip));
    await prefs.setString(_activeTripIdKey, tripId);
    await prefs.setString(_activeTripStatusKey, status);
    await prefs.setInt(
      _activeTripUpdatedAtKey,
      DateTime.now().millisecondsSinceEpoch,
    );
    if (lastLat != null) await prefs.setDouble(_lastLatKey, lastLat);
    if (lastLng != null) await prefs.setDouble(_lastLngKey, lastLng);
    if (heading != null) await prefs.setDouble(_lastHeadingKey, heading);
    if (speed != null) await prefs.setDouble(_lastSpeedKey, speed);
    if (wasOnline != null) await prefs.setBool(_wasOnlineKey, wasOnline);
  }

  static Future<Map<String, dynamic>?> loadActiveRideSnapshot({
    Duration maxAge = const Duration(hours: 8),
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_activeTripSnapshotKey);
    final updatedAt = prefs.getInt(_activeTripUpdatedAtKey) ?? 0;
    final status = prefs.getString(_activeTripStatusKey) ?? '';
    if (raw == null || raw.isEmpty || !_isRecoverableStatus(status)) {
      return null;
    }
    if (updatedAt > 0 &&
        DateTime.now().millisecondsSinceEpoch - updatedAt >
            maxAge.inMilliseconds) {
      return null;
    }
    try {
      return Map<String, dynamic>.from(jsonDecode(raw) as Map);
    } catch (_) {
      return null;
    }
  }

  static Future<Map<String, dynamic>> loadTrackingContext() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'tripId': prefs.getString(_activeTripIdKey),
      'status': prefs.getString(_activeTripStatusKey),
      'wasOnline': prefs.getBool(_wasOnlineKey) ?? false,
      'lastLat': prefs.getDouble(_lastLatKey),
      'lastLng': prefs.getDouble(_lastLngKey),
      'heading': prefs.getDouble(_lastHeadingKey) ?? 0.0,
      'speed': prefs.getDouble(_lastSpeedKey) ?? 0.0,
      'updatedAtMs': prefs.getInt(_activeTripUpdatedAtKey) ?? 0,
    };
  }

  static Future<bool> hasActiveRideHint() async {
    final snapshot = await loadActiveRideSnapshot();
    return snapshot != null;
  }

  static Future<bool> hasFreshActiveRideHint({
    Duration maxAge = const Duration(hours: 8),
  }) async {
    final snapshot = await loadActiveRideSnapshot(maxAge: maxAge);
    return snapshot != null;
  }

  static Future<void> updateTrackingHeartbeat({
    String? tripId,
    String? status,
    double? lat,
    double? lng,
    double? heading,
    double? speed,
    bool? wasOnline,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (tripId != null && tripId.isNotEmpty) {
      await prefs.setString(_activeTripIdKey, tripId);
    }
    if (status != null && status.isNotEmpty) {
      await prefs.setString(_activeTripStatusKey, status);
    }
    await prefs.setInt(
      _activeTripUpdatedAtKey,
      DateTime.now().millisecondsSinceEpoch,
    );
    if (lat != null) await prefs.setDouble(_lastLatKey, lat);
    if (lng != null) await prefs.setDouble(_lastLngKey, lng);
    if (heading != null) await prefs.setDouble(_lastHeadingKey, heading);
    if (speed != null) await prefs.setDouble(_lastSpeedKey, speed);
    if (wasOnline != null) await prefs.setBool(_wasOnlineKey, wasOnline);
  }

  static Future<void> clearActiveRide() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_activeTripSnapshotKey);
    await prefs.remove(_activeTripIdKey);
    await prefs.remove(_activeTripStatusKey);
    await prefs.remove(_activeTripUpdatedAtKey);
    await prefs.remove(_lastLatKey);
    await prefs.remove(_lastLngKey);
    await prefs.remove(_lastHeadingKey);
    await prefs.remove(_lastSpeedKey);
    await prefs.remove(_wasOnlineKey);
  }
}
