import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class TripNavigationSnapshot {
  final String canonicalState;
  final bool isPickupNavigationStage;
  final bool isPickupArrivalStage;
  final bool isDestinationNavigationStage;
  final bool routeReady;
  final bool nearPickup;
  final String headline;
  final String actionLabel;
  final String etaLabel;
  final String distanceLabel;
  final String targetLabel;
  final String helperLabel;

  const TripNavigationSnapshot({
    required this.canonicalState,
    required this.isPickupNavigationStage,
    required this.isPickupArrivalStage,
    required this.isDestinationNavigationStage,
    required this.routeReady,
    required this.nearPickup,
    required this.headline,
    required this.actionLabel,
    required this.etaLabel,
    required this.distanceLabel,
    required this.targetLabel,
    required this.helperLabel,
  });
}

class TripNavigationController {
  static String normalizeState(String? raw) {
    final status = (raw ?? '').trim().toLowerCase();
    switch (status) {
      case 'waiting_for_otp':
        return 'otp_pending';
      case 'trip_started':
        return 'in_progress';
      case 'cancelled_by_user':
      case 'cancelled_by_driver':
      case 'cancelled_by_admin':
        return 'cancelled';
      case 'driver_assigned':
      case 'accepted':
      case 'heading_to_pickup':
        return 'heading_to_pickup';
      case 'otp_verified':
      case 'in_progress':
      case 'on_the_way':
      case 'heading_to_destination':
        return status == 'otp_verified' ? 'heading_to_destination' : status;
      default:
        return status;
    }
  }

  static LatLng? targetForState(
    Map<String, dynamic>? trip,
    String canonicalState,
  ) {
    if (trip == null) return null;
    final usePickup = canonicalState == 'heading_to_pickup' ||
        canonicalState == 'arrived' ||
        canonicalState == 'waiting' ||
        canonicalState == 'otp_pending';
    final lat = _tripDouble(
      trip,
      usePickup ? const ['pickupLat', 'pickup_lat'] : const ['destinationLat', 'destination_lat'],
    );
    final lng = _tripDouble(
      trip,
      usePickup ? const ['pickupLng', 'pickup_lng'] : const ['destinationLng', 'destination_lng'],
    );
    if (lat == 0 || lng == 0) return null;
    return LatLng(lat, lng);
  }

  static TripNavigationSnapshot resolve({
    required Map<String, dynamic>? trip,
    required String rawState,
    required bool routeReady,
    required bool nearPickup,
    required bool waitingActive,
    required double distanceMeters,
    required int etaSec,
  }) {
    final canonicalState = normalizeState(rawState);
    final isPickupNavigationStage = canonicalState == 'heading_to_pickup';
    final isPickupArrivalStage = canonicalState == 'arrived' ||
        canonicalState == 'waiting' ||
        canonicalState == 'otp_pending';
    final isDestinationNavigationStage = canonicalState == 'heading_to_destination' ||
        canonicalState == 'in_progress' ||
        canonicalState == 'on_the_way';
    final targetLabel = _targetLabel(trip, canonicalState);
    final etaLabel = etaSec > 0 ? _formatEta(etaSec) : '--';
    final distanceLabel = distanceMeters > 0 ? _formatDistance(distanceMeters) : '--';

    if (isPickupNavigationStage) {
      return TripNavigationSnapshot(
        canonicalState: canonicalState,
        isPickupNavigationStage: true,
        isPickupArrivalStage: false,
        isDestinationNavigationStage: false,
        routeReady: routeReady,
        nearPickup: nearPickup,
        headline: 'Navigating to Pickup',
        actionLabel: 'Arrived at Pickup',
        etaLabel: etaLabel,
        distanceLabel: distanceLabel,
        targetLabel: targetLabel,
        helperLabel: routeReady
            ? 'Live pickup route active'
            : 'Preparing pickup route and ETA',
      );
    }

    if (isPickupArrivalStage) {
      final waitingLabel = waitingActive ? 'Waiting timer active' : 'Waiting for customer OTP';
      return TripNavigationSnapshot(
        canonicalState: canonicalState,
        isPickupNavigationStage: false,
        isPickupArrivalStage: true,
        isDestinationNavigationStage: false,
        routeReady: routeReady,
        nearPickup: true,
        headline: canonicalState == 'waiting' ? 'Waiting at Pickup' : 'Pickup Reached',
        actionLabel: 'Enter Customer OTP',
        etaLabel: waitingActive ? 'WAITING' : 'ARRIVED',
        distanceLabel: waitingActive ? distanceLabel : '0 m',
        targetLabel: targetLabel,
        helperLabel: waitingLabel,
      );
    }

    if (isDestinationNavigationStage) {
      return TripNavigationSnapshot(
        canonicalState: canonicalState,
        isPickupNavigationStage: false,
        isPickupArrivalStage: false,
        isDestinationNavigationStage: true,
        routeReady: routeReady,
        nearPickup: false,
        headline: 'Navigating to Destination',
        actionLabel: 'Complete Trip',
        etaLabel: etaLabel,
        distanceLabel: distanceLabel,
        targetLabel: targetLabel,
        helperLabel: routeReady
            ? 'Live destination route active'
            : 'Preparing destination route and ETA',
      );
    }

    return TripNavigationSnapshot(
      canonicalState: canonicalState,
      isPickupNavigationStage: false,
      isPickupArrivalStage: false,
      isDestinationNavigationStage: false,
      routeReady: routeReady,
      nearPickup: nearPickup,
      headline: 'Trip Active',
      actionLabel: 'Next Step',
      etaLabel: '--',
      distanceLabel: '--',
      targetLabel: targetLabel,
      helperLabel: 'Waiting for ride lifecycle update',
    );
  }

