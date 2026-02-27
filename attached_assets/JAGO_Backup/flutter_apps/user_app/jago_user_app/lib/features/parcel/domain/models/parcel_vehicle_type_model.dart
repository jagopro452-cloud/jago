class ParcelVehicleTypeResponse {
  String? responseCode;
  String? message;
  List<ParcelVehicleType>? data;

  ParcelVehicleTypeResponse({this.responseCode, this.message, this.data});

  ParcelVehicleTypeResponse.fromJson(Map<String, dynamic> json) {
    responseCode = json['response_code'];
    message = json['message'];
    if (json['data'] != null) {
      data = <ParcelVehicleType>[];
      json['data'].forEach((v) {
        data!.add(ParcelVehicleType.fromJson(v));
      });
    }
  }
}

class ParcelVehicleType {
  String? vehicleCategoryId;
  String? vehicleCategoryName;
  String? vehicleCategoryType;
  String? vehicleCategoryImage;
  double? baseFare;
  double? baseFarePerKm;
  double? perMinuteRate;
  double? minimumFare;
  double? returnFee;

  ParcelVehicleType({
    this.vehicleCategoryId,
    this.vehicleCategoryName,
    this.vehicleCategoryType,
    this.vehicleCategoryImage,
    this.baseFare,
    this.baseFarePerKm,
    this.perMinuteRate,
    this.minimumFare,
    this.returnFee,
  });

  ParcelVehicleType.fromJson(Map<String, dynamic> json) {
    vehicleCategoryId = json['vehicle_category_id'];
    vehicleCategoryName = json['vehicle_category_name'];
    vehicleCategoryType = json['vehicle_category_type'];
    vehicleCategoryImage = json['vehicle_category_image'];
    baseFare = double.tryParse(json['base_fare']?.toString() ?? '0');
    baseFarePerKm = double.tryParse(json['base_fare_per_km']?.toString() ?? '0');
    perMinuteRate = double.tryParse(json['per_minute_rate']?.toString() ?? '0');
    minimumFare = double.tryParse(json['minimum_fare']?.toString() ?? '0');
    returnFee = double.tryParse(json['return_fee']?.toString() ?? '0');
  }

  String get vehicleIcon {
    switch (vehicleCategoryType) {
      case 'motor_bike':
        return '🏍️';
      case 'auto':
        return '🛺';
      case 'car':
        return '🚛';
      default:
        return '📦';
    }
  }
}
