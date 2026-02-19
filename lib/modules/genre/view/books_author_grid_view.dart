import 'package:elkitap/core/widgets/navigation/custom_appbar.dart';
import 'package:elkitap/core/widgets/states/error_state_widget.dart';
import 'package:elkitap/core/widgets/states/loading_widget.dart';
import 'package:elkitap/modules/genre/widget/book_grid_cart.dart';
import 'package:elkitap/modules/store/controllers/all_books_controller.dart';
import 'package:elkitap/modules/store/views/book_detail_view.dart';
import 'package:elkitap/core/widgets/states/empty_states.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class BooksGridAuthorScreen extends StatefulWidget {
  final int? id;
  final String title;
  final bool isAudioMode;

  const BooksGridAuthorScreen({
    required this.id,
    required this.title,
    this.isAudioMode = false,
    super.key,
  });

  @override
  _BooksGridAuthorScreenState createState() => _BooksGridAuthorScreenState();
}

class _BooksGridAuthorScreenState extends State<BooksGridAuthorScreen> {
  late GetAllBooksController booksController;

  @override
  void initState() {
    super.initState();

    booksController = Get.put(
      GetAllBooksController(),
      tag: 'author_${widget.id}_${widget.isAudioMode ? 'audio' : 'books'}',
    );

    if (widget.id != null) {
      // Delay the fetch until after the first frame
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (widget.isAudioMode) {
          booksController.fetchBooks(
            authorIdFilter: widget.id,
            withAudioFilter: true,
            resetPagination: true,
          );
        } else {
          booksController.getBooksByAuthor(widget.id!);
        }
      });
    }
  }

  Future<void> _onRefresh() async {
    if (widget.id != null) {
      if (widget.isAudioMode) {
        await booksController.fetchBooks(
          authorIdFilter: widget.id,
          withAudioFilter: true,
          resetPagination: true,
        );
      } else {
        await booksController.getBooksByAuthor(widget.id!);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: widget.title.tr,
        leadingText: 'leading_text'.tr,
      ),
      body: Obx(() {
        // Loading
        if (booksController.isLoading.value) {
          return const Center(child: LoadingWidget(removeBackWhite: true));
        }

        // Error
        if (booksController.errorMessage.value.isNotEmpty) {
          return RefreshIndicator(
            onRefresh: _onRefresh,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: SizedBox(
                height: MediaQuery.of(context).size.height - 100,
                child: ErrorStateWidget(
                  errorMessage: booksController.errorMessage.value,
                  onRetry: () {
                    if (widget.id != null) {
                      booksController.getBooksByAuthor(widget.id!);
                    }
                  },
                ),
              ),
            ),
          );
        }

        // Empty state
        if (booksController.books.isEmpty) {
          return RefreshIndicator(
            onRefresh: _onRefresh,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: SizedBox(
                height: MediaQuery.of(context).size.height - 100,
                child: NoGenresAvailable(title: 'no_books_found'.tr),
              ),
            ),
          );
        }

        // Books grid with RefreshIndicator
        return RefreshIndicator(
          onRefresh: _onRefresh,
          child: GridView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            itemCount: booksController.books.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 0.65,
            ),
            itemBuilder: (context, index) {
              final book = booksController.books[index];

              return BookCardGridView(
                book: book,
                onTap: () => Get.to(() => BookDetailView(book: book, isAudio: widget.isAudioMode)),
                discountPercentage: 2,
              );
            },
          ),
        );
      }),
    );
  }
}
