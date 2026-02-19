import 'package:elkitap/core/constants/string_constants.dart';
import 'package:elkitap/core/widgets/states/error_state_widget.dart';
import 'package:elkitap/core/widgets/states/loading_widget.dart';
import 'package:elkitap/modules/genre/view/books_grid_screen_view.dart';
import 'package:elkitap/modules/store/controllers/all_books_controller.dart';
import 'package:elkitap/modules/store/views/book_detail_view.dart';
import 'package:elkitap/modules/store/widgets/book_card_widget.dart';
import 'package:elkitap/core/widgets/states/empty_states.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class FeaturedBooksSection extends StatelessWidget {
  final int tabIndex;
  const FeaturedBooksSection({required this.tabIndex, super.key});

  @override
  Widget build(BuildContext context) {
    final GetAllBooksController controller =
        Get.put(GetAllBooksController(), tag: 'featured_books_$tabIndex');

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (controller.books.isEmpty || controller.recommended.value == true) {
        if (tabIndex == 1) {
          controller.searchBooksWithFilters(
            recommendedFilter: true,
            withAudioFilter: true,
          );
        } else {
          controller.getRecommendedBooks();
        }
      }
    });

    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 26),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tabIndex == 0
                      ? "featured_books".tr
                      : 'featured_audiobooks'.tr,
                  style: TextStyle(
                      fontSize: 12,
                      fontFamily: StringConstants.SFPro,
                      color: Colors.grey),
                ),
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: () {
                    Get.to(() => BooksGridScreen(
                        title: "we_recommend_t".tr,
                        id: 0,
                        recommended: true,
                        isAudio: tabIndex == 1));
                  },
                  child: Text(
                    "we_recommend_t".tr,
                    style: TextStyle(
                        fontSize: 20,
                        fontFamily: StringConstants.GilroyBold,
                        fontStyle: FontStyle.normal,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          Obx(() {
            if (controller.isLoading.value) {
              return LoadingWidget(removeBackWhite: true);
            }

            if (controller.errorMessage.value.isNotEmpty) {
              return ErrorStateWidget(
                  errorMessage: controller.errorMessage.value,
                  onRetry: () => controller.getRecommendedBooks());
            }

            final books = controller.books;

            if (books.isEmpty) {
              return NoGenresAvailable(title: 'no_books_found'.tr);
            }

            return SizedBox(
              height: tabIndex == 1 ? 200 : 250,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                physics: const BouncingScrollPhysics(),
                itemCount: books.length > 10 ? 10 : books.length,
                itemBuilder: (context, index) {
                  final book = books[index];
                  final isLast =
                      index == (books.length > 10 ? 9 : books.length - 1);

                  return TweenAnimationBuilder<double>(
                    duration: Duration(milliseconds: 300 + (index * 80)),
                    tween: Tween(begin: 0.0, end: 1.0),
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
                      padding: EdgeInsets.only(
                          right: isLast ? 0 : 32, bottom: 24, top: 24, left: 0),
                      child: BookCard(
                        index: index,
                        tabIndex: tabIndex,
                        book: book,
                        onTap: () {
                          Get.to(
                            () => BookDetailView(
                              book: book,
                              isAudio: tabIndex == 1,
                            ),
                            transition: Transition.rightToLeft,
                            duration: const Duration(milliseconds: 300),
                          );
                        },
                        discountPercentage: 1,
                      ),
                    ),
                  );
                },
              ),
            );
          }),
        ],
      ),
    );
  }
}
