import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:elkitap/data/network/network_manager.dart';
import 'package:elkitap/modules/reader/helpers/reader_helpers.dart';

/// Service for downloading and preparing books for reading
class BookDownloadService {
  final NetworkManager networkManager;
  final Function(double) onProgressUpdate;
  final Function(String) onError;

  BookDownloadService({
    required this.networkManager,
    required this.onProgressUpdate,
    required this.onError,
  });

  /// Fetch signed URL for downloading book
  Future<Map<String, dynamic>> fetchSignedUrl(String bookKey) async {
    final endpoint = '/books/file';
    final query = {'filename': bookKey};

    log('Calling NetworkManager.get -> $endpoint ? filename=$bookKey');
    try {
      final resp = await networkManager.get(
        endpoint,
        sendToken: true,
        queryParameters: query,
      );

      log('NetworkManager.get response: ${jsonEncode(resp)}');

      if (ReaderHelpers.isAuthErrorResponse(resp)) {
        log('Authentication required for signed URL');
        throw Exception('Authentication required');
      }

      if (resp['success'] == true && resp['data'] != null) {
        final data = resp['data'];
        if (data is Map && data.containsKey('url') && data['url'] != null) {
          final signedUrl = data['url'] as String;
          final fileSize = data['size'] ?? 0;
          log('Signed URL obtained: $signedUrl');
          log('Expected size: $fileSize bytes');
          return {'url': signedUrl, 'size': fileSize};
        } else {
          throw Exception('Invalid signed URL response format');
        }
      } else {
        final statusCode = resp['statusCode'] ?? 'unknown';
        final error = resp['error'] ?? resp['data'] ?? 'Unknown error';
        throw Exception('Signed URL API error: $statusCode - $error');
      }
    } catch (e, st) {
      log('Signed URL fetch error: $e\n$st');
      rethrow;
    }
  }

  /// Download book from URL and save to local path
  Future<String> downloadAndPrepareBook(
    String url,
    String savePath, {
    int expectedSize = 0,
  }) async {
    try {
      log('Starting download...');
      log('Save path: $savePath');
      log('Expected size: $expectedSize bytes');

      final client = HttpClient();
      final req = await client.getUrl(Uri.parse(url));
      final resp = await req.close();

      log('HTTP Response status: ${resp.statusCode}');
      log('Content-Length: ${resp.contentLength} bytes');

      if (resp.statusCode != 200) {
        final body = await resp.transform(utf8.decoder).join();
        log('Download failed. Body: $body');
        throw Exception('Failed to download file, status: ${resp.statusCode}');
      }

      final file = File(savePath);
      final sink = file.openWrite();

      final startTime = DateTime.now();
      final totalBytes = resp.contentLength > 0 ? resp.contentLength : expectedSize;
      int receivedBytes = 0;

      const minDisplayDuration = Duration(seconds: 3);

      await for (final chunk in resp) {
        sink.add(chunk);
        receivedBytes += chunk.length;

        if (totalBytes > 0) {
          final realProgress = (receivedBytes / totalBytes) * 0.90;
          onProgressUpdate(realProgress);
        }
      }

      await sink.close();
      final downloadDuration = DateTime.now().difference(startTime);
      final finalSize = await file.length();
      final avgSpeed = downloadDuration.inSeconds > 0 ? finalSize / downloadDuration.inSeconds : finalSize;

      log('Download completed!');
      log('Final size: ${(finalSize / 1024 / 1024).toStringAsFixed(2)} MB');
      log('Duration: ${downloadDuration.inSeconds}s');
      log('Avg speed: ${(avgSpeed / 1024 / 1024).toStringAsFixed(2)} MB/s');

      // Ensure minimum display time for smooth UX
      final elapsedTime = DateTime.now().difference(startTime);
      if (elapsedTime < minDisplayDuration) {
        final remainingTime = minDisplayDuration - elapsedTime;
        final steps = (remainingTime.inMilliseconds / 50).ceil();
        final currentProgress = 0.90; // We've already shown 90% progress
        final targetProgress = 0.90;
        final progressStep = (targetProgress - currentProgress) / steps;

        double displayProgress = currentProgress;
        for (int i = 0; i < steps; i++) {
          await Future.delayed(const Duration(milliseconds: 50));
          displayProgress += progressStep;
          onProgressUpdate(displayProgress.clamp(0.90, 0.90));
        }
      }

      // Check if downloaded file is a .zip containing an .epub
      String actualEpubPath = await ReaderHelpers.extractEpubFromZipIfNeeded(savePath);

      // Animate to 100%
      onProgressUpdate(0.92);

      final prepSteps = 10;
      for (int i = 0; i < prepSteps; i++) {
        await Future.delayed(const Duration(milliseconds: 50));
        onProgressUpdate((0.92 + (0.08 * (i + 1) / prepSteps)).clamp(0.92, 1.0));
      }

      onProgressUpdate(1.0);
      await Future.delayed(const Duration(milliseconds: 300));

      return actualEpubPath;
    } catch (e, st) {
      log('Download/Prepare error: $e\n$st');

      try {
        final file = File(savePath);
        if (await file.exists()) await file.delete();
      } catch (_) {}

      rethrow;
    }
  }
}
