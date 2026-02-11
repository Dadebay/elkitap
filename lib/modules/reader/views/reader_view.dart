import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:cosmos_epub/cosmos_epub.dart';
import 'package:epubx/epubx.dart' hide Image;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:elkitap/core/constants/string_constants.dart';
import 'package:elkitap/core/theme/app_colors.dart';
import 'package:elkitap/data/network/network_manager.dart';
import 'package:elkitap/modules/auth/widget/login_bottom_sheet.dart';
import 'package:elkitap/modules/library/controllers/library_main_controller.dart';
import 'package:elkitap/modules/library/controllers/note_controller.dart';
import 'package:elkitap/modules/reader/controllers/reader_controller.dart';
import 'package:elkitap/modules/reader/mixins/progress_sync_mixin.dart';
import 'package:elkitap/modules/reader/mixins/reader_handlers_mixin.dart';
import 'package:elkitap/modules/reader/services/book_loader_service.dart';
import 'package:elkitap/modules/store/controllers/all_books_controller.dart';
import 'package:elkitap/modules/store/controllers/book_detail_controller.dart';
import 'package:elkitap/modules/store/model/book_item_model.dart';

class EpubReaderScreen extends StatefulWidget {
  final String imageUrl;
  final String? epubPath;
  final String bookId;
  final String bookDescription;
  final bool? isAddedToWantToRead;
  final bool? isMarkedAsFinished;
  final Book? book;
  final int? translateId;

  const EpubReaderScreen({
    required this.imageUrl,
    required this.bookDescription,
    this.isAddedToWantToRead,
    this.isMarkedAsFinished,
    this.epubPath,
    required this.bookId,
    this.book,
    this.translateId,
    super.key,
  });

  @override
  State<EpubReaderScreen> createState() => _EpubReaderScreenState();
}

class _EpubReaderScreenState extends State<EpubReaderScreen> with ProgressSyncMixin, ReaderHandlersMixin {
  // Controllers
  late final EpubController controller;
  late final LibraryMainController libraryMainController;
  @override
  late final GetAllBooksController allBooksController;
  late final NotesController notesController;
  late final BooksDetailController detailController;

  // Services
  late final BookLoaderService _bookLoader;
  final NetworkManager _networkManager = Get.find<NetworkManager>();

  // State
  double _downloadProgress = 0.0;
  bool _hasError = false;
  String? _errorMessage;
  bool _hasAppliedAudioProgress = false;
  EpubBook? _parsedEpubBook;

  // Getters for mixins
  @override
  String get uniqueBookId => _bookLoader.uniqueBookId;

  @override
  Book? get currentBook => widget.book;

  @override
  String get bookId => widget.bookId;

