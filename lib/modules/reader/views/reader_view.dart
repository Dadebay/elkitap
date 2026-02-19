import 'dart:developer';
import 'dart:io';
import 'dart:async';
import 'package:flutter_epub_viewer/flutter_epub_viewer.dart' as epub;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:get/get.dart';
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
import 'package:elkitap/modules/reader/models/reader_theme_model.dart';
import 'package:elkitap/modules/reader/widgets/chapter_drawer.dart';
import 'package:elkitap/modules/reader/widgets/theme_settings_sheet.dart';
import 'package:elkitap/modules/reader/widgets/add_note_sheet.dart';
import 'package:elkitap/modules/reader/widgets/reader_actions_sheet.dart';
import 'package:elkitap/modules/reader/helpers/reader_helpers.dart';
import 'package:elkitap/modules/reader/helpers/book_download_service.dart';
import 'package:elkitap/modules/reader/helpers/reader_ui_builder.dart';

class EpubReaderScreen extends StatefulWidget {
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

  final Book? book;
  final String bookDescription;
  final String bookId;
  final String? epubPath;
  final String imageUrl;
  final bool? isAddedToWantToRead;
  final bool? isMarkedAsFinished;
  final int? translateId;

  @override
  State<EpubReaderScreen> createState() => _EpubReaderScreenState();
}

class _EpubReaderScreenState extends State<EpubReaderScreen> with ProgressSyncMixin, ReaderHandlersMixin {
  late final GetAllBooksController allBooksController;

  late final EpubController controller;

  late final BooksDetailController detailController;
  late final LibraryMainController libraryMainController;
  late final NotesController notesController;

  late final BookLoaderService _bookLoader;

  List<epub.EpubChapter> _chapters = [];
  String? _currentCfi;
  String _currentChapterTitle = '';
  String? _currentHref;

  late ReaderThemeModel _currentTheme;

  double _downloadProgress = 0.0;

  epub.EpubSource? _epubSource;
  String? _errorMessage;
  int _fontSize = 18;
  bool _hasAppliedAudioProgress = false;
  bool _hasError = false;
  bool _hasInitializedReaderTheme = false;
  bool _hasStartedInitialization = false;
  bool _isInitializingBook = false;
  bool _userHasManuallySelectedTheme = false;
  Brightness? _lastBrightness;
  String? _openedFilePath;
  Key _epubViewerKey = UniqueKey();

  bool _isReaderReady = false;

  bool _isLoadingPages = true;
  final NetworkManager _networkManager = Get.find<NetworkManager>();
  String _selectedText = '';
  String? _selectedCfi;
  Rect? _selectionRect;
  bool _showControls = true;
  DateTime? _touchDownAt;

  double _touchDownX = 0.0;

  double _touchDownY = 0.0;
  final epub.EpubController _viewerController = epub.EpubController();
  int _viewerCurrentPage = 1;
  int _viewerTotalPages = 1;
  int _liveTotalPages = 1;

  bool _isProgressLongPressed = false;
  double _tempSliderValue = 0.0;
  double _dragStartValue = 0.0;
  double _dragStartLocalX = 0.0;
  double _lastProgressFactor = 0.0;

  Timer? _initialLoadingTimer;

  String? _cachedLocations;

  bool _isRegeneratingLocations = false;
  bool _isRestoringProgress = false;
  double? _pendingRestoreProgress;
  Timer? _restoreRetryTimer;
  int _restoreRelocateLogCount = 0;
  int _restoreRetryCount = 0;

  Map<String, int> _chapterPages = {};

  @override
  String get bookId => widget.bookId;

  @override
  Book? get currentBook => widget.book;

