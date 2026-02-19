import 'package:elkitap/core/constants/icon_constants.dart';
import 'package:elkitap/core/constants/string_constants.dart';
import 'package:elkitap/core/widgets/common/custom_icon.dart';
import 'package:elkitap/core/widgets/states/loading_widget.dart';
import 'package:elkitap/modules/library/controllers/downloaded_controller.dart';
import 'package:elkitap/modules/library/widgets/download_grid_view.dart';
import 'package:elkitap/modules/library/widgets/download_list_view.dart';
import 'package:elkitap/core/widgets/states/empty_states.dart';
import 'package:elkitap/modules/search/views/searching_view.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconly/iconly.dart';

class DownloadedListScreen extends StatelessWidget {
  const DownloadedListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(DownloadController());

    return Scaffold(
      appBar: _buildAppBar(controller, context),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
              padding: const EdgeInsets.only(left: 16, top: 16),
              child: Text(
                'downloaded'.tr,
                style: const TextStyle(
                  fontSize: 28,
                  fontFamily: StringConstants.GilroyBold,
                  fontWeight: FontWeight.bold,
                ),
              )),
          SizedBox(height: 16),
          Expanded(
            child: Obx(() {
              // Loading state
              if (controller.isLoading.value && controller.downloadedBooks.isEmpty) {
                return const Center(
                  child: LoadingWidget(),
                );
              }
              if (controller.downloadedBooks.isEmpty) {
                return EmptyCollectionWidget(
                  descriptionKey: 'emptyDownloadedDesc',
                );
              }
              return controller.isGridView.value ? DownloadedGridView(controller: controller) : DownloadedListView(controller: controller);
            }),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(DownloadController controller, BuildContext context) {
    return AppBar(
      leadingWidth: 140,
      leading: Obx(() {
        if (controller.selectedBooks.isEmpty) {
          return GestureDetector(
            onTap: () {
              Get.back();
            },
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 16.0),
                  child: Icon(Icons.arrow_back_ios),
                ),
                Text(
                  'leading_text'.tr,
                  style: TextStyle(fontSize: 17, fontFamily: StringConstants.SFPro, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          );
        } else {
          return TextButton(
            onPressed: controller.selectAll,
            child: Text(
              controller.selectedBooks.length == controller.downloadedBooks.length ? 'deselectAll'.tr : 'selectAll'.tr,
              style: TextStyle(fontFamily: StringConstants.SFPro, fontSize: 16, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black),
            ),
          );
        }
      }),
      actions: [
        Obx(() {
          if (controller.selectedBooks.isEmpty) {
            return Row(
              children: [
                IconButton(
                  icon: const Icon(
                    IconlyLight.search,
                  ),
                  onPressed: () {
                    Get.to(() => SearchingViewScreen());
                  },
                ),
                PopupMenuButton<int>(
                  icon: const Icon(
                    Icons.more_vert,
                  ),
                  offset: const Offset(0, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: Colors.grey.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.black.withOpacity(0.6) // dark mode
                      : Colors.white.withOpacity(0.85),
                  elevation: 8,
                  itemBuilder: (context) => [
                    PopupMenuItem<int>(
                      value: 0, // Unique value for selectAll
                      child: SizedBox(
                        width: 200,
                        child: Row(
                          children: [
                            const SizedBox(width: 8),
                            Obx(() => Text(
                                  controller.selectedBooks.length == controller.downloadedBooks.length ? 'deselectAll'.tr : 'selectAll'.tr,
                                  style: const TextStyle(
                                    fontFamily: StringConstants.SFPro,
                                  ),
                                )),
                            const Spacer(),
                            CustomIcon(
                              title: IconConstants.d5,
                              height: 24,
                              width: 24,
                              color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const PopupMenuDivider(
                      height: 4,
                    ),
                    PopupMenuItem<int>(
                      value: 1,
                      child: SizedBox(
                        width: 200,
                        child: Row(
                          children: [
                            if (controller.isGridView.value)
                              const Icon(
                                Icons.check,
                                size: 18,
                              ),
                            const SizedBox(width: 8),
                            Text('gridView'.tr,
                                style: TextStyle(
                                  fontFamily: StringConstants.SFPro,
                                )),
                            const Spacer(),
                            CustomIcon(title: IconConstants.d8, height: 24, width: 24, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black)
                          ],
                        ),
                      ),
                    ),
                    const PopupMenuDivider(),
                    PopupMenuItem<int>(
                      value: 2,
                      child: SizedBox(
                        width: 200,
                        child: Row(
                          children: [
                            if (!controller.isGridView.value)
                              const Icon(
                                Icons.check,
                                size: 18,
                              ),
                            const SizedBox(width: 8),
                            Text('listView'.tr,
                                style: TextStyle(
                                  fontFamily: StringConstants.SFPro,
                                )),
                            const Spacer(),
                            CustomIcon(title: IconConstants.d9, height: 24, width: 24, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black),
                          ],
                        ),
                      ),
                    ),
                  ],
                  onSelected: (value) {
                    if (value == 0) {
                      controller.selectAll();
                    } else if (value == 1) {
                      controller.isGridView.value = true;
                    } else if (value == 2) {
                      controller.isGridView.value = false;
                    }
                  },
                ),
              ],
            );
          } else {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => controller.showRemoveDialog(Get.context!),
                    child: Text(
                      'remove'.tr,
                      style: TextStyle(
                        fontFamily: StringConstants.SFPro,
                        color: Colors.red,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => controller.selectedBooks.clear(),
                    child: Text(
                      'done'.tr,
                      style: TextStyle(
                        fontFamily: StringConstants.SFPro,
                        color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }
        }),
      ],
    );
  }
}
