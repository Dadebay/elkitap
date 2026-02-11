import 'package:elkitap/core/constants/icon_constants.dart';
import 'package:elkitap/core/constants/string_constants.dart';
import 'package:elkitap/core/widgets/common/custom_icon.dart';
import 'package:elkitap/modules/library/controllers/downloaded_controller.dart';
import 'package:elkitap/modules/library/controllers/library_main_controller.dart'; // Import the new controller
import 'package:elkitap/modules/library/controllers/reading_list_controller.dart';
import 'package:elkitap/modules/library/widgets/collections_section.dart';
import 'package:elkitap/modules/library/widgets/current_book_section.dart';
import 'package:elkitap/modules/library/widgets/library_header.dart';
import 'package:elkitap/modules/library/widgets/recently_opened_section.dart';
import 'package:elkitap/modules/library/widgets/suggest_content_widget.dart';
import 'package:elkitap/modules/notifications/controllers/notification_controller.dart';
import 'package:elkitap/modules/store/views/store_detail_view.dart';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

class MyLibraryViewScreen extends StatelessWidget {
  const MyLibraryViewScreen({super.key});

  Future<void> _onRefresh() async {
    final downloadController = Get.find<DownloadController>();
    final libraryMainController = Get.find<LibraryMainController>();

    try {
      if (Get.isRegistered<ReadingListController>()) {
        final readingListController = Get.find<ReadingListController>();
        await readingListController.getCounts();
      }
    } catch (e) {
      print('Refresh: ReadingListController error: $e');
    }

    try {
      if (Get.isRegistered<NotificationController>()) {
        final notificationController = Get.find<NotificationController>();
        await notificationController.fetchNotifications();
      }
    } catch (e) {
      print('Refresh: NotificationController error: $e');
    }

    await downloadController.getStorageInfo();
    libraryMainController.onInit();

    await Future.delayed(const Duration(milliseconds: 300));
  }

  @override
  Widget build(BuildContext context) {
    final libraryMainController = Get.find<LibraryMainController>();

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _onRefresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: Theme.of(context).brightness == Brightness.dark
                        ? [Color(0x001C1C1E), Color(0xFF1C1C1E)]
                        : [Color(0x00E5E5EA), Color(0xFFE5E5EA)],
                  ),
                ),
                child: Column(
                  children: [
                    LibraryHeader(),
                    Obx(() {
                      if (libraryMainController.lastOpenedBook.value != null) {
                        return GestureDetector(
                          onTap: () {
                            Get.to(
                              () => BookDetailView(
                                  book: libraryMainController
                                      .lastOpenedBook.value!),
                              transition: Transition.rightToLeft,
                              duration: const Duration(milliseconds: 300),
                            );
                          },
                          child: CurrentBookSection(
                              book:
                                  libraryMainController.lastOpenedBook.value!),
                        );
                      } else {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(24),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    shape: BoxShape.circle,
                                  ),
                                  child: CustomIcon(
                                    title: IconConstants.libraryFilled,
                                    height: 48,
                                    width: 48,
                                    color: Colors.grey[400],
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'no_books_opened_yet'.tr,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                    fontFamily: StringConstants.SFPro,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'start_reading_to_see_current'.tr,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontFamily: StringConstants.SFPro,
                                    color: Colors.grey[500],
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                    }),
                    RecentlyOpenedSection(),
                  ],
                ),
              ),
              CollectionsSection(controller: Get.find<DownloadController>()),
              const SuggestContentWidget(),
            ],
          ),
        ),
      ),
    );
  }
}
