import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:elkitap/core/widgets/common/app_snackbar.dart';
import 'package:elkitap/core/widgets/states/loading_widget.dart';
import 'package:elkitap/modules/library/controllers/note_controller.dart';
import 'package:elkitap/modules/store/controllers/all_books_controller.dart';
import 'package:elkitap/modules/store/controllers/book_detail_controller.dart';
import 'package:elkitap/modules/store/model/book_item_model.dart';

/// Mixin for reader handlers (notes, save to library, mark as finished)
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

  /// Register all handlers (no-op now, handlers are called directly from EpubViewer callbacks)
  void registerAllHandlers() {
    // No longer registers global CosmosEpub handlers.
    // Handlers are now called directly from EpubViewer callbacks.
  }

  /// Handle note creation from text selection
  Future<void> handleNoteSelection(String selectedText, {String? userNote}) async {
    log('📝 Note handler called: bookId=$bookId, text=$selectedText with note=$userNote');

    try {
      if (selectedText.trim().isEmpty) {
        AppSnackbar.warning(
          'please_select_text_to_create_note'.tr,
          title: 'error_title'.tr,
          duration: const Duration(seconds: 2),
        );
        return;
      }

      final book = currentBook ??
          allBooksController.books.firstWhereOrNull(
            (b) => b.id.toString() == bookId,
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

      final fullSnippet = selectedText.trim();
      final noteContent = userNote?.trim() ?? '';

      log('📝 Note content: $noteContent');
      log('📝 Snippet: $fullSnippet');

      final result = await notesController.addNote(
        bookId: bookId,
        note: noteContent,
        snippet: fullSnippet,
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
  }

  /// Handle saving book to library
  Future<void> handleSaveToLibrary() async {
    log('💾 Save to My Books handler called: bookId=$bookId');

    bool dialogOpened = false;
    try {
      // Ensure book detail is loaded
      if (detailController.bookDetail.value == null) {
        await detailController.fetchBookDetail(int.parse(bookId));
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
  }

  /// Handle marking book as finished
  Future<void> handleMarkAsFinished() async {
    log('📚 Add to Shelf handler called: bookId=$bookId');

    bool dialogOpened = false;
    try {
      // Ensure book detail is loaded
      if (detailController.bookDetail.value == null) {
        await detailController.fetchBookDetail(int.parse(bookId));
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
  }
}