  @override
  void initState() {
    super.initState();

    // Initialize controllers
    libraryMainController = Get.find<LibraryMainController>();
    allBooksController = Get.find<GetAllBooksController>();

    // Initialize book loader service
    _bookLoader = BookLoaderService(
      networkManager: _networkManager,
      bookId: widget.bookId,
      epubPath: widget.epubPath,
      translateId: widget.translateId,
    );

    // Get or create book detail controller
    final controllerTag = widget.bookId;
    if (Get.isRegistered<BooksDetailController>(tag: controllerTag)) {
      detailController = Get.find<BooksDetailController>(tag: controllerTag);
      log('✅ Found existing BooksDetailController with tag: $controllerTag');
    } else {
      detailController = Get.put(BooksDetailController(), tag: controllerTag);
      log('📝 Created new BooksDetailController with tag: $controllerTag');
    }

    // Initialize reader controller
    controller = Get.put(EpubController());

    // Get or create notes controller
    if (Get.isRegistered<NotesController>()) {
      notesController = Get.find<NotesController>();
    } else {
      notesController = Get.put(NotesController());
    }

    // Register handlers
    registerAllHandlers();
    notesController.setCurrentBook(widget.bookId);

    log("Initializing EpubController with bookId: ${widget.bookId}");
    controller.initialize(bookId: int.parse(widget.bookId));

    // Use postFrameCallback to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeWithProgress();
    });
  }

  // Fetch progress and then initialize book
  Future<void> _initializeWithProgress() async {
    try {
      log('📖 Fetching book detail and progress before opening...');

      // Fetch book detail (which includes progress)
      await detailController.fetchBookDetail(int.parse(widget.bookId));

      log('✅ Progress fetched, now initializing book...');
    } catch (e) {
      log('⚠️ Error fetching progress before init: $e');
    } finally {
      // Always initialize the book, even if progress fetch fails
      await _initializeBook();
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  // Auth error checking methods (for mixin)
  @override
  bool isAuthError(dynamic error) {
    final errorStr = error.toString().toLowerCase();
    return errorStr.contains('authentication required') || errorStr.contains('unauthorized') || errorStr.contains('unauthenticated') || errorStr.contains('401');
  }

  @override
  void showLoginBottomSheet() {
    if (Get.isSnackbarOpen) {
      Get.closeAllSnackbars();
    }

    Get.bottomSheet(
      WillPopScope(
        onWillPop: () async => false,
        child: LoginBottomSheet(),
      ),
      isDismissible: true,
      enableDrag: true,
      isScrollControlled: true,
    );
  }

  // Helper methods
  String get _uniqueBookId => uniqueBookId;

  void _logError(String msg) => log('❌ ERROR: $msg');
  void _logInfo(String msg) => log('📘 INFO: $msg');

  bool _isAuthError(dynamic error) => isAuthError(error);
  void _showLoginBottomSheet() => showLoginBottomSheet();

  bool _isAuthErrorResponse(Map<String, dynamic> response) {
    if (response['success'] == false) {
      final statusCode = response['statusCode'];
      if (statusCode == 401) return true;

      final error = response['error']?.toString().toLowerCase() ?? '';
      final message = response['data']?['message']?.toString().toLowerCase() ?? '';

      return error.contains('authentication required') ||
          error.contains('unauthorized') ||
          error.contains('unauthenticated') ||
          message.contains('authentication required') ||
          message.contains('unauthorized') ||
          message.contains('unauthenticated');
    }
    return false;
  }

  double? _getAudioProgress() => getAudioProgress();
  void _cacheTotalPages(int totalPages) => cacheTotalPages(totalPages);
  void _saveTextProgressToAudio(int currentPage, int totalPages) => saveTextProgressToAudio(currentPage, totalPages);

  Future<void> _syncAudioProgressToTextBook() async {
    try {
      final audioProgress = getAudioProgress();
      if (audioProgress == null || audioProgress <= 0) {
        log('📖 No audio progress to sync');
        return;
      }

      log('🔄 Audio progress found: ${(audioProgress * 100).toStringAsFixed(1)}%');
      log('📝 Will apply on first page flip...');

      // Don't call CosmosEpub.setCurrentPageIndex here
      // Let the first onPageFlip handle it properly after book is fully loaded
    } catch (e) {
      log('⚠️ Error checking audio progress: $e');
    }
  }

  Future<void> _handleClose() async {
    try {
      log('🔐 CLOSING READER...');
      await controller.saveProgressAndClose();

      if (detailController.bookDetail.value != null) {
        await detailController.fetchProgress();
        log('✅ Progress refreshed');
      }

      if (mounted) {
        Get.back(result: true);
      }
    } catch (e) {
      log('❌ Error closing reader: $e');
      if (mounted) {
        Get.back(result: false);
      }
    }
  }

  // Core book initialization and loading
  Future<void> _initializeBook() async {
    try {
      setState(() {
        _hasError = false;
        _errorMessage = null;
        _downloadProgress = 0.05; // Start at 5% to show progress immediately
      });

      // Initialize CosmosEpub with retry logic
      bool initialized = false;
      int retryCount = 0;
      const maxRetries = 3;

      while (!initialized && retryCount < maxRetries) {
        try {
          await CosmosEpub.initialize();
          initialized = true;
          log('✅ CosmosEpub initialized (attempt ${retryCount + 1})');
          if (mounted) {
            setState(() => _downloadProgress = 0.10); // 10% after initialization
          }
        } catch (e) {
          retryCount++;
          log('⚠️ CosmosEpub.initialize() error (attempt $retryCount/$maxRetries): $e');

          if (retryCount < maxRetries) {
            // Wait before retry with exponential backoff
            await Future.delayed(Duration(milliseconds: 100 * retryCount));
          } else {
            // All retries failed
            log('❌ Failed to initialize CosmosEpub after $maxRetries attempts');
            throw Exception('Failed to initialize CosmosEpub: $e');
          }
        }
      }

      if (widget.epubPath != null && widget.epubPath!.isNotEmpty) {
        await _downloadAndOpenBook();
      } else {
        await _openAssetBook();
      }

      _setLastOpenedBook();
    } catch (e, st) {
      log('Initialize error: $e\n$st');

      // Check if it's an authentication error
      if (_isAuthError(e)) {
        _showLoginBottomSheet();
      } else {
        log('Failed to open book: $e');
      }
    }
  }

  void _setLastOpenedBook() {
    Book? bookToSave = widget.book;
    if (bookToSave == null) {
      bookToSave = allBooksController.books.firstWhereOrNull(
        (b) => b.id.toString() == widget.bookId,
      );
    }

    if (bookToSave != null) {
      libraryMainController.setLastOpenedBook(bookToSave);
      log('Set last opened book: ${bookToSave.name}');
    } else {
      log('Could not find book with ID ${widget.bookId} to set as last opened.');
    }
  }

  Future<Map<String, dynamic>> _fetchSignedUrl(String bookKey) async {
    final endpoint = '/books/file';
    final query = {'filename': bookKey};

    log('Calling NetworkManager.get -> $endpoint ? filename=$bookKey');
    try {
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
    } catch (e, st) {
      log('Signed URL fetch error: $e\n$st');
      rethrow;
    }
  }

  Future<void> _downloadAndOpenBook() async {
    try {
      log('📚 ========== EPUB DOWNLOAD & OPEN PROCESS START ==========');
      log('📚 Book ID: ${widget.bookId}');
      log('📚 Translate ID: ${widget.translateId}');
      log('📚 Unique Book ID: $_uniqueBookId');
      log('📚 EPUB Path (key): ${widget.epubPath}');

      setState(() {
        _downloadProgress = 0.15; // 15% when checking local file
      });

      final localPath = await _getLocalFilePath(widget.bookId);
      final file = File(localPath);
      log('📚 Local file path: $localPath');

      if (await file.exists()) {
        final fileSize = await file.length();
        log('📚 ✅ Local copy found: $localPath');
        log('📚 File size: ${(fileSize / 1024 / 1024).toStringAsFixed(2)} MB');

        // Check if file is valid (not empty or corrupted)
        if (fileSize > 0) {
          // 🎯 NEW: Parse book first in loading screen (0% to 90%)
          setState(() => _downloadProgress = 0.0);

          log('📖 Parsing locally cached book...');
          final parseStart = DateTime.now();

          _parsedEpubBook = await CosmosEpub.parseLocalBook(localPath: localPath);

          final parseDuration = DateTime.now().difference(parseStart);
          log('📖 ✅ Book parsed in ${parseDuration.inMilliseconds}ms');

          setState(() => _downloadProgress = 0.90);

          // 🎯 NEW: Precalculate page counts (90% to 92%)

          log('📊 Starting page count precalculation...');
          final precalcStart = DateTime.now();

          try {
            await CosmosEpub.precalculatePageCounts(
              epubBook: _parsedEpubBook!,
              bookId: _uniqueBookId,
              pageSize: MediaQuery.of(context).size,
              onProgress: (current, total) {
                if (mounted) {
                  final progressPercent = 0.90 + (0.02 * (current / total));
                  setState(() => _downloadProgress = progressPercent);
                }
              },
            );

            final precalcDuration = DateTime.now().difference(precalcStart);
            log('📊 ✅ Page counts precalculated in ${precalcDuration.inMilliseconds}ms');
          } catch (e) {
            log('⚠️ Page precalculation error: $e (will calculate on first open)');
          }

          // Prepare to open (92% to 100%)

          await _syncAudioProgressToTextBook();

          // Animate to 100%
          final prepSteps = 10;
          for (int i = 0; i < prepSteps; i++) {
            await Future.delayed(const Duration(milliseconds: 50));
            if (mounted) {
              setState(() {
                _downloadProgress = (0.92 + (0.08 * (i + 1) / prepSteps)).clamp(0.92, 1.0);
              });
            }
          }

          setState(() => _downloadProgress = 1.0);
          await Future.delayed(const Duration(milliseconds: 300));

          await _openPreparedBook(localPath);
          return;
        } else {
          log('📚 ⚠️ Local file is empty or corrupted, deleting and re-downloading');
          await file.delete();
        }
      }

      log('📚 ❌ No local copy found, need to download');

      final startFetchUrl = DateTime.now();
      final urlData = await _fetchSignedUrl(widget.epubPath!);
      final signedUrl = urlData['url'] as String;
      final expectedSize = urlData['size'] as int;
      final fetchUrlDuration = DateTime.now().difference(startFetchUrl);
      log('📚 ✅ Signed URL obtained in ${fetchUrlDuration.inMilliseconds}ms');

      // Parse and log URL components for debugging
      try {
        final uri = Uri.parse(signedUrl);
        log('📚 URL Protocol: ${uri.scheme}');
        log('📚 URL Host: ${uri.host}');
        log('📚 URL Path: ${uri.path}');
        if (uri.queryParameters.isNotEmpty) {
          log('📚 URL Query Parameters: ${uri.queryParameters}');
        }
      } catch (e) {
        log('📚 ⚠️ Could not parse URL: $e');
      }

      setState(() {
        _downloadProgress = 0.0;
      });

      final startDownload = DateTime.now();

      // 🎯 Download and parse in parallel
      await _downloadAndPrepareBook(signedUrl, localPath, expectedSize: expectedSize);

      final downloadDuration = DateTime.now().difference(startDownload);
      log('📚 ✅ Download and preparation completed in ${downloadDuration.inSeconds}s');

      // Book is already parsed and ready, just navigate
      log('📚 ========== EPUB DOWNLOAD & OPEN PROCESS END ==========');
    } catch (e, st) {
      _logError('Download/Open Error: $e\n$st');

      // Check if it's an authentication error
      if (_isAuthError(e)) {
        _showLoginBottomSheet();
      } else {
        _setError('Download failed: $e');
      }
    }
  }

  Future<String> _getLocalFilePath(String bookId) async {
    final directory = await getApplicationDocumentsDirectory();
    final booksDir = Directory('${directory.path}/books');

    if (!await booksDir.exists()) {
      await booksDir.create(recursive: true);
    }

    // Use epubPath (bookKey) as part of filename if available to support multiple translations
    if (widget.epubPath != null && widget.epubPath!.isNotEmpty) {
      // Create a safe filename from the path/key
      // key format example: "/private/eng-1765969217345-1765969217345.epub"
      final safeKey = widget.epubPath!.split('/').last;
      log('📁 Using translation-specific cache path: ${booksDir.path}/$safeKey');
      return '${booksDir.path}/$safeKey';
    }

    log('📁 Using default cache path: ${booksDir.path}/book_$_uniqueBookId.epub');
    return '${booksDir.path}/book_$_uniqueBookId.epub';
  }

  /// Downloads book and prepares it in background while showing smooth progress
  /// This ensures when download completes, book is ready to open immediately
  Future<void> _downloadAndPrepareBook(String url, String savePath, {int expectedSize = 0}) async {
    try {
      log('⬇️ 🎯 Starting download with background preparation...');
      log('⬇️ Save path: $savePath');
      log('⬇️ Expected size from API: $expectedSize bytes (${(expectedSize / 1024 / 1024).toStringAsFixed(2)} MB)');

      final client = HttpClient();
      final req = await client.getUrl(Uri.parse(url));
      final resp = await req.close();

      log('⬇️ HTTP Response status: ${resp.statusCode}');
      log('⬇️ Content-Length: ${resp.contentLength} bytes (${(resp.contentLength / 1024 / 1024).toStringAsFixed(2)} MB)');

      if (resp.statusCode != 200) {
        final body = await resp.transform(utf8.decoder).join();
        _logError('Download failed. Body: $body');
        throw Exception('Failed to download file, status: ${resp.statusCode}');
      }

      final file = File(savePath);
      final sink = file.openWrite();

      final startTime = DateTime.now();
      final totalBytes = resp.contentLength > 0 ? resp.contentLength : expectedSize;
      int receivedBytes = 0;

      // Minimum display time for smooth UX (show progress for at least this duration)
      const minDisplayDuration = Duration(seconds: 3);

      // Track real download progress
      await for (final chunk in resp) {
        sink.add(chunk);
        receivedBytes += chunk.length;

        if (totalBytes > 0) {
          // Calculate real download progress (0.0 to 0.90)
          // We reserve last 10% for book parsing and preparation
          final realProgress = (receivedBytes / totalBytes) * 0.90;

          if (mounted) {
            setState(() {
              _downloadProgress = realProgress.clamp(0.0, 0.90);
            });
          }
        }
      }

      await sink.close();
      final downloadDuration = DateTime.now().difference(startTime);
      final finalSize = await file.length();
      final avgSpeed = downloadDuration.inSeconds > 0 ? finalSize / downloadDuration.inSeconds : finalSize;

      log('⬇️ ✅ Download completed!');
      log('⬇️ Final size: ${(finalSize / 1024 / 1024).toStringAsFixed(2)} MB');
      log('⬇️ Download duration: ${downloadDuration.inSeconds}s');
      log('⬇️ Average speed: ${(avgSpeed / 1024 / 1024).toStringAsFixed(2)} MB/s');

      // Ensure minimum display time for smooth UX
      final elapsedTime = DateTime.now().difference(startTime);
      if (elapsedTime < minDisplayDuration) {
        final remainingTime = minDisplayDuration - elapsedTime;
        log('⏳ Extending download display for smooth UX: ${remainingTime.inMilliseconds}ms...');

        // Smoothly animate progress from current to 90% during remaining time
        final steps = (remainingTime.inMilliseconds / 50).ceil();
        final currentProgress = _downloadProgress;
        final targetProgress = 0.90;
        final progressStep = (targetProgress - currentProgress) / steps;

        for (int i = 0; i < steps; i++) {
          await Future.delayed(const Duration(milliseconds: 50));
          if (mounted) {
            setState(() {
              _downloadProgress = (currentProgress + (progressStep * (i + 1))).clamp(0.0, 0.90);
            });
          }
        }
      }

      // 🎯 NEW: Parse book while showing progress (90% to 95%)
      if (mounted) {
        setState(() {
// New translation key
          _downloadProgress = 0.90;
        });
      }

      log('📖 Starting book parsing (loading pages and content)...');
      final parseStart = DateTime.now();

      // 🔍 Check if downloaded file is a .zip containing an .epub
      String actualEpubPath = savePath;

      if (savePath.toLowerCase().endsWith('.zip')) {
        log('📦 Detected .zip file, checking if it contains .epub...');

        try {
          final zipFile = File(savePath);
          final bytes = await zipFile.readAsBytes();
          final archive = ZipDecoder().decodeBytes(bytes);

          // Look for .epub file inside the zip
          ArchiveFile? epubFile;
          for (var file in archive.files) {
            if (!file.isFile) {
              continue; // Skip directories
            }
            if (file.name.toLowerCase().endsWith('.epub')) {
              epubFile = file;
              log('✅ Found .epub inside zip: ${file.name}');
              break;
            }
          }

          if (epubFile != null && epubFile.content != null) {
            // Extract the .epub file
            final extractedEpubPath = savePath.replaceAll('.zip', '.epub');
            final extractedFile = File(extractedEpubPath);
            await extractedFile.writeAsBytes(epubFile.content as List<int>);

            log('✅ Extracted .epub to: $extractedEpubPath');

            // Delete the original .zip file
            try {
              await zipFile.delete();
              log('🗑️ Deleted original .zip file');
            } catch (e) {
              log('⚠️ Could not delete .zip file: $e');
            }

            actualEpubPath = extractedEpubPath;
          } else {
            log('⚠️ No .epub file found inside .zip, will try to parse as is');
          }
        } catch (e) {
          log('⚠️ Error extracting .zip file: $e, will try to parse as is');
        }
      }

      // Parse the book in the loading screen
      _parsedEpubBook = await CosmosEpub.parseLocalBook(localPath: actualEpubPath);

      final parseDuration = DateTime.now().difference(parseStart);
      log('📖 ✅ Book parsed in ${parseDuration.inMilliseconds}ms');

      // 🎯 NEW: Precalculate page counts (95% to 97%)
      if (mounted) {
        setState(() {
// New translation key
          _downloadProgress = 0.92;
        });
      }

      log('📊 Starting page count precalculation...');
      final precalcStart = DateTime.now();

      try {
        await CosmosEpub.precalculatePageCounts(
          epubBook: _parsedEpubBook!,
          bookId: _uniqueBookId,
          pageSize: MediaQuery.of(context).size,
          onProgress: (current, total) {
            if (mounted) {
              final progressPercent = 0.92 + (0.03 * (current / total));
              setState(() => _downloadProgress = progressPercent);
            }
          },
        );

        final precalcDuration = DateTime.now().difference(precalcStart);
        log('📊 ✅ Page counts precalculated in ${precalcDuration.inMilliseconds}ms');
      } catch (e) {
        log('⚠️ Page precalculation error: $e (will calculate on first open)');
      }

      // Animate progress from 90% to 95%
      if (mounted) {
        setState(() {
          _downloadProgress = 0.95;
        });
      }

      // 🎯 NEW: Prepare book for opening (95% to 100%)
      if (mounted) {
        setState(() {
// New translation key
          _downloadProgress = 0.95;
        });
      }

      log('🎯 Preparing book to open...');

      // Sync audio progress before opening
      await _syncAudioProgressToTextBook();

      // Animate to 100%
      final prepSteps = 10;
      for (int i = 0; i < prepSteps; i++) {
        await Future.delayed(const Duration(milliseconds: 50));
        if (mounted) {
          setState(() {
            _downloadProgress = (0.95 + (0.05 * (i + 1) / prepSteps)).clamp(0.95, 1.0);
          });
        }
      }

      // Set to 100%
      if (mounted) {
        setState(() {
          _downloadProgress = 1.0;
        });
      }

      log('📖 ✅ Book ready to open!');

      final totalDuration = DateTime.now().difference(startTime);
      log('⬇️ 🎯 Total process completed in ${totalDuration.inSeconds}s (book parsed and ready)');

      // Small delay to show 100% completion
      await Future.delayed(const Duration(milliseconds: 300));

      // Now open the book instantly (no more loading!)
      await _openPreparedBook(savePath);
    } catch (e, st) {
      _logError('Download/Prepare error: $e\n$st');

      try {
        final file = File(savePath);
        if (await file.exists()) await file.delete();
      } catch (_) {}

      rethrow;
    }
  }

  /// Opens a pre-parsed book instantly - no more loading!
  Future<void> _openPreparedBook(String filePath) async {
    try {
      log('🚀 Opening pre-prepared book instantly...');

      if (_parsedEpubBook == null) {
        log('⚠️ No parsed book found, falling back to normal opening');
        await _openDownloadedBook(filePath);
        return;
      }

      if (mounted) {
        setState(() {
          _downloadProgress = 0.95; // 95% when opening
        });
      }

      final startOpen = DateTime.now();

      try {
        // Ensure CosmosEpub is initialized before opening with retry logic
        bool initialized = false;
        int retryCount = 0;
        const maxRetries = 3;

        while (!initialized && retryCount < maxRetries) {
          try {
            await CosmosEpub.initialize();
            initialized = true;
            log('✅ CosmosEpub initialized for prepared book (attempt ${retryCount + 1})');
          } catch (e) {
            retryCount++;
            log('⚠️ CosmosEpub.initialize() error (attempt $retryCount/$maxRetries): $e');

            if (retryCount < maxRetries) {
              // Wait before retry with exponential backoff
              await Future.delayed(Duration(milliseconds: 100 * retryCount));
            } else {
              // All retries failed, throw error
              log('❌ Failed to initialize CosmosEpub after $maxRetries attempts');
              throw Exception('Failed to initialize CosmosEpub: $e');
            }
          }
        }

        await CosmosEpub.openParsedBook(
          epubBook: _parsedEpubBook!,
          context: context,
          bookDescription: widget.bookDescription,
          imageUrl: widget.imageUrl,
          isInShelf: widget.isAddedToWantToRead ?? false,
          isInMyBooks: widget.isMarkedAsFinished ?? false,
          bookId: _uniqueBookId,
          onPageFlip: (currentPage, totalPages) {
            log('📄 Page flip: $currentPage / $totalPages');

            // Cache total pages for future syncs (first time or if changed)
            _cacheTotalPages(totalPages);

            // On first page flip, check if we should apply audio progress
            if (!_hasAppliedAudioProgress && totalPages > 0) {
              _hasAppliedAudioProgress = true;
              final audioProgress = _getAudioProgress();

              if (audioProgress != null && audioProgress > 0.01) {
                final targetPage = (audioProgress * totalPages).round();
                final currentProgress = currentPage / totalPages;
                final progressDiff = (audioProgress - currentProgress).abs();

                log('📊 First page flip - checking audio progress:');
                log('   Audio progress: ${(audioProgress * 100).toStringAsFixed(1)}%');
                log('   Current page: $currentPage / $totalPages (${(currentProgress * 100).toStringAsFixed(1)}%)');
                log('   Target page: $targetPage');
                log('   Progress diff: ${(progressDiff * 100).toStringAsFixed(1)}%');

                // Jump to target page if different (handles both forward and backward)
                if (targetPage != currentPage) {
                  if (targetPage > currentPage) {
                    log('🎯 Jumping forward to page $targetPage');
                  } else {
                    log('🔙 Current page is ahead - jumping back to page $targetPage');
                  }

                  CosmosEpub.setCurrentPageIndex(_uniqueBookId, targetPage);
                  log('✅ Jump command sent to page $targetPage');
                  return; // Don't save incorrect page
                } else {
                  log('✅ Already at correct page');
                }
              } else {
                log('📖 No audio progress to apply (progress: $audioProgress)');
              }
            }

            controller.onPageFlip(currentPage, totalPages);

            // Save text book progress to audio progress as well for bidirectional sync
            _saveTextProgressToAudio(currentPage, totalPages);
          },
          onLastPage: (lastPageIndex) {
            controller.onLastPage(lastPageIndex);
          },
        );

        final openDuration = DateTime.now().difference(startOpen);
        log('🚀 ✅ Pre-prepared book opened instantly in ${openDuration.inMilliseconds}ms');

        await _handleClose();
      } on Exception catch (e, st) {
        final errorString = e.toString();
        _logError('Failed to open prepared EPUB: $errorString\n$st');

        // Check if it's a parsing error
        if (errorString.contains('TOC file') || errorString.contains('EPUB parsing error') || errorString.contains('does not contain head element')) {
          log('⚠️ EPUB format issue detected - showing user-friendly error');

          // Close loading dialog if open
          if (mounted && Navigator.canPop(context)) {
            Navigator.pop(context);
          }

          // Show user-friendly error dialog
          if (mounted) {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => AlertDialog(
                title: Text('book_format_error'.tr.isEmpty ? 'Format Hatası' : 'book_format_error'.tr),
                content: Text('epub_format_not_supported'.tr.isEmpty ? 'Bu kitabın formatı desteklenmiyor. Lütfen farklı bir format deneyin.' : 'epub_format_not_supported'.tr),
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
        } else {
          // Generic error
          _handleGenericOpenError();
        }
      }
    } catch (e, st) {
      _logError('Failed to open prepared EPUB: $e\n$st');
      _handleGenericOpenError();
    }
  }

  void _handleGenericOpenError() {
    // Close loading dialog if open
    if (mounted && Navigator.canPop(context)) {
      Navigator.pop(context);
    }

    // Show generic error
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: Text('error'.tr.isEmpty ? 'Hata' : 'error'.tr),
          content: Text('failed_to_open_book'.tr.isEmpty ? 'Kitap açılamadı. Lütfen tekrar deneyin.' : 'failed_to_open_book'.tr),
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
  }

  /// Opens a downloaded book from local file path
  Future<void> _openDownloadedBook(String filePath) async {
    try {
      if (mounted) {
        setState(() {
          _downloadProgress = 0.95; // 95% when opening
        });
      }

      // Log file size for debugging
      final file = File(filePath);
      if (await file.exists()) {
        final fileSize = await file.length();
        log('📖 File size: ${(fileSize / 1024 / 1024).toStringAsFixed(2)} MB');
      }

      // Sync audio progress to text book before opening
      await _syncAudioProgressToTextBook();

      final startOpen = DateTime.now();

      try {
        await CosmosEpub.openLocalBook(
          localPath: filePath,
          context: context,
          bookDescription: widget.bookDescription,
          imageUrl: widget.imageUrl,
          isInShelf: widget.isAddedToWantToRead ?? false,
          isInMyBooks: widget.isMarkedAsFinished ?? false,
          bookId: _uniqueBookId,
          onPageFlip: (currentPage, totalPages) {
            log('📄 Page flip: $currentPage / $totalPages');

            // Cache total pages for future syncs (first time or if changed)
            _cacheTotalPages(totalPages);

            // On first page flip, check if we should apply audio progress
            if (!_hasAppliedAudioProgress && totalPages > 0) {
              _hasAppliedAudioProgress = true;
              final audioProgress = _getAudioProgress();

              if (audioProgress != null && audioProgress > 0.01) {
                final targetPage = (audioProgress * totalPages).round();
                final currentProgress = currentPage / totalPages;
                final progressDiff = (audioProgress - currentProgress).abs();

                log('📊 First page flip - checking audio progress:');
                log('   Audio progress: ${(audioProgress * 100).toStringAsFixed(1)}%');
                log('   Current page: $currentPage / $totalPages (${(currentProgress * 100).toStringAsFixed(1)}%)');
                log('   Target page: $targetPage');
                log('   Progress diff: ${(progressDiff * 100).toStringAsFixed(1)}%');

                // Jump to target page if different (handles both forward and backward)
                if (targetPage != currentPage) {
                  if (targetPage > currentPage) {
                    log('🎯 Jumping forward to page $targetPage');
                  } else {
                    log('🔙 Current page is ahead - jumping back to page $targetPage');
                  }

                  CosmosEpub.setCurrentPageIndex(_uniqueBookId, targetPage);
                  log('✅ Jump command sent to page $targetPage');
                  return; // Don't save incorrect page
                } else {
                  log('✅ Already at correct page');
                }
              } else {
                log('📖 No audio progress to apply (progress: $audioProgress)');
              }
            }

            controller.onPageFlip(currentPage, totalPages);

            // Save text book progress to audio progress as well for bidirectional sync
            _saveTextProgressToAudio(currentPage, totalPages);
          },
          onLastPage: (lastPageIndex) {
            controller.onLastPage(lastPageIndex);
          },
        );

        final openDuration = DateTime.now().difference(startOpen);
        log('📖 ✅ Book opened successfully in ${openDuration.inMilliseconds}ms');

        await _handleClose();
      } on Exception catch (e, st) {
        final errorString = e.toString();
        _logError('Failed to open EPUB: $errorString\n$st');

        // Check if it's a parsing error
        if (errorString.contains('TOC file') || errorString.contains('EPUB parsing error') || errorString.contains('does not contain head element')) {
          log('⚠️ EPUB format issue detected - showing user-friendly error');

          // Close loading dialog if open
          if (mounted && Navigator.canPop(context)) {
            Navigator.pop(context);
          }

          // Show user-friendly error dialog
          if (mounted) {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => AlertDialog(
                title: Text('epub_format_error'.tr.isEmpty ? 'Format Hatası' : 'epub_format_error'.tr),
                content: Text('epub_corrupted_message'.tr.isEmpty
                    ? 'Bu EPUB dosyasının formatında bir sorun var. Dosya bozuk olabilir veya desteklenmeyen bir formatta olabilir.\n\nLütfen farklı bir kitap deneyin veya bu kitabı yeniden indirin.'
                    : 'epub_corrupted_message'.tr),
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
          return;
        }

        // For other errors, rethrow
        throw Exception('Failed to open book: $e');
      }
    } catch (e, st) {
      _logError('Failed to open downloaded EPUB: $e\n$st');

      // Close loading dialog if open
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      // Show generic error
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: Text('error'.tr.isEmpty ? 'Hata' : 'error'.tr),
            content: Text('failed_to_open_book'.tr.isEmpty ? 'Kitap açılamadı. Lütfen tekrar deneyin.' : 'failed_to_open_book'.tr),
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
    }
  }

  Future<void> _openAssetBook() async {
    try {
      _logInfo('Opening fallback asset epub');

      if (mounted) Get.back();
    } catch (e, st) {
      _logError('Failed to open asset book: $e\n$st');
      _setError('Failed to open fallback book: $e');
    }
  }

  void _setError(String message) {
    if (!mounted) return;
    setState(() {
      _hasError = true;
      _errorMessage = message;
    });

    Get.back();
    Get.snackbar(
      'error'.tr,
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red,
      colorText: Colors.white,
      duration: const Duration(seconds: 4),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        await _handleClose();
        return false; // _handleClose already calls Get.back()
      },
      child: Scaffold(
        body: SafeArea(
          child: SizedBox.expand(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.network(widget.imageUrl, width: 220, height: 330, fit: BoxFit.cover),
                          const SizedBox(height: 80),
                          Image.asset('assets/images/l1.png', width: 60, height: 30, fit: BoxFit.cover),
                          const SizedBox(height: 20),
                          Text(
                            'loading_t'.tr,
                            style: const TextStyle(
                              fontSize: 15,
                              fontFamily: StringConstants.SFPro,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: LinearProgressIndicator(
                            value: _downloadProgress,
                            backgroundColor: Colors.grey[800],
                            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.mainColor),
                            minHeight: 6,
                          ),
                        ),
                        Container(
                          width: 60,
                          alignment: Alignment.centerRight,
                          child: Text(
                            '${(_downloadProgress * 100).toStringAsFixed(0)}%',
                            textAlign: TextAlign.end,
                            style: const TextStyle(
                              color: AppColors.mainColor,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_hasError)
                    Padding(
                      padding: const EdgeInsets.only(top: 24.0),
                      child: Column(
                        children: [
                          Text(
                            _errorMessage ?? 'Unknown error',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white70),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _hasError = false;
                                _errorMessage = null;
                                _downloadProgress = 0.0;
                              });
                              _initializeBook();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                            ),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
