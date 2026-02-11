import 'package:elkitap/core/widgets/navigation/custom_appbar.dart';
import 'package:elkitap/core/widgets/states/error_state_widget.dart';
import 'package:elkitap/core/widgets/states/loading_widget.dart';
import 'package:elkitap/modules/search/models/authors_model.dart';
import 'package:elkitap/modules/store/controllers/all_books_controller.dart';
import 'package:elkitap/modules/store/controllers/authors_controller.dart';
import 'package:elkitap/modules/store/widgets/author_profil_section.dart';
import 'package:elkitap/modules/store/widgets/books_section.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class BookAuthorView extends StatefulWidget {
  const BookAuthorView({super.key, required this.author});

  final Author author;

  @override
  State<BookAuthorView> createState() => _BookAuthorViewState();
}

class _BookAuthorViewState extends State<BookAuthorView> {
  late GetAllBooksController audiobooksController;
  late AuthorController authorController;
  int? authorId;
  late GetAllBooksController booksController;

  @override
  void dispose() {
    Get.delete<AuthorController>(tag: 'author_detail_$authorId');
    Get.delete<GetAllBooksController>(tag: 'author_$authorId');
    Get.delete<GetAllBooksController>(tag: 'author_audiobooks_$authorId');
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    final args = Get.arguments as Map<String, dynamic>?;
    authorId = args?['authorId'] as int?;

    authorController = Get.put(
      AuthorController(),
      tag: 'author_detail_$authorId',
    );

    booksController = Get.put(
      GetAllBooksController(),
      tag: 'author_$authorId',
    );

    audiobooksController = Get.put(
      GetAllBooksController(),
      tag: 'author_audiobooks_$authorId',
    );

    if (authorId != null) {
      authorController.fetchAuthorDetail(authorId!);
      booksController.getBooksByAuthor(authorId!);
      audiobooksController.fetchBooks(
        authorIdFilter: authorId,
        withAudioFilter: true,
        resetPagination: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(title: '', leadingText: 'leading_text'.tr),
      body: SafeArea(
        child: Obx(() {
          if (authorController.isLoadingDetail.value) {
            return LoadingWidget(removeBackWhite: true);
          }

          if (authorController.errorMessage.value.isNotEmpty) {
            return ErrorStateWidget(
              errorMessage: authorController.errorMessage.value,
              onRetry: () {
                if (authorId != null) {
                  authorController.fetchAuthorDetail(authorId!);
                  booksController.getBooksByAuthor(authorId!);
                }
              },
            );
          }

          final author = authorController.authorDetail.value ?? widget.author;

          return ListView(
            children: [
              AuthorProfileSection(author: author),
              Obx(() {
                if (booksController.books.isEmpty) {
                  return const SizedBox.shrink();
                }
                return BooksSection(books: booksController.books, id: authorId);
              }),
              Obx(() {
                final audiobooks = audiobooksController.books.toList();
                if (audiobooks.isEmpty) {
                  return const SizedBox.shrink();
                }
                return AudiobooksSection(audiobooks: audiobooks, id: authorId);
              }),
            ],
          );
        }),
      ),
    );
  }
}
