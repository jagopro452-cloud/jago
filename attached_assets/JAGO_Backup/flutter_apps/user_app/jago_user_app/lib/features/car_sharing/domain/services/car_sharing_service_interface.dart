abstract class CarSharingServiceInterface {
  Future<dynamic> findSharedRides(Map<String, dynamic> body);
  Future<dynamic> joinSharedRide(Map<String, dynamic> body);
  Future<dynamic> getPassengers(String sharedGroupId);
  Future<dynamic> getAvailableSeats(String sharedGroupId);
  Future<dynamic> getFareEstimate(Map<String, dynamic> body);
  Future<dynamic> getSharingConfig();
  Future<dynamic> getActiveOffers({String? sharingType});
}
