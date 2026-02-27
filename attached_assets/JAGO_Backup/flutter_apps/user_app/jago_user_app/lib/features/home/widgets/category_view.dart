import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jago_user_app/common_widgets/category_widget.dart';
import 'package:jago_user_app/features/car_sharing/screens/find_shared_rides_screen.dart';
import 'package:jago_user_app/features/home/controllers/category_controller.dart';
import 'package:jago_user_app/features/home/widgets/category_shimmer.dart';
import 'package:jago_user_app/features/parcel/screens/parcel_screen.dart';
import 'package:jago_user_app/features/ride/controllers/ride_controller.dart';
import 'package:jago_user_app/features/set_destination/screens/set_destination_screen.dart';
import 'package:jago_user_app/features/splash/controllers/config_controller.dart';
import 'package:jago_user_app/util/dimensions.dart';
import 'package:jago_user_app/util/images.dart';
import 'package:jago_user_app/util/styles.dart';

class CategoryView extends StatelessWidget {
  const CategoryView({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Get.isDarkMode;

    return GetBuilder<CategoryController>(builder: (categoryController){
      return SizedBox(
        height: 108, width: Get.width,
        child: ListView(
          shrinkWrap: true,
          scrollDirection: Axis.horizontal,
          children: [
            categoryController.categoryList != null ?
            categoryController.categoryList!.isNotEmpty ?
            ListView.builder(
                shrinkWrap: true,
                itemCount: categoryController.categoryList!.length,
                padding: EdgeInsets.zero,
                scrollDirection: Axis.horizontal,
                physics: const NeverScrollableScrollPhysics(),
                itemBuilder: (context, index) {
                  return CategoryWidget(index: index, category: categoryController.categoryList![index]);
                }
            ) :
            const SizedBox() :
            const CategoryShimmer(),

            _buildServiceCard(
              context: context,
              isDark: isDark,
              onTap: () => Get.to(() => const ParcelScreen()),
              image: Images.parcel,
              label: 'parcel'.tr,
              gradientColors: const [Color(0xFFEA580C), Color(0xFFD97706)],
            ),

            if(Get.find<ConfigController>().config?.scheduleTripStatus ?? false)
              _buildServiceCard(
                context: context,
                isDark: isDark,
                onTap: () => Get.to(() => const SetDestinationScreen(rideType: RideType.scheduleRide)),
                image: Images.scheduleTripIcon,
                label: 'schedule_trip'.tr,
                gradientColors: const [Color(0xFF7C3AED), Color(0xFF6D28D9)],
              ),

            _buildServiceCard(
              context: context,
              isDark: isDark,
              onTap: () => Get.to(() => const FindSharedRidesScreen()),
              image: Images.carSharingIcon,
              label: 'share_ride'.tr,
              gradientColors: const [Color(0xFF059669), Color(0xFF047857)],
            ),
          ],
        ),
      );
    });
  }

  Widget _buildServiceCard({
    required BuildContext context,
    required bool isDark,
    required VoidCallback onTap,
    required String image,
    required String label,
    required List<Color> gradientColors,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 5.0),
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: 82,
          child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
            Container(
              width: 68, height: 68,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                    ? [const Color(0xFF1E293B), const Color(0xFF334155)]
                    : [
                        gradientColors[0].withValues(alpha: 0.08),
                        gradientColors[1].withValues(alpha: 0.04),
                      ],
                ),
                border: Border.all(
                  color: isDark
                    ? gradientColors[0].withValues(alpha: 0.25)
                    : gradientColors[0].withValues(alpha: 0.15),
                  width: 1.2,
                ),
                boxShadow: isDark ? null : [
                  BoxShadow(
                    color: gradientColors[0].withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                    spreadRadius: -1,
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Image.asset(image),
              ),
            ),
            const SizedBox(height: 6),
            Text(label, style: textSemiBold.copyWith(
              color: Theme.of(context).textTheme.bodyMedium!.color!.withValues(alpha: 0.85),
              fontSize: Dimensions.fontSizeSmall,
            ), maxLines: 1, overflow: TextOverflow.ellipsis),
          ]),
        ),
      ),
    );
  }
}
