import 'package:jago_user_app/features/car_sharing/domain/repositories/car_sharing_repository_interface.dart';
import 'package:jago_user_app/features/car_sharing/domain/services/car_sharing_service_interface.dart';

class CarSharingService implements CarSharingServiceInterface {
  CarSharingRepositoryInterface carSharingRepositoryInterface;

  CarSharingService({required this.carSharingRepositoryInterface});

  @override
  Future findSharedRides(Map<String, dynamic> body) async {
    return await carSharingRepositoryInterface.findSharedRides(body);
  }

  @override
  Future joinSharedRide(Map<String, dynamic> body) async {
    return await carSharingRepositoryInterface.joinSharedRide(body);
  }

  @override
  Future getPassengers(String sharedGroupId) async {
    return await carSharingRepositoryInterface.getPassengers(sharedGroupId);
  }

  @override
  Future getAvailableSeats(String sharedGroupId) async {
    return await carSharingRepositoryInterface.getAvailableSeats(sharedGroupId);
  }

  @override
  Future getFareEstimate(Map<String, dynamic> body) async {
    return await carSharingRepositoryInterface.getFareEstimate(body);
  }

  @override
  Future getSharingConfig() async {
    return await carSharingRepositoryInterface.getSharingConfig();
  }

  @override
  Future getActiveOffers({String? sharingType}) async {
    return await carSharingRepositoryInterface.getActiveOffers(sharingType: sharingType);
  }
}
