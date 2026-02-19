import 'package:elkitap/core/constants/string_constants.dart';
import 'package:elkitap/modules/notifications/controllers/notification_controller.dart';
import 'package:elkitap/modules/notifications/widgets/notification_item.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class NotificationsView extends StatefulWidget {
  const NotificationsView({super.key});

  @override
  State<NotificationsView> createState() => _NotificationsViewState();
}

class _NotificationsViewState extends State<NotificationsView> {
  late final NotificationController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.put(NotificationController());
    controller.fetchNotifications();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF000000) : Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Custom App Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8).copyWith(bottom: 0),
              child: GestureDetector(
                onTap: () {
                  Get.back();
                },
                child: Row(
                  children: [
                    Icon(
                      Icons.arrow_back_ios,
                      color: isDark ? Colors.white : Colors.black,
                      size: 20,
                    ),
                    Text(
                      'leading_text'.tr,
                      style: TextStyle(
                        fontSize: 17,
                        color: isDark ? Colors.white : Colors.black,
                        fontFamily: StringConstants.SFPro,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8).copyWith(top: 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'notifications'.tr,
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                    fontFamily: StringConstants.GilroyBold,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
              ),
            ),
            Expanded(
              child: Obx(() {
                if (controller.isLoading.value) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFFFF5A3C),
                    ),
                  );
                }

                if (controller.suggestions.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assets/images/belle_full.png',
                          width: 150,
                          height: 150,
                          color: isDark ? Colors.white : null,
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'notifications_empty'.tr,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            fontFamily: StringConstants.GilroyBold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'notifications_empty_description'.tr,
                          style: TextStyle(
                            fontSize: 15,
                            color: isDark ? Colors.grey[500] : Colors.grey[600],
                            fontFamily: StringConstants.SFPro,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: controller.refreshNotifications,
                  color: const Color(0xFFFF5A3C),
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: controller.suggestions.length,
                    separatorBuilder: (context, index) => Divider(
                      height: 1,
                      color: isDark ? Colors.grey[800] : Colors.grey[200],
                    ),
                    itemBuilder: (context, index) {
                      final suggestion = controller.suggestions[index];
                      return NotificationItem(
                        suggestion: suggestion,
                      );
                    },
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
