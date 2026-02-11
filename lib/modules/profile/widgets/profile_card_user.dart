import 'package:elkitap/core/constants/string_constants.dart';
import 'package:elkitap/modules/profile/widgets/edit_account_bottomsheet.dart';
import 'package:elkitap/modules/profile/widgets/no_subscribed_widget.dart';
import 'package:elkitap/modules/paymant/controller/payment_controller.dart';
import 'package:elkitap/modules/profile/widgets/subscribed_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:elkitap/modules/auth/controllers/auth_controller.dart';
import 'package:elkitap/modules/auth/models/user_model.dart';

class ProfileCardUser extends StatelessWidget {
  final VoidCallback onSubscribe;
  final User? user;

  const ProfileCardUser({
    super.key,
    required this.onSubscribe,
    this.user,
  });

  @override
  Widget build(BuildContext context) {
    final AuthController authController = Get.find<AuthController>();
    final PaymentController paymentController = Get.find<PaymentController>();

    void _showEditAccountSheet(BuildContext context) {
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (context) => const EditAccountBottomSheet(),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
        ),
      );
    }

    final currentUser = user ?? authController.currentUser.value;
    final username = currentUser?.username ?? 'user'.tr;
    final phone = currentUser?.phone ?? '';

    final subscription = currentUser?.subscription;
    final isSubscribed = subscription?.isActive ?? false;

    return Container(
      // padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1C1C1E) : Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.08),
          blurRadius: 20,
          spreadRadius: 0,
          offset: const Offset(0, 2),
        ),
      ]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(14.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        username,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontFamily: StringConstants.GilroyRegular,
                          fontSize: 20,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        phone,
                        style: const TextStyle(
                          fontSize: 13,
                          fontFamily: StringConstants.SFPro,
                        ),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: GestureDetector(
                    onTap: () {
                      _showEditAccountSheet(context);
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            'edit_account'.tr,
                            style: const TextStyle(
                              fontSize: 12,
                              fontFamily: StringConstants.SFPro,
                            ),
                          ),
                        ),
                        const SizedBox(width: 3),
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 14,
                          color: Colors.grey.shade600,
                        )
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Obx(() {
            if (paymentController.isPaymentActive.value) {
              return const SizedBox.shrink();
            }
            return !isSubscribed
                ? NotSubscribedView(onSubscribe: onSubscribe)
                : SubscribedView(
                    subscription: subscription!,
                  );
          }),
        ],
      ),
    );
  }
}
