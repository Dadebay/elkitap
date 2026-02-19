import 'package:elkitap/core/constants/string_constants.dart';
import 'package:elkitap/core/theme/app_colors.dart';
import 'package:elkitap/core/widgets/common/app_snackbar.dart';
import 'package:elkitap/modules/auth/controllers/auth_controller.dart';
import 'package:elkitap/modules/paymant/view/promocode_sheet.dart';
import 'package:elkitap/modules/paymant/view/subscription_plans_sheet.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SubscriptionExpiredSheet extends StatelessWidget {
  const SubscriptionExpiredSheet({Key? key}) : super(key: key);

  void _showSubscriptionPlansSheet(BuildContext context) async {
    Navigator.pop(context);
    final result = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => const SubscriptionPlansSheet(),
    );

    if (result != null && result != false && context.mounted) {
      final authController = Get.find<AuthController>();
      await authController.getMe();

      // Extract tariff/subscription info to show days added
      int addedDays = 0;
      if (result is Map<String, dynamic>) {
        // Try to get tariff info from response
        final data = result['data'];
        if (data is Map<String, dynamic>) {
          final tariff = data['tariff'];
          if (tariff is Map<String, dynamic>) {
            addedDays = (tariff['duration'] as num?)?.toInt() ?? 0;
          }
        }
      }

      if (addedDays > 0) {
        AppSnackbar.success(
          'payment_success_days_t'.trParams({'days': addedDays.toString()}),
        );
      } else {
        AppSnackbar.success('payment_successful_t'.tr);
      }

      if (context.mounted) {
        Navigator.pop(context, true);
      }
    }
  }

  void _showPromocodeSheet(BuildContext context) async {
    Navigator.pop(context);
    final result = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => const PromocodeSheet(),
    );

    if (result != null) {
      final authController = Get.find<AuthController>();
      await authController.getMe();

      int addedDays = 0;
      if (result is Map<String, dynamic>) {
        addedDays = (result['added_days'] as num?)?.toInt() ?? 0;
      }

      if (addedDays > 0) {
        AppSnackbar.success(
          'promo_code_success_days_t'.trParams({'days': addedDays.toString()}),
        );
      } else {
        AppSnackbar.success('promo_code_success_t'.tr);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[400],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'subscription'.tr,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Image.asset('assets/images/a2.png')),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'account'.tr,
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 13,
                      fontFamily: StringConstants.SFPro,
                    ),
                  ),
                  Obx(() {
                    final authController = Get.find<AuthController>();
                    final phone = authController.currentUser.value?.phone ?? '+993';
                    return Text(
                      phone,
                      style: TextStyle(
                        fontSize: 15,
                        fontFamily: StringConstants.SFPro,
                        fontWeight: FontWeight.w600,
                      ),
                    );
                  }),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          Align(
            alignment: Alignment.centerLeft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Obx(() {
                  final authController = Get.find<AuthController>();
                  final subscription = authController.currentUser.value?.subscription;
                  final daysRemaining = subscription?.daysRemaining ?? 0;
                  final expiredAt = subscription?.expiredAt;

                  String dateStr = '';
                  if (expiredAt != null) {
                    dateStr = '${expiredAt.day.toString().padLeft(2, '0')}.${expiredAt.month.toString().padLeft(2, '0')}.${expiredAt.year}';
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'expired_date_is_t'.trParams({'date': dateStr}),
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        'subscription_ends_in_t'.trParams({'days': daysRemaining.toString()}),
                        style: TextStyle(
                          color: const Color(0xFFFF5722),
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _showSubscriptionPlansSheet(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.mainColor,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'extend_button_t'.tr,
                    style: TextStyle(
                      fontSize: 18,
                      fontFamily: StringConstants.SFPro,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              // TODO: GEÇICI OLARAK COMMENT EDİLDİ - PROMOCODE FIELD ÇALIŞMIYOR
              // Sonra açmak için bu comment'i kaldır
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _showPromocodeSheet(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[200],
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'promocode'.tr,
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.black,
                      fontFamily: StringConstants.SFPro,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
