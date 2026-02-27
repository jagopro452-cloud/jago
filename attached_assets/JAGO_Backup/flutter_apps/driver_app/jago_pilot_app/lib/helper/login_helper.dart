import 'dart:io';
import 'package:get/get.dart';
import 'package:jago_pilot_app/features/auth/controllers/auth_controller.dart';
import 'package:jago_pilot_app/features/auth/screens/sign_in_screen.dart';
import 'package:jago_pilot_app/features/dashboard/screens/dashboard_screen.dart';
import 'package:jago_pilot_app/features/location/controllers/location_controller.dart';
import 'package:jago_pilot_app/features/location/screens/access_location_screen.dart';
import 'package:jago_pilot_app/features/maintainance_mode/screens/maintainance_screen.dart';
import 'package:jago_pilot_app/features/out_of_zone/controllers/out_of_zone_controller.dart';
import 'package:jago_pilot_app/features/profile/controllers/profile_controller.dart';
import 'package:jago_pilot_app/features/splash/controllers/splash_controller.dart';
import 'package:jago_pilot_app/features/splash/domain/models/config_model.dart';
import 'package:jago_pilot_app/features/splash/screens/app_version_warning_screen.dart';
import 'package:jago_pilot_app/helper/firebase_helper.dart';
import 'package:jago_pilot_app/helper/notification_helper.dart';
import 'package:jago_pilot_app/util/app_constants.dart';
import 'pusher_helper.dart';

class LoginHelper{

  LoginHelper();

  void checkLoginRoutes(Map<String,dynamic>? notificationData, String? userName){
    if(_isForceUpdate(Get.find<SplashController>().config)) {
      Get.offAll(()=> const AppVersionWarningScreen());

    }else {
      FirebaseHelper().subscribeFirebaseTopic();
      if(Get.find<AuthController>().getUserToken().isNotEmpty){
        PusherHelper.initializePusher();
      }

      Future.delayed(const Duration(milliseconds: 1000), () {
        if(Get.find<AuthController>().isLoggedIn()){
          if(Get.find<AuthController>().getZoneId() == ''){
            Get.offAll(()=> const AccessLocationScreen());

          }else{
            Get.find<OutOfZoneController>().getZoneList();
            Get.find<ProfileController>().getProfileInfo().then((value){
              if(value.statusCode ==200){
                Get.find<LocationController>().getCurrentLocation().then((value){
                  if(notificationData != null){
                    NotificationHelper.notificationToRoute(notificationData, formSplash: true, userName: userName);
                  }else{
                    Get.offAll(()=> const DashboardScreen());
                  }

                });
                PusherHelper().driverTripRequestSubscribe(value.body['data']['id']);
              }
            });

          }

        }else{
          if(Get.find<SplashController>().config!.maintenanceMode != null &&
              Get.find<SplashController>().config!.maintenanceMode!.maintenanceStatus == 1 &&
              Get.find<SplashController>().config!.maintenanceMode!.selectedMaintenanceSystem!.driverApp == 1
          ){
            Get.offAll(() => const MaintenanceScreen());
          }else{
            Get.offAll(()=> const SignInScreen());
          }
        }
      });
    }
  }

  bool _isForceUpdate(ConfigModel? config) {
    double minimumVersion = Platform.isAndroid
        ? config?.androidAppMinimumVersion ?? 0
        : Platform.isIOS
        ? config?.iosAppMinimumVersion ?? 0
        : 0;

    return minimumVersion > 0 && minimumVersion > AppConstants.appVersion;
  }
}
