import 'package:elkitap/data/network/api_edpoints.dart';
import 'package:elkitap/data/network/network_manager.dart';
import 'package:elkitap/modules/auth/controllers/auth_controller.dart';
import 'package:get/get.dart';

class PromoCodeController extends GetxController {
  final RxString errorMessage = ''.obs;
  final RxBool isLoading = false.obs;
  final RxBool isSuccess = false.obs;
  final Rx<Map<String, dynamic>?> promoData = Rx<Map<String, dynamic>?>(null);

  final AuthController _authController = Get.find<AuthController>();
  final NetworkManager _networkManager = Get.find<NetworkManager>();

  Future<Map<String, dynamic>?> validatePromoCode(String promoCode) async {
    if (promoCode.isEmpty) {
      errorMessage.value = 'Please enter a promo code';
      return null;
    }

    try {
      final previousDays = _authController.currentUser.value?.subscription?.daysRemaining ?? 0;

      isLoading.value = true;
      errorMessage.value = '';
      isSuccess.value = false;
      promoData.value = null;

      final response = await _networkManager.post(
        ApiEndpoints.promoCodes,
        body: {'promo_code': promoCode},
        sendToken: true,
      );

      isLoading.value = false;

      if (response['success'] == true) {
        isSuccess.value = true;
        promoData.value = Map<String, dynamic>.from(
          response['data'] ?? <String, dynamic>{},
        );
        await _authController.getMe();

        final newDays = _authController.currentUser.value?.subscription?.daysRemaining ?? 0;
        final addedDays = (newDays - previousDays).clamp(0, 10000);

        return {
          'data': promoData.value ?? <String, dynamic>{},
          'added_days': addedDays,
          'days_total': newDays,
        };
      } else {
        final error = response['error'] ?? 'Invalid promo code';
        errorMessage.value = error;
        return null;
      }
    } catch (e) {
      isLoading.value = false;
      errorMessage.value = 'An error occurred. Please try again.';
      return null;
    }
  }

  /// Reset all states
  void resetState() {
    isLoading.value = false;
    errorMessage.value = '';
    isSuccess.value = false;
    promoData.value = null;
  }
}
