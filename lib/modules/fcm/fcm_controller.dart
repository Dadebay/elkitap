import 'dart:developer';

import 'package:elkitap/data/network/api_edpoints.dart';
import 'package:elkitap/data/network/network_manager.dart';
import 'package:get/get.dart';

class FcmController extends GetxController {
  final NetworkManager _networkManager = Get.find<NetworkManager>();

  Future<void> updateFcmToken(String fcmToken) async {
    try {
      log('Sending FCM Token to backend: $fcmToken');
      final response = await _networkManager.patch(
        ApiEndpoints.updateFcmToken,
        body: {'fcm_token': fcmToken},
        sendToken: true,
      );

      if (response['success'] == true) {
        log('FCM Token updated successfully');
      } else {
        log('Failed to update FCM Token: ${response['error']}');
      }
    } catch (e) {
      log('Error updating FCM Token: $e');
    }
  }
}
