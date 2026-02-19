import 'package:elkitap/core/widgets/common/app_snackbar.dart';
import 'package:elkitap/core/widgets/states/loading_widget.dart';
import 'package:elkitap/modules/store/controllers/book_detail_controller.dart';
import 'package:elkitap/modules/reader/services/epub_auth_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class EpubSaveHandlers {
  final BooksDetailController detailController;
  final EpubAuthService authService;

  EpubSaveHandlers({
    required this.detailController,
    required this.authService,
  });

  /// Handle saving book to "My Books" / Want to Read
  /// Called directly from reader UI menu button
  Future<void> handleSaveToMyBooks(String bookId) async {
    try {
      if (detailController.bookDetail.value == null) {
        await detailController.fetchBookDetail(int.parse(bookId));
      }

      _showLoadingDialog();

      await detailController.toggleWantToRead();

      _closeDialog();

      if (!detailController.isAuth.value) {
        authService.showLoginBottomSheet();
        return;
      }

      _showSuccessSnackbar(
        detailController.isAddedToWantToRead.value ? 'book_saved_to_library'.tr : 'book_removed_from_library'.tr,
      );
    } catch (e) {
      _closeDialog();

      if (authService.isAuthError(e)) {
        authService.showLoginBottomSheet();
      } else {
        _showErrorSnackbar('failed_to_save_book_try_again'.tr);
      }
    }
  }

  /// Handle adding book to shelf / marking as finished
  /// Called directly from reader UI menu button
  Future<void> handleAddToShelf(String bookId) async {
    try {
      if (detailController.bookDetail.value == null) {
        await detailController.fetchBookDetail(int.parse(bookId));
      }

      _showLoadingDialog();

      final success = await detailController.markAsFinished();

      _closeDialog();

      if (!detailController.isAuth.value) {
        authService.showLoginBottomSheet();
        return;
      }

      if (success) {
        _showSuccessSnackbar(
          detailController.isMarkedAsFinished.value ? 'book_marked_as_finished'.tr : 'book_unmarked_as_finished'.tr,
        );
      } else {
        _showWarningSnackbar('failed_to_update_book_status'.tr);
      }
    } catch (e) {
      _closeDialog();

      if (authService.isAuthError(e)) {
        authService.showLoginBottomSheet();
      } else {
        _showErrorSnackbar('failed_to_mark_as_finished_try_again'.tr);
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
              color: Get.theme.brightness == Brightness.dark ? Colors.grey[900] : Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                LoadingWidget(),
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
    AppSnackbar.success(
      message,
      duration: const Duration(seconds: 2),
    );
  }

  void _showWarningSnackbar(String message) {
    AppSnackbar.warning(
      message,
      duration: const Duration(seconds: 2),
    );
  }

  void _showErrorSnackbar(String message) {
    AppSnackbar.error(
      message,
      duration: const Duration(seconds: 3),
    );
  }
}
