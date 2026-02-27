import 'package:get/get_connect/http/src/response/response.dart';
import 'package:jago_pilot_app/data/api_client.dart';
import 'package:jago_pilot_app/features/subscription/domain/repositories/subscription_repository_interface.dart';
import 'package:jago_pilot_app/util/app_constants.dart';

class SubscriptionRepository implements SubscriptionRepositoryInterface {
  final ApiClient apiClient;

  SubscriptionRepository({required this.apiClient});

  @override
  Future<Response> getPlans() async {
    return await apiClient.getData(AppConstants.subscriptionPlans);
  }

  @override
  Future<Response> subscribe(int planId) async {
    return await apiClient.postData(AppConstants.subscriptionSubscribe, {
      'plan_id': planId.toString(),
    });
  }

  @override
  Future<Response> getStatus() async {
    return await apiClient.getData(AppConstants.subscriptionStatus);
  }

  @override
  Future<Response> getHistory(int offset) async {
    return await apiClient.getData('${AppConstants.subscriptionHistory}?limit=10&offset=$offset');
  }
}
