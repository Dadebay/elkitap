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

class SubFeaturedBooksSection extends StatelessWidget {
  final int tabIndex;
  final int? genreId;
  const SubFeaturedBooksSection({required this.tabIndex, this.genreId, super.key});

  @override
  Widget build(BuildContext context) {
    final GetAllBooksController controller = genreId != null ? Get.find<GetAllBooksController>(tag: 'genre_recommended_$genreId') : Get.find<GetAllBooksController>();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () {
                    Get.to(() => BooksGridScreen(title: "new_in_genre".tr, id: genreId ?? 0, recommended: true));
                  },
                  child: Text(
                    "new_in_genre".tr,
                    style: TextStyle(fontSize: 18, fontFamily: StringConstants.GilroyBold, fontWeight: FontWeight.bold),
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
                onRetry: () => controller.getRecommendedBooks(),
              );
            }

            final books = controller.books;

            if (books.isEmpty) {
              return NoGenresAvailable(title: 'no_books_found'.tr);
            }

            return SizedBox(
              height: 270,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                physics: const BouncingScrollPhysics(),
                itemCount: books.length > 10 ? 10 : books.length,
                itemBuilder: (context, index) {
                  final book = books[index];
                  final isLast = index == (books.length > 10 ? 9 : books.length - 1);

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
                      padding: EdgeInsets.only(right: isLast ? 0 : 32, bottom: 24, top: 24, left: index == 0 ? 10 : 0),
                      child: BookCard(
                        index: index,
                        tabIndex: tabIndex,
                        book: book,
                        onTap: () {
                          Get.to(
                            () => BookDetailView(book: book),
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
