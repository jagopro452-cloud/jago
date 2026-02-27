import 'package:get/get_connect/http/src/response/response.dart';

abstract class SubscriptionRepositoryInterface {
  Future<Response> getPlans();
  Future<Response> subscribe(int planId);
  Future<Response> getStatus();
  Future<Response> getHistory(int offset);
}
