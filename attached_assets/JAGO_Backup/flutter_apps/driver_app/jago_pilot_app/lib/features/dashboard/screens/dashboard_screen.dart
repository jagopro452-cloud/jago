import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jago_pilot_app/common_widgets/custom_asset_image_widget.dart';
import 'package:jago_pilot_app/features/wallet/controllers/wallet_controller.dart';
import 'package:jago_pilot_app/util/dimensions.dart';
import 'package:jago_pilot_app/util/images.dart';
import 'package:jago_pilot_app/util/styles.dart';
import 'package:jago_pilot_app/features/dashboard/controllers/bottom_menu_controller.dart';
import 'package:jago_pilot_app/features/dashboard/domain/models/navigation_model.dart';
import 'package:jago_pilot_app/features/home/screens/home_screen.dart';
import 'package:jago_pilot_app/features/notification/screens/notification_screen.dart';
import 'package:jago_pilot_app/features/profile/controllers/profile_controller.dart';
import 'package:jago_pilot_app/features/ride/controllers/ride_controller.dart';
import 'package:jago_pilot_app/features/trip/screens/trip_screen.dart';
import 'package:jago_pilot_app/features/wallet/screens/wallet_screen.dart';



class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final PageStorageBucket bucket = PageStorageBucket();

  @override
  Widget build(BuildContext context) {
    Get.find<RideController>().updateRoute(true);
    final List<NavigationModel> item = [
      NavigationModel(name: 'home'.tr, activeIcon: Images.homeActive, inactiveIcon: Images.homeOutline, screen: const HomeMenu()),
      NavigationModel(name: 'activity'.tr, activeIcon: Images.activityActive, inactiveIcon: Images.activityOutline, screen: const TripHistoryMenu()),
      NavigationModel(name: 'notification'.tr, activeIcon: Images.notificationActive, inactiveIcon: Images.notificationOutline, screen: const NotificationMenu()),
      NavigationModel(name: 'wallet'.tr, activeIcon: Images.moneyActive, inactiveIcon: Images.moneyOutline, screen: const WalletScreenMenu()),
    ];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (res, val) async {
        if (Get.find<BottomMenuController>().currentTab != 0) {
          if(Get.find<ProfileController>().toggle){
            Get.find<ProfileController>().toggleDrawer();
            Get.find<BottomMenuController>().setTabIndex(0);
          }else{
            if(Get.find<BottomMenuController>().currentTab == 3){
              if(Get.find<WalletController>().walletTypeIndex == 0){
                Get.find<BottomMenuController>().setTabIndex(0);
              }else{
                Get.find<WalletController>().moveToPreviousProfileType();
              }
            }else{
              Get.find<BottomMenuController>().setTabIndex(0);
            }
          }
          return;
        } else {
          if(Get.find<ProfileController>().toggle){
            Get.find<ProfileController>().toggleDrawer();
          }else{
            Get.find<BottomMenuController>().exitApp();
          }
          return;
        }
      },
      child: GetBuilder<BottomMenuController>(builder: (menuController) {
        return SafeArea(
          top: false,
          child: Scaffold(
            resizeToAvoidBottomInset: false,
            body: Stack(children: [
              PageStorage(bucket: bucket, child: item[menuController.currentTab].screen),
              Positioned(
                left: 0, right: 0, bottom: 0,
                child: _PremiumPilotBottomNav(
                  menuController: menuController,
                  items: item,
                ),
              ),
            ]),
          ),
        );
      }),
    );
  }
}

class _PremiumPilotBottomNav extends StatelessWidget {
  final BottomMenuController menuController;
  final List<NavigationModel> items;

  const _PremiumPilotBottomNav({
    required this.menuController,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Get.isDarkMode;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            height: 68,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                  ? [
                      const Color(0xFF1E293B).withValues(alpha: 0.95),
                      const Color(0xFF0F172A).withValues(alpha: 0.95),
                    ]
                  : [
                      const Color(0xFF1E3A8A).withValues(alpha: 0.95),
                      const Color(0xFF2563EB).withValues(alpha: 0.92),
                    ],
              ),
              border: Border.all(
                color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.white.withValues(alpha: 0.2),
                width: 0.8,
              ),
              boxShadow: [
                BoxShadow(
                  offset: const Offset(0, -2),
                  blurRadius: 20,
                  color: isDark
                    ? Colors.black.withValues(alpha: 0.4)
                    : const Color(0xFF1E3A8A).withValues(alpha: 0.3),
                  spreadRadius: -4,
                ),
                BoxShadow(
                  offset: const Offset(0, 6),
                  blurRadius: 16,
                  color: Colors.black.withValues(alpha: 0.15),
                  spreadRadius: -2,
                ),
              ],
            ),
            child: Row(
              children: List.generate(items.length, (index) {
                return Expanded(child: _PremiumPilotNavItem(
                  isSelected: menuController.currentTab == index,
                  name: items[index].name,
                  activeIcon: items[index].activeIcon,
                  inActiveIcon: items[index].inactiveIcon,
                  onTap: () => menuController.setTabIndex(index),
                ));
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _PremiumPilotNavItem extends StatelessWidget {
  final bool isSelected;
  final String name;
  final String activeIcon;
  final String inActiveIcon;
  final VoidCallback onTap;

  const _PremiumPilotNavItem({
    required this.isSelected,
    required this.name,
    required this.activeIcon,
    required this.inActiveIcon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      highlightColor: Colors.transparent,
      hoverColor: Colors.transparent,
      splashColor: Colors.transparent,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              padding: EdgeInsets.symmetric(
                horizontal: isSelected ? 14 : 8,
                vertical: isSelected ? 6 : 4,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: isSelected
                  ? Colors.white.withValues(alpha: 0.18)
                  : Colors.transparent,
              ),
              child: CustomAssetImageWidget(
                isSelected ? activeIcon : inActiveIcon,
                width: 22, height: 22,
                color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.5),
              ),
            ),

            if(isSelected)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  name.tr,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textMedium.copyWith(
                    color: Colors.white,
                    fontSize: 10,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
