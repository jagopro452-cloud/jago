import 'package:jago_user_app/features/parcel/domain/repositories/parcel_repository_interface.dart';
import 'package:jago_user_app/features/parcel/domain/services/parcel_service_interface.dart';

class ParcelService implements ParcelServiceInterface{
  ParcelRepositoryInterface parcelRepositoryInterface;

  ParcelService({required this.parcelRepositoryInterface});

  @override
  Future getRunningParcelList(int offset) async{
   return await parcelRepositoryInterface.getRunningParcelList(offset);
  }

  @override
  Future getParcelCategory() async{
    return await parcelRepositoryInterface.getParcelCategory();
  }

  @override
  Future getParcelVehicleTypes(String zoneId) async{
    return await parcelRepositoryInterface.getParcelVehicleTypes(zoneId);
  }

  @override
  Future getUnpaidParcelList(int offset) async{
    return await parcelRepositoryInterface.getUnpaidParcelList(offset);
  }

}
