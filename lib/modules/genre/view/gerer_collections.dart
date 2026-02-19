import 'package:elkitap/core/constants/string_constants.dart';
import 'package:elkitap/core/widgets/states/error_state_widget.dart';
import 'package:elkitap/core/widgets/states/loading_widget.dart';
import 'package:elkitap/modules/genre/view/books_grid_screen_view.dart';
import 'package:elkitap/modules/store/controllers/all_books_controller.dart';
import 'package:elkitap/modules/store/controllers/all_geners_controller.dart';
import 'package:elkitap/modules/store/views/book_detail_view.dart';
import 'package:elkitap/core/widgets/states/empty_states.dart';

import 'package:elkitap/modules/store/widgets/popular_gerners_book_cart.dart';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CollectionsGenreSection extends StatelessWidget {
  final int id;

  const CollectionsGenreSection({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    final AllGenresController genreController = Get.find();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      genreController.fetchSubGenres(id);
    });

    return Obx(() {
      if (genreController.isLoading.value) {
        return LoadingWidget(removeBackWhite: true);
      }

      if (genreController.errorMessage.value.isNotEmpty) {
        return ErrorStateWidget(
          errorMessage: genreController.errorMessage.value,
          onRetry: () => genreController.fetchSubGenres(id),
        );
      }

      final genres = genreController.getChildGenres(id);

      if (genres.isEmpty) {
        return NoGenresAvailable(title: 'no_genres_available'.tr);
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 22),
          _CollectionsTitleWidget(genres: genres),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: genres.map((genre) {
              return GenreBookSection(
                genre: genre,
              );
            }).toList(),
          ),
        ],
      );
    });
  }
}

class GenreBookSection extends StatefulWidget {
  final dynamic genre;

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
    Get.delete<GetAllBooksController>(tag: 'genre_${widget.genre.id}');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (booksController.books.isEmpty && !booksController.isLoading.value) {
        return const SizedBox.shrink();
      }

      return Padding(
        padding: const EdgeInsets.only(bottom: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 32, right: 32, top: 10, bottom: 22),
              child: Container(
                height: 1.5,
                color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[300]!.withOpacity(0.25) : Colors.grey[300],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 32, bottom: 6),
              child: GestureDetector(
                onTap: () {
                  Get.to(() => BooksGridScreen(title: widget.genre.name, id: widget.genre.id));
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: MediaQuery.of(context).size.width - 80,
                      child: Text(
                        widget.genre.name,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 18,
                          fontFamily: StringConstants.GilroyRegular,
                          fontWeight: FontWeight.bold,
                        ),
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
            SizedBox(
              height: 150,
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

                // Books list
                return ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  physics: const BouncingScrollPhysics(),
                  itemCount: booksController.books.length,
                  itemBuilder: (context, index) {
                    final book = booksController.books[index];
                    final isLast = index == booksController.books.length - 1;

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
                        padding: EdgeInsets.only(right: isLast ? 0 : 14, bottom: 20, top: 8),
                        child: BookCardPopular(
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
                          discountPercentage: 1,
                        ),
                      ),
                    );
                  },
                );
              }),
            ),
          ],
        ),
      );
    });
  }
}

class _CollectionsTitleWidget extends StatefulWidget {
  final List<dynamic> genres;

  const _CollectionsTitleWidget({required this.genres});

  @override
  State<_CollectionsTitleWidget> createState() => _CollectionsTitleWidgetState();
}

class _CollectionsTitleWidgetState extends State<_CollectionsTitleWidget> {
  final Map<int, GetAllBooksController?> _controllers = {};

  @override
  void initState() {
    super.initState();
    // Wait for controllers to be created
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkControllers();
    });
  }

  void _checkControllers() {
    for (var genre in widget.genres) {
      try {
        _controllers[genre.id] = Get.find<GetAllBooksController>(
          tag: 'genre_${genre.id}',
        );
      } catch (e) {
        _controllers[genre.id] = null;
      }
    }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    // Check periodically for controllers if some are missing
    if (_controllers.values.any((c) => c == null)) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) _checkControllers();
      });
    }

    // Check if any controller has books
    bool hasAnyBooks = false;

    for (var controller in _controllers.values) {
      if (controller != null) {
        // Access the observable to trigger Obx reactivity
        if (controller.books.isNotEmpty) {
          hasAnyBooks = true;
          break;
        }
      }
    }

    // Show title initially if controllers aren't loaded yet
    if (_controllers.values.every((c) => c == null)) {
      hasAnyBooks = true;
    }

    if (!hasAnyBooks) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Text(
        "collections".tr,
        style: TextStyle(
          fontSize: 20,
          fontFamily: StringConstants.GilroyRegular,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
