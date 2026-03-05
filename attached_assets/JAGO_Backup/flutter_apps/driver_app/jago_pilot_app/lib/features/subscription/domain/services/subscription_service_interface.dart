abstract class SubscriptionServiceInterface {
  Future<dynamic> getPlans();
  Future<dynamic> subscribe(int planId);
  Future<dynamic> getStatus();
  Future<dynamic> getHistory(int offset);
}
