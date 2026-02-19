import 'package:elkitap/core/constants/string_constants.dart';
import 'package:elkitap/core/widgets/states/loading_widget.dart';

import 'package:elkitap/modules/genre/view/books_grid_screen_view.dart';
import 'package:elkitap/modules/store/controllers/all_books_controller.dart';
import 'package:elkitap/modules/store/views/book_detail_view.dart';
import 'package:elkitap/modules/store/widgets/book_card_widget.dart';
import 'package:elkitap/core/widgets/states/empty_states.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class RecentlyOpenedSection extends StatefulWidget {
  const RecentlyOpenedSection({super.key});

  @override
  State<RecentlyOpenedSection> createState() => _RecentlyOpenedSectionState();
}

class _RecentlyOpenedSectionState extends State<RecentlyOpenedSection> {
  late GetAllBooksController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.put(
      GetAllBooksController(),
      tag: 'recently_opened',
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.getRecentlyOpenedBooks();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value && controller.books.isEmpty) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 32, right: 32, bottom: 12),
              child: Text(
                'recentlyOpened'.tr,
                style: TextStyle(
                  fontSize: 20,
                  fontFamily: StringConstants.GilroyBold,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            LoadingWidget(removeBackWhite: true),
          ],
        );
      }
      if (controller.errorMessage.value.isNotEmpty) SizedBox();
      if (controller.books.isEmpty) NoGenresAvailable(title: 'no_books_found'.tr);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            child: Divider(
              height: 32,
              color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[300]!.withOpacity(0.25) : Colors.grey[300],
              thickness: 1.5,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 32, right: 32, bottom: 10),
            child: GestureDetector(
              onTap: () {
                Get.to(() => BooksGridScreen(title: 'recentlyOpened'.tr, isRecentlyOpened: true));
              },
              child: Text(
                'recentlyOpened'.tr,
                style: TextStyle(
                  fontSize: 22,
                  fontFamily: StringConstants.GilroyBold,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          Container(
            height: 170,
            margin: EdgeInsets.only(bottom: 24),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 32),
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
                    padding: EdgeInsets.only(right: isLast ? 0 : 12, top: 8, bottom: 8),
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
                      progress: (double.tryParse(book.progress ?? '0') ?? 0.0) / 100,
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
    Get.delete<GetAllBooksController>(tag: 'recently_opened');
    super.dispose();
  }
}
