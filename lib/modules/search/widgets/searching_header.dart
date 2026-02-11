import 'package:elkitap/core/constants/string_constants.dart';
import 'package:elkitap/modules/search/controllers/search_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'dart:async';

import 'package:iconly/iconly.dart';

class SearchingHeader extends StatefulWidget {
  const SearchingHeader({super.key});

  @override
  State<SearchingHeader> createState() => _SearchingHeaderState();
}

class _SearchingHeaderState extends State<SearchingHeader> {
  Timer? _debounceTimer;

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String value, SearchResultsController controller) {
    // Cancel previous timer
    _debounceTimer?.cancel();

    // Create new timer
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      // Only search if the value hasn't changed
      if (controller.searchController.text == value) {
        controller.searchAuthors(value);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final SearchResultsController controller = Get.find<SearchResultsController>();

    return Padding(
      padding: const EdgeInsets.only(top: 16, left: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
              icon: Icon(Icons.arrow_back_ios),
              onPressed: () {
                _debounceTimer?.cancel();
                Get.back();
              }),
          Expanded(
            child: Container(
              height: 45,
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[800] : Colors.grey[100],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 14, right: 12),
                    child: Icon(IconlyLight.search, size: 24, color: Colors.grey),
                  ),
                  Expanded(
                    child: TextFormField(
                      controller: controller.searchController,
                      maxLines: 1,
                      style: const TextStyle(
                        fontSize: 14,
                        fontFamily: StringConstants.SFPro,
                      ),
                      decoration: InputDecoration(
                        hintText: 'search'.tr,
                        hintStyle: TextStyle(
                          color: Colors.grey,
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                        ),
                        border: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        errorBorder: InputBorder.none,
                        disabledBorder: InputBorder.none,
                      ),
                      onChanged: (value) {
                        _onSearchChanged(value, controller);
                      },
                      onFieldSubmitted: (value) {
                        _debounceTimer?.cancel();
                        controller.searchAuthors(value);
                      },
                    ),
                  ),
                  Obx(() {
                    if (controller.searchQuery.value.isNotEmpty) {
                      return GestureDetector(
                        onTap: () {
                          _debounceTimer?.cancel();
                          controller.clearSearch();
                        },
                        child: Container(
                          height: 20,
                          width: 20,
                          margin: const EdgeInsets.only(right: 10),
                          decoration: const BoxDecoration(
                            color: Colors.grey,
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.close,
                              size: 14,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      );
                    }
                    return const SizedBox(width: 10);
                  }),
                ],
              ),
            ),
          ),
          SizedBox(width: 8),
        ],
      ),
    );
  }
}
