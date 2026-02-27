import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:get/get.dart';
import 'package:jago_user_app/common_widgets/app_bar_widget.dart';
import 'package:jago_user_app/common_widgets/body_widget.dart';
import 'package:jago_user_app/features/car_sharing/controllers/car_sharing_controller.dart';
import 'package:jago_user_app/features/car_sharing/screens/find_shared_rides_screen.dart';
import 'package:jago_user_app/features/car_sharing/widgets/offer_banner_widget.dart';
import 'package:jago_user_app/util/dimensions.dart';
import 'package:jago_user_app/util/styles.dart';

class SharingTypeSelectionScreen extends StatefulWidget {
  final String? pickupLat;
  final String? pickupLng;
  final String? dropLat;
  final String? dropLng;
  final String? vehicleCategoryId;
  const SharingTypeSelectionScreen({super.key, this.pickupLat, this.pickupLng, this.dropLat, this.dropLng, this.vehicleCategoryId});

  @override
  State<SharingTypeSelectionScreen> createState() => _SharingTypeSelectionScreenState();
}

class _SharingTypeSelectionScreenState extends State<SharingTypeSelectionScreen> {
  @override
  void initState() {
    super.initState();
    final controller = Get.find<CarSharingController>();
    controller.loadSharingConfig();
    controller.loadActiveOffers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GetBuilder<CarSharingController>(builder: (controller) {
        return BodyWidget(
          appBar: AppBarWidget(title: 'share_ride'.tr, showBackButton: true),
          body: controller.isConfigLoading
              ? Center(child: SpinKitCircle(color: const Color(0xFF2563EB), size: 40.0))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('choose_sharing_type'.tr, style: textSemiBold.copyWith(
                      fontSize: Dimensions.fontSizeExtraLarge,
                      color: const Color(0xFF1E3A8A),
                    )),
                    const SizedBox(height: Dimensions.paddingSizeExtraSmall),
                    Text('select_how_you_want_to_share'.tr, style: textRegular.copyWith(
                      fontSize: Dimensions.fontSizeSmall,
                      color: Theme.of(context).hintColor,
                    )),
                    const SizedBox(height: Dimensions.paddingSizeLarge),

                    _buildSharingTypeCard(
                      context: context,
                      controller: controller,
                      type: 'city',
                      title: 'city_sharing'.tr,
                      tagline: 'share_rides_within_city'.tr,
                      description: 'city_sharing_description'.tr,
                      icon: Icons.location_city,
                      gradientColors: const [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                      isEnabled: controller.isSharingTypeEnabled('city'),
                    ),

                    const SizedBox(height: Dimensions.paddingSizeDefault),

                    _buildSharingTypeCard(
                      context: context,
                      controller: controller,
                      type: 'outstation',
                      title: 'outstation_sharing'.tr,
                      tagline: 'share_long_distance_rides'.tr,
                      description: 'outstation_sharing_description'.tr,
                      icon: Icons.route,
                      gradientColors: const [Color(0xFF1E3A8A), Color(0xFF2563EB)],
                      isEnabled: controller.isSharingTypeEnabled('outstation'),
                    ),
                  ]),
                ),
        );
      }),
    );
  }

  Widget _buildSharingTypeCard({
    required BuildContext context,
    required CarSharingController controller,
    required String type,
    required String title,
    required String tagline,
    required String description,
    required IconData icon,
    required List<Color> gradientColors,
    required bool isEnabled,
  }) {
    Map<String, dynamic>? activeOffer = controller.getActiveOfferForType(type);

    return Opacity(
      opacity: isEnabled ? 1.0 : 0.5,
      child: InkWell(
        onTap: isEnabled ? () {
          controller.selectSharingType(type);
          Get.to(() => FindSharedRidesScreen(
            pickupLat: widget.pickupLat,
            pickupLng: widget.pickupLng,
            dropLat: widget.dropLat,
            dropLng: widget.dropLng,
            vehicleCategoryId: widget.vehicleCategoryId,
            sharingType: type,
          ));
        } : null,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isEnabled ? gradientColors : [Colors.grey.shade400, Colors.grey.shade500],
            ),
            boxShadow: [BoxShadow(
              color: (isEnabled ? gradientColors.first : Colors.grey).withValues(alpha: 0.3),
              blurRadius: 12, spreadRadius: 2, offset: const Offset(0, 4),
            )],
          ),
          child: Stack(children: [
            Positioned(
              right: -20, top: -20,
              child: Icon(icon, size: 120, color: Colors.white.withValues(alpha: 0.08)),
            ),
            Positioned(
              left: -30, bottom: -30,
              child: Container(
                height: 100, width: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.05),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                color: Colors.white.withValues(alpha: 0.05),
                border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Container(
                    height: 56, width: 56,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(icon, color: Colors.white, size: 30),
                  ),
                  const SizedBox(width: Dimensions.paddingSizeDefault),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(title, style: textBold.copyWith(
                      color: Colors.white,
                      fontSize: Dimensions.fontSizeExtraLarge,
                    )),
                    const SizedBox(height: 2),
                    Text(tagline, style: textRegular.copyWith(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: Dimensions.fontSizeSmall,
                    )),
                  ])),
                  if (!isEnabled)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                      ),
                      child: Text('coming_soon'.tr, style: textMedium.copyWith(
                        color: Colors.white,
                        fontSize: Dimensions.fontSizeExtraSmall,
                      )),
                    ),
                  if (isEnabled)
                    Container(
                      height: 36, width: 36,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
                    ),
                ]),

                const SizedBox(height: Dimensions.paddingSizeDefault),
                Text(description, style: textRegular.copyWith(
                  color: Colors.white.withValues(alpha: 0.75),
                  fontSize: Dimensions.fontSizeSmall,
                ), maxLines: 2, overflow: TextOverflow.ellipsis),

                if (activeOffer != null) ...[
                  const SizedBox(height: Dimensions.paddingSizeDefault),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Dimensions.paddingSizeSmall,
                      vertical: Dimensions.paddingSizeExtraSmall,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.local_offer, color: Colors.white, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        activeOffer['name'] ?? activeOffer['title'] ?? 'special_offer'.tr,
                        style: textMedium.copyWith(
                          color: Colors.white,
                          fontSize: Dimensions.fontSizeExtraSmall,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _getOfferValueShort(activeOffer),
                          style: textBold.copyWith(
                            color: const Color(0xFF2563EB),
                            fontSize: Dimensions.fontSizeExtraSmall,
                          ),
                        ),
                      ),
                    ]),
                  ),
                ],
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  String _getOfferValueShort(Map<String, dynamic> offer) {
    String discountType = (offer['discount_type'] ?? offer['type'] ?? 'percentage').toString();
    String value = (offer['discount_value'] ?? offer['value'] ?? '0').toString();
    if (discountType == 'percentage' || discountType == 'percent') {
      return '$value% OFF';
    }
    return '₹$value OFF';
  }
}