  static String? validateArrivedPreflight({
    required Map<String, dynamic>? trip,
    required LatLng? driverLocation,
    required int geofenceMeters,
  }) {
    final pickupTarget = targetForState(trip, 'heading_to_pickup');
    if (pickupTarget == null) {
      return 'Pickup location missing. Refresh trip details and try again.';
    }
    if (driverLocation == null) {
      return 'Live GPS is required before marking arrived.';
    }
    final distance = _distanceMeters(driverLocation, pickupTarget);
    if (distance > geofenceMeters) {
      final extra = (distance - geofenceMeters).ceil();
      return 'Move closer to pickup. You are ${distance.round()}m away, around ${extra}m outside the arrival zone.';
    }
    return null;
  }

  static double _distanceMeters(LatLng a, LatLng b) {
    return Geolocator.distanceBetween(
      a.latitude,
      a.longitude,
      b.latitude,
      b.longitude,
    );
  }

  static double _tripDouble(Map<String, dynamic> trip, List<String> keys) {
    for (final key in keys) {
      final value = double.tryParse(trip[key]?.toString() ?? '');
      if (value != null && value != 0) return value;
    }
    return 0;
  }

  static String _targetLabel(Map<String, dynamic>? trip, String canonicalState) {
    if (trip == null) return 'Live navigation target';
    final usePickup = canonicalState == 'heading_to_pickup' ||
        canonicalState == 'arrived' ||
        canonicalState == 'waiting' ||
        canonicalState == 'otp_pending';
    final keys = usePickup
        ? const ['pickupShortName', 'pickupAddress', 'pickup_address']
        : const ['destinationShortName', 'destinationAddress', 'destination_address'];
    for (final key in keys) {
      final value = trip[key]?.toString().trim() ?? '';
      if (value.isNotEmpty) {
        return value.split(',').first.trim();
      }
    }
    return usePickup ? 'Pickup' : 'Destination';
  }

  static String _formatEta(int etaSec) {
    if (etaSec <= 0) return '--';
    final minutes = (etaSec / 60).ceil();
    if (minutes < 60) return '$minutes min';
    final hours = minutes ~/ 60;
    final remainder = minutes % 60;
    return remainder == 0 ? '$hours hr' : '$hours hr $remainder min';
  }

  static String _formatDistance(double meters) {
    if (meters <= 0) return '--';
    if (meters >= 1000) {
      return '${(meters / 1000).toStringAsFixed(1)} km';
    }
    return '${meters.round()} m';
  }
}
