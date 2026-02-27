import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jago_user_app/util/dimensions.dart';
import 'package:jago_user_app/util/styles.dart';

class OfferBannerWidget extends StatefulWidget {
  final Map<String, dynamic> offer;
  final VoidCallback? onApply;
  const OfferBannerWidget({super.key, required this.offer, this.onApply});

  @override
  State<OfferBannerWidget> createState() => _OfferBannerWidgetState();
}

class _OfferBannerWidgetState extends State<OfferBannerWidget> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _gradientAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);
    _gradientAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  String _getOfferValueText() {
    String offerType = (widget.offer['offer_type'] ?? widget.offer['discount_type'] ?? widget.offer['type'] ?? 'discount_percent').toString();
    String value = (widget.offer['offer_value'] ?? widget.offer['discount_value'] ?? widget.offer['value'] ?? '0').toString();
    if (offerType == 'discount_percent' || offerType == 'percentage' || offerType == 'percent') {
      return '$value% ${'off'.tr}';
    } else if (offerType == 'per_seat_discount') {
      return '₹$value ${'off_per_seat'.tr}';
    }
    return '₹$value ${'off'.tr}';
  }

  String _getCountdownText() {
    String? endDate = widget.offer['ends_at'] ?? widget.offer['end_date'] ?? widget.offer['expires_at'];
    if (endDate == null) return '';
    try {
      DateTime end = DateTime.parse(endDate);
      Duration diff = end.difference(DateTime.now());
      if (diff.isNegative) return 'expired'.tr;
      if (diff.inDays > 0) return '${'ends_in'.tr} ${diff.inDays} ${'days'.tr}';
      if (diff.inHours > 0) return '${'ends_in'.tr} ${diff.inHours} ${'hours'.tr}';
      return '${'ends_in'.tr} ${diff.inMinutes} ${'minutes'.tr}';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    String offerName = widget.offer['name'] ?? widget.offer['title'] ?? 'special_offer'.tr;
    String description = widget.offer['description'] ?? widget.offer['subtitle'] ?? '';
    String offerValue = _getOfferValueText();
    String countdown = _getCountdownText();

    return AnimatedBuilder(
      animation: _gradientAnimation,
      builder: (context, child) {
        return Container(
          margin: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeExtraSmall),
          padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(-1.0 + _gradientAnimation.value * 2, -0.5),
              end: Alignment(1.0 - _gradientAnimation.value * 0.5, 0.5),
              colors: const [
                Color(0xFF2563EB),
                Color(0xFF1E3A8A),
                Color(0xFF1D4ED8),
              ],
            ),
            borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
            boxShadow: [BoxShadow(
              color: const Color(0xFF2563EB).withValues(alpha: 0.3),
              blurRadius: 8, spreadRadius: 1, offset: const Offset(0, 2),
            )],
          ),
          child: Row(children: [
            Container(
              height: 50, width: 50,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
              ),
              child: const Center(
                child: Icon(Icons.local_offer, color: Colors.white, size: 28),
              ),
            ),
            const SizedBox(width: Dimensions.paddingSizeSmall),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text(offerName, style: textSemiBold.copyWith(
                  color: Colors.white, fontSize: Dimensions.fontSizeDefault,
                ), maxLines: 1, overflow: TextOverflow.ellipsis)),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Dimensions.paddingSizeSmall,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                  ),
                  child: Text(offerValue, style: textBold.copyWith(
                    color: Colors.white, fontSize: Dimensions.fontSizeSmall,
                  )),
                ),
              ]),
              if (description.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(description, style: textRegular.copyWith(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: Dimensions.fontSizeExtraSmall,
                ), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
              if (countdown.isNotEmpty) ...[
                const SizedBox(height: 4),
                Row(children: [
                  Icon(Icons.timer_outlined, size: 12, color: Colors.white.withValues(alpha: 0.8)),
                  const SizedBox(width: 4),
                  Text(countdown, style: textMedium.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: Dimensions.fontSizeExtraSmall,
                  )),
                  const Spacer(),
                  if (widget.onApply != null)
                    InkWell(
                      onTap: widget.onApply,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                        ),
                        child: Text('apply'.tr, style: textSemiBold.copyWith(
                          color: const Color(0xFF2563EB),
                          fontSize: Dimensions.fontSizeExtraSmall,
                        )),
                      ),
                    ),
                ]),
              ],
            ])),
          ]),
        );
      },
    );
  }
}
