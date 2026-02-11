import 'package:elkitap/core/constants/string_constants.dart';
import 'package:elkitap/modules/search/views/searching_view.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconly/iconly.dart';

class SearchHeader extends StatelessWidget {
  const SearchHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 26, bottom: 14),
            child: Text(
              'search'.tr,
              style: TextStyle(
                fontSize: 34,
                fontFamily: StringConstants.GilroyBold,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          GestureDetector(
            onTap: () => Get.to(() => SearchingViewScreen()),
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[800] : Colors.grey[100],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 14, right: 10),
                    child: Icon(IconlyLight.search, size: 24, color: Colors.grey),
                  ),
                  Expanded(
                    child: TextFormField(
                      maxLines: 1,
                      readOnly: true,
                      onTap: () {
                        Get.to(() => SearchingViewScreen());
                      },
                      onTapAlwaysCalled: true,
                      style: const TextStyle(color: Colors.black, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'search'.tr,
                        hintStyle: const TextStyle(
                          color: Colors.grey,
                          fontSize: 16,
                          fontFamily: StringConstants.SFPro,
                          fontWeight: FontWeight.w500,
                        ),
                        border: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        errorBorder: InputBorder.none,
                        disabledBorder: InputBorder.none,
                      ),
                      onChanged: (_) {
                        Get.to(() => SearchingViewScreen());
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
