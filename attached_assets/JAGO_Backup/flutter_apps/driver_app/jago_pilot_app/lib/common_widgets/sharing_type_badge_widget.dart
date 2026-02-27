import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jago_pilot_app/util/dimensions.dart';
import 'package:jago_pilot_app/util/styles.dart';

class SharingTypeBadgeWidget extends StatelessWidget {
  final String? sharingType;
  
  const SharingTypeBadgeWidget({
    super.key,
    this.sharingType,
  });

  @override
  Widget build(BuildContext context) {
    if (sharingType == null || sharingType!.isEmpty) {
      return const SizedBox.shrink();
    }

    bool isCitySharing = sharingType?.toLowerCase() == 'city';
    Color backgroundColor = isCitySharing ? const Color(0xFF2563EB) : const Color(0xFF059669);
    String displayText = isCitySharing ? 'city_sharing'.tr : 'outstation_sharing'.tr;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Dimensions.paddingSizeSmall,
        vertical: Dimensions.paddingSizeExtraSmall,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(Dimensions.paddingSizeExtraSmall),
      ),
      child: Text(
        displayText,
        style: textRegular.copyWith(
          color: Colors.white,
          fontSize: Dimensions.fontSizeSmall,
        ),
      ),
    );
  }
}
