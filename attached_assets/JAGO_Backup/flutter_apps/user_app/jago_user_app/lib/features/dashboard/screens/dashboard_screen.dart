import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jago_user_app/features/dashboard/domain/models/navigation_model.dart';
import 'package:jago_user_app/features/home/screens/home_screen.dart';
import 'package:jago_user_app/features/notification/screens/notification_screen.dart';
import 'package:jago_user_app/features/profile/screens/profile_screen.dart';
import 'package:jago_user_app/features/trip/screens/trip_screen.dart';
import 'package:jago_user_app/util/dimensions.dart';
import 'package:jago_user_app/util/images.dart';
import 'package:jago_user_app/util/styles.dart';
import 'package:jago_user_app/features/dashboard/controllers/bottom_menu_controller.dart';


class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {

  final PageStorageBucket bucket = PageStorageBucket();
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final List<NavigationModel> item = [
      NavigationModel(
        name: 'home'.tr,
        activeIcon: Images.homeActive,
        inactiveIcon: Images.homeOutline,
        screen: const HomeScreen(),
      ),
      NavigationModel(
        name: 'activity'.tr,
        activeIcon: Images.activityActive,
        inactiveIcon: Images.activityOutline,
        screen: const TripScreen(fromProfile: false),
      ),
      NavigationModel(
        name: 'notification'.tr,
        activeIcon: Images.notificationActive,
        inactiveIcon: Images.notificationOutline,
        screen: const NotificationScreen(),
      ),
      NavigationModel(
        name: 'profile'.tr,
        activeIcon: Images.profileActive,
        inactiveIcon: Images.profileOutline,
        screen: const ProfileScreen(),
      ),
    ];


    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, val) async {
        if (Get.find<BottomMenuController>().currentTab != 0) {
          Get.find<BottomMenuController>().setTabIndex(0);
          return;
        } else {
          Get.find<BottomMenuController>().exitApp();
        }
        return;
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
                child: _PremiumBottomNav(
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

class _PremiumBottomNav extends StatelessWidget {
  final BottomMenuController menuController;
  final List<NavigationModel> items;

  const _PremiumBottomNav({
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
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(items.length, (index) {
                return Expanded(child: _PremiumNavItem(
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

class _PremiumNavItem extends StatelessWidget {
  final bool isSelected;
  final String name;
  final String activeIcon;
  final String inActiveIcon;
  final VoidCallback onTap;

  const _PremiumNavItem({
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
              child: Image.asset(
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
