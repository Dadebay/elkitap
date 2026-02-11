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
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 8),

               Text(
                "checkNetworkSettings".tr,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 24),

              // 🔥 Retry Button
              GestureDetector(
                onTap: () async {
                  // manually re-check internet
                  await connection.checkInitialConnection();
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  child:  Text(
                    "retryButton".tr,
                    style: TextStyle(
                      color: Colors.blue,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
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
