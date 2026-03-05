import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:get/get.dart';
import 'package:jago_user_app/common_widgets/app_bar_widget.dart';
import 'package:jago_user_app/common_widgets/body_widget.dart';
import 'package:jago_user_app/features/car_sharing/controllers/car_sharing_controller.dart';
import 'package:jago_user_app/features/car_sharing/widgets/offer_banner_widget.dart';
import 'package:jago_user_app/features/location/controllers/location_controller.dart';
import 'package:jago_user_app/util/dimensions.dart';
import 'package:jago_user_app/util/styles.dart';

class SharedRideDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> ride;
  final String? sharingType;
  const SharedRideDetailsScreen({super.key, required this.ride, this.sharingType});

  @override
  State<SharedRideDetailsScreen> createState() => _SharedRideDetailsScreenState();
}

class _SharedRideDetailsScreenState extends State<SharedRideDetailsScreen> {
  int _seatsToBook = 1;

  @override
  void initState() {
    super.initState();
    String groupId = (widget.ride['shared_group_id'] ?? widget.ride['id'] ?? '').toString();
    if (groupId.isNotEmpty) {
      Get.find<CarSharingController>().getPassengers(groupId);
      Get.find<CarSharingController>().checkAvailableSeats(groupId);
    }
  }

  @override
  Widget build(BuildContext context) {
    String driverName = widget.ride['driver_name'] ?? widget.ride['driver']?['name'] ?? 'unknown'.tr;
    String pickupAddress = widget.ride['pickup_address'] ?? widget.ride['pickup']?['address'] ?? '';
    String dropAddress = widget.ride['drop_address'] ?? widget.ride['destination_address'] ?? widget.ride['drop']?['address'] ?? '';
    int availableSeats = widget.ride['available_seats'] ?? widget.ride['seats_available'] ?? 0;
    String estimatedFare = '${widget.ride['estimated_fare'] ?? widget.ride['fare'] ?? '0'}';
    String vehicleType = widget.ride['vehicle_category'] ?? widget.ride['vehicle_type'] ?? '';
    String tripRequestId = (widget.ride['trip_request_id'] ?? widget.ride['id'] ?? '').toString();
    String sharedGroupId = (widget.ride['shared_group_id'] ?? widget.ride['id'] ?? '').toString();

    String perSeatFare = (widget.ride['per_seat_fare'] ?? widget.ride['fare_per_seat'] ?? estimatedFare).toString();
    String baseFare = (widget.ride['base_fare'] ?? '').toString();
    String distanceFare = (widget.ride['distance_fare'] ?? '').toString();
    String discount = (widget.ride['discount'] ?? widget.ride['discount_amount'] ?? '').toString();
    String gstAmount = (widget.ride['gst_amount'] ?? widget.ride['gst'] ?? '').toString();
    String commissionInfo = (widget.ride['commission_info'] ?? widget.ride['platform_commission'] ?? '').toString();

    String? effectiveSharingType = widget.sharingType ?? widget.ride['sharing_type'];
    String sharingTypeLabel = effectiveSharingType == 'outstation' ? 'outstation_sharing'.tr : 'city_sharing'.tr;
    Color badgeColor = effectiveSharingType == 'outstation' ? const Color(0xFF059669) : const Color(0xFF2563EB);

    return Scaffold(
      body: GetBuilder<CarSharingController>(builder: (controller) {
        Map<String, dynamic>? activeOffer = effectiveSharingType != null
            ? controller.getActiveOfferForType(effectiveSharingType)
            : null;

        return BodyWidget(
          appBar: AppBarWidget(title: 'ride_details'.tr, showBackButton: true),
          body: controller.isLoading && controller.joinRideResponse == null
              ? Center(child: SpinKitCircle(color: Theme.of(context).primaryColor, size: 40.0))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    if (effectiveSharingType != null)
                      Container(
                        margin: const EdgeInsets.only(bottom: Dimensions.paddingSizeSmall),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: badgeColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                          border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(
                            effectiveSharingType == 'outstation' ? Icons.route : Icons.location_city,
                            size: 16, color: badgeColor,
                          ),
                          const SizedBox(width: 6),
                          Text(sharingTypeLabel, style: textSemiBold.copyWith(
                            fontSize: Dimensions.fontSizeSmall, color: badgeColor,
                          )),
                        ]),
                      ),

                    if (activeOffer != null) ...[
                      OfferBannerWidget(offer: activeOffer),
                      const SizedBox(height: Dimensions.paddingSizeSmall),
                    ],

                    Container(
                      padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                        boxShadow: [BoxShadow(
                          color: Theme.of(context).hintColor.withValues(alpha: 0.1),
                          blurRadius: 5, spreadRadius: 1,
                        )],
                      ),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          Container(
                            height: 50, width: 50,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                            ),
                            child: Icon(Icons.person, color: Theme.of(context).primaryColor, size: 30),
                          ),
                          const SizedBox(width: Dimensions.paddingSizeSmall),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(driverName, style: textSemiBold.copyWith(fontSize: Dimensions.fontSizeLarge)),
                            if (vehicleType.isNotEmpty)
                              Text(vehicleType, style: textRegular.copyWith(
                                fontSize: Dimensions.fontSizeSmall,
                                color: Theme.of(context).hintColor,
                              )),
                          ])),
                        ]),

                        const SizedBox(height: Dimensions.paddingSizeDefault),
                        Divider(color: Theme.of(context).hintColor.withValues(alpha: 0.2)),
                        const SizedBox(height: Dimensions.paddingSizeSmall),

                        _buildInfoRow(context, Icons.circle, 'pickup'.tr, pickupAddress, Colors.green.shade600),
                        const SizedBox(height: Dimensions.paddingSizeSmall),
                        _buildInfoRow(context, Icons.location_on, 'destination'.tr, dropAddress, Theme.of(context).colorScheme.error),

                        const SizedBox(height: Dimensions.paddingSizeDefault),
                        Divider(color: Theme.of(context).hintColor.withValues(alpha: 0.2)),
                        const SizedBox(height: Dimensions.paddingSizeSmall),

                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          _buildStatItem(context, Icons.event_seat, '$availableSeats', 'available_seats'.tr),
                          _buildStatItem(context, Icons.currency_rupee, perSeatFare, 'per_seat_fare'.tr),
                        ]),
                      ]),
                    ),

                    const SizedBox(height: Dimensions.paddingSizeDefault),
                    _buildFareBreakdownCard(
                      context: context,
                      baseFare: baseFare,
                      distanceFare: distanceFare,
                      perSeatFare: perSeatFare,
                      discount: discount,
                      gstAmount: gstAmount,
                      commissionInfo: commissionInfo,
                      totalFare: estimatedFare,
                    ),

                    if (controller.passengers.isNotEmpty) ...[
                      const SizedBox(height: Dimensions.paddingSizeLarge),
                      Text('passengers'.tr, style: textSemiBold.copyWith(fontSize: Dimensions.fontSizeLarge)),
                      const SizedBox(height: Dimensions.paddingSizeSmall),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: controller.passengers.length,
                        itemBuilder: (context, index) {
                          final passenger = controller.passengers[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: Dimensions.paddingSizeExtraSmall),
                            padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                              border: Border.all(color: Theme.of(context).hintColor.withValues(alpha: 0.1)),
                            ),
                            child: Row(children: [
                              Icon(Icons.person_outline, color: Theme.of(context).primaryColor),
                              const SizedBox(width: Dimensions.paddingSizeSmall),
                              Expanded(child: Text(
                                passenger is Map ? (passenger['name'] ?? passenger['customer_name'] ?? 'passenger'.tr) : 'passenger'.tr,
                                style: textRegular.copyWith(fontSize: Dimensions.fontSizeDefault),
                              )),
                              Text(
                                '${passenger is Map ? (passenger['seats_booked'] ?? '1') : '1'} ${'seats'.tr}',
                                style: textMedium.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).hintColor),
                              ),
                            ]),
                          );
                        },
                      ),
                    ],

                    if (controller.joinRideResponse != null) ...[
                      const SizedBox(height: Dimensions.paddingSizeLarge),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: Column(children: [
                          Icon(Icons.check_circle, color: Colors.green.shade600, size: 50),
                          const SizedBox(height: Dimensions.paddingSizeSmall),
                          Text('ride_joined_successfully'.tr, style: textSemiBold.copyWith(
                            fontSize: Dimensions.fontSizeLarge,
                            color: Colors.green.shade700,
                          )),
                          const SizedBox(height: Dimensions.paddingSizeDefault),
                          if (controller.joinRideResponse!['otp'] != null) ...[
                            Text('your_otp'.tr, style: textRegular.copyWith(
                              fontSize: Dimensions.fontSizeSmall,
                              color: Theme.of(context).hintColor,
                            )),
                            const SizedBox(height: Dimensions.paddingSizeExtraSmall),
                            Text('${controller.joinRideResponse!['otp']}', style: textBold.copyWith(
                              fontSize: Dimensions.fontSizeOverLarge,
                              color: Theme.of(context).primaryColor,
                              letterSpacing: 8,
                            )),
                          ],
                          const SizedBox(height: Dimensions.paddingSizeSmall),
                          if (controller.joinRideResponse!['seats_booked'] != null)
                            Text('${'seats_booked'.tr}: ${controller.joinRideResponse!['seats_booked']}', style: textMedium.copyWith(
                              fontSize: Dimensions.fontSizeDefault,
                            )),
                          if (controller.joinRideResponse!['available_seats_remaining'] != null)
                            Text('${'remaining_seats'.tr}: ${controller.joinRideResponse!['available_seats_remaining']}', style: textRegular.copyWith(
                              fontSize: Dimensions.fontSizeSmall,
                              color: Theme.of(context).hintColor,
                            )),
                        ]),
                      ),
                    ],

                    if (controller.joinRideResponse == null) ...[
                      const SizedBox(height: Dimensions.paddingSizeLarge),
                      Text('select_seats'.tr, style: textSemiBold.copyWith(fontSize: Dimensions.fontSizeLarge)),
                      const SizedBox(height: Dimensions.paddingSizeSmall),
                      Row(children: [
                        InkWell(
                          onTap: () {
                            if (_seatsToBook > 1) setState(() => _seatsToBook--);
                          },
                          child: Container(
                            height: 36, width: 36,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                            ),
                            child: Icon(Icons.remove, color: Theme.of(context).primaryColor),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeLarge),
                          child: Text('$_seatsToBook', style: textBold.copyWith(fontSize: Dimensions.fontSizeTwenty)),
                        ),
                        InkWell(
                          onTap: () {
                            if (_seatsToBook < availableSeats) setState(() => _seatsToBook++);
                          },
                          child: Container(
                            height: 36, width: 36,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                            ),
                            child: Icon(Icons.add, color: Theme.of(context).primaryColor),
                          ),
                        ),
                      ]),

                      const SizedBox(height: Dimensions.paddingSizeLarge),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: controller.isLoading ? null : () {
                            final locationController = Get.find<LocationController>();
                            final userAddress = locationController.getUserAddress();
                            controller.joinSharedRide(
                              tripRequestId: tripRequestId,
                              sharedGroupId: sharedGroupId,
                              seatsBooked: _seatsToBook,
                              pickupLat: userAddress?.latitude?.toString() ?? '0',
                              pickupLng: userAddress?.longitude?.toString() ?? '0',
                              pickupAddress: userAddress?.address ?? '',
                              dropLat: '0',
                              dropLng: '0',
                              dropAddress: dropAddress,
                              sharingType: effectiveSharingType,
                              offerId: activeOffer?['id']?.toString(),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).primaryColor,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Dimensions.radiusSmall)),
                          ),
                          child: controller.isLoading
                              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : Text('join_this_ride'.tr, style: textSemiBold.copyWith(color: Colors.white, fontSize: Dimensions.fontSizeLarge)),
                        ),
                      ),
                    ],
                  ]),
                ),
        );
      }),
    );
  }

  Widget _buildFareBreakdownCard({
    required BuildContext context,
    required String baseFare,
    required String distanceFare,
    required String perSeatFare,
    required String discount,
    required String gstAmount,
    required String commissionInfo,
    required String totalFare,
  }) {
    bool hasBreakdown = baseFare.isNotEmpty || distanceFare.isNotEmpty || discount.isNotEmpty || gstAmount.isNotEmpty;
    if (!hasBreakdown && perSeatFare == totalFare) return const SizedBox();

    return Container(
      padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('fare_breakdown'.tr, style: textSemiBold.copyWith(
          fontSize: Dimensions.fontSizeDefault,
          color: const Color(0xFF1E3A8A),
        )),
        const SizedBox(height: Dimensions.paddingSizeSmall),

        if (baseFare.isNotEmpty && baseFare != '0')
          _buildFareRow(context, 'base_fare'.tr, '₹$baseFare'),
        if (distanceFare.isNotEmpty && distanceFare != '0')
          _buildFareRow(context, 'distance_fare'.tr, '₹$distanceFare'),
        if (discount.isNotEmpty && discount != '0' && discount != '')
          _buildFareRow(context, 'discount'.tr, '-₹$discount', valueColor: const Color(0xFF059669)),
        if (gstAmount.isNotEmpty && gstAmount != '0')
          _buildFareRow(context, 'gst'.tr, '₹$gstAmount'),
        if (commissionInfo.isNotEmpty && commissionInfo != '0')
          _buildFareRow(context, 'platform_fee'.tr, '₹$commissionInfo'),

        Divider(color: const Color(0xFF93C5FD).withValues(alpha: 0.5)),
        const SizedBox(height: 4),

        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('per_seat_fare'.tr, style: textBold.copyWith(
            fontSize: Dimensions.fontSizeLarge,
            color: const Color(0xFF2563EB),
          )),
          Text('₹$perSeatFare', style: textBold.copyWith(
            fontSize: Dimensions.fontSizeExtraLarge,
            color: const Color(0xFF2563EB),
          )),
        ]),
      ]),
    );
  }

  Widget _buildFareRow(BuildContext context, String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: textRegular.copyWith(
          fontSize: Dimensions.fontSizeSmall,
          color: Theme.of(context).hintColor,
        )),
        Text(value, style: textMedium.copyWith(
          fontSize: Dimensions.fontSizeSmall,
          color: valueColor ?? Theme.of(context).textTheme.bodyMedium?.color,
        )),
      ]),
    );
  }

  Widget _buildInfoRow(BuildContext context, IconData icon, String label, String value, Color iconColor) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, size: 14, color: iconColor),
      const SizedBox(width: Dimensions.paddingSizeSmall),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: textMedium.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).hintColor)),
        Text(value, style: textRegular.copyWith(fontSize: Dimensions.fontSizeDefault), maxLines: 2, overflow: TextOverflow.ellipsis),
      ])),
    ]);
  }

  Widget _buildStatItem(BuildContext context, IconData icon, String value, String label) {
    return Column(children: [
      Icon(icon, color: Theme.of(context).primaryColor),
      const SizedBox(height: Dimensions.paddingSizeExtraSmall),
      Text(value, style: textSemiBold.copyWith(fontSize: Dimensions.fontSizeLarge)),
      Text(label, style: textRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).hintColor)),
    ]);
  }
}
