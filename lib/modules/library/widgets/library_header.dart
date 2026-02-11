import 'package:elkitap/core/constants/icon_constants.dart';
import 'package:elkitap/core/constants/string_constants.dart';
import 'package:elkitap/data/network/token_managet.dart';
import 'package:elkitap/core/widgets/common/custom_icon.dart';
import 'package:elkitap/modules/auth/views/login_view.dart';
import 'package:elkitap/modules/notifications/controllers/notification_controller.dart';
import 'package:elkitap/modules/notifications/views/notifications_view.dart';
import 'package:elkitap/modules/profile/views/profile_view.dart';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

class LibraryHeader extends StatelessWidget {
  const LibraryHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final TokenManager tokenManager = Get.find<TokenManager>();
    final notificationController = Get.put(NotificationController());

    return Padding(
      padding: const EdgeInsets.all(20).copyWith(top: 15, bottom: 45),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () {
              if (tokenManager.isAuthenticated.value) {
                Get.to(() => const ProfileScreen());
              } else {
                Get.to(() => const AuthViewScreen());
              }
            },
            icon: CustomIcon(
              title: IconConstants.i1,
              height: 28,
              width: 28,
              color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
            ),
          ),
          Text(
            'myLibrary'.tr,
            style: const TextStyle(
              fontFamily: StringConstants.GilroyBold,
              fontSize: 28,
              fontWeight: FontWeight.w600,
            ),
          ),
          Stack(
            children: [
              IconButton(
                onPressed: () {
                  Get.to(
                    () => const NotificationsView(),
                    transition: Transition.rightToLeft,
                    duration: const Duration(milliseconds: 300),
                  );
                },
                icon: Image.asset(
                  'assets/images/belle.png',
                  height: 28,
                  width: 28,
                  color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                ),
              ),
              Obx(() {
                if (notificationController.unreadCount.value == 0) {
                  return const SizedBox();
                }
                return Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: const Color(0xFFFF5A3C),
                      shape: BoxShape.circle,
                    ),
                  ),
                );
              }),
            ],
          ),
        ],
      ),
    );
  }
}
