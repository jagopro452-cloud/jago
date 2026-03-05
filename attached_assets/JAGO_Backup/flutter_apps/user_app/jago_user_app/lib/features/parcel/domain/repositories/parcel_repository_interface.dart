import 'package:jago_user_app/interface/repository_interface.dart';

abstract class ParcelRepositoryInterface implements RepositoryInterface{
  Future<dynamic> getParcelCategory();
  Future<dynamic> getParcelVehicleTypes(String zoneId);
  Future<dynamic> getRunningParcelList(int offset);
  Future<dynamic> getUnpaidParcelList(int offset);
}
