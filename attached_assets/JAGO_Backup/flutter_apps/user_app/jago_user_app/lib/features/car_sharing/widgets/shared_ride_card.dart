import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jago_user_app/util/dimensions.dart';
import 'package:jago_user_app/util/images.dart';
import 'package:jago_user_app/util/styles.dart';

class SharedRideCard extends StatelessWidget {
  final Map<String, dynamic> ride;
  final VoidCallback onTap;
  final String? sharingType;
  final Map<String, dynamic>? activeOffer;
  const SharedRideCard({super.key, required this.ride, required this.onTap, this.sharingType, this.activeOffer});

  @override
  Widget build(BuildContext context) {
    String driverName = ride['driver_name'] ?? ride['driver']?['name'] ?? 'unknown'.tr;
    String pickupAddress = ride['pickup_address'] ?? ride['pickup']?['address'] ?? '';
    String dropAddress = ride['drop_address'] ?? ride['destination_address'] ?? ride['drop']?['address'] ?? '';
    int availableSeats = ride['available_seats'] ?? ride['seats_available'] ?? 0;
    String estimatedFare = '${ride['estimated_fare'] ?? ride['fare'] ?? '0'}';
    String vehicleType = ride['vehicle_category'] ?? ride['vehicle_type'] ?? '';
    String perSeatFare = (ride['per_seat_fare'] ?? ride['fare_per_seat'] ?? estimatedFare).toString();
    String? effectiveSharingType = sharingType ?? ride['sharing_type'];

    Color typeBadgeColor = effectiveSharingType == 'outstation' ? const Color(0xFF059669) : const Color(0xFF2563EB);
    String typeBadgeLabel = effectiveSharingType == 'outstation' ? 'outstation'.tr : 'city'.tr;

    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: Dimensions.paddingSizeSmall),
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
              height: 40, width: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
              ),
              child: Icon(Icons.person, color: Theme.of(context).primaryColor),
            ),
            const SizedBox(width: Dimensions.paddingSizeSmall),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(driverName, style: textSemiBold.copyWith(fontSize: Dimensions.fontSizeDefault)),
              if (vehicleType.isNotEmpty)
                Text(vehicleType, style: textRegular.copyWith(
                  fontSize: Dimensions.fontSizeSmall,
                  color: Theme.of(context).hintColor,
                )),
            ])),
            if (effectiveSharingType != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: typeBadgeColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                  border: Border.all(color: typeBadgeColor.withValues(alpha: 0.3)),
                ),
                child: Text(typeBadgeLabel, style: textMedium.copyWith(
                  fontSize: Dimensions.fontSizeExtraSmall,
                  color: typeBadgeColor,
                )),
              ),
              const SizedBox(width: Dimensions.paddingSizeExtraSmall),
            ],
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: Dimensions.paddingSizeSmall,
                vertical: Dimensions.paddingSizeExtraSmall,
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.event_seat, size: 14, color: Theme.of(context).primaryColor),
                const SizedBox(width: 4),
                Text('$availableSeats ${'seats'.tr}', style: textMedium.copyWith(
                  fontSize: Dimensions.fontSizeSmall,
                  color: Theme.of(context).primaryColor,
                )),
              ]),
            ),
          ]),

          if (activeOffer != null) ...[
            const SizedBox(height: Dimensions.paddingSizeSmall),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2563EB), Color(0xFF1E3A8A)],
                ),
                borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.local_offer, size: 12, color: Colors.white),
                const SizedBox(width: 4),
                Text(
                  _getOfferTag(activeOffer!),
                  style: textMedium.copyWith(
                    fontSize: Dimensions.fontSizeExtraSmall,
                    color: Colors.white,
                  ),
                ),
              ]),
            ),
          ],

          const SizedBox(height: Dimensions.paddingSizeSmall),
          Divider(color: Theme.of(context).hintColor.withValues(alpha: 0.2)),
          const SizedBox(height: Dimensions.paddingSizeSmall),

          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Column(children: [
              Icon(Icons.circle, size: 10, color: Colors.green.shade600),
              Container(height: 20, width: 1, color: Theme.of(context).hintColor.withValues(alpha: 0.3)),
              Icon(Icons.location_on, size: 14, color: Theme.of(context).colorScheme.error),
            ]),
            const SizedBox(width: Dimensions.paddingSizeSmall),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(pickupAddress, style: textRegular.copyWith(fontSize: Dimensions.fontSizeSmall), maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: Dimensions.paddingSizeSmall),
              Text(dropAddress, style: textRegular.copyWith(fontSize: Dimensions.fontSizeSmall), maxLines: 1, overflow: TextOverflow.ellipsis),
            ])),
          ]),

          const SizedBox(height: Dimensions.paddingSizeSmall),
          Divider(color: Theme.of(context).hintColor.withValues(alpha: 0.2)),
          const SizedBox(height: Dimensions.paddingSizeExtraSmall),

          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Icon(Icons.currency_rupee, size: 16, color: const Color(0xFF2563EB)),
                const SizedBox(width: 2),
                Text('₹$perSeatFare/${'seat'.tr}', style: textBold.copyWith(
                  fontSize: Dimensions.fontSizeDefault,
                  color: const Color(0xFF2563EB),
                )),
              ]),
              if (perSeatFare != estimatedFare)
                Text('${'total'.tr}: ₹$estimatedFare', style: textRegular.copyWith(
                  fontSize: Dimensions.fontSizeExtraSmall,
                  color: Theme.of(context).hintColor,
                )),
            ]),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: Dimensions.paddingSize,
                vertical: Dimensions.paddingSizeExtraSmall,
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
              ),
              child: Text('join'.tr, style: textMedium.copyWith(
                fontSize: Dimensions.fontSizeSmall,
                color: Colors.white,
              )),
            ),
          ]),
        ]),
      ),
    );
  }

  String _getOfferTag(Map<String, dynamic> offer) {
    String discountType = (offer['discount_type'] ?? offer['type'] ?? 'percentage').toString();
    String value = (offer['discount_value'] ?? offer['value'] ?? '0').toString();
    String name = offer['name'] ?? offer['title'] ?? '';
    if (name.isNotEmpty) return name;
    if (discountType == 'percentage' || discountType == 'percent') {
      return '$value% OFF';
    }
    return '₹$value OFF';
  }
}
