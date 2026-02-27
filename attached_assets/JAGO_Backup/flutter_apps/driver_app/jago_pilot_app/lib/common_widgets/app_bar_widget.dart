import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jago_pilot_app/features/dashboard/screens/dashboard_screen.dart';
import 'package:jago_pilot_app/util/dimensions.dart';
import 'package:jago_pilot_app/util/images.dart';
import 'package:jago_pilot_app/util/styles.dart';

class AppBarWidget extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showBackButton;
  final Function()? onBackPressed;
  final Function()? onTap;
  final bool regularAppbar;
  const AppBarWidget({super.key, required this.title, this.showBackButton = true, this.onBackPressed, this.onTap,  this.regularAppbar = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: regularAppbar ? 100 : GetPlatform.isAndroid ? 120 : 150,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
        ),
      ),
      child: AppBar(
        title: Text(title, style: textSemiBold.copyWith(
          fontSize: Dimensions.fontSizeExtraLarge,
          color: Colors.white,
        )),
        centerTitle: true,
        leading: showBackButton ? IconButton(
          icon: const Icon(Icons.arrow_back),
          color: Colors.white,
          onPressed: () => onBackPressed != null ? onBackPressed!() : Navigator.canPop(context) ? Navigator.pop(context) :  Get.offAll(() => const DashboardScreen()),
        ) :
        SizedBox(
          width: Dimensions.iconSizeMedium,
          child: InkWell(
            highlightColor: Colors.transparent,
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
              child: Image.asset(
                Images.menuIcon,
                color: Colors.white,
                width: Dimensions.iconSizeMedium,
              ),
            ),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
    );
  }

  @override
  Size get preferredSize =>  Size(Dimensions.webMaxWidth, GetPlatform.isAndroid? Dimensions.androidAppBarHeight : Dimensions.appBarHeight);
}
