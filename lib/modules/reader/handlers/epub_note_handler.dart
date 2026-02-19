import 'package:elkitap/core/widgets/common/app_snackbar.dart';
import 'package:elkitap/core/widgets/states/loading_widget.dart';
import 'package:elkitap/modules/library/controllers/note_controller.dart';
import 'package:elkitap/modules/store/controllers/all_books_controller.dart';
import 'package:elkitap/modules/store/model/book_item_model.dart';
import 'package:elkitap/modules/reader/services/epub_auth_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class EpubNoteHandler {
  final NotesController notesController;
  final GetAllBooksController allBooksController;
  final EpubAuthService authService;

  EpubNoteHandler({
    required this.notesController,
    required this.allBooksController,
    required this.authService,
  });

  /// Handle note creation from text selection
  /// Called directly from EpubViewer's onTextSelected callback
  Future<void> handleNoteSelection(
      Book? currentBook, String bookId, String selectedText,
      {String? userNote}) async {
    try {
      if (selectedText.trim().isEmpty) {
        _showErrorSnackbar(
          'error_title'.tr,
          'please_select_text_to_create_note'.tr,
          Colors.orange,
        );
        return;
      }

      final book = currentBook ??
          allBooksController.books.firstWhereOrNull(
            (b) => b.id.toString() == bookId,
          );

      _showLoadingDialog();

      final fullSnippet = selectedText.trim();
      final noteContent = userNote?.trim() ?? '';

      final result = await notesController.addNote(
        bookId: bookId,
        note: noteContent,
        snippet: fullSnippet,
        bookTitle: book?.name ?? 'unknown_book'.tr,
        bookAuthor: book?.authors.isNotEmpty == true
            ? book!.authors.first.name
            : 'unknown_author'.tr,
      );

      _closeDialog();

      if (result['success'] == true) {
        _showSuccessSnackbar('note_saved_message'.tr);
      } else {
        if (result['message']
                ?.toString()
                .toLowerCase()
                .contains('authentication') ==
            true) {
          authService.showLoginBottomSheet();
        } else {
          _showErrorSnackbar(
            'error'.tr,
            result['message'] ?? 'failed_to_save_note'.tr,
            Colors.red,
          );
        }
      }
    } catch (e) {
      _closeDialog();

      if (authService.isAuthError(e)) {
        authService.showLoginBottomSheet();
      } else {
        _showErrorSnackbar(
          'error'.tr,
          'failed_to_save_note_try_again'.tr,
          Colors.red,
        );
      }
    }
  }

  void _showLoadingDialog() {
    Get.dialog(
      WillPopScope(
        onWillPop: () async => false,
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Get.theme.brightness == Brightness.dark
                  ? Colors.grey[900]
                  : Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                LoadingWidget(),
                SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }

  void _closeDialog() {
    if (Get.isDialogOpen == true) {
      Get.back();
    }
  }

  void _showSuccessSnackbar(String message) {
    AppSnackbar.success(message);
  }

  void _showErrorSnackbar(String title, String message, Color color) {
    if (color == Colors.orange) {
      AppSnackbar.warning(message,
          title: title, duration: const Duration(seconds: 3));
    } else {
      AppSnackbar.error(message,
          title: title, duration: const Duration(seconds: 3));
    }
  }
}
