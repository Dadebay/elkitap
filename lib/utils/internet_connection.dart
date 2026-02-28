import 'package:elkitap/core/constants/string_constants.dart';
import 'package:elkitap/core/theme/app_colors.dart';
import 'package:elkitap/data/controller/connection_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';

class ConnectionCheckView extends StatelessWidget {
  const ConnectionCheckView({super.key});

  @override
  Widget build(BuildContext context) {
    final connection = Get.find<ConnectionController>();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 🔥 Lottie Animation
              Lottie.asset(
                'assets/animations/no_internet_connection.json',
                width: 250,
                height: 250,
                repeat: true,
              ),

              const SizedBox(height: 16),

              Text(
                "noInternetConnection".tr,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  fontFamily: StringConstants.SFPro,
                  color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 8),

              Text(
                "checkNetworkSettings".tr,
                style: TextStyle(
                  fontSize: 14,
                  fontFamily: StringConstants.SFPro,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 32),

              // 🔥 Retry Button
              GestureDetector(
                onTap: () async {
                  // manually re-check internet
                  await connection.checkInitialConnection();
                  if (connection.hasConnection.value) {
                    Get.back();
                  }
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.mainColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    "retryButton".tr,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      fontFamily: StringConstants.SFPro,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Continue Offline Button
              GestureDetector(
                onTap: () {
                  Get.back();
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[700]! : Colors.grey[300]!,
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    "continueOffline".tr,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      fontFamily: StringConstants.SFPro,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
