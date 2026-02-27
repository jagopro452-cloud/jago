import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:get/get.dart';
import 'package:jago_user_app/common_widgets/app_bar_widget.dart';
import 'package:jago_user_app/common_widgets/body_widget.dart';
import 'package:jago_user_app/features/car_sharing/controllers/car_sharing_controller.dart';
import 'package:jago_user_app/features/car_sharing/screens/shared_ride_details_screen.dart';
import 'package:jago_user_app/features/car_sharing/widgets/offer_banner_widget.dart';
import 'package:jago_user_app/features/car_sharing/widgets/shared_ride_card.dart';
import 'package:jago_user_app/features/location/controllers/location_controller.dart';
import 'package:jago_user_app/util/dimensions.dart';
import 'package:jago_user_app/util/images.dart';
import 'package:jago_user_app/util/styles.dart';

class FindSharedRidesScreen extends StatefulWidget {
  final String? pickupLat;
  final String? pickupLng;
  final String? dropLat;
  final String? dropLng;
  final String? vehicleCategoryId;
  final String? sharingType;
  const FindSharedRidesScreen({super.key, this.pickupLat, this.pickupLng, this.dropLat, this.dropLng, this.vehicleCategoryId, this.sharingType});

  @override
  State<FindSharedRidesScreen> createState() => _FindSharedRidesScreenState();
}

class _FindSharedRidesScreenState extends State<FindSharedRidesScreen> {
  bool _hasDestination = false;
  String? _effectiveSharingType;

  @override
  void initState() {
    super.initState();
    _hasDestination = widget.dropLat != null && widget.dropLng != null;
    _effectiveSharingType = widget.sharingType;

    if (_effectiveSharingType == null && _hasDestination) {
      final controller = Get.find<CarSharingController>();
      double pickupLat = double.tryParse(widget.pickupLat ?? '0') ?? 0;
      double pickupLng = double.tryParse(widget.pickupLng ?? '0') ?? 0;
      double dropLat = double.tryParse(widget.dropLat ?? '0') ?? 0;
      double dropLng = double.tryParse(widget.dropLng ?? '0') ?? 0;
      _effectiveSharingType = controller.detectSharingType(pickupLat, pickupLng, dropLat, dropLng);
    }

    if (_hasDestination) {
      _loadSharedRides();
    }

    final controller = Get.find<CarSharingController>();
    controller.loadActiveOffers(sharingType: _effectiveSharingType);
  }

  void _loadSharedRides() {
    final locationController = Get.find<LocationController>();
    final userAddress = locationController.getUserAddress();
    Get.find<CarSharingController>().findSharedRides(
      pickupLat: widget.pickupLat ?? userAddress?.latitude?.toString() ?? '0',
      pickupLng: widget.pickupLng ?? userAddress?.longitude?.toString() ?? '0',
      dropLat: widget.dropLat ?? '0',
      dropLng: widget.dropLng ?? '0',
      vehicleCategoryId: widget.vehicleCategoryId ?? '',
      zoneId: userAddress?.zoneId?.toString() ?? '',
      seatsNeeded: 1,
      sharingType: _effectiveSharingType,
    );
  }

