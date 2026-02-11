import 'package:elkitap/core/constants/icon_constants.dart';
import 'package:elkitap/core/constants/string_constants.dart';
import 'package:elkitap/core/theme/app_colors.dart';
import 'package:elkitap/core/widgets/common/custom_icon.dart';
import 'package:elkitap/modules/library/controllers/downloaded_controller.dart';
import 'package:elkitap/modules/library/controllers/note_controller.dart';
import 'package:elkitap/modules/library/controllers/reading_list_controller.dart';
import 'package:elkitap/modules/library/views/downloaded_book_view.dart';
import 'package:elkitap/modules/library/views/notes_view.dart';
import 'package:elkitap/modules/library/views/reading_list_view.dart';
import 'package:elkitap/modules/paymant/controller/payment_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CollectionsSection extends StatefulWidget {
  final DownloadController controller;
  const CollectionsSection({super.key, required this.controller});

  @override
  State<CollectionsSection> createState() => _CollectionsSectionState();
}

class _CollectionsSectionState extends State<CollectionsSection> {
  late ReadingListController readingListController;
  late NotesController notesController;
  final PaymentController paymentController = Get.find<PaymentController>();

  @override
  void initState() {
    super.initState();

    readingListController = Get.put(ReadingListController());
    notesController = Get.put(
      NotesController(),
      tag: 'collections_notes',
    );

    _fetchCounts();
  }

  Future<void> _fetchCounts() async {
    await readingListController.getCounts();
    await notesController.fetchBookNotes();
  }

  @override
  void dispose() {
    Get.delete<NotesController>(tag: 'collections_notes');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final downloadedCount = widget.controller.downloadedBooks.length;

      final collections = [
        {
          "icon": IconConstants.m1,
          "title": 'wantToRead'.tr,
          "count": readingListController.readCount.value,
          "type": "read",
          "isLoading": readingListController.isLoading.value,
        },
        {
          "icon": IconConstants.m2,
          "title": 'wantToListen'.tr,
          "count": readingListController.listenCount.value,
          "type": "listen",
          "isLoading": readingListController.isLoading.value,
        },
        {
          "icon": IconConstants.m3,
          "title": 'notes'.tr,
          "count": notesController.totalCount.value,
          "type": "notes",
          "isLoading": false,
        },
        {
          "icon": IconConstants.m4,
          "title": 'finished'.tr,
          "count": readingListController.finishedCount.value,
          "type": "finished",
          "isLoading": readingListController.isLoading.value,
        },
        {
          "icon": IconConstants.m5,
          "title": 'downloaded'.tr,
          "count": downloadedCount,
          "type": "downloaded",
          "isLoading": false,
        },
      ];

      return Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'collections'.tr,
              style: TextStyle(fontSize: 22, fontFamily: StringConstants.GilroyBold, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 14),
            Container(
              height: 1,
              color: Theme.of(context).brightness == Brightness.dark ? AppColors.dividerColor : Colors.grey[200],
            ),
            ...collections.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final isLoading = item["isLoading"] as bool;

              return Column(
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CustomIcon(
                      title: item["icon"].toString(),
                      height: 24,
                      width: 24,
                      color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                    ),
                    title: Text(
                      item["title"] as String,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontFamily: StringConstants.SFPro,
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        isLoading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                item["count"].toString(),
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: StringConstants.SFPro,
                                  fontSize: 16,
                                ),
                              ),
                        const SizedBox(width: 16),
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 18,
                          color: Colors.grey[200],
                        ),
                      ],
                    ),
                    onTap: () {
                      final type = item["type"] as String;

                      if (type == "read") {
                        Get.to(() => ReadingListScreen(type: 'read', title: 'wantToRead'.tr))?.then((_) => _fetchCounts());
                      } else if (type == "listen") {
                        Get.to(() => ReadingListScreen(type: 'listen', title: 'wantToListen'.tr))?.then((_) => _fetchCounts());
                      } else if (type == "notes") {
                        Get.to(() => const NotesScreen())?.then((_) => _fetchCounts());
                      } else if (type == "downloaded") {
                        Get.to(() => const DownloadedListScreen())?.then((_) => _fetchCounts());
                      } else if (type == "finished") {
                        Get.to(() => ReadingListScreen(type: 'finished', title: 'finished'.tr))?.then((_) => _fetchCounts());
                      }
                    },
                  ),
                  if (index != collections.length - 1)
                    Container(
                      height: 1,
                      color: Theme.of(context).brightness == Brightness.dark ? AppColors.dividerColor : Colors.grey[200],
                    ),
                ],
              );
            }),
          ],
        ),
      );
    });
  }
}
