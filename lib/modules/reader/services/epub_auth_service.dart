import 'package:elkitap/modules/auth/widget/login_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class EpubAuthService {
  bool isAuthError(dynamic error) {
    final errorStr = error.toString().toLowerCase();
    return errorStr.contains('authentication required') ||
        errorStr.contains('unauthorized') ||
        errorStr.contains('unauthenticated') ||
        errorStr.contains('401');
  }

  bool isAuthErrorResponse(Map<String, dynamic> response) {
    if (response['success'] == false) {
      final statusCode = response['statusCode'];
      if (statusCode == 401) return true;

      final error = response['error']?.toString().toLowerCase() ?? '';
      final message =
          response['data']?['message']?.toString().toLowerCase() ?? '';

      return error.contains('authentication required') ||
          error.contains('unauthorized') ||
          error.contains('unauthenticated') ||
          message.contains('authentication required') ||
          message.contains('unauthorized') ||
          message.contains('unauthenticated');
    }
    return false;
  }

  void showLoginBottomSheet() {
    if (Get.isSnackbarOpen) {
      Get.closeAllSnackbars();
    }

    Get.bottomSheet(
      WillPopScope(
        onWillPop: () async {
          return false;
        },
        child: LoginBottomSheet(),
      ),
      isDismissible: true,
      enableDrag: true,
      isScrollControlled: true,
    );
  }
}