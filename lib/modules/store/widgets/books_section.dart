import 'package:elkitap/core/constants/string_constants.dart';
import 'package:elkitap/modules/genre/view/books_author_grid_view.dart';
import 'package:elkitap/modules/store/model/book_item_model.dart';
import 'package:elkitap/modules/store/views/store_detail_view.dart';
import 'package:elkitap/modules/store/widgets/book_audi_cart.dart';
import 'package:elkitap/modules/store/widgets/popular_gerners_book_cart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class BooksSection extends StatelessWidget {
  final RxList<Book> books;
  final int? id;
  const BooksSection({
    required this.books,
    this.id,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    bool theme = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: EdgeInsets.only(top: 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: theme
              ? [Color(0x001C1C1E), Color(0xFF1C1C1E)] // dark mode gradient
              : [Color(0x00E5E5EA), Color(0xFFE5E5EA)],
          begin: theme ? Alignment.bottomCenter : Alignment.topCenter,
          end: theme ? Alignment.topCenter : Alignment.bottomCenter,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 26).copyWith(bottom: 10),
            child: SectionHeader(
              title: 'books_t'.tr,
              onTap: () {
                Get.to(() => BooksGridAuthorScreen(title: 'books_t'.tr, id: id));
              },
            ),
          ),
          // const SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: books.length,
              itemBuilder: (context, index) {
                final book = books[index];
                return Padding(
                  padding: EdgeInsets.only(
                    left: index == 0 ? 32 : 0,
                    right: index == books.length - 1 ? 32 : 16,
                    top: 8,
                    bottom: 40,
                  ),
                  child: BookCardPopular(
                    book: book,
                    index: index,
                    tabIndex: 0,
                    onTap: () {
                      Get.to(() => BookDetailView(book: book));
                    },
                    discountPercentage: 1,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// Audiobooks Section
class AudiobooksSection extends StatelessWidget {
  final List<Book> audiobooks;
  final int? id;

  const AudiobooksSection({
    required this.audiobooks,
    this.id,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(top: 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: Theme.of(context).brightness == Brightness.dark
              ? [Color(0x001C1C1E), Color(0xFF1C1C1E)] // dark mode gradient
              : [Color(0x00E5E5EA), Color(0xFFE5E5EA)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 26),
            child: SectionHeader(
              title: 'audio_book'.tr,
              onTap: () {
                Get.to(() => BooksGridAuthorScreen(title: 'audio_book'.tr, id: id, isAudioMode: true));
              },
            ),
          ),
          SizedBox(
            height: BookCardAudio.defaultWidth + 48,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: audiobooks.length,
              itemBuilder: (context, index) {
                final book = audiobooks[index];
                return Padding(
                  padding: EdgeInsets.only(
                    left: index == 0 ? 32 : 0,
                    right: index == audiobooks.length - 1 ? 32 : 16,
                    top: 8,
                    bottom: 40,
                  ),
                  child: BookCardAudio(
                    book: book,
                    index: index,
                    tabIndex: 1,
                    onTap: () {
                      Get.to(() => BookDetailView(
                            book: book,
                            isAudio: true,
                          ));
                    },
                    discountPercentage: 1,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// Section Header Component
class SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback onTap;

  const SectionHeader({super.key, required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 24, fontFamily: StringConstants.GilroyRegular, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 8),
            InkWell(
              onTap: onTap,
              child: Icon(
                Icons.arrow_forward_ios,
                size: 18,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
