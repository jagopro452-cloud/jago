abstract class ParcelServiceInterface{
  Future<dynamic> getParcelCategory();
  Future<dynamic> getParcelVehicleTypes(String zoneId);
  Future<dynamic> getRunningParcelList(int offset);
  Future<dynamic> getUnpaidParcelList(int offset);
}
