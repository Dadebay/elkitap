import 'package:elkitap/data/network/api_edpoints.dart';
import 'package:elkitap/data/network/network_manager.dart';
import 'package:elkitap/data/network/token_managet.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SuggestionController extends GetxController {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController authorController = TextEditingController();
  final TextEditingController commentController = TextEditingController();

  final isLoading = false.obs;

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  @override
  void onClose() {
    titleController.dispose();
    authorController.dispose();
    commentController.dispose();
    super.onClose();
  }

  Future<bool> submitSuggestion() async {
    if (!formKey.currentState!.validate()) return false;

    // Check if user is logged in
    final TokenManager tokenManager = Get.find<TokenManager>();
    if (!tokenManager.isAuthenticated.value) {
      Get.snackbar(
        'loginRequired'.tr,
        'loginRequiredDesc'.tr,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    }

    isLoading.value = true;
    update();

    try {
      final NetworkManager networkManager = Get.find<NetworkManager>();

      final data = {
        "name": titleController.text,
        "description": commentController.text,
        "author": authorController.text,
      };

      final response = await networkManager.post(
        ApiEndpoints.suggests,
        body: data,
        sendToken: true,
      );

      isLoading.value = false;
      update();

      if (response['success'] == true) {
        _clearForm();
        return true;
      } else {
        // Check if it's an authentication error (401 status or auth-related message)
        final statusCode = response['statusCode'] ?? 0;
        final errorMessage = response['error']?.toString().toLowerCase() ?? '';
        final isAuthError =
            statusCode == 401 || errorMessage.contains('unauthorized') || errorMessage.contains('authentication') || errorMessage.contains('unauthenticated') || errorMessage.contains('login');

        Get.snackbar(
          isAuthError ? 'loginRequired'.tr : 'error'.tr,
          isAuthError ? 'loginRequiredDesc'.tr : (response['error'] ?? 'unknown_error'.tr),
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return false;
      }
    } catch (e) {
      isLoading.value = false;
      update();
      Get.snackbar(
        'error'.tr,
        e.toString(),
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    }
  }

  void _clearForm() {
    titleController.clear();
    authorController.clear();
    commentController.clear();
  }
}
