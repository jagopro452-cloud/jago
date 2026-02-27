import 'dart:math';
import 'package:get/get.dart';
import 'package:jago_user_app/data/api_checker.dart';
import 'package:jago_user_app/features/car_sharing/domain/services/car_sharing_service.dart';
import 'package:jago_user_app/helper/display_helper.dart';

class CarSharingController extends GetxController implements GetxService {
  final CarSharingService carSharingService;

  CarSharingController({required this.carSharingService});

  bool isLoading = false;
  bool isConfigLoading = false;
  List<dynamic> sharedRides = [];
  List<dynamic> passengers = [];
  Map<String, dynamic>? fareEstimate;
  Map<String, dynamic>? availableSeatsData;
  Map<String, dynamic>? joinRideResponse;

  String selectedSharingType = 'city';
  Map<String, dynamic> sharingConfig = {};
  List<dynamic> activeOffers = [];
  String? detectedSharingType;

  Future<void> loadSharingConfig() async {
    isConfigLoading = true;
    update();
    Response? response = await carSharingService.getSharingConfig();
    if (response!.statusCode == 200) {
      isConfigLoading = false;
      Map<String, dynamic> responseData = {};
      if (response.body['data'] != null && response.body['data'] is Map<String, dynamic>) {
        responseData = response.body['data'];
      } else if (response.body['content'] != null && response.body['content'] is Map<String, dynamic>) {
        responseData = response.body['content'];
      } else if (response.body is Map<String, dynamic>) {
        responseData = response.body;
      }
      sharingConfig = responseData['config'] is Map<String, dynamic> ? responseData['config'] : responseData;
      if (responseData['active_offers'] != null && responseData['active_offers'] is Map<String, dynamic>) {
        Map<String, dynamic> offersMap = responseData['active_offers'];
        activeOffers = [];
        offersMap.forEach((type, offers) {
          if (offers is List) {
            for (var offer in offers) {
              if (offer is Map<String, dynamic>) {
                offer['sharing_type'] = type;
                activeOffers.add(offer);
              }
            }
          }
        });
      }
    } else {
      isConfigLoading = false;
      ApiChecker.checkApi(response);
    }
    update();
  }

  void selectSharingType(String type) {
    selectedSharingType = type;
    update();
    loadActiveOffers(sharingType: type);
  }

  Future<void> loadActiveOffers({String? sharingType}) async {
    Response? response = await carSharingService.getActiveOffers(sharingType: sharingType ?? selectedSharingType);
    if (response!.statusCode == 200) {
      if (response.body['data'] != null) {
        activeOffers = response.body['data'] is List ? response.body['data'] : [];
      } else if (response.body is List) {
        activeOffers = response.body;
      } else {
        activeOffers = [];
      }
    } else {
      activeOffers = [];
    }
    update();
  }

  String detectSharingType(double pickupLat, double pickupLng, double dropLat, double dropLng) {
    double distanceKm = _calculateDistanceKm(pickupLat, pickupLng, dropLat, dropLng);
    double threshold = 50.0;
    if (sharingConfig.isNotEmpty) {
      threshold = double.tryParse(
        (sharingConfig['distance_threshold_km'] ?? sharingConfig['city']?['max_distance_km'] ?? '50').toString()
      ) ?? 50.0;
    }
    detectedSharingType = distanceKm > threshold ? 'outstation' : 'city';
    update();
    return detectedSharingType!;
  }

  double _calculateDistanceKm(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadiusKm = 6371.0;
    double dLat = _degToRad(lat2 - lat1);
    double dLon = _degToRad(lon2 - lon1);
    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degToRad(lat1)) * cos(_degToRad(lat2)) *
        sin(dLon / 2) * sin(dLon / 2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadiusKm * c;
  }

  double _degToRad(double deg) => deg * (pi / 180);

  bool isSharingTypeEnabled(String type) {
    if (sharingConfig.isEmpty) return true;
    if (type == 'city') {
      return sharingConfig['city']?['enabled'] != false && sharingConfig['city_enabled'] != false;
    } else {
      return sharingConfig['outstation']?['enabled'] != false && sharingConfig['outstation_enabled'] != false;
    }
  }

  Map<String, dynamic>? getActiveOfferForType(String type) {
    for (var offer in activeOffers) {
      if (offer is Map<String, dynamic>) {
        if (offer['sharing_type'] == type || offer['type'] == type) {
          return offer;
        }
      }
    }
    if (sharingConfig[type] != null && sharingConfig[type]['active_offer'] != null) {
      return sharingConfig[type]['active_offer'] is Map<String, dynamic>
          ? sharingConfig[type]['active_offer'] : null;
    }
    return null;
  }

