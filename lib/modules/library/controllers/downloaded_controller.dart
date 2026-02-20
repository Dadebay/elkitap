// ignore_for_file: deprecated_member_use

import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:elkitap/core/config/secure_file_storage_service.dart';
import 'package:elkitap/core/constants/string_constants.dart';
import 'package:elkitap/core/widgets/common/app_snackbar.dart';
import 'package:elkitap/data/network/network_manager.dart';
import 'package:elkitap/data/network/token_managet.dart';
import 'package:elkitap/modules/library/model/book_download_model.dart';
import 'package:elkitap/utils/hls_downloader.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class DownloadController extends GetxController {
  final SecureFileStorageService _storageService = SecureFileStorageService();
  final NetworkManager _networkManager = Get.find<NetworkManager>();
  final TokenManager _tokenManager = Get.find<TokenManager>();
  final GetStorage _storage = GetStorage();

  static const String _downloadsKey = 'book_downloads';

  final RxList<BookDownload> downloadedBooks = <BookDownload>[].obs;
  final RxBool isLoading = false.obs;
  final RxDouble downloadProgress = 0.0.obs;
  final RxList<String> selectedBooks = <String>[].obs;
  final RxBool isGridView = true.obs;
  final RxBool isAudio = false.obs;

  CancelToken? _currentCancelToken;

  @override
  void onInit() {
    super.onInit();
    loadDownloadedBooks();
  }

  Future<void> downloadAndEncryptBook({
    required String bookId,
    required String bookKey,
    required String bookTitle,
    required String imageUrl,
    required String author,
  }) async {
    try {
      if (await _isBookDownloaded(bookId, isAudio: false)) {
        throw Exception('Book already downloaded');
      }

      isLoading.value = true;
      downloadProgress.value = 0.0;

      final signedUrl = await _fetchSignedUrl(bookKey);
      final epubBytes = await _downloadFileWithProgress(signedUrl);
      final fileName = '${bookId}_${DateTime.now().millisecondsSinceEpoch}';
      final result = await _storageService.saveEncryptedEpub(
        fileName,
        epubBytes,
      );

      if (!result['success']) {
        throw Exception(result['error']);
      }

      // Save metadata to Hive
      final download = BookDownload(
        id: bookId,
        title: bookTitle,
        author: author,
        fileName: fileName,
        coverUrl: imageUrl,
        downloadDate: DateTime.now(),
        fileSize: result['size'],
        hash: result['hash'],
        encryptedPath: result['path'],
      );

      await _saveDownloadMetadata(download);

      await loadDownloadedBooks();
    } catch (e) {
      rethrow;
    } finally {
      isLoading.value = false;
      downloadProgress.value = 0.0;
    }
  }

  Future<void> downloadAndEncryptAudioBook({
    required String bookId,
    required String bookTitle,
    required String imageUrl,
    required String author,
    required String hlsUrl,
  }) async {
    // Prevent multiple simultaneous downloads
    if (isLoading.value) {
      AppSnackbar.info('download_in_progress'.tr);
      return;
    }

    try {
      if (await _isBookDownloaded(bookId, isAudio: true)) {
        throw Exception('Audiobook already downloaded');
      }

      isLoading.value = true;
      downloadProgress.value = 0.0;
      _currentCancelToken = CancelToken();

      final hlsDownloader = HlsDownloader();
      final audioBytes = await hlsDownloader.downloadHlsSegments(
        hlsUrl,
        onProgress: (progress) => downloadProgress.value = progress,
        cancelToken: _currentCancelToken,
      );

      final fileName = 'audio_${bookId}_${DateTime.now().millisecondsSinceEpoch}';

      // Encryption disabled — save raw audio for direct offline playback
      // final result = await _storageService.saveEncryptedAudio(fileName, audioBytes);
      final result = await _storageService.saveRawAudio(fileName, audioBytes);

      if (!result['success']) {
        throw Exception(result['error']);
      }

      final download = BookDownload(
        id: bookId,
        title: bookTitle,
        author: author,
        fileName: fileName,
        coverUrl: imageUrl,
        downloadDate: DateTime.now(),
        fileSize: result['size'],
        hash: result['hash'],
        encryptedPath: result['path'],
        isAudio: true,
        hlsUrl: hlsUrl,
      );

      await _saveDownloadMetadata(download);

      // Update list
      await loadDownloadedBooks();

      AppSnackbar.success('audiobook_downloaded_successfully'.tr);
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
        AppSnackbar.info('download_cancelled'.tr);
      } else {
        AppSnackbar.error('failed_to_download_audiobook'.trParams({'error': e.toString()}));
        rethrow;
      }
    } catch (e) {
      AppSnackbar.error('failed_to_download_audiobook'.trParams({'error': e.toString()}));
      rethrow;
    } finally {
      isLoading.value = false;
      downloadProgress.value = 0.0;
      _currentCancelToken = null;
    }
  }

  /// Cancel ongoing download
  void cancelDownload() {
    try {
      if (_currentCancelToken != null && !_currentCancelToken!.isCancelled) {
        _currentCancelToken!.cancel('User cancelled download');
      }
    } catch (e) {
      print('Error cancelling download: $e');
    } finally {
      // Always reset state
      _currentCancelToken = null;
      isLoading.value = false;
      downloadProgress.value = 0.0;
    }
  }

  // Fetch signed URL
  Future<String> _fetchSignedUrl(String bookKey) async {
    final endpoint = '/books/file';
    final query = {'filename': bookKey};

    try {
      final resp = await _networkManager.get(
        endpoint,
        sendToken: true,
        queryParameters: query,
      );

      if (resp['success'] == true && resp['data'] != null) {
        final data = resp['data'];
        if (data is Map && data.containsKey('url') && data['url'] != null) {
          return data['url'].toString();
        }
      }
      throw Exception('Failed to get download URL');
    } catch (e) {
      rethrow;
    }
  }

  Future<Uint8List> _downloadFileWithProgress(String url) async {
    try {
      final client = HttpClient();
      final req = await client.getUrl(Uri.parse(url));
      final resp = await req.close();

      if (resp.statusCode != 200) {
        throw Exception('Download failed: ${resp.statusCode}');
      }

      final contentLength = resp.contentLength;
      final List<int> bytes = [];
      int downloaded = 0;

      await for (final data in resp) {
        bytes.addAll(data);
        downloaded += data.length;

        if (contentLength > 0) {
          downloadProgress.value = downloaded / contentLength;
        }
      }

      return Uint8List.fromList(bytes);
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> _isBookDownloaded(String bookId, {required bool isAudio}) async {
    final downloads = _getDownloadsMap();
    final key = '${bookId}_${isAudio ? 'audio' : 'text'}';
    return downloads.containsKey(key);
  }

  Future<void> _saveDownloadMetadata(BookDownload download) async {
    final downloads = _getDownloadsMap();
    final key = '${download.id}_${download.isAudio ? 'audio' : 'text'}';
    downloads[key] = download.toJson();
    await _storage.write(_downloadsKey, downloads);
  }

  Map<String, dynamic> _getDownloadsMap() {
    final data = _storage.read(_downloadsKey);
    if (data == null) return {};
    return Map<String, dynamic>.from(data as Map);
  }

  Future<void> loadDownloadedBooks() async {
    try {
      isLoading.value = true;

      // Check if user is authenticated
      final token = _tokenManager.getToken();
      if (token == null || token.isEmpty) {
        print('⚠️ No token found, clearing downloaded books');
        downloadedBooks.clear();
        isLoading.value = false;
        return;
      }

      final downloads = _getDownloadsMap();
      downloadedBooks.value = downloads.values.map((json) => BookDownload.fromJson(Map<String, dynamic>.from(json as Map))).toList();
      downloadedBooks.sort((a, b) => b.downloadDate.compareTo(a.downloadDate));
    } catch (e) {
      print('Error loading downloads: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<String?> openEncryptedBook(BookDownload book) async {
    try {
      final tempFile = await _storageService.exportDecryptedToTemp(book.fileName);

      if (tempFile != null && await tempFile.exists()) {
        return tempFile.path;
      }
      return null;
    } catch (e) {
      throw Exception('Failed to open book: $e');
    }
  }

  Future<void> deleteDownload(String bookId, {bool? isAudio}) async {
    try {
      final downloads = _getDownloadsMap();
      final textKey = '${bookId}_text';
      final audioKey = '${bookId}_audio';

      String? keyToDelete;
      BookDownload? bookToDelete;

      if (isAudio != null) {
        keyToDelete = isAudio ? audioKey : textKey;
        final json = downloads[keyToDelete];
        if (json != null) {
          bookToDelete = BookDownload.fromJson(Map<String, dynamic>.from(json as Map));
        }
      } else {
        if (downloads.containsKey(textKey)) {
          keyToDelete = textKey;
          bookToDelete = BookDownload.fromJson(Map<String, dynamic>.from(downloads[textKey] as Map));
        } else if (downloads.containsKey(audioKey)) {
          keyToDelete = audioKey;
          bookToDelete = BookDownload.fromJson(Map<String, dynamic>.from(downloads[audioKey] as Map));
        }
      }

      if (bookToDelete == null || keyToDelete == null) {
        throw Exception('Book not found');
      }
      if (!bookToDelete.isAudio) {
        await _storageService.deleteEncryptedEpub(bookToDelete.fileName);
      }

      downloads.remove(keyToDelete);
      await _storage.write(_downloadsKey, downloads);
      await loadDownloadedBooks();

      AppSnackbar.success('book_deleted_successfully'.tr);
    } catch (e) {
      AppSnackbar.error('failed_to_delete_book'.trParams({'error': e.toString()}));
    }
  }

  // Get storage info
  Future<Map<String, dynamic>> getStorageInfo() async {
    int totalSize = 0;
    for (var book in downloadedBooks) {
      totalSize += book.fileSize;
    }

    return {
      'totalBooks': downloadedBooks.length,
      'totalSize': totalSize,
      'totalSizeMB': (totalSize / (1024 * 1024)).toStringAsFixed(2),
    };
  }

  // Toggle view mode
  void toggleView() {
    isGridView.value = !isGridView.value;
  }

  // Toggle between text and audio modes
  void toggleToText() {
    isAudio.value = false;
  }

  void toggleToAudio() {
    isAudio.value = true;
  }

  // Toggle book selection
  void toggleBookSelection(String bookId) {
    if (selectedBooks.contains(bookId)) {
      selectedBooks.remove(bookId);
    } else {
      selectedBooks.add(bookId);
    }
  }

  // Clear selection
  void clearSelection() {
    selectedBooks.clear();
  }

  // Delete selected books
  Future<void> deleteSelectedBooks() async {
    try {
      final bookIds = List<String>.from(selectedBooks);

      for (var bookId in bookIds) {
        // Find the book in the list to get its type
        final book = downloadedBooks.firstWhereOrNull((b) => b.id == bookId);
        if (book != null) {
          await deleteDownload(bookId, isAudio: book.isAudio);
        }
      }

      selectedBooks.clear();

      AppSnackbar.success('multiple_books_deleted_successfully'.trParams({'count': bookIds.length.toString()}));
    } catch (e) {
      AppSnackbar.error('failed_to_delete_some_books'.trParams({'error': e.toString()}));
    }
  }

  void selectAll() {
    if (selectedBooks.length == downloadedBooks.length) {
      selectedBooks.clear();
    } else {
      selectedBooks.value = downloadedBooks.map((book) => book.id).toList();
    }
  }

  void toggleSelection(String bookId) {
    if (selectedBooks.contains(bookId)) {
      selectedBooks.remove(bookId);
    } else {
      selectedBooks.add(bookId);
    }
  }

  // Show remove dialog for a single book from detail view
  void showRemoveDialogForBook(BuildContext context, String bookId) {
    final book = downloadedBooks.firstWhereOrNull((b) => b.id == bookId);
    if (book == null) return;

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Dialog(
          backgroundColor: theme.dialogBackgroundColor,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 32,
            vertical: 24,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Book Cover
                Container(
                  width: 80,
                  height: 110,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: [
                      BoxShadow(
                        color: theme.shadowColor.withOpacity(0.15),
                        blurRadius: 5,
                        offset: const Offset(2, 2),
                      ),
                    ],
                    image: DecorationImage(
                      image: (book.coverUrl != null && book.coverUrl!.isNotEmpty ? NetworkImage(book.coverUrl!) : const AssetImage('assets/images/book.png')) as ImageProvider,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Message
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: book.title,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontFamily: StringConstants.SFPro,
                          fontSize: 17,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      TextSpan(
                        text: 'remove_this_book_from_downloads_q'.tr,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontFamily: StringConstants.SFPro,
                          fontSize: 17,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),

                TextButton(
                  onPressed: () async {
                    Get.back();
                    final bookToDelete = downloadedBooks.firstWhereOrNull((b) => b.id == bookId);
                    if (bookToDelete != null) {
                      await deleteDownload(bookId, isAudio: bookToDelete.isAudio);
                    }
                    Get.back();
                  },
                  style: TextButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                    backgroundColor: colorScheme.surfaceContainerHighest,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'remove_button_t'.tr,
                    style: TextStyle(
                      color: colorScheme.error.withOpacity(0.8),
                      fontSize: 18,
                      fontFamily: StringConstants.SFPro,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                TextButton(
                  onPressed: () => Get.back(),
                  style: TextButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'cancel_button_t'.tr,
                    style: TextStyle(
                      fontSize: 18,
                      color: colorScheme.onSurface,
                      fontFamily: StringConstants.SFPro,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void showRemoveDialog(BuildContext context) {
    if (selectedBooks.isEmpty) return;

    final selected = downloadedBooks.where((book) => selectedBooks.contains(book.id)).take(4).toList();

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.white,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 32,
            vertical: 24,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Stack(
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: 120,
                      child: Stack(
                        children: [
                          Align(
                            alignment: Alignment.topCenter,
                            child: SizedBox(
                              height: 120,
                              child: Stack(
                                alignment: Alignment.center,
                                children: List.generate(selected.length, (
                                  index,
                                ) {
                                  final book = selected[index];
                                  final totalWidth = (selected.length - 1) * 50;
                                  final offsetX = (index * 50) - (totalWidth / 2);

                                  return Transform.translate(
                                    offset: Offset(offsetX, 0),
                                    child: Container(
                                      width: 80,
                                      height: 110,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(6),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(
                                              0.15,
                                            ),
                                            blurRadius: 5,
                                            offset: const Offset(2, 2),
                                          ),
                                        ],
                                        image: DecorationImage(
                                          image: (book.coverUrl != null && book.coverUrl!.isNotEmpty ? NetworkImage(book.coverUrl!) : const AssetImage('assets/images/book.png')) as ImageProvider,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Message
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: "${'remove_dialog_part1_t'.tr}${selectedBooks.length}",
                            style: const TextStyle(fontFamily: StringConstants.SFPro, fontSize: 16, color: Colors.black),
                          ),
                          TextSpan(
                            text: 'remove_dialog_remove_t'.tr,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontFamily: StringConstants.SFPro,
                            ),
                          ),
                          TextSpan(
                            text: 'remove_dialog_part2_t'.tr,
                            style: const TextStyle(
                              fontSize: 16,
                              fontFamily: StringConstants.SFPro,
                            ),
                          ),
                          TextSpan(
                            text: 'want_to_read_t'.tr,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontFamily: StringConstants.SFPro,
                              fontSize: 17,
                            ),
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),

                    const Divider(height: 1),

                    TextButton(
                      onPressed: () async {
                        final bookIds = List<String>.from(selectedBooks);
                        Get.back(); // Close dialog
                        for (var bookId in bookIds) {
                          final bookToDelete = downloadedBooks.firstWhereOrNull((b) => b.id == bookId);
                          if (bookToDelete != null) {
                            await deleteDownload(bookId, isAudio: bookToDelete.isAudio);
                          }
                        }

                        selectedBooks.clear();
                      },
                      style: TextButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                      ),
                      child: Text(
                        'remove_button_t'.tr,
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 18,
                          fontFamily: StringConstants.SFPro,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                    const Divider(height: 1),
                    TextButton(
                      onPressed: () => Get.back(),
                      style: TextButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                      ),
                      child: Text(
                        'cancel_button_t'.tr,
                        style: const TextStyle(
                          fontSize: 18,
                          fontFamily: StringConstants.SFPro,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void onClose() {
    // Clear downloaded books list and selected items
    downloadedBooks.clear();
    selectedBooks.clear();

    super.onClose();
  }
}
