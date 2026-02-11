import 'dart:developer';
import 'package:cosmos_epub/cosmos_epub.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:elkitap/core/widgets/common/app_snackbar.dart';
import 'package:elkitap/core/widgets/states/loading_widget.dart';
import 'package:elkitap/modules/library/controllers/note_controller.dart';
import 'package:elkitap/modules/store/controllers/all_books_controller.dart';
import 'package:elkitap/modules/store/controllers/book_detail_controller.dart';
import 'package:elkitap/modules/store/model/book_item_model.dart';

/// Mixin for registering CosmosEpub handlers (notes, save to library, mark as finished)
/// Handles user interactions with book reader features
mixin ReaderHandlersMixin {
  // These getters must be implemented by the class using this mixin
  NotesController get notesController;
  BooksDetailController get detailController;
  GetAllBooksController get allBooksController;
  Book? get currentBook;
  String get bookId;

  // These methods must be implemented by the class using this mixin
  bool isAuthError(dynamic error);
  void showLoginBottomSheet();

  /// Register all CosmosEpub handlers
  void registerAllHandlers() {
    registerNoteHandler();
    registerSaveToLibraryHandler();
    registerMarkAsFinishedHandler();
  }

  /// Register handler for adding notes
  void registerNoteHandler() {
    CosmosEpub.registerAddNoteHandler((bookId, selectedText) async {
      log('📝 Note handler called: bookId=$bookId, text=$selectedText');

      try {
        if (selectedText.trim().isEmpty) {
          AppSnackbar.warning(
            'please_select_text_to_create_note'.tr,
            title: 'error_title'.tr,
            duration: const Duration(seconds: 2),
          );
          return;
        }

        final trimmedBookId = bookId.split('_').first;
        log('📝 Trimmed bookId: $trimmedBookId');

        final book = currentBook ??
            allBooksController.books.firstWhereOrNull(
              (b) => b.id.toString() == trimmedBookId,
            );

        Get.dialog(
          WillPopScope(
            onWillPop: () async => false,
            child: Padding(
              padding: const EdgeInsets.all(50.0),
              child: LoadingWidget(),
            ),
          ),
          barrierDismissible: false,
        );

        final fullNote = selectedText.trim();

        // Extract snippet from user's note (after \n\n) if exists, otherwise from selected text
        String snippetText = fullNote;
        if (fullNote.contains('\n\n')) {
          final parts = fullNote.split('\n\n');
          if (parts.length > 1 && parts.last.trim().isNotEmpty) {
            // User added a note, use that for snippet
            snippetText = parts.last.trim();
          }
        }

        final snippet = _getSnippet(snippetText, wordCount: 3);

        log('📝 Full note: $fullNote');
        log('📝 Snippet: $snippet');

        final result = await notesController.addNote(
          bookId: trimmedBookId,
          note: fullNote,
          snippet: snippet,
          bookTitle: book?.name ?? 'Unknown Book',
          bookAuthor: book?.authors.isNotEmpty == true ? book!.authors.first.name : 'Unknown Author',
        );

        if (Get.isDialogOpen == true) {
          Get.back();
        }

        if (result['success'] == true) {
          AppSnackbar.success(
            'note_saved_message'.tr,
            duration: const Duration(seconds: 2),
          );
        } else {
          if (result['message']?.toString().toLowerCase().contains('authentication') == true) {
            showLoginBottomSheet();
          } else {
            log(result['message'] ?? 'failed_to_save_note'.tr);
            AppSnackbar.error(
              result['message'] ?? 'failed_to_save_note'.tr,
              duration: const Duration(seconds: 3),
            );
          }
        }
      } catch (e, stackTrace) {
        if (Get.isDialogOpen == true) {
          Get.back();
        }

        log('❌ Error in note handler: $e');
        log('Stack trace: $stackTrace');

        if (isAuthError(e)) {
          showLoginBottomSheet();
        } else {
          AppSnackbar.error(
            'failed_to_save_note_try_again'.tr,
            duration: const Duration(seconds: 3),
          );
        }
      }
    });
  }

  /// Register handler for saving book to library
  void registerSaveToLibraryHandler() {
    CosmosEpub.registerSaveToMyBooksHandler((bookId) async {
      log('💾 Save to My Books handler called: bookId=$bookId');

      final trimmedBookId = bookId.split('_').first;
      log('💾 Trimmed bookId: $trimmedBookId');

      bool dialogOpened = false;
      try {
        // Ensure book detail is loaded
        if (detailController.bookDetail.value == null) {
          await detailController.fetchBookDetail(int.parse(trimmedBookId));
        }

        // Show loading dialog
        Get.dialog(
          WillPopScope(
            onWillPop: () async => false,
            child: Padding(
              padding: const EdgeInsets.all(50.0),
              child: LoadingWidget(),
            ),
          ),
          barrierDismissible: false,
        );
        dialogOpened = true;

        // Call toggleWantToRead to save the book
        await detailController.toggleWantToRead();

        // Check if authentication is required
        if (!detailController.isAuth.value) {
          if (dialogOpened && Get.isDialogOpen == true) {
            Get.back();
            dialogOpened = false;
          }
          showLoginBottomSheet();
          return;
        }

        // Close loading dialog
        if (dialogOpened && Get.isDialogOpen == true) {
          Get.back();
          dialogOpened = false;
        }

        // Small delay to ensure dialog is fully closed
        await Future.delayed(const Duration(milliseconds: 100));

        // Show success message
        AppSnackbar.success(
          detailController.isAddedToWantToRead.value ? 'book_saved_to_library'.tr : 'book_removed_from_library'.tr,
          duration: const Duration(seconds: 2),
        );
      } catch (e, stackTrace) {
        log('❌ Error in save handler: $e');
        log('Stack trace: $stackTrace');

        if (isAuthError(e)) {
          showLoginBottomSheet();
        } else {
          AppSnackbar.error(
            'failed_to_save_book_try_again'.tr,
            duration: const Duration(seconds: 3),
          );
        }
      } finally {
        if (dialogOpened && Get.isDialogOpen == true) {
          Get.back();
        }
      }
    });
  }

  /// Register handler for marking book as finished
  void registerMarkAsFinishedHandler() {
    CosmosEpub.registerAddToShelfHandler((bookId) async {
      log('📚 Add to Shelf handler called: bookId=$bookId');

      final trimmedBookId = bookId.split('_').first;
      log('📚 Trimmed bookId: $trimmedBookId');

      bool dialogOpened = false;
      try {
        // Ensure book detail is loaded
        if (detailController.bookDetail.value == null) {
          await detailController.fetchBookDetail(int.parse(trimmedBookId));
        }

        // Show loading dialog
        Get.dialog(
          WillPopScope(
            onWillPop: () async => false,
            child: Padding(
              padding: const EdgeInsets.all(50.0),
              child: LoadingWidget(),
            ),
          ),
          barrierDismissible: false,
        );
        dialogOpened = true;

        // Call markAsFinished
        final success = await detailController.markAsFinished();

        // Check if authentication is required
        if (!detailController.isAuth.value) {
          if (dialogOpened && Get.isDialogOpen == true) {
            Get.back();
            dialogOpened = false;
          }
          showLoginBottomSheet();
          return;
        }

        // Close loading dialog
        if (dialogOpened && Get.isDialogOpen == true) {
          Get.back();
          dialogOpened = false;
        }

        // Small delay to ensure dialog is fully closed
        await Future.delayed(const Duration(milliseconds: 100));

        if (success) {
          AppSnackbar.success(
            detailController.isMarkedAsFinished.value ? 'book_marked_as_finished'.tr : 'book_unmarked_as_finished'.tr,
            duration: const Duration(seconds: 2),
          );
        } else {
          AppSnackbar.warning(
            'failed_to_update_book_status'.tr,
            duration: const Duration(seconds: 2),
          );
        }
      } catch (e, stackTrace) {
        log('❌ Error in shelf handler: $e');
        log('Stack trace: $stackTrace');

        if (isAuthError(e)) {
          showLoginBottomSheet();
        } else {
          AppSnackbar.error(
            'failed_to_mark_as_finished_try_again'.tr,
            duration: const Duration(seconds: 3),
          );
        }
      } finally {
        if (dialogOpened && Get.isDialogOpen == true) {
          Get.back();
        }
      }
    });
  }

  /// Extract snippet from text (first N words)
  String _getSnippet(String text, {int wordCount = 3}) {
    final trimmed = text.trim();
    final words = trimmed.split(RegExp(r'\s+'));

    if (words.length <= wordCount) {
      return trimmed;
    }

    return words.take(wordCount).join(' ');
  }
}
