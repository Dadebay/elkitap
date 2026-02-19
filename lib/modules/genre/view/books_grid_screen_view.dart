import 'package:elkitap/core/widgets/navigation/custom_appbar.dart';
import 'package:elkitap/core/widgets/states/error_state_widget.dart';
import 'package:elkitap/core/widgets/states/loading_widget.dart';
import 'package:elkitap/modules/genre/widget/book_grid_cart.dart';
import 'package:elkitap/modules/store/controllers/all_books_controller.dart';

import 'package:elkitap/modules/store/views/book_detail_view.dart';
import 'package:elkitap/core/widgets/states/empty_states.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class BooksGridScreen extends StatefulWidget {
  final String title;
  final int? id;
  final bool recommended;
  final bool isWeekly;
  final bool isRecentlyOpened;
  final bool isWantToRead;
  final bool isWantToListen;
  final bool isMyBooks;
  final bool isAudio;

  const BooksGridScreen({
    required this.title,
    this.id,
    this.recommended = false,
    this.isWeekly = false,
    this.isRecentlyOpened = false,
    this.isWantToRead = false,
    this.isWantToListen = false,
    this.isMyBooks = false,
    this.isAudio = false,
    super.key,
  });

  @override
  State<BooksGridScreen> createState() => _BooksGridScreenState();
}

class _BooksGridScreenState extends State<BooksGridScreen> {
  late final GetAllBooksController booksController;
  bool isInitialized = false;
  final ScrollController scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    final tag = "books_${widget.id}_${widget.recommended}_${widget.isWeekly}_${widget.isRecentlyOpened}_${widget.isWantToRead}_${widget.isWantToListen}_${widget.isMyBooks}_${widget.isAudio}";

    if (Get.isRegistered<GetAllBooksController>(tag: tag)) {
      booksController = Get.find<GetAllBooksController>(tag: tag);
    } else {
      booksController = Get.put(GetAllBooksController(), tag: tag);
    }

    scrollController.addListener(() {
      if (scrollController.position.pixels >= scrollController.position.maxScrollExtent - 100) {
        booksController.loadMoreBooks();
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchBooks();
    });
  }

  Future<void> _fetchBooks() async {
    if (isInitialized) return;
    isInitialized = true;

    if (widget.isRecentlyOpened) {
      await booksController.getRecentlyOpenedBooks();
    } else if (widget.isWantToRead) {
      await booksController.getBooksWantToRead();
    } else if (widget.isWantToListen) {
      await booksController.getBooksWantToListen();
    } else if (widget.isMyBooks) {
      await booksController.getMyBooks();
    } else if (widget.recommended) {
      if (widget.isAudio) {
        await booksController.searchBooksWithFilters(recommendedFilter: true, withAudioFilter: true);
      } else {
        await booksController.getRecommendedBooks();
      }
    } else if (widget.isWeekly) {
      if (widget.isAudio) {
        await booksController.searchBooksWithFilters(topOfTheWeekFilter: true, withAudioFilter: true);
      } else {
        await booksController.getTopOfTheWeekBooks();
      }
    } else if (widget.id != null) {
      if (widget.isAudio) {
        await booksController.searchBooksWithFilters(genreIdFilter: widget.id, withAudioFilter: true);
      } else {
        await booksController.getBooksByGenre(widget.id!);
      }
    }
  }

  Future<void> _handleRefresh() async {
    isInitialized = false;
    await _fetchBooks();
    isInitialized = true;
  }

  @override
  void dispose() {
    final tag = "books_${widget.id}_${widget.recommended}_${widget.isWeekly}_${widget.isRecentlyOpened}_${widget.isWantToRead}_${widget.isWantToListen}_${widget.isMyBooks}_${widget.isAudio}";
    if (Get.isRegistered<GetAllBooksController>(tag: tag)) {
      Get.delete<GetAllBooksController>(tag: tag);
    }
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: widget.title.tr,
        leadingText: 'leading_text'.tr,
      ),
      body: Obx(() {
        if (booksController.isLoading.value && booksController.books.isEmpty) {
          return const Center(child: LoadingWidget(removeBackWhite: true));
        }

        if (booksController.errorMessage.value.isNotEmpty && booksController.books.isEmpty) {
          return RefreshIndicator(
            onRefresh: _handleRefresh,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: SizedBox(
                height: MediaQuery.of(context).size.height - AppBar().preferredSize.height - MediaQuery.of(context).padding.top,
                child: ErrorStateWidget(
                  errorMessage: booksController.errorMessage.value,
                  onRetry: () {
                    _fetchBooks();
                  },
                ),
              ),
            ),
          );
        }

        if (booksController.books.isEmpty) {
          return RefreshIndicator(
            onRefresh: _handleRefresh,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Center(
                      child: NoGenresAvailable(title: 'no_books_found'.tr),
                    ),
                  ),
                );
              },
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: _handleRefresh,
          child: Column(
            children: [
              Expanded(
                child: GridView.builder(
                  controller: scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  itemCount: booksController.books.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: widget.isAudio ? 0.80 : 0.65,
                  ),
                  itemBuilder: (context, index) {
                    final book = booksController.books[index];
                    return BookCardGridView(
                      book: book,
                      onTap: () {
                        Get.to(() => BookDetailView(book: book));
                      },
                      discountPercentage: 2,
                    );
                  },
                ),
              ),
              Obx(() {
                return booksController.isLoadingMore.value
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const SizedBox.shrink();
              }),
            ],
          ),
        );
      }),
    );
  }
}
