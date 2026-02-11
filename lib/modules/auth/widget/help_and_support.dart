// ignore_for_file: deprecated_member_use

import 'package:elkitap/core/constants/icon_constants.dart';
import 'package:elkitap/core/widgets/common/app_snackbar.dart';
import 'package:elkitap/core/widgets/common/custom_icon.dart';
import 'package:elkitap/core/widgets/states/loading_widget.dart';
import 'package:elkitap/modules/profile/controllers/contacts_controller.dart';
import 'package:flutter/material.dart';
import 'package:elkitap/core/constants/string_constants.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpAndSupportAuth extends GetView<ContactsController> {
  const HelpAndSupportAuth({super.key});

  // Method to launch URLs
  Future<void> _openUrl(String url) async {
    if (url.isEmpty) {
      AppSnackbar.error('link_not_available'.tr);
      return;
    }

    try {
      final Uri uri = Uri.parse(url);

      // Use platformDispatcher or try different launch modes
      bool launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        // Try with default browser mode
        launched = await launchUrl(uri);
      }

      if (!launched) {
        throw Exception('Could not launch URL');
      }
    } catch (e) {
      AppSnackbar.error('could_not_open_link'.tr);
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
                Expanded(
                  child: Text(
                    'help_and_support'.tr, // Title of the bottom sheet
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontFamily: StringConstants.SFPro,
                      fontWeight: FontWeight.bold, // Make it bold as in the image
                      color: Theme.of(context).textTheme.bodyLarge!.color, // Theme-adaptive text color
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
          Flexible(
            // Use Flexible to prevent bottom sheet from taking infinite height
            child: Obx(() {
              if (controller.isLoading.value) {
                return LoadingWidget(removeBackWhite: true);
              }

              return ListView(
                shrinkWrap: true, // Make ListView only take the space it needs
                physics: const NeverScrollableScrollPhysics(), // Disable scrolling for this short list
                children: [
                  _buildRow(
                    context,
                    icon: IconConstants.h1,
                    title: "help_and_support".tr,
                    onTap: () {
                      // Launch Telegram or support link
                      final tgName = controller.telegramName;
                      if (tgName.isNotEmpty) {
                        _openUrl('https://t.me/$tgName');
                      }
                    },
                  ),

                  _divider(context),

                  // Terms and Conditions
                  _buildRow(
                    context,
                    icon: IconConstants.h2,
                    title: "terms_and_conditions".tr,
                    onTap: () {
                      _openUrl(controller.userAgreementUrl);
                    },
                  ),

                  _divider(context),

                  // Privacy and Policy
                  _buildRow(
                    context,
                    icon: IconConstants.h3,
                    title: "privacy_and_policy".tr,
                    onTap: () {
                      _openUrl(controller.privacyPolicyLink);
                    },
                  ),
                ],
              );
            }),
          ),
          const SizedBox(height: 20),
          const Spacer()
          // Help & Support
        ],
      ),
    );
  }

  Widget _buildRow(
    BuildContext context, {
    required String icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: CustomIcon(
        title: icon,
        height: 24,
        width: 24,
        color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontFamily: StringConstants.SFPro,
          color: Theme.of(context).textTheme.bodyLarge!.color,
        ),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  Widget _divider(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16.0),
      child: Divider(
        height: 1,
        thickness: 0.4,
        color: Theme.of(context).dividerColor.withOpacity(0.4),
      ),
    );
  }
}
