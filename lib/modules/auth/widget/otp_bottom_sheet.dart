// ignore_for_file: deprecated_member_use

import 'dart:async';

import 'package:elkitap/core/constants/string_constants.dart';
import 'package:elkitap/core/widgets/common/app_snackbar.dart';
import 'package:elkitap/core/widgets/navigation/bottom_nav_bar.dart';
import 'package:elkitap/core/widgets/states/loading_widget.dart';
import 'package:elkitap/modules/auth/controllers/auth_controller.dart';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pinput/pinput.dart';

class OtpVerificationSheetContent extends StatefulWidget {
  const OtpVerificationSheetContent({super.key});

  @override
  State<OtpVerificationSheetContent> createState() => _OtpVerificationSheetContentState();
}

class _OtpVerificationSheetContentState extends State<OtpVerificationSheetContent> {
  final TextEditingController _pinController = TextEditingController();
  final AuthController authController = Get.find<AuthController>();
  final FocusNode _focusNode = FocusNode();
  late Timer _timer;
  int _start = 60;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
    // Auto-focus on the PIN input when sheet opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _pinController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _startTimer() {
    _start = 60;
    _canResend = false;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_start == 0) {
        setState(() {
          _canResend = true;
          timer.cancel();
        });
      } else {
        setState(() {
          _start--;
        });
      }
    });
  }

  void _resendCode() async {
    if (authController.isLoading.value) return;

    authController.isLoading.value = true;

    Get.defaultDialog(
      content: LoadingWidget(),
      backgroundColor: Colors.transparent,
      title: '',
      barrierDismissible: false,
    );

    // Call API
    final success = await authController.sendCode(authController.currentPhone.value);

    // Close dialog safely
    if (Get.isDialogOpen == true) {
      Get.back();
    }

    authController.isLoading.value = false;

    if (success) {
      // Use post frame callback to update UI state
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _startTimer();
        AppSnackbar.success('code_resent_successfully'.tr);
      });
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        AppSnackbar.error('failed_to_resend_code'.tr);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Default Pinput theme
    final defaultPinTheme = PinTheme(
      width: 48,
      height: 48,
      textStyle: const TextStyle(
        fontSize: 20,
        color: Colors.black,
        fontWeight: FontWeight.w600,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
    );

    // Focused Pinput theme
    final focusedPinTheme = defaultPinTheme.copyDecorationWith(
      border: Border.all(color: const Color(0xFFFF6B35), width: 2),
    );

    // Submitted Pinput theme
    final submittedPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration?.copyWith(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300),
      ),
    );

    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: () {
                Get.back();
              },
              child: Row(
                children: [
                  Icon(Icons.arrow_back_ios),
                  Text(
                    'leading_text'.tr,
                    style: const TextStyle(
                      fontSize: 17,
                      fontFamily: StringConstants.SFPro,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14.0),
              child: Text(
                'phoneNumberCode'.tr,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  fontFamily: StringConstants.SFPro,
                  color: Colors.black,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text('receive5DigitCode'.tr,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontFamily: StringConstants.SFPro,
                  color: Colors.grey[700],
                )),
            const SizedBox(height: 24),
            Center(
              child: Pinput(
                length: 4,
                controller: _pinController,
                focusNode: _focusNode,
                autofocus: true,
                defaultPinTheme: defaultPinTheme,
                focusedPinTheme: focusedPinTheme,
                submittedPinTheme: submittedPinTheme,
                keyboardType: TextInputType.number,
                onCompleted: (pin) {
                  debugPrint('Completed: $pin');
                },
                onChanged: (value) {
                  debugPrint('Changed: $value');
                  setState(() {});
                },
                cursor: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(bottom: 9),
                      width: 22,
                      height: 1,
                      color: Colors.black,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 50),
            Center(
              child: Obx(() {
                return ElevatedButton(
                  onPressed: _pinController.text.length == 4 && !authController.isLoading.value
                      ? () async {
                          String otp = _pinController.text;
                          debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
                          debugPrint('🔘 VERIFY BUTTON PRESSED');
                          debugPrint('📝 OTP Entered: $otp');
                          debugPrint('📏 OTP Length: ${otp.length}');
                          debugPrint('🔒 Is Loading: ${authController.isLoading.value}');

                          // Show loading dialog
                          debugPrint('⏳ Showing Loading Dialog...');
                          Get.defaultDialog(
                            content: LoadingWidget(),
                            backgroundColor: Colors.transparent,
                            title: '',
                            barrierDismissible: false,
                          );

                          // Verify code and login
                          debugPrint('🚀 Calling verifyCodeAndLogin...');
                          final success = await authController.verifyCodeAndLogin(otp);
                          debugPrint('📊 Verification Result: $success');

                          // Close loading dialog safely
                          if (Get.isDialogOpen == true) {
                            debugPrint('❌ Closing Loading Dialog...');
                            Get.back();
                          }

                          if (success) {
                            debugPrint('✅ OTP Verification Successful!');
                            // Use post frame callback to ensure navigation happens after build
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              debugPrint('🔙 Closing OTP Sheet...');
                              // Close OTP sheet
                              if (Navigator.canPop(context)) {
                                Navigator.pop(context);
                              }

                              // Show success message
                              debugPrint('🎉 Showing Success Message...');
                              // AppSnackbar.success('login_success'.tr);

                              // Navigate to home
                              debugPrint('🏠 Navigating to Home Screen...');
                              Get.offAll(() => const BottomNavScreen());
                              debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
                            });
                          } else {
                            debugPrint('❌ OTP Verification Failed!');
                            debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
                          }
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _pinController.text.length == 4 ? const Color(0xFFFF6B35) : Colors.grey.shade200,
                    foregroundColor: _pinController.text.length == 4 ? Colors.white : Colors.grey.shade500,
                    minimumSize: Size(MediaQuery.of(context).size.width, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: authController.isLoading.value
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'continue_text'.tr,
                          style: const TextStyle(
                            fontSize: 18,
                            fontFamily: StringConstants.SFPro,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                );
              }),
            ),
            const SizedBox(height: 24),
            Center(
              child: _canResend
                  ? TextButton(
                      onPressed: _resendCode,
                      child: Text(
                        'recentCode'.tr,
                        style: const TextStyle(
                          fontSize: 16,
                          fontFamily: StringConstants.SFPro,
                          color: Color(0xFFFF6B35),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    )
                  : Text(
                      '${'recentCodeWithTimer'.tr} ${_start.toString().padLeft(2, '0')} )',
                      style: TextStyle(
                        fontSize: 16,
                        fontFamily: StringConstants.SFPro,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
