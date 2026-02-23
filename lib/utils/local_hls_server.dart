import 'dart:developer';
import 'dart:io';

/// Lightweight local HTTP server that serves HLS files (m3u8 + .ts segments)
/// from a directory on disk.
///
/// iOS AVPlayer refuses to play HLS manifests from file:// URIs
/// (CoreMediaErrorDomain -12865). Serving them over localhost HTTP circumvents
/// this while keeping all data fully offline.
class LocalHlsServer {
  HttpServer? _server;
  String? _servingDir;

  /// The localhost port the server is bound to, or 0 when stopped.
  int get port => _server?.port ?? 0;

  /// Whether the server is currently running.
  bool get isRunning => _server != null;

  /// Starts serving files from [directoryPath] on a random available port.
  /// Returns the base URL, e.g. `http://localhost:54321`.
  Future<String> start(String directoryPath) async {
    // If already serving the same directory, reuse.
    if (_server != null && _servingDir == directoryPath) {
      return 'http://localhost:${_server!.port}';
    }

    // Stop any previous server
    await stop();

    _servingDir = directoryPath;
    _server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    log('🌐 LocalHlsServer started on port ${_server!.port}, serving: $directoryPath');

    _server!.listen((HttpRequest request) async {
      // Build file path from the request URI (relative to the serving dir).
      // e.g. /index.m3u8 → <directoryPath>/index.m3u8
      final requestedPath = Uri.decodeFull(request.uri.path);
      final filePath = '$directoryPath$requestedPath';
      final file = File(filePath);

      if (await file.exists()) {
        try {
          final bytes = await file.readAsBytes();

          // Determine Content-Type
          String contentType = 'application/octet-stream';
          if (filePath.endsWith('.m3u8')) {
            contentType = 'application/vnd.apple.mpegurl';
          } else if (filePath.endsWith('.ts')) {
            contentType = 'video/mp2t';
          } else if (filePath.endsWith('.aac')) {
            contentType = 'audio/aac';
          }

          request.response
            ..statusCode = HttpStatus.ok
            ..headers.set('Content-Type', contentType)
            ..headers.set('Content-Length', bytes.length.toString())
            ..headers.set('Accept-Ranges', 'bytes')
            ..add(bytes);
          await request.response.close();
        } catch (e) {
          log('🌐 LocalHlsServer error serving $requestedPath: $e');
          request.response.statusCode = HttpStatus.internalServerError;
          await request.response.close();
        }
      } else {
        log('🌐 LocalHlsServer 404: $requestedPath');
        request.response.statusCode = HttpStatus.notFound;
        await request.response.close();
      }
    });

    return 'http://localhost:${_server!.port}';
  }

  /// Stops the server.
  Future<void> stop() async {
    if (_server != null) {
      log('🌐 LocalHlsServer stopping (port ${_server!.port})');
      await _server!.close(force: true);
      _server = null;
      _servingDir = null;
    }
  }
}
