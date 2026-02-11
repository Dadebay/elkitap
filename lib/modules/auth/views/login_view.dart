// ignore_for_file: deprecated_member_use

import 'package:elkitap/core/constants/icon_constants.dart';
import 'package:elkitap/core/constants/string_constants.dart';
import 'package:elkitap/core/theme/app_colors.dart';
import 'package:elkitap/core/widgets/common/app_snackbar.dart';
import 'package:elkitap/core/widgets/common/custom_icon.dart';
import 'package:elkitap/core/widgets/common/language_selector.dart';
import 'package:elkitap/core/widgets/states/loading_widget.dart';
import 'package:elkitap/modules/auth/controllers/auth_controller.dart';
import 'package:elkitap/modules/auth/widget/help_and_support.dart';
import 'package:elkitap/modules/auth/widget/otp_bottom_sheet.dart';
import 'package:elkitap/modules/profile/controllers/contacts_controller.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:url_launcher/url_launcher.dart';

class AuthViewScreen extends StatefulWidget {
  const AuthViewScreen({super.key});

  @override
  State<AuthViewScreen> createState() => _AuthViewScreenState();
}

class _AuthViewScreenState extends State<AuthViewScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final ContactsController _contactsController = Get.find<ContactsController>();
  String selectedLanguage = 'turkmen'.tr;

  bool _isFocused = false;
  bool _isValid = false;

  @override
  void initState() {
    super.initState();
    _contactsController.getContacts();
    _phoneController.addListener(_onTextChanged);
    _focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
  }

  void _onTextChanged() {
    setState(() {
      _isValid = _phoneController.text.trim().length > 7;
    });
  }

  void _showHelpBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const HelpAndSupportAuth(),
    );
  }

  void _showOtpBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25.0))),
      builder: (BuildContext context) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: const OtpVerificationSheetContent(),
        );
      },
    );
  }

  void _onContinuePressed() async {
    if (!_isValid) return;

    final authController = Get.find<AuthController>();

    // Show loading dialog
    Get.defaultDialog(
      content: LoadingWidget(removeBackWhite: true),
      backgroundColor: Colors.transparent,
      title: '',
      barrierDismissible: false,
    );

    // Send code
    final success = await authController.sendCode(_phoneController.text);

    if (Get.isDialogOpen == true) {
      Get.close(1);
    }

    if (success) {
      Future.microtask(() {
        _showOtpBottomSheet(context);
      });
    }
  }

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
  void dispose() {
    _phoneController.removeListener(_onTextChanged);
    _focusNode.removeListener(_onFocusChange);
    _phoneController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final borderColor = _isFocused ? AppColors.mainColor : Colors.grey.shade400;
    final continueColor = _isValid ? AppColors.mainColor : const Color(0xFFE5E5EA);
    final continueTextColor = _isValid ? Colors.white : const Color(0xFFC7C7CC);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Top Navigation
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => Get.back(),
                    child: Row(
                      children: [
                        const Icon(Icons.arrow_back_ios, size: 20),
                        const SizedBox(width: 4),
                        Text(
                          'leading_text'.tr,
                          style: const TextStyle(
                            fontSize: 17,
                            fontFamily: StringConstants.SFPro,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  const LanguageSelector(),
                  const Spacer(),
                  const SizedBox(width: 20),
                  GestureDetector(
                    onTap: () {
                      _showHelpBottomSheet(context);
                    },
                    child: SizedBox(
                      width: 28,
                      height: 28,
                      child: CustomIcon(
                        title: IconConstants.p4,
                        height: 28,
                        width: 28,
                        color: Colors.black,
                      ),
                    ),
                  )
                ],
              ),
            ),

            const SizedBox(height: 40),
            Text(
              'phoneNumber'.tr,
              style: const TextStyle(
                fontSize: 17,
                fontFamily: StringConstants.SFPro,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'enterNumberToLogin'.tr,
              style: const TextStyle(
                fontSize: 15,
                fontFamily: StringConstants.SFPro,
                color: Colors.grey,
                fontWeight: FontWeight.w400,
              ),
            ),

            const SizedBox(height: 40),

            // Phone Input
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'phoneNumber'.tr,
                    style: const TextStyle(
                      fontSize: 14,
                      fontFamily: StringConstants.SFPro,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 5),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      border: Border.all(color: borderColor, width: 2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    child: Row(
                      children: [
                        Text(
                          'countryCode'.tr,
                          style: const TextStyle(
                            fontSize: 17,
                            fontFamily: StringConstants.SFPro,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 24,
                          color: Colors.grey.shade300,
                          margin: const EdgeInsets.symmetric(horizontal: 12),
                        ),
                        Expanded(
                          child: TextField(
                            controller: _phoneController,
                            focusNode: _focusNode,
                            keyboardType: TextInputType.phone,
                            maxLength: 8,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w400,
                            ),
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                              counterText: '',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(),

            // Continue button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: GestureDetector(
                onTap: _isValid ? _onContinuePressed : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: double.infinity,
                  height: 56,
                  decoration: BoxDecoration(
                    color: continueColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      'continue_text'.tr,
                      style: TextStyle(
                        fontSize: 17,
                        fontFamily: StringConstants.SFPro,
                        fontWeight: FontWeight.w600,
                        color: continueTextColor,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Terms Text (FIXED — no Obx)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
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

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
