import 'package:jago_pilot_app/features/subscription/domain/repositories/subscription_repository_interface.dart';
import 'package:jago_pilot_app/features/subscription/domain/services/subscription_service_interface.dart';

class SubscriptionService implements SubscriptionServiceInterface {
  final SubscriptionRepositoryInterface subscriptionRepositoryInterface;
  SubscriptionService({required this.subscriptionRepositoryInterface});

  @override
  Future getPlans() {
    return subscriptionRepositoryInterface.getPlans();
  }

  @override
  Future subscribe(int planId) {
    return subscriptionRepositoryInterface.subscribe(planId);
  }

  @override
  Future getStatus() {
    return subscriptionRepositoryInterface.getStatus();
  }

  @override
  Future getHistory(int offset) {
    return subscriptionRepositoryInterface.getHistory(offset);
  }
}
