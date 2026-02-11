import 'package:elkitap/core/constants/string_constants.dart';
import 'package:elkitap/core/widgets/states/error_state_widget.dart';
import 'package:elkitap/core/widgets/states/loading_widget.dart';
import 'package:elkitap/modules/genre/view/books_grid_screen_view.dart';
import 'package:elkitap/modules/store/controllers/all_books_controller.dart';
import 'package:elkitap/modules/store/controllers/all_geners_controller.dart';
import 'package:elkitap/modules/store/views/store_detail_view.dart';
import 'package:elkitap/core/widgets/states/empty_states.dart';

import 'package:elkitap/modules/store/widgets/popular_gerners_book_cart.dart';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PopularByGenreSection extends StatelessWidget {
  const PopularByGenreSection({super.key});

  @override
  Widget build(BuildContext context) {
    final AllGenresController genreController = Get.find<AllGenresController>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 22),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Text(
            "popular_by_genre_t".tr,
            style: TextStyle(
              fontSize: 20,
              fontFamily: StringConstants.GilroyRegular,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Obx(() {
          if (genreController.isLoading.value) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: LoadingWidget(),
              ),
            );
          }

          // Show error message
          if (genreController.errorMessage.value.isNotEmpty) {
            return ErrorStateWidget(
              errorMessage: genreController.errorMessage.value,
              onRetry: () => genreController.refreshGenres(),
            );
          }

          // Show empty state
          if (genreController.genres.isEmpty) {
            return NoGenresAvailable(
              title: 'no_genres_available'.tr,
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: genreController.genres.map((genre) {
              return GenreBookSection(genre: genre);
            }).toList(),
          );
        }),
      ],
    );
  }
}

// Separate widget for each genre to manage its own books
class GenreBookSection extends StatefulWidget {
  final dynamic genre; // Replace with your Genre model type

  const GenreBookSection({
    super.key,
    required this.genre,
  });

  @override
  State<GenreBookSection> createState() => _GenreBookSectionState();
}

class _GenreBookSectionState extends State<GenreBookSection> {
  late GetAllBooksController booksController;
  bool isInitialized = false;

  @override
  void initState() {
    super.initState();

    booksController = Get.put(
      GetAllBooksController(),
      tag: 'genre_${widget.genre.id}',
    );

    _fetchGenreBooks();
  }

  Future<void> _fetchGenreBooks() async {
    if (!isInitialized) {
      isInitialized = true;
      await booksController.getBooksByGenre(widget.genre.id);
    }
  }

  @override
  void dispose() {
    // Clean up the controller when widget is disposed
    Get.delete<GetAllBooksController>(tag: 'genre_${widget.genre.id}');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.only(left: 32, right: 32),
            child: Container(height: 1.5, color: Colors.grey[300]),
          ),
          const SizedBox(height: 22),
          Padding(
            padding: const EdgeInsets.only(
              left: 32,
            ),
            child: GestureDetector(
              onTap: () {
                Get.to(() => BooksGridScreen(
                      title: widget.genre.name,
                      id: widget.genre.id,
                    ));
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                    widget.genre.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontFamily: StringConstants.GilroyRegular,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.arrow_forward_ios,
                    size: 18,
                    color: Colors.grey,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 124,
            child: Obx(() {
              // Show loading state for this genre
              if (booksController.isLoading.value) {
                return const Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                );
              }

              // Show error state
              if (booksController.errorMessage.value.isNotEmpty) {
                return ErrorStateWidget(
                  errorMessage: booksController.errorMessage.value,
                  onRetry: _fetchGenreBooks,
                );
              }

              // Show empty state
              if (booksController.books.isEmpty) {
                return NoGenresAvailable(
                  title: 'no_books_found'.tr,
                );
              }

              // final booksToShow = booksController.books.take(5).toList();

              return ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: booksController.books.length,
                separatorBuilder: (_, __) => const SizedBox(width: 14),
                itemBuilder: (context, index) {
                  final book = booksController.books[index];
                  return Padding(
                    padding: EdgeInsets.only(left: index == 0 ? 32 : 0),
                    child: BookCardPopular(
                      book: book,
                      index: index,
                      tabIndex: 0,
                      onTap: () {
                        Get.to(() => BookDetailView(
                              book: book,
                            ));
                      },
                      discountPercentage: 1,
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }
}
