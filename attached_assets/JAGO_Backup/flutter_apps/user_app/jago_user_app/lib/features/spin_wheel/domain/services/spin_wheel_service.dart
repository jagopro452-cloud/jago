import 'package:jago_user_app/features/spin_wheel/domain/repositories/spin_wheel_repository_interface.dart';
import 'package:jago_user_app/features/spin_wheel/domain/services/spin_wheel_service_interface.dart';

class SpinWheelService implements SpinWheelServiceInterface {
  SpinWheelRepositoryInterface spinWheelRepositoryInterface;

  SpinWheelService({required this.spinWheelRepositoryInterface});

  @override
  Future getConfig() async {
    return await spinWheelRepositoryInterface.getConfig();
  }

  @override
  Future spin(String? tripRequestId) async {
    return await spinWheelRepositoryInterface.spin(tripRequestId);
  }

  @override
  Future getHistory() async {
    return await spinWheelRepositoryInterface.getHistory();
  }
}
