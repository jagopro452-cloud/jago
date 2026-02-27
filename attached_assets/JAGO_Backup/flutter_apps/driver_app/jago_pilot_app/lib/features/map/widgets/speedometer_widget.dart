import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jago_pilot_app/features/location/controllers/location_controller.dart';
import 'package:jago_pilot_app/util/dimensions.dart';
import 'package:jago_pilot_app/util/styles.dart';

class SpeedometerWidget extends StatelessWidget {
  const SpeedometerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<LocationController>(builder: (locationController) {
      int speedKmh = locationController.currentSpeedKmh.round();
      Color speedColor = _getSpeedColor(speedKmh);

      return Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Theme.of(context).cardColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 8,
              spreadRadius: 1,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(
            color: speedColor,
            width: 3,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$speedKmh',
              style: textBold.copyWith(
                fontSize: 24,
                color: speedColor,
                height: 1.1,
              ),
            ),
            Text(
              'km/h',
              style: textRegular.copyWith(
                fontSize: Dimensions.fontSizeExtraSmall,
                color: Theme.of(context).hintColor,
              ),
            ),
          ],
        ),
      );
    });
  }

  Color _getSpeedColor(int speed) {
    if (speed <= 40) return const Color(0xFF22C55E);
    if (speed <= 60) return const Color(0xFF2563EB);
    if (speed <= 80) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }
}
