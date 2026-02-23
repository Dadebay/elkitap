import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';

/// Result of a successful HLS download.
class HlsDownloadResult {
  /// The local `index.m3u8` file that just_audio can play directly.
  final File m3u8File;

  /// Total bytes written (sum of all segment sizes).
  final int totalBytes;

  /// Number of segments successfully downloaded.
  final int segmentCount;

  HlsDownloadResult({
    required this.m3u8File,
    required this.totalBytes,
    required this.segmentCount,
  });
}

class HlsDownloader {
  final Dio _dio = Dio();

  /// Downloads all HLS segments into [outputDir] as individual `.ts` files
  /// and creates a local `index.m3u8` that references them by filename.
  ///
  /// Preserves each MPEG-TS segment file intact so iOS AVPlayer can correctly
  /// determine the full audiobook duration and seek across all segments,
  /// instead of stopping early due to a timestamp discontinuity in a
  /// concatenated single-file approach.
  ///
  /// Returns [HlsDownloadResult] with path to the local `index.m3u8`.
  Future<HlsDownloadResult> downloadHlsToFile(
    String m3u8Url, {
    required Directory outputDir,
    Function(double progress)? onProgress,
    CancelToken? cancelToken,
  }) async {
    final startedAt = DateTime.now();
    log('HLS: ===== DOWNLOAD START (dir-based local HLS) =====');
    log('HLS: Platform=${Platform.operatingSystem}');
    log('HLS: Output dir: ${outputDir.path}');
    log('HLS: Fetching manifest from $m3u8Url');

    // 1. Create output directory
    await outputDir.create(recursive: true);

    // 2. Fetch original manifest
    final manifestResp = await _dio.get(m3u8Url, cancelToken: cancelToken);
    if (manifestResp.statusCode != 200) {
      throw Exception('Failed to fetch HLS manifest: ${manifestResp.statusCode}');
    }
    final parsed = _parseManifest(m3u8Url, manifestResp.data.toString());
    if (parsed.segments.isEmpty) {
      throw Exception('No audio segments found in HLS manifest');
    }

    log('HLS: Found ${parsed.segments.length} segments');
    log('HLS: First segment URL: ${parsed.segments[0].url}');

    // 3. Download each segment, save as individual .ts file
    int completedSegments = 0;
    int totalBytes = 0;
    bool formatLogged = false;

    for (int i = 0; i < parsed.segments.length; i++) {
      final seg = parsed.segments[i];

      if (cancelToken != null && cancelToken.isCancelled) {
        log('HLS: Download cancelled at segment $i');
        throw DioException(
          type: DioExceptionType.cancel,
          requestOptions: RequestOptions(path: seg.url),
          message: 'User cancelled download',
        );
      }

      final segFile = File('${outputDir.path}/${seg.localName}');

      int retries = 0;
      const maxRetries = 3;
      while (retries < maxRetries) {
        try {
          final segResp = await _dio.get<List<int>>(
            seg.url,
            options: Options(responseType: ResponseType.bytes),
            cancelToken: cancelToken,
          );

          if (segResp.statusCode == 200 && segResp.data != null) {
            final bytes = Uint8List.fromList(segResp.data!);

            if (!formatLogged && bytes.length >= 2) {
              formatLogged = true;
              final b0 = bytes[0];
              final b1 = bytes.length > 1 ? bytes[1] : 0;
              String fmt = 'UNKNOWN (0x${b0.toRadixString(16).padLeft(2, '0')} 0x${b1.toRadixString(16).padLeft(2, '0')})';
              if (b0 == 0x47)
                fmt = 'MPEG-TS — saving as individual .ts files for local HLS';
              else if (b0 == 0xFF && (b1 == 0xF1 || b1 == 0xF9)) fmt = 'ADTS AAC';
              log('HLS: *** SEGMENT FORMAT: $fmt ***');
            }

            await segFile.writeAsBytes(bytes, flush: true);
            totalBytes += bytes.length;
            completedSegments++;

            if (completedSegments % 25 == 0 || completedSegments == parsed.segments.length) {
              final mb = totalBytes / (1024 * 1024);
              final pct = (completedSegments / parsed.segments.length * 100).toStringAsFixed(1);
              log('HLS: Progress $pct% | Segments: $completedSegments/${parsed.segments.length} | Written: ${mb.toStringAsFixed(2)} MB');
            }

            onProgress?.call(completedSegments / parsed.segments.length);
            break;
          } else {
            log('HLS: Unexpected status for segment $i: ${segResp.statusCode}');
            retries++;
          }
        } catch (e) {
          if (e is DioException && e.type == DioExceptionType.cancel) rethrow;
          retries++;
          if (retries >= maxRetries) {
            log('HLS: Skipping segment $i after $maxRetries failures: $e');
          } else {
            log('HLS: Retry $retries for segment $i');
            await Future.delayed(Duration(milliseconds: 300 * retries));
          }
        }
      }
    }

    if (completedSegments == 0) {
      throw Exception('Failed to download any audio segments');
    }

    // 4. Write local index.m3u8 with relative .ts filenames
    final localManifest = _buildLocalManifest(parsed, completedSegments);
    final m3u8File = File('${outputDir.path}/index.m3u8');
    await m3u8File.writeAsString(localManifest);

    final elapsed = DateTime.now().difference(startedAt);
    log('HLS: Downloaded $completedSegments/${parsed.segments.length} segments');
    log('HLS: Total size: ${(totalBytes / (1024 * 1024)).toStringAsFixed(2)} MB');
    log('HLS: Local m3u8: ${m3u8File.path}');
    log('HLS: Elapsed: ${elapsed.inSeconds}s');
    log('HLS: ===== DOWNLOAD END (dir-based local HLS) =====');

    return HlsDownloadResult(
      m3u8File: m3u8File,
      totalBytes: totalBytes,
      segmentCount: completedSegments,
    );
  }

