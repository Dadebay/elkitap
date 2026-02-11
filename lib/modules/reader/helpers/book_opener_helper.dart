import 'dart:developer';
import 'package:cosmos_epub/cosmos_epub.dart';
import 'package:epubx/epubx.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Helper class for opening EPUB books in CosmosEpub reader
/// Handles both parsed and unparsed books with proper error handling
class BookOpenerHelper {
  /// Open a pre-parsed EPUB book
  static Future<void> openParsedBook({
    required EpubBook epubBook,
    required BuildContext context,
    required String bookId,
    required String bookDescription,
    required String imageUrl,
    required bool isInShelf,
    required bool isInMyBooks,
    required Function(int currentPage, int totalPages) onPageFlip,
    required Function(int lastPageIndex) onLastPage,
  }) async {
    log('🚀 Opening pre-parsed book...');
    final startOpen = DateTime.now();

    await CosmosEpub.openParsedBook(
      epubBook: epubBook,
      context: context,
      bookDescription: bookDescription,
      imageUrl: imageUrl,
      isInShelf: isInShelf,
      isInMyBooks: isInMyBooks,
      bookId: bookId,
      onPageFlip: onPageFlip,
      onLastPage: onLastPage,
    );

    final openDuration = DateTime.now().difference(startOpen);
    log('🚀 ✅ Book opened in ${openDuration.inMilliseconds}ms');
  }

  /// Open an EPUB book from local file path
  static Future<void> openLocalBook({
    required String localPath,
    required BuildContext context,
    required String bookId,
    required String bookDescription,
    required String imageUrl,
    required bool isInShelf,
    required bool isInMyBooks,
    required Function(int currentPage, int totalPages) onPageFlip,
    required Function(int lastPageIndex) onLastPage,
  }) async {
    log('📖 Opening book from local path...');
    final startOpen = DateTime.now();

    await CosmosEpub.openLocalBook(
      localPath: localPath,
      context: context,
      bookDescription: bookDescription,
      imageUrl: imageUrl,
      isInShelf: isInShelf,
      isInMyBooks: isInMyBooks,
      bookId: bookId,
      onPageFlip: onPageFlip,
      onLastPage: onLastPage,
    );

    final openDuration = DateTime.now().difference(startOpen);
    log('📖 ✅ Book opened in ${openDuration.inMilliseconds}ms');
  }

  /// Show format error dialog
  static void showFormatErrorDialog(BuildContext context) {
    if (!context.mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(
          'book_format_error'.tr.isEmpty ? 'Format Hatası' : 'book_format_error'.tr,
        ),
        content: Text(
          'epub_format_not_supported'.tr.isEmpty ? 'Bu kitabın formatı desteklenmiyor. Lütfen farklı bir format deneyin.' : 'epub_format_not_supported'.tr,
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back to previous screen
            },
            child: Text('ok'.tr.isEmpty ? 'Tamam' : 'ok'.tr),
          ),
        ],
      ),
    );
  }

  /// Show corrupted file error dialog
  static void showCorruptedFileDialog(BuildContext context) {
    if (!context.mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(
          'epub_format_error'.tr.isEmpty ? 'Format Hatası' : 'epub_format_error'.tr,
        ),
        content: Text(
          'epub_corrupted_message'.tr.isEmpty
              ? 'Bu EPUB dosyasının formatında bir sorun var. Dosya bozuk olabilir veya desteklenmeyen bir formatta olabilir.\n\nLütfen farklı bir kitap deneyin veya bu kitabı yeniden indirin.'
              : 'epub_corrupted_message'.tr,
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back to previous screen
            },
            child: Text('ok'.tr.isEmpty ? 'Tamam' : 'ok'.tr),
          ),
        ],
      ),
    );
  }

  /// Show generic error dialog
  static void showGenericErrorDialog(BuildContext context) {
    if (!context.mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('error'.tr.isEmpty ? 'Hata' : 'error'.tr),
        content: Text(
          'failed_to_open_book'.tr.isEmpty ? 'Kitap açılamadı. Lütfen tekrar deneyin.' : 'failed_to_open_book'.tr,
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back to previous screen
            },
            child: Text('ok'.tr.isEmpty ? 'Tamam' : 'ok'.tr),
          ),
        ],
      ),
    );
  }

  /// Check if error is a format/parsing error
  static bool isFormatError(Exception error) {
    final errorString = error.toString();
    return errorString.contains('TOC file') || errorString.contains('EPUB parsing error') || errorString.contains('does not contain head element');
  }
}