  @override
  Widget build(BuildContext context) {
    String sharingTypeLabel = _effectiveSharingType == 'outstation' ? 'outstation_sharing'.tr : 'city_sharing'.tr;
    Color badgeColor = _effectiveSharingType == 'outstation' ? const Color(0xFF059669) : const Color(0xFF2563EB);

    return Scaffold(
      body: GetBuilder<CarSharingController>(builder: (carSharingController) {
        Map<String, dynamic>? activeOffer = _effectiveSharingType != null
            ? carSharingController.getActiveOfferForType(_effectiveSharingType!)
            : null;

        return BodyWidget(
          appBar: AppBarWidget(title: 'car_sharing'.tr, showBackButton: true),
          body: Column(children: [
            Padding(
              padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Text('find_shared_rides'.tr, style: textSemiBold.copyWith(
                    fontSize: Dimensions.fontSizeExtraLarge,
                  )),
                  const SizedBox(width: Dimensions.paddingSizeSmall),
                  if (_effectiveSharingType != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: badgeColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                        border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
                      ),
                      child: Text(sharingTypeLabel, style: textMedium.copyWith(
                        fontSize: Dimensions.fontSizeExtraSmall,
                        color: badgeColor,
                      )),
                    ),
                ]),
                const SizedBox(height: Dimensions.paddingSizeExtraSmall),
                Text('join_shared_ride_save_money'.tr, style: textRegular.copyWith(
                  fontSize: Dimensions.fontSizeSmall,
                  color: Theme.of(context).hintColor,
                )),

                if (activeOffer != null) ...[
                  const SizedBox(height: Dimensions.paddingSizeSmall),
                  OfferBannerWidget(offer: activeOffer),
                ],

                if (carSharingController.fareEstimate != null) ...[
                  const SizedBox(height: Dimensions.paddingSizeSmall),
                  _buildFareBreakdown(context, carSharingController.fareEstimate!),
                ],
              ]),
            ),

            Expanded(
              child: !_hasDestination
                  ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Image.asset(Images.noDataFound, height: 100, width: 100),
                      const SizedBox(height: Dimensions.paddingSizeDefault),
                      Text('no_shared_rides_found'.tr, style: textRegular.copyWith(
                        fontSize: Dimensions.fontSizeDefault,
                        color: Theme.of(context).hintColor,
                      )),
                    ]))
                  : carSharingController.isLoading
                  ? Center(child: SpinKitCircle(color: Theme.of(context).primaryColor, size: 40.0))
                  : carSharingController.sharedRides.isEmpty
                  ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Image.asset(Images.noDataFound, height: 100, width: 100),
                      const SizedBox(height: Dimensions.paddingSizeDefault),
                      Text('no_shared_rides_available'.tr, style: textRegular.copyWith(
                        fontSize: Dimensions.fontSizeDefault,
                        color: Theme.of(context).hintColor,
                      )),
                      const SizedBox(height: Dimensions.paddingSizeSmall),
                      InkWell(
                        onTap: _loadSharedRides,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: Dimensions.paddingSizeLarge,
                            vertical: Dimensions.paddingSizeSmall,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor,
                            borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                          ),
                          child: Text('refresh'.tr, style: textMedium.copyWith(
                            color: Colors.white,
                            fontSize: Dimensions.fontSizeDefault,
                          )),
                        ),
                      ),
                    ]))
                  : RefreshIndicator(
                      onRefresh: () async => _loadSharedRides(),
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
                        itemCount: carSharingController.sharedRides.length,
                        itemBuilder: (context, index) {
                          final ride = carSharingController.sharedRides[index];
                          return SharedRideCard(
                            ride: ride is Map<String, dynamic> ? ride : {},
                            sharingType: _effectiveSharingType,
                            activeOffer: activeOffer,
                            onTap: () => Get.to(() => SharedRideDetailsScreen(
                              ride: ride is Map<String, dynamic> ? ride : {},
                              sharingType: _effectiveSharingType,
                            )),
                          );
                        },
                      ),
                    ),
            ),
          ]),
        );
      }),
    );
  }

  Widget _buildFareBreakdown(BuildContext context, Map<String, dynamic> fare) {
    String perSeatFare = (fare['per_seat_fare'] ?? fare['fare_per_seat'] ?? '').toString();
    String gstAmount = (fare['gst_amount'] ?? fare['gst'] ?? '').toString();
    String totalFare = (fare['total_fare'] ?? fare['total'] ?? '').toString();

    if (perSeatFare.isEmpty && totalFare.isEmpty) return const SizedBox();

    return Container(
      padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('fare_estimate'.tr, style: textSemiBold.copyWith(
          fontSize: Dimensions.fontSizeSmall,
          color: const Color(0xFF1E3A8A),
        )),
        const SizedBox(height: 4),
        if (perSeatFare.isNotEmpty)
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('per_seat_fare'.tr, style: textRegular.copyWith(fontSize: Dimensions.fontSizeSmall)),
            Text('₹$perSeatFare', style: textSemiBold.copyWith(
              fontSize: Dimensions.fontSizeDefault,
              color: const Color(0xFF2563EB),
            )),
          ]),
        if (gstAmount.isNotEmpty && gstAmount != '0') ...[
          const SizedBox(height: 2),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('gst'.tr, style: textRegular.copyWith(
              fontSize: Dimensions.fontSizeExtraSmall,
              color: Theme.of(context).hintColor,
            )),
            Text('₹$gstAmount', style: textRegular.copyWith(
              fontSize: Dimensions.fontSizeExtraSmall,
              color: Theme.of(context).hintColor,
            )),
          ]),
        ],
        if (totalFare.isNotEmpty) ...[
          const SizedBox(height: 2),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('total'.tr, style: textMedium.copyWith(fontSize: Dimensions.fontSizeSmall)),
            Text('₹$totalFare', style: textBold.copyWith(
              fontSize: Dimensions.fontSizeDefault,
              color: const Color(0xFF1E3A8A),
            )),
          ]),
        ],
      ]),
    );
  }
}
