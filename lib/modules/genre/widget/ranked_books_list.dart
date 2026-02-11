import 'package:cached_network_image/cached_network_image.dart';
import 'package:elkitap/core/constants/icon_constants.dart';
import 'package:elkitap/core/constants/string_constants.dart';
import 'package:elkitap/data/network/api_edpoints.dart';
import 'package:elkitap/core/widgets/common/custom_icon.dart';
import 'package:elkitap/modules/store/model/book_item_model.dart';
import 'package:elkitap/modules/store/views/store_detail_view.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class RankedBooksList extends StatelessWidget {
  final List<Book> books;
  final int tabIndex;
  final PageController? pageController;

  RankedBooksList({
    super.key,
    required this.books,
    this.tabIndex = 0,
    this.pageController,
  });

  @override
  Widget build(BuildContext context) {
    final chunks = <List<Book>>[];
    for (var i = 0; i < books.length; i += 3) {
      chunks.add(
        books.sublist(i, (i + 3 > books.length) ? books.length : i + 3),
      );
    }

    return SizedBox(
      height: tabIndex == 1 ? 300 : 410,
      child: PageView.builder(
        controller: pageController ?? PageController(viewportFraction: 0.85),
        scrollDirection: Axis.horizontal,
        itemCount: chunks.length,
        itemBuilder: (context, pageIndex) {
          final pageBooks = chunks[pageIndex];
          return Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 8, right: 8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: List.generate(pageBooks.length, (index) {
                final book = pageBooks[index];
                final rank = pageIndex * 3 + index + 1;
                return GestureDetector(
                    onTap: () {
                      Get.to(() => BookDetailView(book: book, isAudio: tabIndex == 1));
                    },
                    child: _buildBookRankCard(book, rank));
              }),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBookRankCard(Book book, int rank) {
    const double bookWidth = 65;
    const double bookHeight = 95;
    final effectiveHeight = book.withAudio && tabIndex == 1 ? bookWidth : bookHeight;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            height: effectiveHeight,
            width: bookWidth,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  spreadRadius: 1,
                  offset: const Offset(0, 2),
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 16,
                  spreadRadius: 2,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: () {
                String? imageToUse;
                if (book.withAudio && tabIndex == 1) {
                  imageToUse = book.audioImage;
                } else {
                  imageToUse = book.image;
                }
                if (imageToUse == null || imageToUse.isEmpty) {
                  return Container(
                    color: Colors.grey[100],
                    child: Center(
                      child: CustomIcon(
                        title: IconConstants.libraryFilled,
                        height: 24,
                        width: 24,
                        color: Colors.grey[400],
                      ),
                    ),
                  );
                }

                return CachedNetworkImage(
                  height: effectiveHeight,
                  width: bookWidth,
                  imageUrl: ApiEndpoints.imageBaseUrl + imageToUse,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: Colors.grey[100],
                    child: Center(
                      child: SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.grey[400],
                        ),
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.grey[100],
                    child: Center(
                      child: CustomIcon(
                        title: IconConstants.libraryFilled,
                        height: 24,
                        width: 24,
                        color: Colors.grey[400],
                      ),
                    ),
                  ),
                );
              }(),
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$rank',
                  style: const TextStyle(
                    fontSize: 28,
                    fontFamily: StringConstants.GilroyRegular,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 12),

                // Title + Author
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        book.name,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontFamily: StringConstants.SFPro,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        overflow: TextOverflow.ellipsis,
                        book.authors.isNotEmpty ? book.authors.first.name : 'Unknown Author',
                        style: TextStyle(color: Colors.grey[600], fontFamily: StringConstants.SFPro, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
