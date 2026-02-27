import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jago_user_app/common_widgets/image_widget.dart';
import 'package:jago_user_app/features/home/domain/models/categoty_model.dart';
import 'package:jago_user_app/features/ride/controllers/ride_controller.dart';
import 'package:jago_user_app/features/set_destination/screens/set_destination_screen.dart';
import 'package:jago_user_app/features/splash/controllers/config_controller.dart';
import 'package:jago_user_app/helper/price_converter.dart';
import 'package:jago_user_app/util/dimensions.dart';
import 'package:jago_user_app/util/images.dart';
import 'package:jago_user_app/util/styles.dart';

class CategoryWidget extends StatelessWidget {
  final Category category;
  final bool? isSelected;
  final bool fromSelect;
  final int index;
  final Function (void)? onTap;
  const CategoryWidget({
    super.key, required this.category, this.isSelected,
    this.fromSelect = false, required this.index,this.onTap
  });

  static const List<List<Color>> _gradients = [
    [Color(0xFF2563EB), Color(0xFF1D4ED8)],
    [Color(0xFF7C3AED), Color(0xFF6D28D9)],
    [Color(0xFF059669), Color(0xFF047857)],
    [Color(0xFFEA580C), Color(0xFFD97706)],
    [Color(0xFFDB2777), Color(0xFFBE185D)],
    [Color(0xFF0891B2), Color(0xFF0E7490)],
  ];

  @override
  Widget build(BuildContext context) {
    bool isActive = isSelected != null && isSelected!;
    final gradientColors = _gradients[index % _gradients.length];
    final isDark = Get.isDarkMode;

    return InkWell(
      onTap: () {
        Get.find<RideController>().setRideCategoryIndex(index);
        if(!fromSelect) {
          Get.to(() => const SetDestinationScreen());
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        width: isSelected != null ? 92 : 82,
        child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
          Container(
            height: isSelected != null ? 78 : 68,
            width: isSelected != null ? 78 : 68,
            margin: const EdgeInsets.only(right: Dimensions.paddingSizeSmall),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: isActive
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: gradientColors,
                  )
                : LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark
                      ? [const Color(0xFF1E293B), const Color(0xFF334155)]
                      : [
                          gradientColors[0].withValues(alpha: 0.08),
                          gradientColors[1].withValues(alpha: 0.04),
                        ],
                  ),
              border: isActive ? null : Border.all(
                color: isDark
                  ? gradientColors[0].withValues(alpha: 0.25)
                  : gradientColors[0].withValues(alpha: 0.15),
                width: 1.2,
              ),
              boxShadow: isActive ? [
                BoxShadow(
                  color: gradientColors[0].withValues(alpha: 0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                  spreadRadius: -2,
                ),
                BoxShadow(
                  color: gradientColors[1].withValues(alpha: 0.15),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ] : [
                BoxShadow(
                  color: isDark
                    ? Colors.black.withValues(alpha: 0.2)
                    : gradientColors[0].withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                  spreadRadius: -1,
                ),
              ],
            ),
            child: Stack(children: [
              Padding(
                padding: const EdgeInsets.all(8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: category.id == '0' ?
                  Image.asset(category.image??'') :
                  ImageWidget(
                    image: '${Get.find<ConfigController>().config?.imageBaseUrl?.vehicleCategory}/${category.image}',
                    height: Get.height,
                  ),
                ),
              ),

              Positioned(
                top: 4,
                left: 4,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isActive
                      ? Colors.white.withValues(alpha: 0.25)
                      : gradientColors[0].withValues(alpha: 0.12),
                  ),
                  child: Image.asset(
                    Images.offerIcon, height: 14, width: 14,
                    color: isActive ? Colors.white : gradientColors[0],
                  ),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 6),

          Text(
            category.name??'',
            style: textSemiBold.copyWith(
              color: isActive
                ? gradientColors[0]
                : Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.85),
              fontSize: Dimensions.fontSizeSmall,
            ), maxLines: 1, overflow: TextOverflow.ellipsis,
          ),

          if(category.fare != null && category.fare!.isNotEmpty && category.fare!.first.baseFarePerKm != null)
            Text(
              '${PriceConverter.convertPrice(category.fare!.first.baseFarePerKm ?? 0)}/km',
              style: textMedium.copyWith(
                color: isActive
                    ? gradientColors[0].withValues(alpha: 0.8)
                    : Theme.of(context).hintColor.withValues(alpha: 0.6),
                fontSize: Dimensions.fontSizeExtraSmall,
              ), maxLines: 1, overflow: TextOverflow.ellipsis,
            ),
        ]),
      ),
    );
  }
}
