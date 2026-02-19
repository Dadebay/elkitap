import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:elkitap/data/network/network_manager.dart';

/// Service class for downloading and opening EPUB books
/// Handles book download, caching, parsing and opening
class BookLoaderService {
  final NetworkManager _networkManager;
  final String bookId;
  final String? epubPath;
  final int? translateId;

  BookLoaderService({
    required NetworkManager networkManager,
    required this.bookId,
    this.epubPath,
    this.translateId,
  }) : _networkManager = networkManager;

  /// Get unique book identifier including translation
  String get uniqueBookId {
    if (translateId != null) {
      return '${bookId}_t$translateId';
    }
    return bookId;
  }

  /// Get local file path for cached book
  Future<String> getLocalFilePath() async {
    final directory = await getApplicationDocumentsDirectory();
    final booksDir = Directory('${directory.path}/books');

    if (!await booksDir.exists()) {
      await booksDir.create(recursive: true);
    }

    // Use epubPath (bookKey) as part of filename if available to support multiple translations
    if (epubPath != null && epubPath!.isNotEmpty) {
      // Create a safe filename from the path/key
      // key format example: "/private/eng-1765969217345-1765969217345.epub"
      final safeKey = epubPath!.split('/').last;
      log('📁 Using translation-specific cache path: ${booksDir.path}/$safeKey');
      return '${booksDir.path}/$safeKey';
    }

    log('📁 Using default cache path: ${booksDir.path}/book_$uniqueBookId.epub');
    return '${booksDir.path}/book_$uniqueBookId.epub';
  }

  /// Check if book exists locally and is valid
  Future<bool> hasValidLocalCopy() async {
    try {
      final localPath = await getLocalFilePath();
      final file = File(localPath);

      if (await file.exists()) {
        final fileSize = await file.length();
        log('📚 ✅ Local copy found: $localPath');
        log('📚 File size: ${(fileSize / 1024 / 1024).toStringAsFixed(2)} MB');

        return fileSize > 0;
      }

      log('📚 ❌ No local copy found');
      return false;
    } catch (e) {
      log('⚠️ Error checking local copy: $e');
      return false;
    }
  }

  /// Fetch signed URL for book download
  Future<Map<String, dynamic>> fetchSignedUrl() async {
    if (epubPath == null || epubPath!.isEmpty) {
      throw Exception('EPUB path is required for download');
    }

    final endpoint = '/books/file';
    final query = {'filename': epubPath!};

    log('Calling NetworkManager.get -> $endpoint ? filename=$epubPath');

    final resp = await _networkManager.get(
      endpoint,
      sendToken: true,
      queryParameters: query,
    );

    log('NetworkManager.get response: ${jsonEncode(resp)}');

    // Check for authentication error
    if (_isAuthErrorResponse(resp)) {
      log('Authentication required for signed URL');
      throw Exception('Authentication required');
    }

    if (resp['success'] == true && resp['data'] != null) {
      final data = resp['data'];
      if (data is Map && data.containsKey('url') && data['url'] != null) {
        final signedUrl = data['url'].toString();
        final fileSize = data['size'] as int? ?? 0;
        log('Signed URL obtained: $signedUrl');
        log('File size from API: $fileSize bytes (${(fileSize / 1024 / 1024).toStringAsFixed(2)} MB)');
        return {'url': signedUrl, 'size': fileSize};
      } else {
        throw Exception('Signed URL missing in response data');
      }
    } else {
      final statusCode = resp['statusCode'] ?? 'unknown';
      final error = resp['error'] ?? resp['data'] ?? 'Unknown error';
      throw Exception('Signed URL API error: $statusCode - $error');
    }
  }

  /// Download book from URL with progress tracking
  Future<void> downloadBook(
    String url,
    String savePath, {
    required Function(double) onProgress,
    int expectedSize = 0,
  }) async {
    log('⬇️ 🎯 Starting download...');
    log('⬇️ Save path: $savePath');
    log('⬇️ Expected size: $expectedSize bytes (${(expectedSize / 1024 / 1024).toStringAsFixed(2)} MB)');

    final client = HttpClient();
    final req = await client.getUrl(Uri.parse(url));
    final resp = await req.close();

    log('⬇️ HTTP Response status: ${resp.statusCode}');
    log('⬇️ Content-Length: ${resp.contentLength} bytes');

    if (resp.statusCode != 200) {
      final body = await resp.transform(utf8.decoder).join();
      throw Exception('Download failed (${resp.statusCode}): $body');
    }

    final file = File(savePath);
    final sink = file.openWrite();

    final startTime = DateTime.now();
    final totalBytes =
        resp.contentLength > 0 ? resp.contentLength : expectedSize;
    int receivedBytes = 0;

    await for (final chunk in resp) {
      sink.add(chunk);
      receivedBytes += chunk.length;

      if (totalBytes > 0) {
        // Progress from 0.0 to 0.90 (reserve 10% for parsing)
        final progress = (receivedBytes / totalBytes) * 0.90;
        onProgress(progress.clamp(0.0, 0.90));
      }
    }

    await sink.close();

    final downloadDuration = DateTime.now().difference(startTime);
    final finalSize = await file.length();
    final avgSpeed = downloadDuration.inSeconds > 0
        ? finalSize / downloadDuration.inSeconds
        : finalSize;

    log('⬇️ ✅ Download completed!');
    log('⬇️ Final size: ${(finalSize / 1024 / 1024).toStringAsFixed(2)} MB');
    log('⬇️ Duration: ${downloadDuration.inSeconds}s');
    log('⬇️ Avg speed: ${(avgSpeed / 1024 / 1024).toStringAsFixed(2)} MB/s');
  }

  /// Delete local cached book
  Future<void> deleteLocalCopy() async {
    try {
      final localPath = await getLocalFilePath();
      final file = File(localPath);
      if (await file.exists()) {
        await file.delete();
        log('🗑️ Deleted corrupted local copy: $localPath');
      }
    } catch (e) {
      log('⚠️ Error deleting local copy: $e');
    }
  }

  bool _isAuthErrorResponse(Map<String, dynamic> response) {
    if (response['success'] == false) {
      final statusCode = response['statusCode'];
      if (statusCode == 401) return true;

      final error = response['error']?.toString().toLowerCase() ?? '';
      final message =
          response['data']?['message']?.toString().toLowerCase() ?? '';

      return error.contains('authentication required') ||
          error.contains('unauthorized') ||
          error.contains('unauthenticated') ||
          message.contains('authentication required') ||
          message.contains('unauthorized') ||
          message.contains('unauthenticated');
    }
    return false;
  }
}
