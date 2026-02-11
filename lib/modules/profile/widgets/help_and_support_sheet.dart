import 'package:elkitap/core/constants/icon_constants.dart';
import 'package:elkitap/core/constants/string_constants.dart';
import 'package:elkitap/core/widgets/common/app_snackbar.dart';
import 'package:elkitap/core/widgets/common/custom_icon.dart';
import 'package:elkitap/core/widgets/states/loading_widget.dart';
import 'package:elkitap/modules/profile/controllers/contacts_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpAndSupportBottomSheet extends GetView<ContactsController> {
  const HelpAndSupportBottomSheet({super.key});

  Future<void> _launchPhone(String phoneNumber) async {
    if (phoneNumber.isEmpty) {
      AppSnackbar.error('phone_not_available'.tr);
      return;
    }

    try {
      final Uri uri = Uri.parse('tel:$phoneNumber');
      bool launched = await launchUrl(uri);

      if (!launched) {
        throw Exception('Could not launch phone');
      }
    } catch (e) {
      AppSnackbar.error('could_not_make_call'.tr);
    }
  }

  // Method to launch email
  Future<void> _launchEmail(String email) async {
    if (email.isEmpty) {
      AppSnackbar.error('email_not_available'.tr);
      return;
    }

    try {
      final Uri uri = Uri.parse('mailto:$email');
      bool launched = await launchUrl(uri);

      if (!launched) {
        throw Exception('Could not launch email');
      }
    } catch (e) {
      AppSnackbar.error('could_not_send_email'.tr);
    }
  }

  // Method to launch Telegram
  Future<void> _launchTelegram(String username) async {
    if (username.isEmpty) {
      AppSnackbar.error('telegram_not_available'.tr);
      return;
    }

    try {
      final Uri uri = Uri.parse('https://t.me/$username');
      bool launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        // Try with default browser mode
        launched = await launchUrl(uri);
      }

      if (!launched) {
        throw Exception('Could not launch Telegram');
      }
    } catch (e) {
      AppSnackbar.error('could_not_open_telegram'.tr);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).pop();
                  },
                  child: Icon(
                    Icons.arrow_back_ios,
                    color: Theme.of(context).iconTheme.color,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'profile'.tr,
                  style: TextStyle(
                    fontSize: 18,
                    fontFamily: StringConstants.SFPro,
                    color: Theme.of(context).textTheme.bodyLarge!.color, // Theme-adaptive text color
                    fontWeight: FontWeight.w400,
                  ),
                ),
                Expanded(
                  child: Text(
                    'help_and_support'.tr, // Title of the bottom sheet
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontFamily: StringConstants.SFPro,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.bodyLarge!.color,
                    ),
                  ),
                ),
                const SizedBox(width: 80),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Flexible(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: LoadingWidget(),
                  ),
                );
              }

              return ListView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildOptionTile(
                    context,
                    icon: IconConstants.p8,
                    title: "call_t".tr,
                    hasTrailingIcon: false,
                    onTap: () {
                      _launchPhone(controller.phoneNumber);
                    },
                  ),
                  _buildOptionTile(
                    context,
                    icon: IconConstants.p9, // Email icon
                    title: "email_t".tr, // Localized
                    hasTrailingIcon: false, // No trailing icon for Email
                    onTap: () {
                      _launchEmail(controller.emailAddress);
                    },
                  ),
                  _buildOptionTile(
                    context,
                    icon: IconConstants.p10, // Send icon (for Start)
                    title: "start_t".tr, // Localized
                    hasTrailingIcon: true, // Has trailing icon
                    onTap: () {
                      _launchTelegram(controller.startupName);
                    },
                  ),
                  _buildOptionTile(
                    context,
                    icon: IconConstants.p10, // Send icon (for Telegram)
                    title: "telegram_t".tr, // Localized
                    hasTrailingIcon: true, // Has trailing icon
                    showDivider: false, // Last item, no divider below it
                    onTap: () {
                      _launchTelegram(controller.telegramName);
                    },
                  ),
                ],
              );
            }),
          ),
          const SizedBox(height: 20),
          const Spacer()
        ],
      ),
    );
  }

  // Helper method to build each ListTile with a divider
  Widget _buildOptionTile(
    BuildContext context, {
    required String icon,
    required String title,
    bool hasTrailingIcon = false,
    bool showDivider = true, // Control divider visibility
    VoidCallback? onTap,
  }) {
    // Determine icon size based on the icon path
    double iconHeight = 24;
    double iconWidth = 24;

    if (icon == IconConstants.p9) {
      iconHeight = 20; // Adjust these values as needed
      iconWidth = 28; // Make it wider for the email icon
    }

    return Column(
      children: [
        ListTile(
          leading: CustomIcon(
            title: icon,
            height: iconHeight,
            width: iconWidth,
            color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
          ),
          title: Text(
            title,
            style: TextStyle(
              fontFamily: StringConstants.SFPro,
              fontSize: 16,
              color: Theme.of(context).textTheme.bodyLarge!.color, // Theme-adaptive text color
            ),
          ),
          trailing: hasTrailingIcon
              ? CustomIcon(
                  title: IconConstants.p11,
                  height: 40,
                  width: 40,
                  color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                )
              : null,
          onTap: onTap,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
        ),
        if (showDivider)
          Padding(
            padding: const EdgeInsets.only(left: 16.0),
            child: Divider(
              height: 1,
              color: Theme.of(context).dividerColor.withOpacity(0.5),
              thickness: 0.5,
            ),
          ),
      ],
    );
  }
}
