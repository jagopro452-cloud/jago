import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jago_user_app/features/home/widgets/voice_search_dialog.dart';
import 'package:jago_user_app/util/dimensions.dart';
import 'package:jago_user_app/util/images.dart';
import 'package:jago_user_app/util/styles.dart';
import 'package:jago_user_app/features/set_destination/screens/set_destination_screen.dart';

class HomeSearchWidget extends StatelessWidget {
  const HomeSearchWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Get.isDarkMode;

    return Container(
      height: 54,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        border: Border.all(
          color: isDark
            ? const Color(0xFF334155)
            : Theme.of(context).primaryColor.withValues(alpha: 0.12),
          width: 1.2,
        ),
        boxShadow: isDark ? null : [
          BoxShadow(
            color: const Color(0xFF2563EB).withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
            spreadRadius: -2,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => Get.to(() => const SetDestinationScreen()),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Theme.of(context).primaryColor.withValues(alpha: 0.12),
                      Theme.of(context).primaryColor.withValues(alpha: 0.06),
                    ],
                  ),
                ),
                child: Center(
                  child: Image.asset(
                    Images.homeSearchIcon,
                    color: Theme.of(context).primaryColor,
                    height: 18, width: 18,
                  ),
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Text(
                  'where_to_go'.tr,
                  style: textMedium.copyWith(
                    color: Theme.of(context).hintColor.withValues(alpha: 0.7),
                    fontSize: Dimensions.fontSizeDefault,
                    letterSpacing: 0.2,
                  ),
                ),
              ),

              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: isDark
                    ? const Color(0xFF334155)
                    : const Color(0xFFF1F5F9),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () {
                    Get.dialog(const VoiceSearchDialog(), barrierDismissible: false);
                  },
                  child: Center(
                    child: Image.asset(
                      Images.microPhoneIcon,
                      color: Theme.of(context).hintColor,
                      height: 18, width: 18,
                    ),
                  ),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
