import 'package:elkitap/core/constants/icon_constants.dart';
import 'package:elkitap/core/constants/string_constants.dart';
import 'package:elkitap/core/widgets/common/custom_icon.dart';
import 'package:elkitap/modules/library/controllers/library_controller.dart';
import 'package:elkitap/modules/search/views/searching_view.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconly/iconly.dart';

PreferredSizeWidget customAppBar(ReadingListController controller, BuildContext context) {
  return AppBar(
    elevation: 0,
    leadingWidth: 140,
    leading: Obx(() {
      if (controller.selectedBooks.isEmpty) {
        return Row(
          children: [
            SizedBox(width: 12),
            GestureDetector(
              onTap: () {
                Get.back();
              },
              child: const Icon(
                Icons.arrow_back_ios,
              ),
            ),
            Text(
              'leading_text'.tr,
              style: TextStyle(fontSize: 17, fontFamily: StringConstants.SFPro, fontWeight: FontWeight.w500),
            ),
          ],
        );
      } else {
        return TextButton(
          onPressed: controller.selectAll,
          child: Text(
            controller.selectedBooks.length == controller.books.length ? 'deselectAll'.tr : 'selectAll'.tr,
            style: TextStyle(fontFamily: StringConstants.SFPro, fontSize: 16, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black),
          ),
        );
      }
    }),
    titleSpacing: 0,
    actions: [
      Obx(() {
        if (controller.selectedBooks.isEmpty) {
          return Row(
            children: [
              IconButton(
                icon: Icon(IconlyLight.search),
                onPressed: () {
                  Get.to(() => SearchingViewScreen());
                },
              ),
              PopupMenuButton<int>(
                icon: const Icon(Icons.more_vert),
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
                    : Colors.white,
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
                                controller.selectedBooks.length == controller.books.length && controller.books.length > 0 ? 'deselectAll'.tr : 'selectAll'.tr,
                                style: const TextStyle(
                                  fontFamily: StringConstants.SFPro,
                                ),
                              )),
                          const Spacer(),
                          CustomIcon(
                            title: IconConstants.d5,
                            height: 20,
                            width: 20,
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
          // ... (Selection mode code remains the same)
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
