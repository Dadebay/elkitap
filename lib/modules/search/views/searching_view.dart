import 'package:elkitap/core/widgets/states/error_state_widget.dart';
import 'package:elkitap/core/widgets/states/loading_widget.dart';
import 'package:elkitap/core/theme/app_colors.dart';
import 'package:elkitap/modules/search/controllers/filter_controller.dart';
import 'package:elkitap/modules/search/controllers/search_controller.dart';
import 'package:elkitap/core/widgets/states/empty_states.dart';
import 'package:elkitap/modules/search/widgets/active_filters_bar.dart';
import 'package:elkitap/modules/search/widgets/result_section.dart';
import 'package:elkitap/modules/search/widgets/search_history_widget.dart';
import 'package:elkitap/modules/search/widgets/searching_header.dart';
import 'package:flutter/material.dart';
import 'package:elkitap/core/constants/string_constants.dart';
import 'package:get/get.dart';

class SearchingViewScreen extends StatefulWidget {
  const SearchingViewScreen({super.key});

  @override
  State<SearchingViewScreen> createState() => _SearchingViewScreenState();
}

class _SearchingViewScreenState extends State<SearchingViewScreen> {
  final ScrollController _scrollController = ScrollController();
  late SearchResultsController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.put(SearchResultsController());
    Get.put(FilterController());
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      controller.loadMoreBooks();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            SearchingHeader(),
            ActiveFiltersBar(
              onClearAll: () => controller.reSearchWithFilters(),
            ),
            Expanded(
              child: Obx(() {
                // Check if filters are active
                final hasFilters = Get.isRegistered<FilterController>() && Get.find<FilterController>().hasActiveFilters;

                if (controller.searchQuery.value.isEmpty && !hasFilters && controller.books.isEmpty) {
                  return buildSearchHistoryOrEmpty(context);
                }

                if (controller.isLoading.value) {
                  return LoadingWidget(removeBackWhite: true);
                }

                // Show error
                if (controller.errorMessage.value.isNotEmpty) {
                  return ErrorStateWidget(
                    errorMessage: controller.errorMessage.value,
                    onRetry: () => controller.searchAuthors(
                      controller.searchQuery.value,
                    ),
                  );
                }

                if (controller.authors.isEmpty && controller.books.isEmpty) {
                  return NoSearchResults();
                }

                return Column(
                  children: [
                    _buildSearchTabs(context),
                    Expanded(
                      child: SearchResultsSection(
                        controller: controller,
                        scrollController: _scrollController,
                      ),
                    ),
                  ],
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchTabs(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tabs = [
      ('all', 'all'.tr),
      ('books', 'books_t'.tr),
      ('authors', 'authors_title_t'.tr),
    ];
    return Obx(() => Container(
          margin: const EdgeInsets.fromLTRB(20, 8, 10, 4),
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.all(3),
          child: Row(
            children: tabs.map((tab) {
              final isSelected = controller.searchMode.value == tab.$1;
              return Expanded(
                child: GestureDetector(
                  onTap: () => controller.searchMode.value = tab.$1,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.mainColor : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      tab.$2,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        fontFamily: StringConstants.GilroyMedium,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                        color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ));
  }

  Widget buildSearchHistoryOrEmpty(BuildContext context) {
    if (controller.searchHistory.isEmpty) {
      return NoSearchResults();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'recentlySearched'.tr,
                style: TextStyle(
                  fontFamily: StringConstants.SFPro,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              GestureDetector(
                onTap: () {
                  controller.clearHistory();
                },
                child: Text(
                  'clear'.tr,
                  style: TextStyle(
                    fontFamily: StringConstants.SFPro,
                    color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: controller.searchHistory.length,
            itemBuilder: (context, index) {
              final query = controller.searchHistory[index];
              return Column(
                children: [
                  SearchHistoryItem(
                    query: query,
                    onTap: () => controller.searchFromHistory(query),
                    onDelete: () => controller.removeFromHistory(query),
                  ),
                  if (index < query.length - 1)
                    Divider(
                      color: Colors.grey[200],
                      height: 1,
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