  // ── Manifest parsing ────────────────────────────────────────────────────────

  _ParsedManifest _parseManifest(String baseUrl, String manifest) {
    final lines = manifest.split('\n').map((l) => l.trim()).toList();
    final int lastSlash = baseUrl.lastIndexOf('/');
    final String baseDir = baseUrl.substring(0, lastSlash + 1);

    String? targetDuration;
    String? version;
    String? mediaSequence;
    final List<_SegmentEntry> segments = [];

    String? pendingExtinf;
    int segIndex = 0;

    for (final line in lines) {
      if (line.isEmpty) continue;

      if (line.startsWith('#EXT-X-VERSION:')) {
        version = line;
      } else if (line.startsWith('#EXT-X-TARGETDURATION:')) {
        targetDuration = line;
      } else if (line.startsWith('#EXT-X-MEDIA-SEQUENCE:')) {
        mediaSequence = line;
      } else if (line.startsWith('#EXTINF:')) {
        pendingExtinf = line;
      } else if (!line.startsWith('#')) {
        final String url;
        if (line.startsWith('http://') || line.startsWith('https://')) {
          url = line;
        } else if (line.startsWith('/')) {
          final uri = Uri.parse(baseUrl);
          url = '${uri.scheme}://${uri.host}$line';
        } else {
          url = '$baseDir$line';
        }
        segments.add(_SegmentEntry(
          url: url,
          localName: 'segment_${segIndex.toString().padLeft(3, '0')}.ts',
          extinf: pendingExtinf,
        ));
        pendingExtinf = null;
        segIndex++;
      }
    }

    return _ParsedManifest(
      version: version,
      targetDuration: targetDuration,
      mediaSequence: mediaSequence,
      segments: segments,
    );
  }

  String _buildLocalManifest(_ParsedManifest parsed, int downloadedCount) {
    final buf = StringBuffer();
    buf.writeln('#EXTM3U');
    if (parsed.version != null) buf.writeln(parsed.version);
    if (parsed.targetDuration != null) buf.writeln(parsed.targetDuration);
    if (parsed.mediaSequence != null) buf.writeln(parsed.mediaSequence);

    for (int i = 0; i < downloadedCount && i < parsed.segments.length; i++) {
      final seg = parsed.segments[i];
      buf.writeln(seg.extinf ?? '#EXTINF:0,');
      buf.writeln(seg.localName);
    }
    buf.writeln('#EXT-X-ENDLIST');
    return buf.toString();
  }
}

// ── Internal data classes ───────────────────────────────────────────────────

class _SegmentEntry {
  final String url;
  final String localName;
  final String? extinf;
  _SegmentEntry({required this.url, required this.localName, this.extinf});
}

class _ParsedManifest {
  final String? version;
  final String? targetDuration;
  final String? mediaSequence;
  final List<_SegmentEntry> segments;
  _ParsedManifest({
    this.version,
    this.targetDuration,
    this.mediaSequence,
    required this.segments,
  });
}