  Future<void> findSharedRides({
    required String pickupLat,
    required String pickupLng,
    required String dropLat,
    required String dropLng,
    required String vehicleCategoryId,
    required String zoneId,
    required int seatsNeeded,
    String? sharingType,
  }) async {
    isLoading = true;
    sharedRides = [];
    update();
    Map<String, dynamic> body = {
      'pickup_lat': pickupLat,
      'pickup_lng': pickupLng,
      'drop_lat': dropLat,
      'drop_lng': dropLng,
      'vehicle_category_id': vehicleCategoryId,
      'zone_id': zoneId,
      'seats_needed': seatsNeeded,
    };
    if (sharingType != null && sharingType.isNotEmpty) {
      body['sharing_type'] = sharingType;
    }
    Response? response = await carSharingService.findSharedRides(body);
    if (response!.statusCode == 200) {
      isLoading = false;
      if (response.body['data'] != null) {
        sharedRides = response.body['data'];
      } else if (response.body is List) {
        sharedRides = response.body;
      }
    } else {
      isLoading = false;
      ApiChecker.checkApi(response);
    }
    update();
  }

  Future<void> joinSharedRide({
    required String tripRequestId,
    required String sharedGroupId,
    required int seatsBooked,
    required String pickupLat,
    required String pickupLng,
    required String pickupAddress,
    required String dropLat,
    required String dropLng,
    required String dropAddress,
    String? sharingType,
    String? offerId,
  }) async {
    isLoading = true;
    update();
    Map<String, dynamic> body = {
      'trip_request_id': tripRequestId,
      'shared_group_id': sharedGroupId,
      'seats_booked': seatsBooked,
      'pickup_lat': pickupLat,
      'pickup_lng': pickupLng,
      'pickup_address': pickupAddress,
      'drop_lat': dropLat,
      'drop_lng': dropLng,
      'drop_address': dropAddress,
    };
    if (sharingType != null && sharingType.isNotEmpty) {
      body['sharing_type'] = sharingType;
    }
    if (offerId != null && offerId.isNotEmpty) {
      body['offer_id'] = offerId;
    }
    Response? response = await carSharingService.joinSharedRide(body);
    if (response!.statusCode == 200) {
      isLoading = false;
      joinRideResponse = response.body is Map<String, dynamic> ? response.body : null;
      showCustomSnackBar('successfully_joined_shared_ride'.tr, isError: false);
    } else {
      isLoading = false;
      ApiChecker.checkApi(response);
    }
    update();
  }

  Future<void> getPassengers(String sharedGroupId) async {
    isLoading = true;
    update();
    Response? response = await carSharingService.getPassengers(sharedGroupId);
    if (response!.statusCode == 200) {
      isLoading = false;
      if (response.body['passengers'] != null) {
        passengers = response.body['passengers'];
      }
    } else {
      isLoading = false;
      ApiChecker.checkApi(response);
    }
    update();
  }

  Future<void> checkAvailableSeats(String sharedGroupId) async {
    isLoading = true;
    update();
    Response? response = await carSharingService.getAvailableSeats(sharedGroupId);
    if (response!.statusCode == 200) {
      isLoading = false;
      availableSeatsData = response.body is Map<String, dynamic> ? response.body : null;
    } else {
      isLoading = false;
      ApiChecker.checkApi(response);
    }
    update();
  }

  Future<void> getFareEstimate({
    required String pickupLat,
    required String pickupLng,
    required String dropLat,
    required String dropLng,
    required String zoneId,
    required String vehicleCategoryId,
    required int seatsNeeded,
    String? sharingType,
  }) async {
    isLoading = true;
    update();
    Map<String, dynamic> body = {
      'pickup_lat': pickupLat,
      'pickup_lng': pickupLng,
      'drop_lat': dropLat,
      'drop_lng': dropLng,
      'zone_id': zoneId,
      'vehicle_category_id': vehicleCategoryId,
      'seats_needed': seatsNeeded,
    };
    if (sharingType != null && sharingType.isNotEmpty) {
      body['sharing_type'] = sharingType;
    }
    Response? response = await carSharingService.getFareEstimate(body);
    if (response!.statusCode == 200) {
      isLoading = false;
      fareEstimate = response.body is Map<String, dynamic> ? response.body : null;
    } else {
      isLoading = false;
      ApiChecker.checkApi(response);
    }
    update();
  }

  void clearData() {
    sharedRides = [];
    passengers = [];
    fareEstimate = null;
    availableSeatsData = null;
    joinRideResponse = null;
    update();
  }
}
