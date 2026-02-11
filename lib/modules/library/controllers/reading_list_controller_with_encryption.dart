import 'dart:typed_data';
import 'package:elkitap/core/config/secure_file_storage_service.dart';
import 'package:elkitap/core/widgets/common/app_snackbar.dart';
import 'package:get/get.dart';

class EncriptReadingListController extends GetxController {
  final SecureFileStorageService _storageService = SecureFileStorageService();

  final RxList<Map<String, dynamic>> downloadedBooks = <Map<String, dynamic>>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isGridView = true.obs;
  final RxList<String> selectedBooks = <String>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadDownloadedBooks();
  }

  Future<void> downloadAndEncryptBook({
    required String bookId,
    required String bookTitle,
    required Uint8List epubBytes,
    String? coverUrl,
    String? author,
  }) async {
    try {
      isLoading.value = true;

      final fileName = '${bookId}_${DateTime.now().millisecondsSinceEpoch}';
      final result = await _storageService.saveEncryptedEpub(
        fileName,
        epubBytes,
      );

      if (result['success']) {
        downloadedBooks.add({
          'id': bookId,
          'title': bookTitle,
          'fileName': fileName,
          'author': author,
          'coverUrl': coverUrl,
          'downloadDate': DateTime.now().toIso8601String(),
          'hash': result['hash'],
          'size': result['size'],
          'path': result['path'],
        });

        AppSnackbar.success('Book encrypted and saved successfully');
      } else {
        AppSnackbar.error('Failed to encrypt book: ${result['error']}');
      }
    } catch (e) {
      AppSnackbar.error('Failed to download book: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // Read encrypted book
  Future<Uint8List?> readEncryptedBook(String fileName) async {
    try {
      isLoading.value = true;

      final result = await _storageService.readDecryptedEpub(fileName);

      if (result['success']) {
        return result['data'] as Uint8List;
      } else {
        AppSnackbar.error('Failed to read book: ${result['error']}');
        return null;
      }
    } catch (e) {
      AppSnackbar.error('Failed to decrypt book: $e');
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> openBook(String fileName) async {
    try {
      isLoading.value = true;

      final tempFile = await _storageService.exportDecryptedToTemp(fileName);

      if (tempFile != null) {
        AppSnackbar.info('Opening book...');
      } else {
        AppSnackbar.error('Failed to open book');
      }
    } catch (e) {
      AppSnackbar.error('Failed to open book: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> verifyBookIntegrity(Map<String, dynamic> book) async {
    try {
      final fileName = book['fileName'] as String;
      final originalHash = book['hash'] as String;

      final isValid = await _storageService.verifyEpubIntegrity(
        fileName,
        originalHash,
      );

      if (!isValid) {
        AppSnackbar.warning('Book file may be corrupted');
      }

      return isValid;
    } catch (e) {
      return false;
    }
  }

  // Delete encrypted book
  Future<void> deleteBook(String fileName) async {
    try {
      final success = await _storageService.deleteEncryptedEpub(fileName);

      if (success) {
        downloadedBooks.removeWhere((book) => book['fileName'] == fileName);
        AppSnackbar.success('Book deleted successfully');
      } else {
        AppSnackbar.error('Failed to delete book');
      }
    } catch (e) {
      AppSnackbar.error('Failed to delete book: $e');
    }
  }

  Future<void> loadDownloadedBooks() async {
    try {
      isLoading.value = true;

      final files = await _storageService.getAllEncryptedEpubs();
      downloadedBooks.value = files;
    } catch (e) {
      AppSnackbar.error('Failed to load books: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<Map<String, dynamic>> getStorageStats() async {
    return await _storageService.getStorageInfo();
  }

  void toggleView() {
    isGridView.value = !isGridView.value;
  }

  void toggleBookSelection(String fileName) {
    if (selectedBooks.contains(fileName)) {
      selectedBooks.remove(fileName);
    } else {
      selectedBooks.add(fileName);
    }
  }

  Future<void> deleteSelectedBooks() async {
    for (var fileName in selectedBooks) {
      await deleteBook(fileName);
    }
    selectedBooks.clear();
  }
}
