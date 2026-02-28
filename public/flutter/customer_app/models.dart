// ================================================================
// JAGO Customer App — Data Models
// ================================================================

class CustomerProfile {
  final String id;
  final String fullName;
  final String phone;
  final double rating;
  final double walletBalance;
  final CustomerStats stats;

  CustomerProfile({
    required this.id,
    required this.fullName,
    required this.phone,
    required this.rating,
    required this.walletBalance,
    required this.stats,
  });

  factory CustomerProfile.fromJson(Map<String, dynamic> j) => CustomerProfile(
        id: j['id'],
        fullName: j['fullName'] ?? '',
        phone: j['phone'] ?? '',
        rating: (j['rating'] as num?)?.toDouble() ?? 0,
        walletBalance: (j['walletBalance'] as num?)?.toDouble() ?? 0,
        stats: CustomerStats.fromJson(j['stats'] ?? {}),
      );
}

class CustomerStats {
  final int completedTrips;
  final double totalSpent;

  CustomerStats({required this.completedTrips, required this.totalSpent});

  factory CustomerStats.fromJson(Map<String, dynamic> j) => CustomerStats(
        completedTrips: j['completedTrips'] ?? 0,
        totalSpent: (j['totalSpent'] as num?)?.toDouble() ?? 0,
      );
}

class FareOption {
  final String vehicleCategoryId;
  final String vehicleName;
  final double baseFare;
  final double farePerKm;
  final double estimatedFare;

  FareOption({
    required this.vehicleCategoryId,
    required this.vehicleName,
    required this.baseFare,
    required this.farePerKm,
    required this.estimatedFare,
  });

  factory FareOption.fromJson(Map<String, dynamic> j) => FareOption(
        vehicleCategoryId: j['vehicleCategoryId'] ?? '',
        vehicleName: j['vehicleName'] ?? '',
        baseFare: (j['baseFare'] as num?)?.toDouble() ?? 0,
        farePerKm: (j['farePerKm'] as num?)?.toDouble() ?? 0,
        estimatedFare: (j['estimatedFare'] as num?)?.toDouble() ?? 0,
      );
}

class NearbyDriver {
  final String id;
  final String fullName;
  final double lat;
  final double lng;
  final double? heading;
  final double rating;

  NearbyDriver({
    required this.id,
    required this.fullName,
    required this.lat,
    required this.lng,
    this.heading,
    required this.rating,
  });

  factory NearbyDriver.fromJson(Map<String, dynamic> j) => NearbyDriver(
        id: j['id'],
        fullName: j['fullName'] ?? '',
        lat: (j['lat'] as num).toDouble(),
        lng: (j['lng'] as num).toDouble(),
        heading: (j['heading'] as num?)?.toDouble(),
        rating: (j['rating'] as num?)?.toDouble() ?? 0,
      );
}

class BookingResult {
  final String tripId;
  final String refId;
  final String currentStatus; // 'driver_assigned' | 'searching'
  final AssignedDriver? driver;

  BookingResult({
    required this.tripId,
    required this.refId,
    required this.currentStatus,
    this.driver,
  });

  factory BookingResult.fromJson(Map<String, dynamic> j) {
    final trip = j['trip'] as Map<String, dynamic>;
    return BookingResult(
      tripId: trip['id'],
      refId: trip['refId'] ?? '',
      currentStatus: trip['currentStatus'] ?? 'searching',
      driver: j['driver'] != null
          ? AssignedDriver.fromJson(j['driver'])
          : null,
    );
  }
}

class AssignedDriver {
  final String id;
  final String fullName;
  final double lat;
  final double lng;
  final double? rating;

  AssignedDriver({
    required this.id,
    required this.fullName,
    required this.lat,
    required this.lng,
    this.rating,
  });

  factory AssignedDriver.fromJson(Map<String, dynamic> j) => AssignedDriver(
        id: j['id'],
        fullName: j['fullName'] ?? '',
        lat: (j['lat'] as num).toDouble(),
        lng: (j['lng'] as num).toDouble(),
        rating: (j['rating'] as num?)?.toDouble(),
      );
}

class ActiveTrip {
  final String id;
  final String currentStatus;
  final String? driverName;
  final String? driverPhone;
  final double? driverLat;
  final double? driverLng;
  final double? driverHeading;
  final String? pickupOtpVisible; // only when status == 'arrived'
  final String pickupAddress;
  final String destinationAddress;
  final double? estimatedFare;
  final double? actualFare;

  ActiveTrip({
    required this.id,
    required this.currentStatus,
    this.driverName,
    this.driverPhone,
    this.driverLat,
    this.driverLng,
    this.driverHeading,
    this.pickupOtpVisible,
    required this.pickupAddress,
    required this.destinationAddress,
    this.estimatedFare,
    this.actualFare,
  });

  factory ActiveTrip.fromJson(Map<String, dynamic> j) => ActiveTrip(
        id: j['id'],
        currentStatus: j['currentStatus'] ?? '',
        driverName: j['driverName'],
        driverPhone: j['driverPhone'],
        driverLat: (j['driverLat'] as num?)?.toDouble(),
        driverLng: (j['driverLng'] as num?)?.toDouble(),
        driverHeading: (j['driverHeading'] as num?)?.toDouble(),
        pickupOtpVisible: j['pickupOtpVisible'],
        pickupAddress: j['pickupAddress'] ?? '',
        destinationAddress: j['destinationAddress'] ?? '',
        estimatedFare: (j['estimatedFare'] as num?)?.toDouble(),
        actualFare: (j['actualFare'] as num?)?.toDouble(),
      );

  bool get isCompleted => currentStatus == TripStatus.completed;
  bool get isCancelled => currentStatus == TripStatus.cancelled;
  bool get driverArrived => currentStatus == TripStatus.arrived;
  bool get rideInProgress => currentStatus == TripStatus.onTheWay;
}

class AppConfigs {
  final List<VehicleCategory> vehicleCategories;
  final List<String> cancellationReasons;
  final Map<String, String> configs;

  AppConfigs({
    required this.vehicleCategories,
    required this.cancellationReasons,
    required this.configs,
  });

  factory AppConfigs.fromJson(Map<String, dynamic> j) => AppConfigs(
        vehicleCategories: (j['vehicleCategories'] as List? ?? [])
            .map((e) => VehicleCategory.fromJson(e))
            .toList(),
        cancellationReasons:
            (j['cancellationReasons'] as List? ?? []).cast<String>(),
        configs: Map<String, String>.from(j['configs'] ?? {}),
      );

  String get currencySymbol => configs['currency_symbol'] ?? '₹';
  String get sosNumber => configs['sos_number'] ?? '';
}

class VehicleCategory {
  final String id;
  final String name;
  final String? icon;
  final double baseFare;
  final double farePerKm;

  VehicleCategory({
    required this.id,
    required this.name,
    this.icon,
    required this.baseFare,
    required this.farePerKm,
  });

  factory VehicleCategory.fromJson(Map<String, dynamic> j) => VehicleCategory(
        id: j['id'],
        name: j['name'] ?? '',
        icon: j['icon'],
        baseFare: (j['baseFare'] as num?)?.toDouble() ?? 0,
        farePerKm: (j['farePerKm'] as num?)?.toDouble() ?? 0,
      );
}

// Trip status constants
class TripStatus {
  static const String searching      = 'searching';
  static const String driverAssigned = 'driver_assigned';
  static const String accepted       = 'accepted';
  static const String arrived        = 'arrived';
  static const String onTheWay       = 'on_the_way';
  static const String completed      = 'completed';
  static const String cancelled      = 'cancelled';
}
