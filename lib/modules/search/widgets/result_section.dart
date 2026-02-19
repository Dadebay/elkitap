import 'package:cached_network_image/cached_network_image.dart';
import 'package:elkitap/core/constants/string_constants.dart';
import 'package:elkitap/core/theme/app_colors.dart';
import 'package:elkitap/data/network/api_edpoints.dart';
import 'package:elkitap/core/widgets/states/loading_widget.dart';
import 'package:elkitap/modules/search/controllers/search_controller.dart';
import 'package:elkitap/modules/store/views/author_view.dart';
import 'package:elkitap/modules/store/views/book_detail_view.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SearchResultsSection extends StatelessWidget {
  final SearchResultsController controller;
  final ScrollController scrollController;

  const SearchResultsSection({
    super.key,
    required this.controller,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    // Snapshot the observable values ONCE at build time
    final authors = controller.authors;
    final books = controller.books;
    final isLoadingMore = controller.isLoadingMore.value;
    final hasMoreBooks = controller.hasMoreBooks.value;

    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
      itemCount: _calculateItemCount(authors.length, books.length),
      itemBuilder: (context, index) {
        return _buildItemAtIndex(context, index, authors, books, isLoadingMore, hasMoreBooks);
      },
    );
  }

  int _calculateItemCount(int authorsLength, int booksLength) {
    int count = 0;

    // Authors section
    if (authorsLength > 0) {
      count += 1; // Header
      count += 1; // Divider
      count += authorsLength; // Author items
      count += 1; // Spacing
    }

    // Books section
    if (booksLength > 0) {
      count += 1; // Header
      count += 1; // Divider
      count += booksLength; // Book items
      count += 1; // Loading/No more results indicator
    }

    return count;
  }

  Widget _buildItemAtIndex(
    BuildContext context,
    int index,
    List authors,
    List books,
    bool isLoadingMore,
    bool hasMoreBooks,
  ) {
    int currentIndex = index;

    // Authors section
    if (authors.isNotEmpty) {
      if (currentIndex == 0) {
        return Text(
          'authors_title_t'.tr,
          style: const TextStyle(
            fontFamily: StringConstants.GilroyRegular,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        );
      }
      currentIndex--;

      if (currentIndex == 0) {
        return Column(
          children: [
            const SizedBox(height: 16),
            Divider(color: Colors.grey[200], height: 1),
            const SizedBox(height: 8),
          ],
        );
      }
      currentIndex--;

      if (currentIndex < authors.length) {
        return _buildAuthorItem(context, authors[currentIndex]);
      }
      currentIndex -= authors.length;

      if (currentIndex == 0) {
        return const SizedBox(height: 30);
      }
      currentIndex--;
    }

    // Books section
    if (books.isNotEmpty) {
      if (currentIndex == 0) {
        return Text(
          'books_t'.tr,
          style: const TextStyle(
            fontFamily: StringConstants.SFPro,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        );
      }
      currentIndex--;

      if (currentIndex == 0) {
        return Column(
          children: [
            const SizedBox(height: 16),
            Divider(color: AppColors.dividerColor, height: 1),
            const SizedBox(height: 8),
          ],
        );
      }
      currentIndex--;

      if (currentIndex < books.length) {
        return _buildBookItem(context, books[currentIndex]);
      }
      currentIndex -= books.length;

      if (currentIndex == 0) {
        return _buildLoadingIndicator(isLoadingMore, hasMoreBooks);
      }
    }

    return const SizedBox.shrink();
  }

  Widget _buildAuthorItem(BuildContext context, dynamic author) {
    final imageUrl = author.getFullImageUrl(ApiEndpoints.imageBaseUrl);
    final authorIndex = controller.authors.indexOf(author);

    return Column(
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(
            radius: 28,
            backgroundColor: Colors.grey[300],
            backgroundImage: imageUrl != null && imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null,
            child: imageUrl == null || imageUrl.isEmpty
                ? Text(
                    author.name.isNotEmpty ? author.name[0].toUpperCase() : '?',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  )
                : null,
          ),
          title: SizedBox(
            width: MediaQuery.of(context).size.width * 0.6,
            child: Text(
              author.name,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: StringConstants.SFPro,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          subtitle: Text(
            '${author.bookCount} ${'books_t'.tr}',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
              fontFamily: StringConstants.SFPro,
            ),
          ),
          onTap: () {
            Get.to(
              () => BookAuthorView(author: author),
              arguments: {'authorId': author.id},
            );
          },
        ),
        if (authorIndex < controller.authors.length - 1)
          Column(
            children: [
              Divider(color: Colors.grey[300], height: 1, thickness: 0.5),
              const SizedBox(height: 8),
            ],
          ),
      ],
    );
  }

  Widget _buildBookItem(BuildContext context, dynamic book) {
    final imageUrl = book.getFullImageUrl(ApiEndpoints.imageBaseUrl);
    final bookIndex = controller.books.indexOf(book);

    return Column(
      children: [
        InkWell(
          onTap: () {
            Get.to(() => BookDetailView(book: book));
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Book Cover Image
                Container(
                  width: 60,
                  height: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.12),
                        blurRadius: 12,
                        spreadRadius: 1,
                        offset: const Offset(0, 3),
                      ),
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 20,
                        spreadRadius: 3,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: imageUrl != null && imageUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: imageUrl,
                            fit: BoxFit.fill,
                            placeholder: (context, url) => Container(
                              color: Colors.grey[300],
                              child: Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: Colors.grey[300],
                              child: Center(
                                child: Icon(Icons.book, color: Colors.grey[600]),
                              ),
                            ),
                          )
                        : Container(
                            color: Colors.grey[300],
                            child: Center(
                              child: Icon(Icons.book, color: Colors.grey[600]),
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        book.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: StringConstants.SFPro,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        book.authors != null && book.authors.isNotEmpty ? book.authors.first.name : 'Unknown Author',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 13,
                          fontFamily: StringConstants.SFPro,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        if (bookIndex < controller.books.length - 1)
          Column(
            children: [
              Divider(color: AppColors.dividerColor, height: 1, thickness: 0.5),
              const SizedBox(height: 8),
            ],
          ),
      ],
    );
  }

  Widget _buildLoadingIndicator(bool isLoadingMore, bool hasMoreBooks) {
    if (isLoadingMore) {
      return LoadingWidget(
        removeBackWhite: true,
      );
    }

    if (!hasMoreBooks) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Text(
            'no_more_results'.tr,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
              fontFamily: StringConstants.SFPro,
            ),
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }
}
