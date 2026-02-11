import 'package:elkitap/core/widgets/states/error_state_widget.dart';
import 'package:elkitap/core/widgets/states/loading_widget.dart';
import 'package:elkitap/modules/search/controllers/search_controller.dart';
import 'package:elkitap/core/widgets/states/empty_states.dart';
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
            Expanded(
              child: Obx(() {
                if (controller.searchQuery.value.isEmpty) {
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

                return SearchResultsSection(
                  controller: controller,
                  scrollController: _scrollController,
                );
              }),
            ),
          ],
        ),
      ),
    );
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
