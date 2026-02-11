import 'package:elkitap/data/network/api_edpoints.dart';
import 'package:elkitap/data/network/network_manager.dart';
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
        Get.snackbar(
          'error'.tr,
          response['message'] ?? 'unknown_error'.tr,
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
