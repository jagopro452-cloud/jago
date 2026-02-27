import 'package:get/get.dart';
import 'package:jago_user_app/data/api_checker.dart';
import 'package:jago_user_app/features/spin_wheel/domain/services/spin_wheel_service.dart';
import 'package:jago_user_app/helper/display_helper.dart';

class SpinWheelController extends GetxController implements GetxService {
  final SpinWheelService spinWheelService;

  SpinWheelController({required this.spinWheelService});

  bool isActive = false;
  String title = '';
  String subtitle = '';
  List<dynamic> segments = [];
  List<dynamic> segmentColors = [];
  bool isLoading = false;
  bool isSpinning = false;
  Map<String, dynamic>? lastResult;
  List<dynamic> history = [];

  Future<void> getConfig() async {
    isLoading = true;
    update();
    Response? response = await spinWheelService.getConfig();
    if (response!.statusCode == 200) {
      isActive = response.body['data']['is_active'] ?? false;
      title = response.body['data']['title'] ?? '';
      subtitle = response.body['data']['subtitle'] ?? '';
      segments = response.body['data']['segments'] ?? [];
      segmentColors = response.body['data']['segment_colors'] ?? [];
      isLoading = false;
    } else {
      isLoading = false;
      ApiChecker.checkApi(response);
    }
    update();
  }

  Future<int?> spin(String? tripRequestId) async {
    isSpinning = true;
    update();
    Response? response = await spinWheelService.spin(tripRequestId);
    if (response!.statusCode == 200) {
      lastResult = response.body['data'];
      int winIndex = lastResult!['win_index'] ?? 0;
      isSpinning = false;
      update();
      return winIndex;
    } else {
      isSpinning = false;
      ApiChecker.checkApi(response);
      update();
      return null;
    }
  }

  void showResult() {
    if (lastResult != null) {
      showCustomSnackBar(
        lastResult!['message'] ?? 'you_won'.tr,
        isError: false,
      );
    }
  }

  Future<void> getHistory() async {
    isLoading = true;
    update();
    Response? response = await spinWheelService.getHistory();
    if (response!.statusCode == 200) {
      history = response.body['data'] ?? [];
      isLoading = false;
    } else {
      isLoading = false;
      ApiChecker.checkApi(response);
    }
    update();
  }
}
