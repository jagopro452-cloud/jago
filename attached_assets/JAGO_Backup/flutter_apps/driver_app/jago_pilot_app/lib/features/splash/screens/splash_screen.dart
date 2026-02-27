import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:jago_pilot_app/features/trip/controllers/trip_controller.dart';
import 'package:jago_pilot_app/features/wallet/controllers/wallet_controller.dart';
import 'package:jago_pilot_app/helper/login_helper.dart';
import 'package:jago_pilot_app/localization/language_selection_screen.dart';
import 'package:jago_pilot_app/localization/localization_controller.dart';
import 'package:jago_pilot_app/util/images.dart';
import 'package:jago_pilot_app/features/auth/controllers/auth_controller.dart';
import 'package:jago_pilot_app/features/location/controllers/location_controller.dart';
import 'package:jago_pilot_app/features/profile/controllers/profile_controller.dart';
import 'package:jago_pilot_app/features/ride/controllers/ride_controller.dart';
import 'package:jago_pilot_app/features/splash/controllers/splash_controller.dart';

class SplashScreen extends StatefulWidget {
  final Map<String,dynamic>? notificationData;
  final String? userName;
  const SplashScreen({super.key, this.notificationData, this.userName});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  StreamSubscription<List<ConnectivityResult>>? _onConnectivityChanged;
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _bottomFadeAnimation;

  @override
  void initState() {
    super.initState();

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    if(!GetPlatform.isIOS){
      _checkConnectivity();
    }

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _scaleController,
        curve: Curves.elasticOut,
      ),
    );

    _bottomFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: const Interval(0.5, 1.0, curve: Curves.easeIn),
      ),
    );

    _fadeController.forward();
    _scaleController.forward();

    Get.find<SplashController>().initSharedData();
    Get.find<TripController>().rideCancellationReasonList();
    Get.find<TripController>().parcelCancellationReasonList();
    Get.find<AuthController>().remainingTime();
    Get.find<WalletController>().getPaymentGetWayList();
    _route();

  }


  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    _onConnectivityChanged?.cancel();
    _fadeController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  void _checkConnectivity(){
    bool isFirst = true;
    _onConnectivityChanged = Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> result) {
      bool isConnected = result.contains(ConnectivityResult.wifi) || result.contains(ConnectivityResult.mobile);
      if((isFirst && !isConnected) || !isFirst && context.mounted) {
        ScaffoldMessenger.of(Get.context!).removeCurrentSnackBar();
        ScaffoldMessenger.of(Get.context!).hideCurrentSnackBar();
        ScaffoldMessenger.of(Get.context!).showSnackBar(SnackBar(
          backgroundColor: isConnected ? Colors.green : Colors.red,
          duration: Duration(seconds: isConnected ? 3 : 6000),
          content: Text(
            isConnected ? 'connected'.tr : 'no_connection'.tr,
            textAlign: TextAlign.center,
          ),
        ));

        if(isConnected) {
          _route();
        }
      }
      isFirst = false;
    });
  }


  void _route() async {
    bool isSuccess = await Get.find<SplashController>().getConfigData();
    if (isSuccess) {
      if(Get.find<LocalizationController>().haveLocalLanguageCode()){
        LoginHelper().checkLoginRoutes(widget.notificationData, widget.userName);
      }else{
        Get.offAll(()=> LanguageSelectionScreen(userName: widget.userName, notificationData: widget.notificationData));
      }

    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GetBuilder<RideController>(builder: (rideController) {
        return GetBuilder<ProfileController>(builder: (profileController) {
          return GetBuilder<LocationController>(builder: (locationController) {
            return Container(
              width: double.infinity,
              height: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF1E3A8A),
                    Color(0xFF1D4ED8),
                    Color(0xFF0F172A),
                  ],
                  stops: [0.0, 0.4, 1.0],
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: -100,
                    left: -100,
                    child: Container(
                      width: 300,
                      height: 300,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.04),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -80,
                    right: -80,
                    child: Container(
                      width: 220,
                      height: 220,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.03),
                      ),
                    ),
                  ),
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Spacer(flex: 3),
                        AnimatedBuilder(
                          animation: Listenable.merge([_fadeAnimation, _scaleAnimation]),
                          builder: (context, child) {
                            return Opacity(
                              opacity: _fadeAnimation.value,
                              child: Transform.scale(
                                scale: _scaleAnimation.value,
                                child: child,
                              ),
                            );
                          },
                          child: Image.asset(
                            Images.splashLogo,
                            width: 260,
                            fit: BoxFit.contain,
                          ),
                        ),
                        const Spacer(flex: 3),
                        AnimatedBuilder(
                          animation: _bottomFadeAnimation,
                          builder: (context, child) {
                            return Opacity(
                              opacity: _bottomFadeAnimation.value,
                              child: child,
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 48),
                            child: Column(
                              children: [
                                Container(
                                  width: 24,
                                  height: 2,
                                  margin: const EdgeInsets.only(bottom: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.3),
                                    borderRadius: BorderRadius.circular(1),
                                  ),
                                ),
                                Text(
                                  'by Mindwhile IT Solutions',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w400,
                                    color: Colors.white.withValues(alpha: 0.45),
                                    letterSpacing: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          });
        });
      }),
    );
  }

}
