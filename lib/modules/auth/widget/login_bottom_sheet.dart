// ignore_for_file: deprecated_member_use

import 'package:elkitap/core/constants/string_constants.dart';
import 'package:elkitap/core/theme/app_colors.dart';
import 'package:elkitap/core/widgets/common/app_snackbar.dart';
import 'package:elkitap/core/widgets/states/loading_widget.dart';
import 'package:elkitap/modules/auth/controllers/auth_controller.dart';
import 'package:elkitap/modules/auth/widget/otp_bottom_sheet.dart';
import 'package:elkitap/modules/profile/controllers/contacts_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import 'package:flutter/gestures.dart';
import 'package:url_launcher/url_launcher.dart';

class LoginBottomSheet extends StatefulWidget {
  const LoginBottomSheet({Key? key}) : super(key: key);

  @override
  State<LoginBottomSheet> createState() => _LoginBottomSheetState();
}

class _LoginBottomSheetState extends State<LoginBottomSheet> {
  final TextEditingController _phoneController = TextEditingController();
  final FocusNode _phoneFocusNode = FocusNode();
  final AuthController _authController = Get.find<AuthController>();
  final ContactsController _contactsController = Get.find<ContactsController>();

  @override
  void dispose() {
    _phoneController.dispose();
    _phoneFocusNode.dispose();
    super.dispose();
  }

  bool _isPhoneValid() {
    final phone = _phoneController.text.replaceAll(' ', '');
    return phone.length == 8;
  }

  Future<void> _handleContinue() async {
    if (!_isPhoneValid()) return;

    final phone = _phoneController.text.replaceAll(' ', '');

    Get.defaultDialog(
      content: LoadingWidget(removeBackWhite: true),
      backgroundColor: Colors.transparent,
      title: '',
      barrierDismissible: false,
    );

    // Send verification code
    final success = await _authController.sendCode(phone);

    // Close loading dialog
    if (Get.isDialogOpen == true) {
      Get.back();
    }

    if (success) {
      // Use post frame callback to ensure navigation happens after build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Close login sheet
        if (Get.isBottomSheetOpen == true) {
          Get.back();
        }

        // Show OTP sheet
        _showOtpBottomSheet();

        // Show success message
        AppSnackbar.success('verification_code_sent'.tr);
      });
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        AppSnackbar.error('failed_to_send_code'.tr);
      });
    }
  }

  void _showOtpBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: const OtpVerificationSheetContent(),
      ),
    );
  }

  // Open URL in browser
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
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
      decoration: BoxDecoration(
        color: Get.theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Title
          Text(
            'login_title'.tr,
            style: const TextStyle(
              fontSize: 24,
              fontFamily: StringConstants.SFPro,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),

          // Phone number label
          Text(
            'phoneNumber'.tr,
            style: TextStyle(
              fontSize: 16,
              fontFamily: StringConstants.SFPro,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),

          // Phone input
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                // Country code
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    '+993',
                    style: TextStyle(
                      fontFamily: StringConstants.SFPro,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),

                // Phone number input
                Expanded(
                  child: TextField(
                    controller: _phoneController,
                    focusNode: _phoneFocusNode,
                    keyboardType: TextInputType.phone,
                    autofocus: true,
                    style: const TextStyle(
                      fontSize: 16,
                      fontFamily: StringConstants.SFPro,
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: const InputDecoration(
                      hintText: '61 00 00 00',
                      border: InputBorder.none,
                      hintStyle: TextStyle(
                        fontFamily: StringConstants.SFPro,
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(8),
                      _PhoneNumberFormatter(),
                    ],
                    onChanged: (value) {
                      setState(() {});
                    },
                    onSubmitted: (_) {
                      if (_isPhoneValid()) {
                        _handleContinue();
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Continue button
          Obx(() {
            return SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isPhoneValid() && !_authController.isLoading.value ? _handleContinue : null,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  backgroundColor: _isPhoneValid() ? AppColors.mainColor : Colors.grey.withOpacity(0.3),
                  disabledBackgroundColor: Colors.grey.withOpacity(0.3),
                ),
                child: _authController.isLoading.value
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        'continue_text'.tr,
                        style: TextStyle(
                          fontSize: 16,
                          fontFamily: StringConstants.SFPro,
                          fontWeight: FontWeight.w600,
                          color: _isPhoneValid() ? Colors.white : Colors.grey,
                        ),
                      ),
              ),
            );
          }),
          Padding(
            padding: const EdgeInsets.only(left: 24, right: 24, top: 16, bottom: 24),
            child: RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: const TextStyle(
                  fontSize: 13,
                  fontFamily: StringConstants.SFPro,
                  color: Colors.grey,
                  fontWeight: FontWeight.w400,
                ),
                children: [
                  TextSpan(text: 'byPressingContinue'.tr),
                  TextSpan(
                    text: 'termsOfUse'.tr,
                    style: const TextStyle(
                      color: Colors.black,
                      fontFamily: StringConstants.SFPro,
                      fontWeight: FontWeight.w500,
                      decoration: TextDecoration.underline,
                    ),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () {
                        _openUrl(_contactsController.userAgreementUrl);
                      },
                  ),
                  TextSpan(text: 'andNewLine'.tr),
                  TextSpan(
                    text: 'privacyPolicy'.tr,
                    style: const TextStyle(
                      color: Colors.black,
                      fontFamily: StringConstants.SFPro,
                      fontWeight: FontWeight.w500,
                      decoration: TextDecoration.underline,
                    ),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () {
                        _openUrl(_contactsController.privacyPolicyLink);
                      },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Phone number formatter
class _PhoneNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll(' ', '');
    final buffer = StringBuffer();

    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      if ((i + 1) % 2 == 0 && i + 1 != text.length) {
        buffer.write(' ');
      }
    }

    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
