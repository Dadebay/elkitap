import 'package:elkitap/core/constants/icon_constants.dart';
import 'package:elkitap/core/constants/string_constants.dart';
import 'package:elkitap/core/widgets/common/custom_icon.dart';
import 'package:elkitap/modules/auth/views/login_view.dart';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ErrorStateWidget extends StatelessWidget {
  final VoidCallback onRetry;
  final String? errorMessage;

  const ErrorStateWidget({
    Key? key,
    required this.onRetry,
    this.errorMessage,
  }) : super(key: key);

  void _handleError(BuildContext context) {
    if (errorMessage?.toLowerCase().contains('authentication') ?? false) {
      Get.to(() => const AuthViewScreen());
    } else {
      onRetry();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAuthError = errorMessage?.toLowerCase().contains('authentication') ?? false;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Error icon
            isAuthError
                ? CustomIcon(title: IconConstants.libraryFilled, height: 62, width: 62, color: Colors.black)
                : Icon(
                    Icons.cloud_off_rounded,
                    size: 50,
                    color: Colors.grey[400],
                  ),

            const SizedBox(height: 32),

            // Title
            Text(
              isAuthError ? 'loginRequired'.tr : 'connectionError'.tr,
              style: const TextStyle(
                fontSize: 22,
                fontFamily: StringConstants.SFPro,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 12),

            // Description
            Text(
              isAuthError ? 'loginRequiredDesc'.tr : 'connectionErrorDesc'.tr,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey[600],
                fontFamily: StringConstants.SFPro,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 32),

            // Action button
            ElevatedButton(
              onPressed: () => _handleError(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF5A3C),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                isAuthError ? 'login'.tr : 'retry'.tr,
                style: const TextStyle(
                  fontSize: 16,
                  fontFamily: StringConstants.SFPro,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
