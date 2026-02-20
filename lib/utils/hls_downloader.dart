import 'dart:async';
import 'dart:developer';
import 'dart:typed_data';
import 'package:dio/dio.dart';

class HlsDownloader {
  final Dio _dio = Dio();

  /// Downloads all segments from an HLS (m3u8) URL and concatenates them.
  /// returns [Uint8List] of the combined segments.
  Future<Uint8List> downloadHlsSegments(
    String m3u8Url, {
    Function(double progress)? onProgress,
    CancelToken? cancelToken,
  }) async {
    try {
      log('HLS: Fetching manifest from $m3u8Url');
      final response = await _dio.get(
        m3u8Url,
        cancelToken: cancelToken,
      );
      if (response.statusCode != 200) {
        throw Exception('Failed to fetch HLS manifest: ${response.statusCode}');
      }

      final manifestContent = response.data.toString();
      final List<String> segmentUrls = _parseSegmentUrls(m3u8Url, manifestContent);

      if (segmentUrls.isEmpty) {
        throw Exception('No audio segments found in HLS manifest');
      }

      log('HLS: Found ${segmentUrls.length} segments');

      final List<Uint8List?> segments = List.filled(segmentUrls.length, null);
      int completedSegments = 0;

      // Use a limit on concurrency to avoid overwhelming the network/server
      const int maxConcurrency = 5;
      final List<Future<void>> workers = [];

      for (int i = 0; i < maxConcurrency; i++) {
        workers.add(() async {
          for (int j = i; j < segmentUrls.length; j += maxConcurrency) {
            try {
              final segmentResponse = await _dio.get<List<int>>(
                segmentUrls[j],
                options: Options(responseType: ResponseType.bytes),
                cancelToken: cancelToken,
              );

              if (segmentResponse.statusCode == 200 && segmentResponse.data != null) {
                segments[j] = Uint8List.fromList(segmentResponse.data!);
                completedSegments++;
                if (onProgress != null) {
                  onProgress(completedSegments / segmentUrls.length);
                }
              } else {
                log('HLS: Failed to download segment $j: ${segmentResponse.statusCode}');
              }
            } catch (e) {
              if (e is DioException && e.type == DioExceptionType.cancel) {
                log('HLS: Download cancelled');
                rethrow;
              }
              log('HLS: Error downloading segment $j: $e');
            }
          }
        }());
      }

      await Future.wait(workers);

      // Concatenate all successfully downloaded segments
      final List<int> combinedBytes = [];
      int successfulCount = 0;
      for (var segment in segments) {
        if (segment != null) {
          combinedBytes.addAll(segment);
          successfulCount++;
        }
      }

      log('HLS: Successfully downloaded $successfulCount/${segmentUrls.length} segments');

      if (successfulCount == 0) {
        throw Exception('Failed to download any audio segments');
      }

      return Uint8List.fromList(combinedBytes);
    } catch (e) {
      log('HLS: Error during HLS download: $e');
      rethrow;
    }
  }

  List<String> _parseSegmentUrls(String baseUrl, String manifest) {
    final List<String> urls = [];
    final lines = manifest.split('\n');

    // Find the base URL for relative paths
    final int lastSlashIndex = baseUrl.lastIndexOf('/');
    final String baseDir = baseUrl.substring(0, lastSlashIndex + 1);

    for (var line in lines) {
      line = line.trim();
      if (line.isEmpty || line.startsWith('#')) continue;

      if (line.startsWith('http://') || line.startsWith('https://')) {
        urls.add(line);
      } else {
        // Handle relative paths
        if (line.startsWith('/')) {
          // Absolute path from root (rare in HLS but possible)
          final uri = Uri.parse(baseUrl);
          urls.add('${uri.scheme}://${uri.host}${line}');
        } else {
          // Relative to current manifest
          urls.add('$baseDir$line');
        }
      }
    }

    return urls;
  }
}
