import 'package:elkitap/modules/search/widgets/genres_section.dart';
import 'package:elkitap/modules/search/widgets/recently_viewed_section.dart';
import 'package:elkitap/modules/search/widgets/search_header.dart';
import 'package:elkitap/modules/store/controllers/all_books_controller.dart';
import 'package:elkitap/modules/store/controllers/all_geners_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SearchViewScreen extends StatelessWidget {
  const SearchViewScreen({super.key});

  Future<void> _handleRefresh() async {
    // Get controllers
    // Get controllers safely
    final allGenresController = Get.find<AllGenresController>();

    final List<Future> futures = [
      allGenresController.refreshGenres(),
    ];

    if (Get.isRegistered<GetAllBooksController>(tag: 'recently_viewed')) {
      final recentlyViewedController =
          Get.find<GetAllBooksController>(tag: 'recently_viewed');
      futures.add(recentlyViewedController.getRecentlyOpenedBooks());
    }

    // Refresh concurrently
    await Future.wait(futures);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _handleRefresh,
          child: ListView(
            children: [
              SearchHeader(),
              RecentlyViewedSection(discountPercentage: 1),
              GenresSection(),
            ],
          ),
        ),
      ),
    );
  }
}
