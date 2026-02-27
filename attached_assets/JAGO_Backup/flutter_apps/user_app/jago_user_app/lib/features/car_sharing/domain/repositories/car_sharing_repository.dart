import 'package:get/get_connect/http/src/response/response.dart';
import 'package:jago_user_app/data/api_client.dart';
import 'package:jago_user_app/features/car_sharing/domain/repositories/car_sharing_repository_interface.dart';
import 'package:jago_user_app/util/app_constants.dart';

class CarSharingRepository implements CarSharingRepositoryInterface {
  final ApiClient apiClient;

  CarSharingRepository({required this.apiClient});

  @override
  Future<Response?> findSharedRides(Map<String, dynamic> body) async {
    return await apiClient.postData(AppConstants.carSharingFindRides, body);
  }

  @override
  Future<Response?> joinSharedRide(Map<String, dynamic> body) async {
    return await apiClient.postData(AppConstants.carSharingJoinRide, body);
  }

  @override
  Future<Response?> getPassengers(String sharedGroupId) async {
    return await apiClient.getData('${AppConstants.carSharingPassengers}?shared_group_id=$sharedGroupId');
  }

  @override
  Future<Response?> getAvailableSeats(String sharedGroupId) async {
    return await apiClient.getData('${AppConstants.carSharingAvailableSeats}?shared_group_id=$sharedGroupId');
  }

  @override
  Future<Response?> getFareEstimate(Map<String, dynamic> body) async {
    return await apiClient.postData(AppConstants.carSharingFareEstimate, body);
  }

  @override
  Future<Response?> getSharingConfig() async {
    return await apiClient.getData(AppConstants.carSharingConfig);
  }

  @override
  Future<Response?> getActiveOffers({String? sharingType}) async {
    String url = AppConstants.carSharingOffers;
    if (sharingType != null && sharingType.isNotEmpty) {
      url += '?sharing_type=$sharingType';
    }
    return await apiClient.getData(url);
  }
}
