import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Global snackbar helper functions for consistent UI notifications
class AppSnackbar {
  AppSnackbar._();

  /// Show success snackbar with error handling
  static void success(String message, {String? title, Duration? duration}) {
    _showSnackbarSafely(
      title: title ?? 'success'.tr,
      message: message,
      backgroundColor: Colors.green.withOpacity(0.8),
      duration: duration,
    );
  }

  /// Show error snackbar with error handling
  static void error(String message, {String? title, Duration? duration}) {
    _showSnackbarSafely(
      title: title ?? 'error'.tr,
      message: message,
      backgroundColor: Colors.red.withOpacity(0.8),
      duration: duration,
    );
  }

  /// Show info snackbar with error handling
  static void info(String message, {String? title, Duration? duration}) {
    _showSnackbarSafely(
      title: title ?? 'info'.tr,
      message: message,
      backgroundColor: Colors.blue.withOpacity(0.8),
      duration: duration,
    );
  }

  /// Show warning snackbar with error handling
  static void warning(String message, {String? title, Duration? duration}) {
    _showSnackbarSafely(
      title: title ?? 'warning'.tr,
      message: message,
      backgroundColor: Colors.orange.withOpacity(0.8),
      duration: duration,
    );
  }

  /// Show custom snackbar with custom color and error handling
  static void custom({
    required String message,
    String? title,
    Color? backgroundColor,
    Color? textColor,
    Duration? duration,
  }) {
    _showSnackbarSafely(
      title: title ?? '',
      message: message,
      backgroundColor: backgroundColor ?? Colors.grey.withOpacity(0.8),
      textColor: textColor,
      duration: duration,
    );
  }

  /// Internal method to show snackbar with proper error handling
  static void _showSnackbarSafely({
    required String title,
    required String message,
    required Color backgroundColor,
    Color? textColor,
    Duration? duration,
  }) {
    try {
      // Check if GetX is properly initialized and has a context
      if (!Get.isRegistered<GetMaterialController>()) {
        debugPrint('GetX not initialized, cannot show snackbar: $message');
        return;
      }

      // Schedule snackbar to show after current frame
      WidgetsBinding.instance.addPostFrameCallback((_) {
        try {
          Get.snackbar(
            title,
            message,
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: backgroundColor,
            colorText: textColor ?? Colors.white,
            duration: duration ?? const Duration(seconds: 3),
            margin: const EdgeInsets.all(16),
            borderRadius: 12,
            isDismissible: true,
            dismissDirection: DismissDirection.horizontal,
          );
        } catch (e) {
          debugPrint('Error showing snackbar: $e');
        }
      });
    } catch (e) {
      debugPrint('Error preparing snackbar: $e');
    }
  }
}
