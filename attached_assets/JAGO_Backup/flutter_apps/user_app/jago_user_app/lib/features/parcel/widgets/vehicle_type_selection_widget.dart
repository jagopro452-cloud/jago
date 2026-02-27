import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:get/get.dart';
import 'package:jago_user_app/features/parcel/controllers/parcel_controller.dart';
import 'package:jago_user_app/features/parcel/domain/models/parcel_vehicle_type_model.dart';
import 'package:jago_user_app/features/ride/controllers/ride_controller.dart';
import 'package:jago_user_app/features/map/controllers/map_controller.dart';
import 'package:jago_user_app/features/splash/controllers/config_controller.dart';
import 'package:jago_user_app/util/dimensions.dart';
import 'package:jago_user_app/util/styles.dart';
import 'package:jago_user_app/common_widgets/button_widget.dart';

class VehicleTypeSelectionWidget extends StatelessWidget {
  const VehicleTypeSelectionWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ParcelController>(builder: (parcelController) {
      return GetBuilder<RideController>(builder: (rideController) {
        if (parcelController.isLoadingVehicleTypes) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
              child: SpinKitCircle(color: Theme.of(context).primaryColor, size: 40.0),
            ),
          );
        }

        if (parcelController.parcelVehicleTypes == null || parcelController.parcelVehicleTypes!.isEmpty) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: Dimensions.paddingSizeDefault),
              Icon(Icons.local_shipping_outlined, size: 48, color: Theme.of(context).hintColor),
              const SizedBox(height: Dimensions.paddingSizeSmall),
              Text(
                'no_vehicle_types_available'.tr,
                style: textMedium.copyWith(color: Theme.of(context).hintColor),
              ),
              const SizedBox(height: Dimensions.paddingSizeSmall),
              Text(
                'please_try_different_location'.tr,
                style: textRegular.copyWith(color: Theme.of(context).hintColor, fontSize: Dimensions.fontSizeSmall),
                textAlign: TextAlign.center,
              ),
            ],
          );
        }

        String currencySymbol = Get.find<ConfigController>().config?.currencySymbol ?? '₹';

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'select_vehicle_type'.tr,
              style: textSemiBold.copyWith(fontSize: Dimensions.fontSizeLarge),
            ),
            const SizedBox(height: 4),
            Text(
              'choose_the_right_vehicle_for_your_parcel'.tr,
              style: textRegular.copyWith(color: Theme.of(context).hintColor, fontSize: Dimensions.fontSizeSmall),
            ),
            const SizedBox(height: Dimensions.paddingSizeDefault),

            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              itemCount: parcelController.parcelVehicleTypes!.length,
              itemBuilder: (context, index) {
                ParcelVehicleType vehicleType = parcelController.parcelVehicleTypes![index];
                bool isSelected = parcelController.selectedVehicleTypeIndex == index;

                return _VehicleTypeCard(
                  vehicleType: vehicleType,
                  isSelected: isSelected,
                  currencySymbol: currencySymbol,
                  onTap: () => parcelController.selectVehicleType(index),
                );
              },
            ),

            const SizedBox(height: Dimensions.paddingSizeDefault),

            rideController.isSubmit
                ? Center(child: SpinKitCircle(color: Theme.of(context).primaryColor, size: 40.0))
                : ButtonWidget(
                    buttonText: 'continue_with_vehicle'.tr,
                    onPressed: parcelController.selectedVehicleTypeIndex >= 0
                        ? () {
                            rideController.submitRideRequest(
                              '',
                              true,
                              categoryId: parcelController.selectedVehicleCategoryId ?? '',
                            ).then((value) {
                              if (value.statusCode == 200) {
                                Get.find<ParcelController>().updateParcelState(ParcelDeliveryState.findingRider);
                                Get.find<MapController>().getPolyline();
                                Get.find<MapController>().notifyMapController();
                                parcelController.updatePaymentPerson(false);
                              }
                            });
                          }
                        : null,
                  ),
          ],
        );
      });
    });
  }
}

class _VehicleTypeCard extends StatelessWidget {
  final ParcelVehicleType vehicleType;
  final bool isSelected;
  final String currencySymbol;
  final VoidCallback onTap;

  const _VehicleTypeCard({
    required this.vehicleType,
    required this.isSelected,
    required this.currencySymbol,
    required this.onTap,
  });

  IconData get _vehicleIcon {
    switch (vehicleType.vehicleCategoryType) {
      case 'motor_bike':
        return Icons.two_wheeler;
      case 'auto':
        return Icons.electric_rickshaw;
      case 'car':
        return Icons.local_shipping;
      default:
        return Icons.inventory_2;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: Dimensions.paddingSizeSmall),
        padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).primaryColor.withValues(alpha: 0.08)
              : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).primaryColor
                : Theme.of(context).hintColor.withValues(alpha: 0.2),
            width: isSelected ? 2.0 : 1.0,
          ),
          boxShadow: isSelected
              ? [BoxShadow(
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.15),
                  blurRadius: 8,
                  spreadRadius: 1,
                  offset: const Offset(0, 2),
                )]
              : [BoxShadow(
                  color: Theme.of(context).shadowColor.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                )],
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: isSelected
                    ? Theme.of(context).primaryColor.withValues(alpha: 0.15)
                    : Theme.of(context).primaryColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
              ),
              child: Icon(
                _vehicleIcon,
                color: Theme.of(context).primaryColor,
                size: 28,
              ),
            ),
            const SizedBox(width: Dimensions.paddingSizeDefault),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    vehicleType.vehicleCategoryName ?? '',
                    style: textSemiBold.copyWith(
                      fontSize: Dimensions.fontSizeLarge,
                      color: isSelected ? Theme.of(context).primaryColor : null,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$currencySymbol${vehicleType.baseFarePerKm?.toStringAsFixed(1) ?? '0'}/km',
                    style: textRegular.copyWith(
                      color: Theme.of(context).hintColor,
                      fontSize: Dimensions.fontSizeSmall,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$currencySymbol${vehicleType.baseFare?.toStringAsFixed(0) ?? '0'}',
                  style: textBold.copyWith(
                    fontSize: Dimensions.fontSizeLarge,
                    color: isSelected ? Theme.of(context).primaryColor : Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
                Text(
                  'base_fare'.tr,
                  style: textRegular.copyWith(
                    color: Theme.of(context).hintColor,
                    fontSize: Dimensions.fontSizeExtraSmall,
                  ),
                ),
              ],
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Icon(Icons.check_circle, color: Theme.of(context).primaryColor, size: 24),
            ],
          ],
        ),
      ),
    );
  }
}
