import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jago_pilot_app/features/splash/controllers/splash_controller.dart';
import 'package:jago_pilot_app/features/subscription/controllers/subscription_controller.dart';
import 'package:jago_pilot_app/util/dimensions.dart';
import 'package:jago_pilot_app/util/styles.dart';
import 'package:jago_pilot_app/common_widgets/app_bar_widget.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  @override
  void initState() {
    super.initState();
    Get.find<SubscriptionController>().getPlans();
    Get.find<SubscriptionController>().getStatus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GetBuilder<SubscriptionController>(builder: (controller) {
        return CustomScrollView(slivers: [
          SliverAppBar(
            pinned: true,
            elevation: 0,
            centerTitle: false,
            toolbarHeight: 80,
            automaticallyImplyLeading: false,
            backgroundColor: Theme.of(context).highlightColor,
            flexibleSpace: AppBarWidget(
              title: 'subscription_plans'.tr,
              showBackButton: true,
              onTap: () => Get.back(),
            ),
          ),

          SliverToBoxAdapter(
            child: controller.isLoading
                ? const Padding(
                    padding: EdgeInsets.only(top: 100),
                    child: Center(child: CircularProgressIndicator()),
                  )
                : Padding(
                    padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildEarningModelBanner(context, controller),
                        const SizedBox(height: Dimensions.paddingSizeDefault),
                        _buildStatusCard(context, controller),
                        const SizedBox(height: Dimensions.paddingSizeExtraLarge),
                        Text(
                          'available_plans'.tr,
                          style: textBold.copyWith(
                            color: Theme.of(context).textTheme.bodyMedium!.color,
                            fontSize: Dimensions.fontSizeExtraLarge,
                          ),
                        ),
                        const SizedBox(height: Dimensions.paddingSizeDefault),
                        controller.plans.isEmpty
                            ? Padding(
                                padding: const EdgeInsets.only(top: 40),
                                child: Center(
                                  child: Text(
                                    'no_plans_available'.tr,
                                    style: textSemiBold.copyWith(color: Colors.grey),
                                  ),
                                ),
                              )
                            : ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: controller.plans.length,
                                itemBuilder: (context, index) {
                                  return _buildPlanCard(context, controller, controller.plans[index]);
                                },
                              ),
                      ],
                    ),
                  ),
          ),
        ]);
      }),
    );
  }

  Widget _buildEarningModelBanner(BuildContext context, SubscriptionController controller) {
    final config = Get.find<SplashController>().config;
    final isSubscription = config?.earningModel == 'subscription';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isSubscription ? const Color(0xFF2563EB).withValues(alpha: 0.1) : const Color(0xFF16A34A).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSubscription ? const Color(0xFF2563EB).withValues(alpha: 0.3) : const Color(0xFF16A34A).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            color: isSubscription ? const Color(0xFF2563EB) : const Color(0xFF16A34A),
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              isSubscription
                  ? 'Your platform uses the Subscription Model. You need an active subscription to accept rides. Platform Fee: ₹${config?.platformFeeAmount ?? 0} + GST per ride.'
                  : 'Your platform uses the Commission Model. Commission Rate: ${config?.commissionPercent ?? 0}% + GST deducted per ride. No subscription required.',
              style: TextStyle(
                color: isSubscription ? const Color(0xFF1E3A8A) : const Color(0xFF166534),
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard(BuildContext context, SubscriptionController controller) {
    bool hasSubscription = controller.currentStatus['has_subscription'] == true;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: hasSubscription
              ? [const Color(0xFF2563EB), const Color(0xFF1E3A8A)]
              : [Colors.grey.shade600, Colors.grey.shade800],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (hasSubscription ? const Color(0xFF2563EB) : Colors.grey).withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'current_status'.tr,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            hasSubscription ? 'active_subscription'.tr : 'no_active_subscription'.tr,
            style: textBold.copyWith(color: Colors.white, fontSize: 20),
          ),
          if (controller.isSubscriptionModel) ...[
            const SizedBox(height: 8),
            Text(
              'Platform Fee per ride: ₹${controller.platformFeeAmount} + GST',
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ],
          if (hasSubscription) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('rides_used'.tr, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    const SizedBox(height: 2),
                    Text(
                      '${controller.currentStatus['rides_used'] ?? 0}',
                      style: textBold.copyWith(color: Colors.white, fontSize: 18),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('rides_remaining'.tr, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    const SizedBox(height: 2),
                    Text(
                      '${controller.currentStatus['rides_remaining'] ?? 0}',
                      style: textBold.copyWith(color: Colors.white, fontSize: 18),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('plan_name'.tr, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    const SizedBox(height: 2),
                    Text(
                      '${controller.currentStatus['plan_name'] ?? ''}',
                      style: textSemiBold.copyWith(color: Colors.white, fontSize: 14),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPlanCard(BuildContext context, SubscriptionController controller, dynamic plan) {
    return Container(
      margin: const EdgeInsets.only(bottom: Dimensions.paddingSizeDefault),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2563EB).withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    '${plan['name'] ?? ''}',
                    style: textBold.copyWith(
                      fontSize: Dimensions.fontSizeLarge,
                      color: Theme.of(context).textTheme.bodyMedium!.color,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '₹${plan['price'] ?? 0}',
                    style: textBold.copyWith(
                      color: const Color(0xFF2563EB),
                      fontSize: Dimensions.fontSizeLarge,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: Dimensions.paddingSizeSmall),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                const SizedBox(width: 6),
                Text(
                  '${'duration'.tr}: ${plan['duration'] ?? 0} ${'days'.tr}',
                  style: textSemiBold.copyWith(
                    color: Colors.grey[600],
                    fontSize: Dimensions.fontSizeDefault,
                  ),
                ),
                const SizedBox(width: 16),
                const Icon(Icons.directions_car, size: 16, color: Colors.grey),
                const SizedBox(width: 6),
                Text(
                  '${'rides_limit'.tr}: ${plan['rides_limit'] ?? 'unlimited'.tr}',
                  style: textSemiBold.copyWith(
                    color: Colors.grey[600],
                    fontSize: Dimensions.fontSizeDefault,
                  ),
                ),
              ],
            ),
            if (plan['description'] != null && plan['description'].toString().isNotEmpty) ...[
              const SizedBox(height: Dimensions.paddingSizeSmall),
              Text(
                '${plan['description']}',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: Dimensions.fontSizeSmall,
                ),
              ),
            ],
            const SizedBox(height: Dimensions.paddingSizeDefault),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: controller.isLoading
                    ? null
                    : () => controller.subscribe(plan['id'] ?? 0),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Text(
                  'subscribe'.tr,
                  style: textBold.copyWith(color: Colors.white, fontSize: Dimensions.fontSizeDefault),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
