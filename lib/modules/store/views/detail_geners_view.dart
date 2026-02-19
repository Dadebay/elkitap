import 'dart:developer';

import 'package:elkitap/core/constants/string_constants.dart';
import 'package:elkitap/core/widgets/states/error_state_widget.dart';
import 'package:elkitap/core/widgets/states/loading_widget.dart';
import 'package:elkitap/modules/genre/view/books_grid_screen_view.dart';
import 'package:elkitap/modules/store/controllers/all_books_controller.dart';
import 'package:elkitap/modules/store/controllers/book_detail_controller.dart';
import 'package:elkitap/modules/store/model/book_detail_model.dart';
import 'package:elkitap/modules/store/views/book_detail_view.dart';
import 'package:elkitap/core/widgets/states/empty_states.dart';
import 'package:elkitap/modules/store/widgets/popular_gerners_book_cart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class GenreBooksDetailSection extends StatelessWidget {
  final String bookId; // Add bookId parameter to find controller with tag

  const GenreBooksDetailSection({
    super.key,
    required this.bookId,
  });

  @override
  Widget build(BuildContext context) {
    // Find controller with the correct tag
    final controller = Get.find<BooksDetailController>(tag: bookId);

    return Obx(() {
      // Get genres from controller
      final genres = controller.bookDetail.value?.genres ?? [];

      if (genres.isEmpty) {
        return NoGenresAvailable(
          title: 'no_genres_available'.tr,
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          ...genres.map((genre) => _GenreBookList(genre: genre)).toList(),
        ],
      );
    });
  }
}

class _GenreBookList extends StatefulWidget {
  final GenreBook genre;

  const _GenreBookList({
    required this.genre,
  });

  @override
  State<_GenreBookList> createState() => _GenreBookListState();
}

class _GenreBookListState extends State<_GenreBookList> {
  late GetAllBooksController booksController;
  bool isInitialized = false;

  @override
  void initState() {
    super.initState();
    booksController = Get.put(
      GetAllBooksController(),
      tag: 'genre_${widget.genre.id}',
    );

    booksController = Get.put(
      GetAllBooksController(),
      tag: 'genre_${widget.genre.id}',
    );

    // Fetch books AFTER the build is complete
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchGenreBooks();
    });
  }

  Future<void> _fetchGenreBooks() async {
    if (!isInitialized) {
      isInitialized = true;
      await booksController.getBooksByGenre(widget.genre.id);
    }
    // _fetchGenreBooks();
  }

  @override
  void dispose() {
    // Clean up the controller when widget is disposed
    Get.delete<GetAllBooksController>(tag: 'genre_${widget.genre.id}');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Genre Title with Arrow
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: GestureDetector(
            onTap: () {
              Get.to(() => BooksGridScreen(title: widget.genre.name, id: widget.genre.id));
            },
            child: Row(
              children: [
                SizedBox(
                  width: MediaQuery.of(context).size.width - 96,
                  child: Text(
                    widget.genre.name,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 18,
                      fontFamily: StringConstants.GilroyRegular,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(width: 8),
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.grey,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 4),

        // Books Horizontal List
        Obx(() {
          // Loading State
          if (booksController.isLoading.value) {
            return const SizedBox(
              height: 124,
              child: Center(
                child: LoadingWidget(),
              ),
            );
          }

          // Error State
          if (booksController.errorMessage.value.isNotEmpty) {
            return ErrorStateWidget(
              errorMessage: booksController.errorMessage.value,
              onRetry: () => booksController.getBooksByGenre(widget.genre.id),
            );
          }

          // Empty State
          if (booksController.books.isEmpty) {
            return NoGenresAvailable(title: 'no_books_found'.tr);
          }

          return SizedBox(
            height: 150,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: booksController.books.length,
              itemBuilder: (context, index) {
                final book = booksController.books[index];
                return Padding(
                  padding: EdgeInsets.only(
                    top: 12,
                    bottom: 18,
                    left: index == 0 ? 32 : 7,
                    right: index == booksController.books.length - 1 ? 32 : 7,
                  ),
                  child: BookCardPopular(
                    book: book,
                    index: index,
                    tabIndex: 0,
                    onTap: () {
                      log('Book clicked: ${book.name} (ID: ${book.id})');
                      Get.to(() => BookDetailView(book: book), preventDuplicates: false);
                    },
                    discountPercentage: 1,
                  ),
                );
              },
            ),
          );
        }),
        const SizedBox(height: 24),
      ],
    );
  }
}
