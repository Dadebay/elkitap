import 'package:elkitap/core/constants/string_constants.dart';
import 'package:elkitap/core/theme/app_colors.dart';
import 'package:elkitap/modules/search/controllers/filter_controller.dart';
import 'package:elkitap/modules/search/controllers/search_controller.dart';
import 'package:elkitap/modules/search/views/filter_page.dart';
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
  final SearchResultsController controller = Get.find<SearchResultsController>();

  @override
  void dispose() {
    _debounceTimer?.cancel();
    controller.searchController.text = '';
    super.dispose();
  }

  void _onSearchChanged(String value, SearchResultsController controller) {
    _debounceTimer?.cancel();
    print('⌨️ onChanged: "$value"');
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (controller.searchController.text == value) {
        print('⌨️ debounce fired: searchAuthors("$value")');
        controller.searchAuthors(value);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, left: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
              padding: EdgeInsets.zero,
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
                      autofocus: true,
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
                        final hasFilters = Get.isRegistered<FilterController>() && Get.find<FilterController>().hasActiveFilters;
                        print('⌨️ onFieldSubmitted: "$value", hasFilters=$hasFilters, searchQuery="${controller.searchQuery.value}"');

                        if (value.trim().isEmpty && hasFilters) {
                          // Query empty but filters active — just close keyboard, keep results
                          print('⌨️ OK pressed with empty query + active filters → keeping results, closing keyboard');
                          FocusScope.of(context).unfocus();
                          return;
                        }
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
          _buildFilterButton(context),
          const SizedBox(width: 4),
        ],
      ),
    );
  }

  Widget _buildFilterButton(BuildContext context) {
    final filterController = Get.find<FilterController>();
    return Obx(() {
      final filterCount = filterController.activeFilterCount;
      return GestureDetector(
        onTap: () => _showFilterSheet(context),
        child: Container(
          width: 40,
          height: 40,
          margin: const EdgeInsets.only(left: 4),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(
                IconlyLight.filter,
                size: 24,
                color: filterCount > 0 ? AppColors.mainColor : (Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black),
              ),
              if (filterCount > 0)
                Positioned(
                  top: 2,
                  right: 2,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: const BoxDecoration(
                      color: AppColors.mainColor,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '$filterCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    });
  }

  void _showFilterSheet(BuildContext context) {
    Get.to(
      () => FilterPage(
        onApply: () {
          final searchController = Get.find<SearchResultsController>();
          searchController.reSearchWithFilters();
        },
      ),
      transition: Transition.cupertino,
    );
  }
}
