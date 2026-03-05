import 'package:get/get.dart';
import 'package:jago_pilot_app/data/api_checker.dart';
import 'package:jago_pilot_app/features/splash/controllers/splash_controller.dart';
import 'package:jago_pilot_app/features/subscription/domain/services/subscription_service_interface.dart';
import 'package:jago_pilot_app/helper/display_helper.dart';

class SubscriptionController extends GetxController implements GetxService {
  final SubscriptionServiceInterface subscriptionServiceInterface;

  SubscriptionController({required this.subscriptionServiceInterface});

  List<dynamic> plans = [];
  Map<String, dynamic> currentStatus = {};
  List<dynamic> subscriptionHistory = [];
  bool isLoading = false;

  String get earningModel => Get.find<SplashController>().config?.earningModel ?? 'commission';
  double get platformFeeAmount => Get.find<SplashController>().config?.platformFeeAmount ?? 0;
  double get commissionPercent => Get.find<SplashController>().config?.commissionPercent ?? 0;
  double get gstPercent => Get.find<SplashController>().config?.gstPercent ?? 0;
  bool get isSubscriptionModel => earningModel == 'subscription';

  Future<void> getPlans() async {
    isLoading = true;
    update();
    Response response = await subscriptionServiceInterface.getPlans();
    if (response.statusCode == 200) {
      plans = response.body is List ? response.body : (response.body['data'] ?? []);
    } else {
      ApiChecker.checkApi(response);
    }
    isLoading = false;
    update();
  }

  Future<void> getStatus() async {
    Response response = await subscriptionServiceInterface.getStatus();
    if (response.statusCode == 200) {
      currentStatus = response.body is Map<String, dynamic> ? response.body : {};
    } else {
      ApiChecker.checkApi(response);
    }
    update();
  }

  Future<void> subscribe(int planId) async {
    isLoading = true;
    update();
    Response response = await subscriptionServiceInterface.subscribe(planId);
    if (response.statusCode == 200) {
      showCustomSnackBar('subscribed_successfully'.tr, isError: false);
      getPlans();
      getStatus();
    } else {
      ApiChecker.checkApi(response);
    }
    isLoading = false;
    update();
  }

  Future<void> getHistory(int offset) async {
    isLoading = true;
    update();
    Response response = await subscriptionServiceInterface.getHistory(offset);
    if (response.statusCode == 200) {
      if (offset == 1) {
        subscriptionHistory = response.body is List ? response.body : (response.body['data'] ?? []);
      } else {
        subscriptionHistory.addAll(response.body is List ? response.body : (response.body['data'] ?? []));
      }
    } else {
      ApiChecker.checkApi(response);
    }
    isLoading = false;
    update();
  }
}
