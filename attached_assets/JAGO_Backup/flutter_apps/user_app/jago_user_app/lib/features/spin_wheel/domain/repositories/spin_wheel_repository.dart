import 'package:get/get_connect/http/src/response/response.dart';
import 'package:jago_user_app/data/api_client.dart';
import 'package:jago_user_app/features/spin_wheel/domain/repositories/spin_wheel_repository_interface.dart';
import 'package:jago_user_app/util/app_constants.dart';

class SpinWheelRepository implements SpinWheelRepositoryInterface {
  final ApiClient apiClient;

  SpinWheelRepository({required this.apiClient});

  @override
  Future<Response> getConfig() async {
    return await apiClient.getData(AppConstants.spinWheelConfig);
  }

  @override
  Future<Response> spin(String? tripRequestId) async {
    return await apiClient.postData(AppConstants.spinWheelSpin, {
      'trip_request_id': tripRequestId,
    });
  }

  @override
  Future<Response> getHistory() async {
    return await apiClient.getData(AppConstants.spinWheelHistory);
  }
}
