import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Helper class for EPUB reader error dialogs
class BookOpenerHelper {
  /// Show format error dialog
  static void showFormatErrorDialog(BuildContext context) {
    if (!context.mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(
          'book_format_error'.tr.isEmpty ? 'Format Hatasi' : 'book_format_error'.tr,
        ),
        content: Text(
          'epub_format_not_supported'.tr.isEmpty ? 'Bu kitabin formati desteklenmiyor. Lutfen farkli bir format deneyin.' : 'epub_format_not_supported'.tr,
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
          'epub_format_error'.tr.isEmpty ? 'Format Hatasi' : 'epub_format_error'.tr,
        ),
        content: Text(
          'epub_corrupted_message'.tr.isEmpty
              ? 'Bu EPUB dosyasinin formatinda bir sorun var. Dosya bozuk olabilir veya desteklenmeyen bir formatta olabilir.\n\nLutfen farkli bir kitap deneyin veya bu kitabi yeniden indirin.'
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
          'failed_to_open_book'.tr.isEmpty ? 'Kitap acilamadi. Lutfen tekrar deneyin.' : 'failed_to_open_book'.tr,
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
