abstract class SpinWheelServiceInterface {
  Future<dynamic> getConfig();
  Future<dynamic> spin(String? tripRequestId);
  Future<dynamic> getHistory();
}
