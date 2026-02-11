import 'package:elkitap/core/constants/string_constants.dart';
import 'package:elkitap/core/theme/app_colors.dart';

import 'package:elkitap/modules/paymant/view/promocode_sheet.dart';
import 'package:elkitap/modules/paymant/widget/subscription_expired_sheet.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:elkitap/modules/auth/models/subscription_model.dart';

class SubscribedView extends StatelessWidget {
  final Subscription subscription;

  const SubscribedView({
    super.key,
    required this.subscription,
  });

  @override
  Widget build(BuildContext context) {
    void _showSubscriptionExpiredSheet(BuildContext context) {
      showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) => const SubscriptionExpiredSheet(),
      );
    }

    void _showPromocodeSheet(BuildContext context) {
      Navigator.pop(context);
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) => const PromocodeSheet(),
      );
    }

    // 0 = Active (Normal)
    // 1 = Expiring Soon (< 3 days)
    // 2 = Expired
    final daysLeft = subscription.daysRemaining;

    int state = 0;
    if (!subscription.isActive) {
      state = 2;
    } else if (daysLeft <= 3) {
      state = 1;
    }

    Color statusColor = Colors.grey.shade600; // Default text color
    String statusTitle = "";
    String statusSubtitle = "subscription_ends_in_t".trParams({'days': daysLeft.toString()});

    if (state == 1) {
      // Expiring Soon
      statusColor = const Color(0xFFFF9500); // Orange
      statusTitle = "expiring_soon".tr;
      statusSubtitle = "subscription_ends_in_t".trParams({'days': daysLeft.toString()});
    } else if (state == 2) {
      // Expired
      statusColor = const Color(0xFFFF3B30); // Red
      statusTitle = "your_subscription_expired".tr;

      // Formatting date: "31st October" style
      final date = subscription.expiredAt;
      final months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
      final monthName = months[date.month - 1]; // 1-based to 0-based

      String daySuffix(int day) {
        if (day >= 11 && day <= 13) {
          return 'th';
        }
        switch (day % 10) {
          case 1:
            return 'st';
          case 2:
            return 'nd';
          case 3:
            return 'rd';
          default:
            return 'th';
        }
      }

      final dayStr = "${date.day}${daySuffix(date.day)}";
      // We might need to translate months if strict localization is required,
      // but for now matching the design "31st October".
      // If full localization is needed, better to use intl DateFormat.
      // For now, assuming English style or using available translation keys if any.

      final expiryDate = "$dayStr $monthName";
      statusSubtitle = "expired_date_is".trParams({'date': expiryDate});
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.only(left: 14, right: 14, top: 25),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.6,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (state != 0) ...[
                      Text(
                        statusTitle,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                          fontFamily: StringConstants.GilroyRegular,
                        ),
                      ),
                      const SizedBox(height: 4),
                    ],
                    Text(
                      statusSubtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: state == 0 ? null : Colors.grey.shade600,
                        fontFamily: StringConstants.SFPro,
                      ),
                    ),
                  ],
                ),
              ),
              state == 2
                  ? ColorFiltered(
                      colorFilter: const ColorFilter.mode(Colors.grey, BlendMode.srcIn),
                      child: Image.asset(
                        'assets/images/subscribed.png',
                        height: 46,
                        width: 46,
                      ),
                    )
                  : Image.asset(
                      'assets/images/subscribed.png',
                      height: 46,
                      width: 46,
                    )
            ],
          ),
        ),
        Container(
          height: 1,
          margin: EdgeInsets.symmetric(vertical: 12),
          color: AppColors.dividerColor,
        ),
        Padding(
          padding: const EdgeInsets.all(10.0).copyWith(top: 0),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    _showSubscriptionExpiredSheet(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF5A26), // Orange Color from design
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(40),
                    ),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  child: Text("extend".tr, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, fontFamily: StringConstants.SFPro, color: Colors.white)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    _showPromocodeSheet(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).brightness == Brightness.dark ? Color(0xFF2C2C2E) : Color(0xFFF2F2F7), // Light Grey
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(40),
                    ),
                    elevation: 0,
                    padding: EdgeInsets.symmetric(vertical: 8),
                  ),
                  child: Text("promocode".tr,
                      style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w500, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black, fontFamily: StringConstants.SFPro)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