  @override
  void dispose() {
    _initialLoadingTimer?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    libraryMainController = Get.find<LibraryMainController>();
    allBooksController = Get.find<GetAllBooksController>();

    _bookLoader = BookLoaderService(
      networkManager: _networkManager,
      bookId: widget.bookId,
      epubPath: widget.epubPath,
      translateId: widget.translateId,
    );

    final controllerTag = widget.bookId;
    if (Get.isRegistered<BooksDetailController>(tag: controllerTag)) {
      detailController = Get.find<BooksDetailController>(tag: controllerTag);
      log('Found existing BooksDetailController with tag: $controllerTag');
    } else {
      detailController = Get.put(BooksDetailController(), tag: controllerTag);
      log('Created new BooksDetailController with tag: $controllerTag');
    }

    controller = Get.put(EpubController());

    if (Get.isRegistered<NotesController>()) {
      notesController = Get.find<NotesController>();
    } else {
      notesController = Get.put(NotesController());
    }

    registerAllHandlers();

    log("📚 READER: Initializing EpubController with bookId: ${widget.bookId}");
    log("   Translate ID: ${widget.translateId}");
    log("   uniqueBookId: $_uniqueBookId");

    controller.initialize(bookId: int.parse(widget.bookId));

    // Safety watchdog: keep loading state strict until VPP is ready
    _initialLoadingTimer = Timer(const Duration(seconds: 8), () {
      if (mounted && _isLoadingPages) {
        log('⏱️ Still waiting for VPP lock; keep loading visible (strict mode)');
      }
    });

    // Pre-load cached epub.js locations for fast reopening (font-size-specific)
    _cachedLocations = getCachedLocationsData(fontSize: _fontSize);
    if (_cachedLocations != null) {
      log('⚡ Found cached locations for $_uniqueBookId at fontSize $_fontSize (${_cachedLocations!.length} chars) — will skip locations.generate()');
    } else {
      log('📖 No cached locations for $_uniqueBookId at fontSize $_fontSize — first open or font changed');
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      log("📚 READER: PostFrameCallback - setting current book and initializing with progress");
      notesController.setCurrentBook(widget.bookId);
      _initializeWithProgress();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final currentBrightness = Theme.of(context).brightness;
    final isDarkMode = currentBrightness == Brightness.dark;

    // Initialize theme on first run
    if (!_hasInitializedReaderTheme) {
      _currentTheme = isDarkMode ? ReaderThemeModel.darkThemes.first : ReaderThemeModel.lightThemes.first;
      _lastBrightness = currentBrightness;
      _hasInitializedReaderTheme = true;
      return;
    }

    // Update theme when system brightness changes, but only if user hasn't manually selected a theme
    if (_lastBrightness != currentBrightness && !_userHasManuallySelectedTheme) {
      setState(() {
        _currentTheme = isDarkMode ? ReaderThemeModel.darkThemes.first : ReaderThemeModel.lightThemes.first;
        _lastBrightness = currentBrightness;
      });

      // Update the epub viewer theme if it's already initialized
      if (_isReaderReady) {
        _viewerController.updateTheme(theme: _currentTheme.epubTheme);
      }
    }
  }

  @override
  bool isAuthError(dynamic error) {
    return ReaderHelpers.isAuthError(error);
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

  @override
  String get uniqueBookId => _bookLoader.uniqueBookId;

  Future<void> _initializeWithProgress() async {
    if (_hasStartedInitialization) {
      log('⏭️ _initializeWithProgress already started, skipping duplicate call');
      return;
    }
    _hasStartedInitialization = true;

    try {
      log('📚 READER INIT: Starting _initializeWithProgress');
      log('   Book ID: ${widget.bookId}');
      log('   uniqueBookId: $_uniqueBookId');
      log('   Fetching book detail and progress in parallel...');

      final bookDetailFuture = detailController.fetchBookDetail(int.parse(widget.bookId));
      final progressFuture = detailController.fetchProgress();
      final initBookFuture = _initializeBook();

      await Future.wait([
        bookDetailFuture.catchError((e, st) {
          log('⚠️ fetchBookDetail error (non-fatal): $e');
        }),
        progressFuture.catchError((e, st) {
          log('⚠️ fetchProgress error (non-fatal): $e');
        }),
      ]);
      log('   Book detail and progress fetched');

      await initBookFuture;
      log('   Book initialization completed');
    } catch (e, st) {
      log('❌ Error in _initializeWithProgress: $e');
      log('Stack trace: $st');
    }
  }

  String get _uniqueBookId => uniqueBookId;

  void _logError(String msg) => log('ERROR: $msg');

  void _logInfo(String msg) => log('INFO: $msg');

  bool _isAuthError(dynamic error) => ReaderHelpers.isAuthError(error);

  void _showLoginBottomSheet() => showLoginBottomSheet();

  double? _getAudioProgress() => getAudioProgress();

  void _cacheTotalPages(int totalPages) => cacheTotalPages(totalPages);

  void _saveTextProgressToAudio(int currentPage, int totalPages) => saveTextProgressToAudio(currentPage, totalPages);

  Future<void> _buildChapterPages() async {
    if (_chapters.isEmpty) {
      log('⚠️ _buildChapterPages called but _chapters is empty');
      return;
    }

    try {
      log('🗺️ Building chapter-to-page mapping for ${_chapters.length} chapters...');
      final pageInfo = await _viewerController.getPageInfo();
      final totalPages = (pageInfo['totalPages'] as num?)?.toInt() ?? 1;
      log('📊 Total pages from pageInfo: $totalPages');

      if (totalPages <= 10) {
        log('⏸️ Skipping chapter page mapping (totalPages=$totalPages too low)');
        return;
      }

      final accuratePages = await _viewerController.getAllChapterPages();
      if (accuratePages.isNotEmpty) {
        _viewerController.updateChapterStartPages(accuratePages);
        log('✅ Updated ${accuratePages.length} chapter startPage values from JS');
      }

      final Map<String, int> newChapterPages = {};

      for (int i = 0; i < _chapters.length; i++) {
        final chapter = _chapters[i];

        final page = chapter.startPage ?? (((i * totalPages) / _chapters.length).round() + 1).clamp(1, totalPages);
        newChapterPages[chapter.href] = page;
        log('📖 ${chapter.title.trim().replaceAll(RegExp(r'\s+'), ' ')} → page $page (index $i/${_chapters.length})');
      }

      if (mounted) {
        setState(() {
          _chapterPages = newChapterPages;
        });

        cacheChapterMapping(newChapterPages);
        log('✅ Chapter pages built and cached: ${_chapterPages.length} chapters mapped (will be refined during navigation)');
      }
    } catch (e, stackTrace) {
      log('❌ Error building chapter pages: $e');
      log('Stack trace: $stackTrace');
    }
  }

  Future<void> _handleClose() async {
    try {
      log('CLOSING READER...');
      await controller.saveProgressAndClose();

      if (detailController.bookDetail.value != null) {
        await detailController.fetchProgress();
        log('Progress refreshed');
      }

      if (mounted) {
        Get.back(result: true);
      }
    } catch (e) {
      log('Error closing reader: $e');
      if (mounted) {
        Get.back(result: false);
      }
    }
  }

  Future<void> _updatePageInfo({bool skipProgressSave = false}) async {
    try {
      final pageInfo = await _viewerController.getPageInfo();
      final currentPage = (pageInfo['currentPage'] as num?)?.toInt() ?? 1;
      final totalPages = (pageInfo['totalPages'] as num?)?.toInt() ?? 1;
      final vppReady = pageInfo['vppReady'] == true;
      final vppSampleCount = (pageInfo['vppSampleCount'] as num?)?.toInt() ?? 0;

      _liveTotalPages = totalPages;

      // Enhanced page info logging
      log('╔═══════════════════════════════════════════════════════════╗');
      log('║  📖 READER STATE UPDATE                                   ║');
      log('╠═══════════════════════════════════════════════════════════╣');
      log('║  📝 Font Size:        $_fontSize                           ║');
      log('║  📄 Current Page:     $currentPage / $totalPages           ║');
      log('║  🔒 VPP Status:       ${vppReady ? "LOCKED ✅" : "Calibrating... ($vppSampleCount samples)"}  ║');
      log('║  📊 Display Pages:    $_viewerTotalPages                   ║');
      log('║  🔄 Live Total:       $_liveTotalPages                     ║');
      log('╚═══════════════════════════════════════════════════════════╝');

      if (mounted) {
        setState(() {
          _viewerCurrentPage = currentPage;

          // Only show page count and dismiss loading when VPP is locked
          if (totalPages > 1 && vppReady) {
            _viewerTotalPages = totalPages;

            if (_isLoadingPages) {
              _isLoadingPages = false;
              _initialLoadingTimer?.cancel();
              log('✅ VPP locked - final page count: $totalPages pages');
            }
          } else if (totalPages > 1 && !vppReady) {
            log('⏳ VPP calibrating (samples=$vppSampleCount) - keeping loading spinner visible...');
          }
        });
      }

      // Mark reader ready to dismiss loading overlay early (allows navigation during VPP calibration)
      if (totalPages > 1 && !_isReaderReady) {
        _markReaderReadyIfPossible();
      }

      // Apply audio progress immediately (don't wait for VPP lock)
      if (totalPages > 1 && !_hasAppliedAudioProgress) {
        _applyAudioProgressIfNeeded();
      }

      // Save progress only after VPP is ready (fully calibrated)
      if (totalPages > 1 && vppReady) {
        _cacheTotalPages(totalPages);

        if (!skipProgressSave) {
          controller.onPageFlip(currentPage, totalPages);
          _saveTextProgressToAudio(currentPage, totalPages);
        } else {
          log('⏸️ Skipping progress save during initialization (page: $currentPage/$totalPages)');
        }
      } else if (totalPages > 1) {
        log('⏸️ Waiting VPP lock before cache/save (samples=$vppSampleCount, pending=$totalPages pages)');
      }
    } catch (e) {
      log('Error getting page info: $e');
    }
  }

  Future<void> _retryPageInfoUntilValid() async {
    int retries = 0;
    const maxRetries = 10;
    const retryDelay = Duration(milliseconds: 300);

    while (retries < maxRetries && mounted) {
      await Future.delayed(retryDelay);
      retries++;
      log('🔄 Retry #$retries: Fetching page info...');

      await _updatePageInfo(skipProgressSave: true);

      if (_viewerTotalPages > 10) {
        log('✅ Valid total pages found: $_viewerTotalPages');

        if (_chapters.isNotEmpty) {
          await _buildChapterPages();
        }
        break;
      }
    }

    if (_viewerTotalPages <= 1 && retries >= maxRetries) {
      log('⚠️ Page info retries exhausted (liveTotal=$_liveTotalPages)');
    }
  }

  void _applyAudioProgressIfNeeded() {
    log('📖 _applyAudioProgressIfNeeded START');
    log('   hasAppliedAudioProgress: $_hasAppliedAudioProgress');
    log('   viewerTotalPages: $_viewerTotalPages');
    log('   liveTotalPages: $_liveTotalPages');
    log('   uniqueBookId: $_uniqueBookId');

    if (_hasAppliedAudioProgress) {
      log('   ❌ Already applied audio progress, skipping');
      return;
    }

    if (_liveTotalPages <= 1) {
      log('⏳ Deferring audio progress apply (liveTotalPages=$_liveTotalPages)');
      return;
    }

    _hasAppliedAudioProgress = true;

    final audioProgress = _getAudioProgress();
    log('   audioProgress from storage: $audioProgress');

    if (audioProgress != null && audioProgress > 0.01) {
      final targetPage = (audioProgress * _liveTotalPages).round();
      log('✅ Audio progress found: ${(audioProgress * 100).toStringAsFixed(1)}%');
      log('   Target page: $targetPage / $_liveTotalPages');
      log('🚀 Applying audio progress to viewer...');
      _viewerController.toProgressPercentage(audioProgress);
      log('✅ Applied progress successfully');
    } else {
      log('❌ No audio progress to apply (progress: $audioProgress)');
    }

    _markReaderReadyIfPossible();
  }

  void _updateCurrentChapter() {
    if (_chapters.isEmpty) {
      setState(() {
        _currentChapterTitle = widget.book?.name ?? '';
      });
      return;
    }

    String chapterTitle = ReaderHelpers.getChapterTitleByHref(
      _currentHref,
      _chapters,
      widget.book?.name ?? '',
    );
    setState(() {
      _currentChapterTitle = chapterTitle;
    });
    log('📖 Current chapter updated: $_currentChapterTitle (href: $_currentHref)');
  }

  Future<void> _initializeBook() async {
    if (_isInitializingBook) {
      log('⏭️ _initializeBook already in progress, skipping duplicate call');
      return;
    }

    _isInitializingBook = true;
    try {
      setState(() {
        _hasError = false;
        _errorMessage = null;
        _downloadProgress = 0.05;
      });

      if (mounted) {
        setState(() => _downloadProgress = 0.10);
      }

      if (widget.epubPath != null && widget.epubPath!.isNotEmpty) {
        await _downloadAndOpenBook();
      } else {
        await _openAssetBook();
      }

      _setLastOpenedBook();
    } catch (e, st) {
      log('Initialize error: $e\n$st');

      if (_isAuthError(e)) {
        _showLoginBottomSheet();
      } else {
        log('Failed to open book: $e');
      }
    } finally {
      _isInitializingBook = false;
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

  Future<void> _downloadAndOpenBook() async {
    try {
      log('========== EPUB DOWNLOAD & OPEN PROCESS START ==========');
      log('Book ID: ${widget.bookId}');
      log('Translate ID: ${widget.translateId}');
      log('Unique Book ID: $_uniqueBookId');
      log('EPUB Path (key): ${widget.epubPath}');

      setState(() {
        _downloadProgress = 0.15;
      });

      final localPath = await ReaderHelpers.getLocalFilePath(widget.bookId, widget.epubPath);
      final file = File(localPath);
      log('Local file path: $localPath');

      if (await file.exists()) {
        final fileSize = await file.length();
        log('Local copy found: $localPath');
        log('File size: ${(fileSize / 1024 / 1024).toStringAsFixed(2)} MB');

        if (fileSize > 0) {
          setState(() => _downloadProgress = 0.90);

          _showReader(localPath);
          return;
        } else {
          log('Local file is empty or corrupted, deleting and re-downloading');
          await file.delete();
        }
      }

      log('No local copy found, need to download');

      final downloadService = BookDownloadService(
        networkManager: _networkManager,
        onProgressUpdate: (progress) {
          if (mounted) {
            setState(() {
              _downloadProgress = (progress * 0.90).clamp(0.0, 0.90);
            });
          }
        },
        onError: (error) {
          _setError(error);
        },
      );

      final startFetchUrl = DateTime.now();
      final urlData = await downloadService.fetchSignedUrl(widget.epubPath!);
      final signedUrl = urlData['url'] as String;
      final expectedSize = urlData['size'] as int;
      final fetchUrlDuration = DateTime.now().difference(startFetchUrl);
      log('Signed URL obtained in ${fetchUrlDuration.inMilliseconds}ms');

      setState(() {
        _downloadProgress = 0.0;
      });

      final startDownload = DateTime.now();

      final actualEpubPath = await downloadService.downloadAndPrepareBook(
        signedUrl,
        localPath,
        expectedSize: expectedSize,
      );

      final downloadDuration = DateTime.now().difference(startDownload);
      log('Download and preparation completed in ${downloadDuration.inSeconds}s');

      if (mounted) {
        setState(() {
          _downloadProgress = 0.90;
        });
      }

      _showReader(actualEpubPath);

      log('========== EPUB DOWNLOAD & OPEN PROCESS END ==========');
    } catch (e, st) {
      _logError('Download/Open Error: $e\n$st');

      if (_isAuthError(e)) {
        _showLoginBottomSheet();
      } else {
        _setError('Download failed: $e');
      }
    }
  }

  void _showReader(String filePath) {
    if (!mounted) return;

    if (_epubSource != null && _openedFilePath == filePath) {
      log('⏭️ Reader already opened with same file path, skipping re-open');
      return;
    }

    log('Opening reader for: $filePath');

    setState(() {
      _openedFilePath = filePath;
      _epubViewerKey = UniqueKey();
      _epubSource = epub.EpubSource.fromFile(File(filePath));
      _isReaderReady = false;
      _downloadProgress = 0.90;
    });
  }

  void _markReaderReadyIfPossible() {
    if (!mounted || _isReaderReady) return;
    // Allow dismissing overlay even with _viewerTotalPages=1 (it shows loading spinner until VPP ready)
    // We check _liveTotalPages instead to know if book has loaded
    if (_liveTotalPages <= 1) return;

    setState(() {
      _isReaderReady = true;
      _downloadProgress = 1.0;
    });
    log('✅ Reader ready - loading overlay dismissed (displayPages=$_viewerTotalPages, livePages=$_liveTotalPages)');
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

  void _showReaderMenu() {
    ReaderActionsSheet.show(
      context,
      onBookDescription: null,
      onSaveToLibrary: () {
        handleSaveToLibrary();
      },
      onMarkAsFinished: () {
        handleMarkAsFinished();
      },
      isAddedToShelf: detailController.isAddedToWantToRead.value,
      isMarkedAsFinished: detailController.isMarkedAsFinished.value,
    );
  }

  void _showChapterDrawer() {
    ChapterDrawer.show(
      context,
      _viewerController,
      bookTitle: widget.book?.name,
      bookCoverUrl: widget.imageUrl,
      currentPage: _viewerCurrentPage,
      totalPages: _viewerTotalPages,
      currentCfi: _currentCfi,
      currentHref: _currentHref,
      isLoadingPages: _isLoadingPages,
      theme: _currentTheme,
    );
  }

  void _showThemeSettings() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ThemeSettingsSheet(
        currentTheme: _currentTheme,
        currentFontSize: _fontSize,
        onThemeChanged: _onThemeChanged,
        onFontSizeChanged: _onFontSizeChanged,
      ),
    );
  }

  void _onThemeChanged(ReaderThemeModel theme) {
    setState(() {
      _currentTheme = theme;
      _userHasManuallySelectedTheme = true; // Mark that user has manually selected a theme
    });
    _viewerController.updateTheme(theme: theme.epubTheme);
  }

  void _onFontSizeChanged(int size) {
    log('╔═══════════════════════════════════════════════════════════╗');
    log('║  🔤 FONT SIZE CHANGED                                     ║');
    log('╠═══════════════════════════════════════════════════════════╣');
    log('║  Old Size:  $_fontSize                                     ║');
    log('║  New Size:  $size                                          ║');
    log('║  Status:    Resetting VPP & regenerating locations...     ║');
    log('╚═══════════════════════════════════════════════════════════╝');

    setState(() {
      _fontSize = size;
      _isRegeneratingLocations = true;
      _isLoadingPages = true;
      // Reset total pages to show loading spinner until VPP recalibrates
      _viewerTotalPages = 1;
      _liveTotalPages = 1;
    });
    _viewerController.setFontSize(fontSize: size.toDouble());
  }

  void _handleShare(String text) async {
    try {
      await SharePlus.instance.share(
        ShareParams(text: text),
      );
    } catch (e) {
      log('Error sharing text: $e');
    }
  }

  void _handleCopy(String text) async {
    try {
      await Clipboard.setData(ClipboardData(text: text));
    } catch (e) {
      log('Error copying text: $e');
    }
  }

  Future<void> _jumpToPage(int page) async {
    if (_viewerTotalPages <= 1) return;

    final targetPage = page.clamp(1, _viewerTotalPages);

    final progressPercent = (_viewerTotalPages > 1) ? (targetPage - 1) / (_viewerTotalPages - 1) : 0.0;

    log('📌 Jumping to page $targetPage (progress: $progressPercent)');

    setState(() {
      _viewerCurrentPage = targetPage;
    });

    try {
      await _viewerController.toProgressPercentage(progressPercent);
    } catch (e) {
      log('❌ Error jumping to page $targetPage: $e');
    }
  }

  /// Clear selection state in both Flutter and JavaScript
  void _clearSelectionFully() {
    _viewerController.clearSelection();
    if (mounted) {
      setState(() {
        _selectedText = '';
        _selectedCfi = null;
        _selectionRect = null;
      });
    }
    log('🧹 Selection fully cleared (Flutter + JS)');
  }

  Future<void> _showAddNoteSheet(String selectedText) async {
    log('📍 Opening note sheet with CFI: $_selectedCfi');

    final cfiToUse = _selectedCfi;
    final savedCfi = _currentCfi;
    final savedPage = _viewerCurrentPage;
    final savedTotalPages = _viewerTotalPages;
    log('📍 Saved position before note sheet: CFI=$savedCfi, page=$savedPage/$savedTotalPages');

    // Clear selection before opening sheet to unblock navigation
    _clearSelectionFully();

    await AddNoteSheet.show(
      context,
      selectedText: selectedText,
      onSave: (note, color) async {
        log('📍 Saving note with CFI: $cfiToUse');
        await handleNoteSelection(selectedText, userNote: note);
      },
    );

    if (mounted) {
      setState(() {
        _selectedText = '';
        _selectedCfi = null;
        _selectionRect = null;
      });

      await Future.delayed(const Duration(milliseconds: 400));

      if (savedCfi != null && savedCfi.isNotEmpty) {
        log('🔄 Restoring reader position to CFI: $savedCfi');
        _viewerController.display(cfi: savedCfi);
      } else if (savedTotalPages > 1 && savedPage > 0) {
        final progress = (savedPage - 1) / (savedTotalPages - 1);
        log('🔄 Restoring reader position to progress: ${(progress * 100).toStringAsFixed(1)}%');
        _viewerController.toProgressPercentage(progress);
      }

      log('✅ Bottom sheet closed, selection cleared, position restored');
    }
  }

  /// Build custom selection toolbar (replaces native context menu)
  Widget _buildSelectionToolbar() {
    final rect = _selectionRect!;
    final screenWidth = MediaQuery.of(context).size.width;
    final topPadding = MediaQuery.of(context).viewPadding.top + 15;

    // Position toolbar above the selection, centered on it
    const toolbarHeight = 44.0;
    const toolbarPadding = 12.0;

    // Calculate the actual Y position of the selection in the Stack
    // The EpubViewer has top padding = viewPadding.top
    final selectionTopInStack = rect.top + topPadding;
    final selectionBottomInStack = rect.bottom + topPadding;

    // Try to place above selection; if not enough space, place below
    double toolbarTop;
    if (selectionTopInStack - toolbarHeight - toolbarPadding > topPadding) {
      toolbarTop = selectionTopInStack - toolbarHeight - toolbarPadding;
    } else {
      toolbarTop = selectionBottomInStack + toolbarPadding;
    }

    // Center horizontally on the selection, but clamp to screen
    final selectionCenterX = rect.left + rect.width / 2;
    const estimatedToolbarWidth = 220.0;
    double toolbarLeft = (selectionCenterX - estimatedToolbarWidth / 2).clamp(8.0, screenWidth - estimatedToolbarWidth - 8.0);

    return Positioned(
      top: toolbarTop,
      left: toolbarLeft,
      child: Material(
        color: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: _currentTheme.isDark ? const Color(0xFF2C2C2E) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.25),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _toolbarButton(
                label: 'add_note'.tr,
                onTap: () {
                  final text = _selectedText;
                  if (text.isNotEmpty) {
                    _showAddNoteSheet(text);
                  }
                },
              ),
              _toolbarDivider(),
              _toolbarButton(
                label: 'share_text'.tr,
                onTap: () {
                  final text = _selectedText;
                  _clearSelectionFully();
                  if (text.isNotEmpty) {
                    _handleShare(text);
                  }
                },
              ),
              _toolbarDivider(),
              _toolbarButton(
                label: 'copy_text'.tr,
                onTap: () {
                  final text = _selectedText;
                  _clearSelectionFully();
                  if (text.isNotEmpty) {
                    _handleCopy(text);
                    Get.snackbar(
                      '',
                      '',
                      snackPosition: SnackPosition.BOTTOM,
                      backgroundColor: Colors.green.withOpacity(0.9),
                      colorText: Colors.white,
                      duration: const Duration(seconds: 2),
                      margin: const EdgeInsets.all(16),
                      borderRadius: 8,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      titleText: const SizedBox.shrink(),
                      messageText: Text(
                        'copied_to_clipboard'.tr,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      isDismissible: true,
                      dismissDirection: DismissDirection.horizontal,
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _toolbarButton({
    required String label,
    required VoidCallback onTap,
  }) {
    final color = _currentTheme.isDark ? Colors.white : Colors.black87;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Text(
          label,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
        ),
      ),
    );
  }

  Widget _toolbarDivider() {
    return Container(
      width: 0.5,
      height: 30,
      color: _currentTheme.isDark ? Colors.grey.shade600 : Colors.grey.shade300,
    );
  }

  Widget _buildReaderView() {
    return WillPopScope(
      onWillPop: () async {
        await _handleClose();
        return false;
      },
      child: Scaffold(
        backgroundColor: _currentTheme.backgroundColor,
        resizeToAvoidBottomInset: false,
        body: Stack(
          children: [
            RepaintBoundary(
              child: Container(
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).viewPadding.top + 40,
                  bottom: MediaQuery.of(context).viewPadding.bottom + 30,
                ),
                color: _currentTheme.backgroundColor,
                child: epub.EpubViewer(
                  key: _epubViewerKey,
                  epubController: _viewerController,
                  epubSource: _epubSource!,
                  displaySettings: epub.EpubDisplaySettings(
                    flow: epub.EpubFlow.paginated,
                    snap: true,
                    theme: _currentTheme.epubTheme,
                    fontSize: _fontSize,
                  ),
                  suppressNativeContextMenu: true,
                  cachedLocations: _cachedLocations,
                  onLocationsCached: (locationsJson) async {
                    log('💾 Received locations from epub.js (${locationsJson.length} chars) — caching for next open');
                    cacheLocationsData(locationsJson, fontSize: _fontSize);
                    _cachedLocations = locationsJson;

                    // Rebuild chapter page mapping when locations change
                    // (e.g., after font size change triggers re-generation)
                    if (_chapters.isNotEmpty) {
                      await _buildChapterPages();
                    }

                    // Update page info with new locations (especially after font size change)
                    await _updatePageInfo(skipProgressSave: false);

                    // Hide loading overlay after locations regeneration completes
                    if (mounted && _isRegeneratingLocations) {
                      setState(() {
                        _isRegeneratingLocations = false;
                      });
                    }
                  },
                  onEpubLoaded: () {
                    log('EPUB loaded successfully');
                  },
                  onChaptersLoaded: (chapters) {
                    log('Chapters loaded: ${chapters.length}');
                    if (mounted) {
                      setState(() {
                        _chapters = chapters;
                      });
                    }
                    _updateCurrentChapter();
                  },
                  onRelocated: (location) {
                    log('📍 Relocated: progress=${(location.progress * 100).toStringAsFixed(1)}% | Page: $_viewerCurrentPage/$_viewerTotalPages | FontSize: $_fontSize');

                    setState(() {
                      _currentCfi = location.startCfi;
                      _currentHref = location.href;
                    });

                    if (_isRestoringProgress && _pendingRestoreProgress != null) {
                      final currentProgress = location.progress;
                      final targetProgress = _pendingRestoreProgress!;
                      if (currentProgress >= (targetProgress - 0.01) && currentProgress > 0.0) {
                        _isRestoringProgress = false;
                        _pendingRestoreProgress = null;
                        _restoreRetryTimer?.cancel();
                        log('✅ Restore complete (progress: $currentProgress)');
                        _markReaderReadyIfPossible();
                      } else {
                        _restoreRelocateLogCount++;
                        if (_restoreRelocateLogCount % 10 == 1) {
                          log('⏳ Restoring progress (current: $currentProgress, target: $targetProgress)');
                        }
                        _restoreRetryTimer?.cancel();
                        _restoreRetryTimer = Timer(const Duration(milliseconds: 350), () {
                          if (_isRestoringProgress && _pendingRestoreProgress != null) {
                            _restoreRetryCount++;
                            if (_restoreRetryCount % 5 == 1) {
                              log('🔁 Retry restore to ${_pendingRestoreProgress!}');
                            }
                            _viewerController.toProgressPercentage(_pendingRestoreProgress!);
                          }
                        });
                      }
                    }

                    _updatePageInfo(skipProgressSave: !_hasAppliedAudioProgress || _isRestoringProgress);

                    log('   totalPages after update: $_viewerTotalPages');
                    _updateCurrentChapter();
                  },
                  onLocationLoaded: () {
                    log('📍 Location loaded (page counts available)');
                    log('   Current state: totalPages=$_viewerTotalPages, currentPage=$_viewerCurrentPage');
                    log('   hasAppliedAudioProgress: $_hasAppliedAudioProgress');

                    _updatePageInfo(skipProgressSave: true);
                    log('   After _updatePageInfo: totalPages=$_viewerTotalPages, currentPage=$_viewerCurrentPage');

                    _updateCurrentChapter();

                    log('   Starting _retryPageInfoUntilValid...');
                    _retryPageInfoUntilValid();
                  },
                  onTextSelected: (selection) {
                    _selectedText = selection.selectedText;
                    _selectedCfi = selection.selectionCfi;
                    log('📍 Text selected: ${selection.selectedText}');
                    log('📍 Selection CFI: ${selection.selectionCfi}');
                  },
                  onSelection: (selectedText, cfiRange, selectionRect, viewRect) {
                    setState(() {
                      _selectedText = selectedText;
                      _selectedCfi = cfiRange;
                      _selectionRect = selectionRect;
                    });
                    log('📍 onSelection CFI: $cfiRange, rect: $selectionRect');
                  },
                  onDeselection: () {
                    setState(() {
                      _selectedText = '';
                      _selectedCfi = null;
                      _selectionRect = null;
                    });
                  },
                  onTouchDown: (x, y) {
                    _touchDownX = x;
                    _touchDownY = y;
                    _touchDownAt = DateTime.now();
                    log('👆 TOUCH DOWN (x: $x, y: $y) showControls=$_showControls');
                  },
                  onTouchUp: (x, y) {
                    final dt = _touchDownAt != null ? DateTime.now().difference(_touchDownAt!).inMilliseconds : -1;
                    final dx = (x - _touchDownX).abs();
                    final dy = (y - _touchDownY).abs();
                    final isTapLike = dx < 0.05 && dy < 0.05 && dt >= 0 && dt < 500;

                    log('👆 TOUCH UP (x: $x, y: $y) longPressed=$_isProgressLongPressed showControls(before)=$_showControls dx=${dx.toStringAsFixed(3)} dy=${dy.toStringAsFixed(3)} dt=${dt}ms isTapLike=$isTapLike');

                    if (!_isProgressLongPressed && isTapLike) {
                      if (_selectedText.isNotEmpty) {
                        _clearSelectionFully();
                        return;
                      }

                      setState(() {
                        _showControls = !_showControls;
                        log('🎛️ showControls toggled -> now: $_showControls');
                      });
                    } else {
                      log('🎛️ skip toggle (longPressed=$_isProgressLongPressed, isTapLike=$isTapLike)');
                    }
                  },
                ),
              ),
            ),

            // Custom selection toolbar
            if (_selectedText.isNotEmpty && _selectionRect != null) _buildSelectionToolbar(),

            ReaderUIBuilder.buildTopOverlay(
              showControls: _showControls,
              theme: _currentTheme,
              bookTitle: _currentChapterTitle.isNotEmpty ? _currentChapterTitle : widget.book?.name ?? '',
              onClose: _handleClose,
              onMenuTap: _showReaderMenu,
            ),
            if (!_showControls && _currentChapterTitle.isNotEmpty)
              ReaderUIBuilder.buildMinimalChapterTitle(
                showControls: _showControls,
                chapterTitle: _currentChapterTitle,
              ),
            ReaderUIBuilder.buildBottomOverlay(
              showControls: _showControls,
              theme: _currentTheme,
              currentPage: _viewerCurrentPage,
              totalPages: _viewerTotalPages,
              isLoadingPages: _isLoadingPages,
              onChapterDrawerTap: _showChapterDrawer,
              onThemeSettingsTap: _showThemeSettings,
              context: context,
              isProgressLongPressed: _isProgressLongPressed,
              tempSliderValue: _tempSliderValue,
              lastProgressFactor: _lastProgressFactor,
              isRegeneratingLocations: _isRegeneratingLocations,
              onHorizontalDragStart: (details) {
                _dragStartLocalX = details.localPosition.dx;
                final currentNormalized = _viewerTotalPages > 1 ? (_viewerCurrentPage - 1) / (_viewerTotalPages - 1) : 0.0;
                setState(() {
                  _isProgressLongPressed = true;
                  _dragStartValue = currentNormalized.clamp(0.0, 1.0);
                  _tempSliderValue = _dragStartValue;
                });
              },
              onHorizontalDragUpdate: (details) {
                final RenderBox box = context.findRenderObject() as RenderBox;
                final localX = details.localPosition.dx;
                final delta = (localX - _dragStartLocalX) / box.size.width;
                final percentage = (_dragStartValue + delta).clamp(0.0, 1.0);
                setState(() {
                  _tempSliderValue = percentage;
                });
              },
              onHorizontalDragEnd: (details) {
                final targetPage = (_tempSliderValue * _viewerTotalPages).round().clamp(1, _viewerTotalPages);
                if (targetPage != _viewerCurrentPage) {
                  _jumpToPage(targetPage);
                }
                setState(() {
                  _isProgressLongPressed = false;
                  _lastProgressFactor = _viewerTotalPages > 0 ? targetPage / _viewerTotalPages : 0.0;
                });
              },
            ),
            if (!_showControls && !_isLoadingPages)
              ReaderUIBuilder.buildMinimalPageIndicator(
                showControls: _showControls,
                currentPage: _viewerCurrentPage,
              ),
            ReaderUIBuilder.buildLongPressPageIndicator(
              isProgressLongPressed: _isProgressLongPressed,
              theme: _currentTheme,
              currentPage: _viewerCurrentPage,
              totalPages: _viewerTotalPages,
              tempSliderValue: _tempSliderValue,
              chapterTitle: _currentChapterTitle,
              context: context,
              chapters: _chapters,
              chapterPages: _chapterPages,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingBody() {
    final isDark = _currentTheme.isDark;
    final primaryTextColor = _currentTheme.textColor;
    final secondaryTextColor = isDark ? Colors.white70 : Colors.black54;
    final progressBackgroundColor = isDark ? Colors.grey.shade800 : Colors.grey.shade300;

    return SafeArea(
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
                        style: TextStyle(
                          fontSize: 15,
                          fontFamily: StringConstants.SFPro,
                          fontWeight: FontWeight.w600,
                          color: primaryTextColor,
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
                        backgroundColor: progressBackgroundColor,
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
                        style: TextStyle(color: secondaryTextColor),
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
    );
  }

  Widget _buildLoadingOverlay() {
    return Positioned.fill(
      child: Material(
        color: _currentTheme.backgroundColor,
        child: _buildLoadingBody(),
      ),
    );
  }

  Widget _buildLoadingView() {
    return WillPopScope(
      onWillPop: () async {
        await _handleClose();
        return false;
      },
      child: Scaffold(
        backgroundColor: _currentTheme.backgroundColor,
        body: _buildLoadingBody(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: _currentTheme.backgroundColor,
        statusBarIconBrightness: _currentTheme.isDark ? Brightness.light : Brightness.dark,
        systemNavigationBarColor: _currentTheme.backgroundColor,
        systemNavigationBarIconBrightness: _currentTheme.isDark ? Brightness.light : Brightness.dark,
      ),
      child: _epubSource == null
          ? _buildLoadingView()
          : Stack(
              children: [
                _buildReaderView(),
                if (!_isReaderReady) _buildLoadingOverlay(),
              ],
            ),
    );
  }
}
