import 'dart:io';
import 'package:elkitap/data/network/network_manager.dart';
import 'package:path_provider/path_provider.dart';

class EpubDownloadService {
  final NetworkManager _networkManager;

  EpubDownloadService(this._networkManager);

  Future<String> fetchSignedUrl(String bookKey) async {
    final endpoint = '/books/file';
    final query = {'filename': bookKey};

    try {
      final resp = await _networkManager.get(
        endpoint,
        sendToken: true,
        queryParameters: query,
      );

      if (_isAuthErrorResponse(resp)) {
        throw Exception('Authentication required');
      }

      if (resp['success'] == true && resp['data'] != null) {
        final data = resp['data'];
        if (data is Map && data.containsKey('url') && data['url'] != null) {
          return data['url'].toString();
        } else {
          throw Exception('Signed URL missing in response data');
        }
      } else {
        final statusCode = resp['statusCode'] ?? 'unknown';
        final error = resp['error'] ?? resp['data'] ?? 'Unknown error';
        throw Exception('Signed URL API error: $statusCode - $error');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<String> getLocalFilePath(String bookId, {String? epubPath}) async {
    final directory = await getApplicationDocumentsDirectory();
    final booksDir = Directory('${directory.path}/books');

    if (!await booksDir.exists()) {
      await booksDir.create(recursive: true);
    }

    // If epubPath is provided, use it to create a unique filename
    // This ensures different translations of the same book have different cache files
    if (epubPath != null && epubPath.isNotEmpty) {
      // Extract filename from path or create hash
      final pathHash = epubPath.hashCode.abs().toString();
      return '${booksDir.path}/book_${bookId}_$pathHash.epub';
    }

    return '${booksDir.path}/book_$bookId.epub';
  }

  Future<void> downloadFile(
    String url,
    String savePath, {
    Function(double)? onProgress,
  }) async {
    try {
      final client = HttpClient();
      final req = await client.getUrl(Uri.parse(url));
      final resp = await req.close();

      if (resp.statusCode != 200) {
        // final body = await resp.transform(utf8.decoder).join();
        throw Exception('Failed to download file, status: ${resp.statusCode}');
      }

      final file = File(savePath);
      final sink = file.openWrite();
      final contentLength = resp.contentLength;

      int receivedBytes = 0;

      await for (var chunk in resp) {
        sink.add(chunk);
        receivedBytes += chunk.length;

        if (onProgress != null && contentLength > 0) {
          final progress = receivedBytes / contentLength;
          onProgress(progress);
        }
      }

      await sink.close();
    } catch (e) {
      try {
        final file = File(savePath);
        if (await file.exists()) await file.delete();
      } catch (_) {}

      rethrow;
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
