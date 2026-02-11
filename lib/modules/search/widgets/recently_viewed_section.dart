import 'package:elkitap/core/constants/string_constants.dart';
import 'package:elkitap/data/network/api_edpoints.dart';
import 'package:elkitap/core/widgets/states/loading_widget.dart';
import 'package:elkitap/modules/genre/view/books_grid_screen_view.dart';
import 'package:elkitap/modules/store/controllers/all_books_controller.dart';
import 'package:elkitap/modules/store/views/store_detail_view.dart';
import 'package:elkitap/modules/store/widgets/book_card_widget.dart';
import 'package:elkitap/core/widgets/states/empty_states.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class RecentlyViewedSection extends StatefulWidget {
  final int discountPercentage;
  const RecentlyViewedSection({super.key, required this.discountPercentage});

  @override
  State<RecentlyViewedSection> createState() => _RecentlyViewedSectionState();
}

class _RecentlyViewedSectionState extends State<RecentlyViewedSection> {
  late GetAllBooksController controller;

  @override
  void initState() {
    super.initState();

    controller = Get.put(
      GetAllBooksController(),
      tag: 'recently_viewed',
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.getRecentlyOpenedBooks();
    });
  }

  String getFullImageUrl(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) return '';
    return '${ApiEndpoints.imageBaseUrl}$imagePath';
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value && controller.books.isEmpty) {
        return LoadingWidget(removeBackWhite: true);
      }

      if (controller.errorMessage.value.isNotEmpty) {
        return SizedBox();
      }

      if (controller.books.isEmpty) {
        return NoGenresAvailable(title: 'no_books_found'.tr);
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding:
                const EdgeInsets.only(left: 24, right: 32, top: 30, bottom: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () => Get.to(() => BooksGridScreen(
                      title: 'recentlyOpened'.tr, isRecentlyOpened: true)),
                  child: Text(
                    'recently_viewed_t'.tr,
                    style: TextStyle(
                      fontSize: 20,
                      fontFamily: StringConstants.GilroyBold,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 155,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              physics: const BouncingScrollPhysics(),
              itemCount: controller.books.length,
              itemBuilder: (context, index) {
                final book = controller.books[index];
                final isLast = index == controller.books.length - 1;

                return TweenAnimationBuilder<double>(
                  duration: Duration(milliseconds: 300 + (index * 80)),
                  tween: Tween(begin: 0.0, end: 1.0),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) {
                    return Opacity(
                      opacity: value,
                      child: Transform.translate(
                        offset: Offset(20 * (1 - value), 0),
                        child: child,
                      ),
                    );
                  },
                  child: Padding(
                    padding: EdgeInsets.only(right: isLast ? 0 : 12),
                    child: BookCardReOpen(
                      book: book,
                      index: index,
                      tabIndex: 0,
                      onTap: () {
                        Get.to(
                          () => BookDetailView(book: book),
                          transition: Transition.rightToLeft,
                          duration: const Duration(milliseconds: 300),
                        );
                      },
                      progress: 0.0,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      );
    });
  }

  @override
  void dispose() {
    Get.delete<GetAllBooksController>(tag: 'recently_viewed');
    super.dispose();
  }
}
