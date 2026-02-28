// ================================================================
// JAGO Driver App — Data Models
// ================================================================

class DriverProfile {
  final String id;
  final String fullName;
  final String phone;
  final double rating;
  final double walletBalance;
  final bool isLocked;
  final bool isOnline;
  final DriverStats stats;

  DriverProfile({
    required this.id,
    required this.fullName,
    required this.phone,
    required this.rating,
    required this.walletBalance,
    required this.isLocked,
    required this.isOnline,
    required this.stats,
  });

  factory DriverProfile.fromJson(Map<String, dynamic> j) => DriverProfile(
        id: j['id'],
        fullName: j['fullName'] ?? '',
        phone: j['phone'] ?? '',
        rating: (j['rating'] as num?)?.toDouble() ?? 0,
        walletBalance: (j['walletBalance'] as num?)?.toDouble() ?? 0,
        isLocked: j['isLocked'] ?? false,
        isOnline: j['isOnline'] ?? false,
        stats: DriverStats.fromJson(j['stats'] ?? {}),
      );
}

class DriverStats {
  final int completedTrips;
  final double totalEarned;

  DriverStats({required this.completedTrips, required this.totalEarned});

  factory DriverStats.fromJson(Map<String, dynamic> j) => DriverStats(
        completedTrips: j['completedTrips'] ?? 0,
        totalEarned: (j['totalEarned'] as num?)?.toDouble() ?? 0,
      );
}

class IncomingTrip {
  final String id;
  final String customerName;
  final String? customerPhone;
  final String pickupAddress;
  final String destinationAddress;
  final double estimatedFare;
  final double? estimatedDistance;
  final String stage; // 'assigned' | 'accepted'

  IncomingTrip({
    required this.id,
    required this.customerName,
    this.customerPhone,
    required this.pickupAddress,
    required this.destinationAddress,
    required this.estimatedFare,
    this.estimatedDistance,
    required this.stage,
  });

  factory IncomingTrip.fromJson(Map<String, dynamic> j) => IncomingTrip(
        id: j['id'],
        customerName: j['customerName'] ?? 'Customer',
        customerPhone: j['customerPhone'],
        pickupAddress: j['pickupAddress'] ?? '',
        destinationAddress: j['destinationAddress'] ?? '',
        estimatedFare: (j['estimatedFare'] as num?)?.toDouble() ?? 0,
        estimatedDistance: (j['estimatedDistance'] as num?)?.toDouble(),
        stage: j['stage'] ?? 'assigned',
      );
}

class TripDetail {
  final String id;
  final String refId;
  final String currentStatus;
  final String pickupAddress;
  final String destinationAddress;
  final double? actualFare;
  final double? estimatedFare;
  final String? pickupOtp;
  final double? platformDeduction;

  TripDetail({
    required this.id,
    required this.refId,
    required this.currentStatus,
    required this.pickupAddress,
    required this.destinationAddress,
    this.actualFare,
    this.estimatedFare,
    this.pickupOtp,
    this.platformDeduction,
  });

  factory TripDetail.fromJson(Map<String, dynamic> j) => TripDetail(
        id: j['id'],
        refId: j['refId'] ?? '',
        currentStatus: j['currentStatus'] ?? '',
        pickupAddress: j['pickupAddress'] ?? '',
        destinationAddress: j['destinationAddress'] ?? '',
        actualFare: (j['actualFare'] as num?)?.toDouble(),
        estimatedFare: (j['estimatedFare'] as num?)?.toDouble(),
        pickupOtp: j['pickupOtp'],
        platformDeduction: (j['platformDeduction'] as num?)?.toDouble(),
      );
}

class WalletInfo {
  final double walletBalance;
  final bool isLocked;
  final String? lockReason;
  final double pendingPaymentAmount;
  final List<PaymentRecord> history;

  WalletInfo({
    required this.walletBalance,
    required this.isLocked,
    this.lockReason,
    required this.pendingPaymentAmount,
    required this.history,
  });

  factory WalletInfo.fromJson(Map<String, dynamic> j) => WalletInfo(
        walletBalance: (j['walletBalance'] as num?)?.toDouble() ?? 0,
        isLocked: j['isLocked'] ?? false,
        lockReason: j['lockReason'],
        pendingPaymentAmount:
            (j['pendingPaymentAmount'] as num?)?.toDouble() ?? 0,
        history: (j['history'] as List? ?? [])
            .map((e) => PaymentRecord.fromJson(e))
            .toList(),
      );
}

class PaymentRecord {
  final String id;
  final String type;
  final double amount;
  final String description;
  final DateTime createdAt;

  PaymentRecord({
    required this.id,
    required this.type,
    required this.amount,
    required this.description,
    required this.createdAt,
  });

  factory PaymentRecord.fromJson(Map<String, dynamic> j) => PaymentRecord(
        id: j['id'].toString(),
        type: j['type'] ?? '',
        amount: (j['amount'] as num?)?.toDouble() ?? 0,
        description: j['description'] ?? '',
        createdAt: DateTime.tryParse(j['createdAt'] ?? '') ?? DateTime.now(),
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
