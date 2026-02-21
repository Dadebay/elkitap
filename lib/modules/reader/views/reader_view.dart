import 'dart:developer';
import 'dart:io';
import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
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
    this.localFilePath,
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

  /// When provided, skips network download and opens this decrypted local file directly.
  final String? localFilePath;

  @override
  State<EpubReaderScreen> createState() => _EpubReaderScreenState();
}

class _EpubReaderScreenState extends State<EpubReaderScreen> with ProgressSyncMixin, ReaderHandlersMixin, WidgetsBindingObserver {
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
  int _jsRawCurrentPage = 1; // raw unstabilised page from JS — used for swipe-guard comparisons
  int _viewerTotalPages = 1;
  int _liveTotalPages = 1;
  int _stableTotalPages = 1;

  bool _isProgressLongPressed = false;
  double _tempSliderValue = 0.0;
  double _dragStartValue = 0.0;
  double _dragStartLocalX = 0.0;
  double? _pendingJumpProgressFactor;
  double _lastRelocatedProgress = 0.0;

  Timer? _initialLoadingTimer;
  Timer? _fontSizeDebounceTimer;

  String? _cachedLocations;

  bool _isRegeneratingLocations = false;
  bool _isRestoringProgress = false;
  bool _isRetryingPageInfo = false;
  bool _isBuildingChapterPages = false;
  bool _useManualSwipeFallback = false;
  bool _isVppLocked = false;
  bool _vppDisplayTimedOut = false; // true after 6.5 s without VPP lock — stops spinner even if JS never locks
  bool _isAwaitingFontVppRecalibration = false;
  int _manualSwipeRequestId = 0;
  DateTime? _vppPendingSince;
  String? _lastLocationsFingerprint;
  DateTime? _lastLocationsReceivedAt;
  int _lastChapterBuildTotalPages = 0;
  double? _pendingRestoreProgress;
  Timer? _restoreRetryTimer;
  int _restoreRelocateLogCount = 0;
  int _restoreRetryCount = 0;
  int _restoreStuckAtZeroCount = 0; // counts onRelocated events where progress=0 while _isRestoringProgress
  bool _hasPostVppRestoreKick = false;

  Map<String, int> _chapterPages = {};

  void _applyReaderSystemUiStyle() {
    if (!Platform.isAndroid) return;

    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );

    // Use theme colors if initialized, otherwise use safe defaults
    final Color backgroundColor;
    final Brightness iconBrightness;

    if (_hasInitializedReaderTheme) {
      backgroundColor = _currentTheme.backgroundColor;
      iconBrightness = _currentTheme.isDark ? Brightness.light : Brightness.dark;
    } else {
      // Default to black for initial state
      backgroundColor = Colors.black;
      iconBrightness = Brightness.light;
    }

    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        systemNavigationBarColor: backgroundColor,
        systemNavigationBarDividerColor: backgroundColor,
        systemNavigationBarIconBrightness: iconBrightness,
        systemNavigationBarContrastEnforced: false,
      ),
    );
  }

  void _startRestoreWatchdog() {
    _restoreRetryTimer?.cancel();
    _restoreRetryTimer = Timer.periodic(const Duration(milliseconds: 450), (timer) {
      if (!mounted || !_isRestoringProgress || _pendingRestoreProgress == null) {
        timer.cancel();
        return;
      }

      _restoreRetryCount++;

      // Timeout: if restore still hasn't succeeded after 15 retries (~6.75s),
      // epub.js is likely reporting progress=0 for the correct physical location
      // (broken location index for this book). Give up so the user can navigate freely.
      if (_restoreRetryCount >= 15) {
        log('⚠️ Restore watchdog timeout after $_restoreRetryCount retries — abandoning restore at ${_pendingRestoreProgress!}');
        timer.cancel();
        setState(() {
          _isRestoringProgress = false;
          _pendingRestoreProgress = null;
        });
        _markReaderReadyIfPossible();
        return;
      }

      if (_restoreRetryCount % 4 == 1) {
        log('🔁 Retry restore to ${_pendingRestoreProgress!}');
      }
      _viewerController.toProgressPercentage(_pendingRestoreProgress!);
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _applyReaderSystemUiStyle();
    }
  }

  @override
  String get bookId => widget.bookId;

  @override
  Book? get currentBook => widget.book;

  @override
  void dispose() {
    _initialLoadingTimer?.cancel();
    _fontSizeDebounceTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    _applyReaderSystemUiStyle();

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

    // Extract numeric book ID (handle downloaded books with format "1241_t1647")
    final numericBookId = widget.bookId.contains('_') ? int.parse(widget.bookId.split('_').first) : int.parse(widget.bookId);

    controller.initialize(bookId: numericBookId);

    // Safety watchdog: if VPP never locks, force dismiss the loading overlay so
    // the user isn't stuck staring at a spinner forever.
    _initialLoadingTimer = Timer(const Duration(seconds: 8), () {
      if (!mounted) return;
      if (_isLoadingPages && _liveTotalPages > 1) {
        log('⏱️ Loading timeout (8s) — VPP still not locked. Force-dismissing loading overlay.');
        setState(() {
          _isLoadingPages = false;
          _useManualSwipeFallback = true;
          if (_viewerTotalPages <= 1) _viewerTotalPages = _liveTotalPages;
        });
        _markReaderReadyIfPossible();
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

      // Update system UI style for new theme
      _applyReaderSystemUiStyle();
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
      final initBookFuture = _initializeBook();

      // Offline mode for downloaded books: skip network requests.
      if (widget.localFilePath != null && widget.localFilePath!.isNotEmpty) {
        log('   Offline local file mode detected, skipping detail/progress network fetch');
        await initBookFuture;
      } else {
        log('   Fetching book detail and progress in parallel...');

        // Extract numeric book ID (handle downloaded books with format "1241_t1647")
        final numericBookId = widget.bookId.contains('_') ? int.parse(widget.bookId.split('_').first) : int.parse(widget.bookId);

        final bookDetailFuture = detailController.fetchBookDetail(numericBookId);
        final progressFuture = detailController.fetchProgress();

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
      }

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

  void _cacheTotalPages(int totalPages) => cacheTotalPages(totalPages, fontSize: _fontSize);

  void _saveTextProgressToAudio(int currentPage, int totalPages) => saveTextProgressToAudio(currentPage, totalPages);

  Future<void> _buildChapterPages() async {
    if (_chapters.isEmpty) {
      log('⚠️ _buildChapterPages called but _chapters is empty');
      return;
    }

    if (_isBuildingChapterPages) {
      log('⏭️ _buildChapterPages already running, skipping duplicate call');
      return;
    }

    if (_viewerTotalPages > 1 && _lastChapterBuildTotalPages == _viewerTotalPages && _chapterPages.length == _chapters.length) {
      log('⏭️ Chapter pages already built for totalPages=$_viewerTotalPages, skipping');
      return;
    }

    _isBuildingChapterPages = true;

    try {
      log('🗺️ Building chapter-to-page mapping for ${_chapters.length} chapters...');
      final pageInfo = await _viewerController.getPageInfo();
      final totalPages = (pageInfo['totalPages'] as num?)?.toInt() ?? 1;
      final vppReady = pageInfo['vppReady'] == true;
      log('📊 Total pages from pageInfo: $totalPages');

      if (!vppReady) {
        log('⏸️ Skip chapter mapping while VPP pending (totalPages=$totalPages)');
        return;
      }

      if (mounted && totalPages > 10 && _viewerTotalPages <= 1) {
        setState(() {
          _viewerTotalPages = totalPages;
          _liveTotalPages = totalPages;
          _isLoadingPages = false;
          _useManualSwipeFallback = true;
        });
        _markReaderReadyIfPossible();
        log('⚡ Early unlock from chapter mapping: $totalPages pages');
      }

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
      }

      if (mounted) {
        setState(() {
          _chapterPages = newChapterPages;
        });

        _lastChapterBuildTotalPages = totalPages;

        cacheChapterMapping(newChapterPages);
        log('✅ Chapter pages built and cached: ${_chapterPages.length} chapters mapped (will be refined during navigation)');
      }
    } catch (e, stackTrace) {
      log('❌ Error building chapter pages: $e');
      log('Stack trace: $stackTrace');
    } finally {
      _isBuildingChapterPages = false;
    }
  }

  Future<void> _handleClose() async {
    try {
      log('CLOSING READER...');

      // Force-save current position when VPP never locked during this session.
      // Without this, closing the reader before VPP calibration completes leaves
      // controller.currentPage == 0, so saveProgressAndClose() skips the network save
      // and the user is taken back to the old server-side progress on next open.
      if (controller.currentPage.value == 0) {
        final effectiveTotal = _viewerTotalPages > 1 ? _viewerTotalPages : _liveTotalPages;
        final effectivePage = _jsRawCurrentPage > 0 ? _jsRawCurrentPage : _viewerCurrentPage;
        if (effectiveTotal > 1 && effectivePage > 0) {
          log('💾 Pre-close force save (VPP never locked): page $effectivePage / $effectiveTotal');
          controller.onPageFlip(effectivePage, effectiveTotal);
          _saveTextProgressToAudio(effectivePage, effectiveTotal);
        }
      }

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
      int currentPage = (pageInfo['currentPage'] as num?)?.toInt() ?? 1;
      // Store the raw JS page BEFORE any Dart-side stabilisation so that swipe guards
      // can detect real page movement even when progress=0 locks the stabilised value at 1.
      _jsRawCurrentPage = currentPage;
      final rawTotalPages = (pageInfo['totalPages'] as num?)?.toInt() ?? 1;
      final vppReady = pageInfo['vppReady'] == true;
      final vppSampleCount = (pageInfo['vppSampleCount'] as num?)?.toInt() ?? 0;

      // Stabilize page count against common ±1 jitters from webview/VPP calibration.
      int totalPages = rawTotalPages;

      // While VPP is pending the rawTotalPages from JS is the epub.js location-index count
      // (e.g. 1789), which is a different unit from the VPP visual-page count (e.g. 894).
      // They are NOT comparable — the location count is always ~2× the visual page count
      // for this renderer. So when we have a cached VPP total (same font size, locked
      // from a previous session), always prefer it over the raw location count.
      // Only ignore the cache when font size has changed (_isAwaitingFontVppRecalibration).
      final cachedTotalPages = getCachedTotalPages(fontSize: _fontSize);
      if (!vppReady && !_isAwaitingFontVppRecalibration && cachedTotalPages != null && cachedTotalPages > 1) {
        totalPages = cachedTotalPages;
        log('🧷 Using cached VPP totalPages while calibrating: raw=$rawTotalPages -> cached=$cachedTotalPages');
      } else if (!vppReady && _isAwaitingFontVppRecalibration && cachedTotalPages != null && cachedTotalPages > 1) {
        log('🔤 Font size changed: ignore cached totalPages=$cachedTotalPages until VPP locks');
      }

      if (rawTotalPages > 1) {
        if (_stableTotalPages <= 1) {
          _stableTotalPages = totalPages;
        } else if (totalPages >= _stableTotalPages) {
          _stableTotalPages = totalPages;
        } else {
          final isOnePageDrop = (_stableTotalPages - totalPages) == 1;
          if (isOnePageDrop) {
            totalPages = _stableTotalPages;
            log('🧮 Stabilized totalPages jitter: raw=$totalPages -> stable=$_stableTotalPages');
          } else {
            // Accept meaningful decreases (e.g. real recalculation after settings change)
            _stableTotalPages = totalPages;
          }
        }
        totalPages = _stableTotalPages;
      }

      // While VPP is not locked, pageInfo.currentPage can jitter without real movement.
      // Use relocated progress as source of truth to avoid fake increments from page 1.
      // BUT: when progress is broken (always 0) yet JS tracked page has advanced past 1,
      // trust the JS tracked page — clamping to progress would force page back to 1.
      // Also bypass when progress is non-zero but tiny (book-start zone where spine items
      // transition from 0 → small progress), detected by JS raw page being >2× the
      // progress-based estimate (e.g. raw=19, progressBased=2 → 19 > 4 → trust JS).
      final progressBasedEstimate = ((_lastRelocatedProgress.clamp(0.0, 1.0)) * totalPages).floor() + 1;
      final useRawPageWhileProgressBroken = !vppReady && totalPages > 1 && _jsRawCurrentPage > 1 && (_lastRelocatedProgress <= 0.0005 || _jsRawCurrentPage > progressBasedEstimate * 2);
      if (!vppReady && totalPages > 1 && !useRawPageWhileProgressBroken) {
        final normalized = progressBasedEstimate.clamp(1, totalPages);
        if ((currentPage - normalized).abs() >= 1) {
          log('🧮 Stabilized currentPage while VPP pending: raw=$currentPage -> progressBased=$normalized (p=${(_lastRelocatedProgress * 100).toStringAsFixed(2)}%)');
          currentPage = normalized;
        }
      }

      // Extra boundary clamp: prevent start/end off-by-one flicker only while VPP is pending.
      // After VPP lock, rely on JS-calculated currentPage to avoid getting stuck at page 1.
      // Skip when progress is broken but JS reports a valid page > 1.
      if (!vppReady && !useRawPageWhileProgressBroken) {
        if (_lastRelocatedProgress <= 0.0005 && currentPage > 1) {
          currentPage = 1;
        } else if (_lastRelocatedProgress >= 0.9995 && totalPages > 1 && currentPage < totalPages) {
          currentPage = totalPages;
        }
      }

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
        final int? pendingJumpTargetPage =
            (_pendingJumpProgressFactor != null && totalPages > 1) ? ((_pendingJumpProgressFactor!.clamp(0.0, 1.0) * (totalPages - 1)) + 1).round().clamp(1, totalPages) : null;

        setState(() {
          _viewerCurrentPage = currentPage;
          _isVppLocked = vppReady;

          if (pendingJumpTargetPage != null && (currentPage - pendingJumpTargetPage).abs() <= 1) {
            _pendingJumpProgressFactor = null;
          }

          if (vppReady) {
            _vppPendingSince = null;
            _vppDisplayTimedOut = false;
            _isAwaitingFontVppRecalibration = false;
          }

          // Only show page count and dismiss loading when VPP is locked
          if (totalPages > 1 && vppReady) {
            _viewerTotalPages = totalPages;
            if (_useManualSwipeFallback) {
              _useManualSwipeFallback = false;
              _manualSwipeRequestId++; // invalidate any pending delayed fallback callbacks
              log('✅ VPP locked - disabling manual swipe fallback');
            }

            if (_isLoadingPages) {
              _isLoadingPages = false;
              _initialLoadingTimer?.cancel();
              log('✅ VPP locked - final page count: $totalPages pages');
            }
          } else if (totalPages > 1 && !vppReady) {
            _vppPendingSince ??= DateTime.now();

            // Fast fallback: don't block reader for long VPP calibration.
            final pendingMs = DateTime.now().difference(_vppPendingSince!).inMilliseconds;
            if (_viewerTotalPages <= 1 && pendingMs >= 1800) {
              _viewerTotalPages = totalPages;
              // Keep _isLoadingPages = true to show loading indicator in page counter during VPP calibration
              _useManualSwipeFallback = true;
              _markReaderReadyIfPossible();
              log('⚡ Forced fallback after ${pendingMs}ms VPP pending. Using live pages: $totalPages');
            }

            // Safety timeout: if VPP does not lock for too long, stop spinner and continue with fallback pages.
            // This prevents endless "Calibrating..." state on devices/webviews where VPP samples never arrive.
            if (_isLoadingPages && pendingMs >= 6500 && _liveTotalPages > 1 && !_isRestoringProgress) {
              _isLoadingPages = false;
              _vppDisplayTimedOut = true; // stop page-counter spinner even if VPP never locks
              _initialLoadingTimer?.cancel();
              _useManualSwipeFallback = true;
              log('⚠️ VPP lock timeout after ${pendingMs}ms (samples=$vppSampleCount). Fail-open: hiding loading spinner and continuing with fallback pages ($_liveTotalPages).');
            }

            if (_isLoadingPages) {
              log('⏳ VPP calibrating (samples=$vppSampleCount) - keeping loading spinner visible...');
            }
          }
        });
      }

      if (vppReady && _isRestoringProgress && _pendingRestoreProgress != null && !_hasPostVppRestoreKick && currentPage <= 2) {
        _hasPostVppRestoreKick = true;
        final target = _pendingRestoreProgress!;
        Future.delayed(const Duration(milliseconds: 180), () {
          if (!mounted || !_isRestoringProgress || _pendingRestoreProgress == null) return;
          log('🎯 Post-VPP restore kick to $target');
          _viewerController.toProgressPercentage(target);
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

      final effectiveSkipProgressSave = skipProgressSave || _isRestoringProgress;
      if (_isRestoringProgress) {
        log('⏸️ Restore in progress - skip saving progress this cycle (page: $currentPage/$totalPages)');
      }

      // Save progress only after VPP is ready (fully calibrated)
      if (totalPages > 1 && vppReady) {
        _cacheTotalPages(totalPages);

        if (!effectiveSkipProgressSave) {
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
    if (_isRetryingPageInfo) {
      log('⏭️ _retryPageInfoUntilValid already running, skipping duplicate call');
      return;
    }

    _isRetryingPageInfo = true;
    int retries = 0;
    int stalledVppRetries = 0;
    const maxRetries = 10;
    const retryDelay = Duration(milliseconds: 300);

    try {
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

        if (_liveTotalPages > 10 && _viewerTotalPages <= 1) {
          stalledVppRetries++;
          if (stalledVppRetries >= 4) {
            if (mounted) {
              setState(() {
                _viewerTotalPages = _liveTotalPages;
                // Keep _isLoadingPages = true to show loading indicator during VPP calibration
                _useManualSwipeFallback = true;
              });
            }

            _markReaderReadyIfPossible();
            log('⚠️ VPP lock delayed. Fallback enabled with live pages: $_liveTotalPages');

            if (_chapters.isNotEmpty) {
              await _buildChapterPages();
            }
            break;
          }
        }
      }

      if (_viewerTotalPages <= 1 && retries >= maxRetries) {
        log('⚠️ Page info retries exhausted (liveTotal=$_liveTotalPages)');
      }
    } finally {
      _isRetryingPageInfo = false;
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

    if (audioProgress != null && audioProgress > 0.001) {
      final targetPage = (audioProgress * _liveTotalPages).round();
      log('✅ Audio progress found: ${(audioProgress * 100).toStringAsFixed(1)}%');
      log('   Target page: $targetPage / $_liveTotalPages');
      log('🚀 Applying audio progress to viewer...');

      _isRestoringProgress = true;
      _pendingRestoreProgress = audioProgress;
      _pendingJumpProgressFactor = audioProgress;
      _restoreRetryTimer?.cancel();
      _restoreRelocateLogCount = 0;
      _restoreRetryCount = 0;
      _restoreStuckAtZeroCount = 0;
      _hasPostVppRestoreKick = false;
      _startRestoreWatchdog();

      _viewerController.toProgressPercentage(audioProgress);
      log('✅ Applied progress successfully');
    } else {
      _isRestoringProgress = false;
      _pendingRestoreProgress = null;
      _restoreRetryTimer?.cancel();
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

      // If a pre-decrypted local file is provided, open it directly (downloaded book)
      if (widget.localFilePath != null && widget.localFilePath!.isNotEmpty) {
        log('📦 Opening pre-decrypted local file: ${widget.localFilePath}');
        setState(() => _downloadProgress = 0.90);
        _showReader(widget.localFilePath!);
      } else if (widget.epubPath != null && widget.epubPath!.isNotEmpty) {
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
      // Extract numeric book ID (handle downloaded books with format "1241_t1647")
      final searchBookId = widget.bookId.contains('_') ? widget.bookId.split('_').first : widget.bookId;

      bookToSave = allBooksController.books.firstWhereOrNull(
        (b) => b.id.toString() == searchBookId,
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
      _hasAppliedAudioProgress = false; // Reset to allow audio progress restoration on reopen
      _pendingJumpProgressFactor = null;
      _isRestoringProgress = false;
      _pendingRestoreProgress = null;
      _restoreRetryTimer?.cancel();
      _restoreRelocateLogCount = 0;
      _restoreRetryCount = 0;
      _restoreStuckAtZeroCount = 0;
      _hasPostVppRestoreKick = false;
      _useManualSwipeFallback = false;
      _isVppLocked = false;
      _vppDisplayTimedOut = false;
      _isAwaitingFontVppRecalibration = false;
      _jsRawCurrentPage = 1;
      _stableTotalPages = 1;
      _lastChapterBuildTotalPages = 0;
      _vppPendingSince = null;
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

  Widget _buildReaderCoverImage() {
    final imageUrl = widget.imageUrl.trim();

    if (imageUrl.isEmpty) {
      return Image.asset('assets/images/l1.png', width: 220, height: 330, fit: BoxFit.cover);
    }

    return CachedNetworkImage(
      imageUrl: imageUrl,
      width: 220,
      height: 330,
      fit: BoxFit.cover,
      placeholder: (context, url) => Image.asset('assets/images/l1.png', width: 220, height: 330, fit: BoxFit.cover),
      errorWidget: (context, url, error) => Image.asset('assets/images/l1.png', width: 220, height: 330, fit: BoxFit.cover),
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

    // Update system UI style for new theme
    _applyReaderSystemUiStyle();
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
      _isAwaitingFontVppRecalibration = true;
      _isLoadingPages = true;
      // Reset total pages to show loading spinner until VPP recalibrates
      _viewerTotalPages = 1;
      _liveTotalPages = 1;
      _stableTotalPages = 1;
      _lastChapterBuildTotalPages = 0;
      _vppPendingSince = null;
    });

    _fontSizeDebounceTimer?.cancel();
    _fontSizeDebounceTimer = Timer(const Duration(milliseconds: 220), () {
      if (!mounted) return;
      log('📤 Applying debounced font size: $_fontSize');
      _viewerController.setFontSize(fontSize: _fontSize.toDouble());
    });
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

  void _triggerManualPageTurn({required bool toNext}) {
    // Both call sites already confirmed (via _jsRawCurrentPage guard) that JS did not handle
    // the swipe, so fire unconditionally. This also covers the WebView-stolen-touch case
    // where VPP is locked but the native scroll consumed the event before epub.js could.

    final requestId = ++_manualSwipeRequestId;
    // Use the raw JS page (not Dart-stabilised _viewerCurrentPage) so the guard
    // correctly detects movement even when progress=0 keeps _viewerCurrentPage at 1.
    final startRawPage = _jsRawCurrentPage;

    if (toNext) {
      _viewerController.next();
      log('➡️ Manual swipe fallback: next page (step 1)');
    } else {
      _viewerController.prev();
      log('⬅️ Manual swipe fallback: previous page (step 1)');
    }

    Future.delayed(const Duration(milliseconds: 240), () {
      if (!mounted || requestId != _manualSwipeRequestId) return;

      // First command already worked — JS moved to a different raw page.
      if (_jsRawCurrentPage != startRawPage) return;

      // Second-stage nudge by progress to recover stuck pages on some WebView/offline states.
      if (_viewerTotalPages <= 1) return;

      // When epub.js reports progress=0 for all pages (broken location index), deriving
      // nudgedProgress from _viewerCurrentPage always yields 0.0, which resolves to the
      // first spine item and jumps the user forward every single time they swipe back.
      // Guard: only use progress nudge when we have a meaningful non-zero progress signal.
      // Otherwise fall back to a second direct prev()/next() call.
      if (_lastRelocatedProgress <= 0.0005) {
        // Progress is broken (always 0) — step 1 already fired next()/prev().
        // Do NOT repeat; the JS tracked page will handle direction correctly.
        log('↪️ Manual swipe fallback: skip step 2 (progress=0 mode, step 1 sufficient)');
        return;
      }

      final step = 1 / (_viewerTotalPages - 1);
      final currentProgress = _lastRelocatedProgress.clamp(0.0, 1.0);
      final nudgedProgress = toNext ? (currentProgress + step).clamp(0.0, 1.0) : (currentProgress - step).clamp(0.0, 1.0);

      _viewerController.toProgressPercentage(nudgedProgress);
      log('↪️ Manual swipe fallback: progress nudge (step 2) -> ${(nudgedProgress * 100).toStringAsFixed(2)}%');
    });
  }

  Future<void> _jumpToPage(int page) async {
    final effectiveTotalPages = _viewerTotalPages > 1 ? _viewerTotalPages : _liveTotalPages;
    if (effectiveTotalPages <= 1) return;

    final targetPage = page.clamp(1, effectiveTotalPages);

    final progressPercent = (effectiveTotalPages > 1) ? (targetPage - 1) / (effectiveTotalPages - 1) : 0.0;

    log('📌 Jumping to page $targetPage (progress: $progressPercent)');

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
    print('📖 Building reader view (ready=$_isReaderReady, loadingPages=$_isLoadingPages, displayPages=$_viewerTotalPages color:${_currentTheme.backgroundColor}, livePages=$_liveTotalPages)');
    return WillPopScope(
      onWillPop: () async {
        await _handleClose();
        return false;
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: (_currentTheme.epubTheme.backgroundDecoration as BoxDecoration?)?.color ?? _currentTheme.backgroundColor,
        body: Stack(
          children: [
            RepaintBoundary(
              child: Container(
                padding: EdgeInsets.only(top: MediaQuery.of(context).viewPadding.top + 40, bottom: MediaQuery.of(context).viewPadding.bottom + 40),
                color: (_currentTheme.epubTheme.backgroundDecoration as BoxDecoration?)?.color ?? _currentTheme.backgroundColor,
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
                    final fingerprint = '$_fontSize:${locationsJson.length}:${locationsJson.hashCode}';
                    final now = DateTime.now();
                    final duplicate = _lastLocationsFingerprint == fingerprint && _lastLocationsReceivedAt != null && now.difference(_lastLocationsReceivedAt!).inMilliseconds < 1500;

                    if (duplicate) {
                      log('⏭️ Ignoring duplicate locationsSaved callback (fontSize=$_fontSize)');
                      return;
                    }

                    _lastLocationsFingerprint = fingerprint;
                    _lastLocationsReceivedAt = now;

                    log('💾 Received locations from epub.js (${locationsJson.length} chars) — caching for next open');
                    cacheLocationsData(locationsJson, fontSize: _fontSize);
                    _cachedLocations = locationsJson;

                    // Update page info first to unlock UI as soon as possible.
                    await _updatePageInfo(skipProgressSave: true);

                    // Rebuild chapter page mapping when locations change
                    // (e.g., after font size change triggers re-generation)
                    if (_chapters.isNotEmpty) {
                      unawaited(_buildChapterPages());
                    }

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

                    _lastRelocatedProgress = location.progress;

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

                        // Stuck-at-zero escape hatch:
                        // Some books have broken epub.js location indices that always
                        // report progress=0 even when the correct CFI is displayed.
                        // After the watchdog has tried a few times and every relocated
                        // event still comes back at 0%, the display IS at the right
                        // physical position — just epub.js can't report it correctly.
                        // Stop retrying so the user can navigate freely.
                        if (currentProgress <= 0.001 && _restoreRetryCount >= 3) {
                          _restoreStuckAtZeroCount++;
                          if (_restoreStuckAtZeroCount >= 4) {
                            log('⚠️ Restore stuck at 0% for $_restoreStuckAtZeroCount events (target=$targetProgress) — epub.js location index broken for this book. Abandoning restore.');
                            setState(() {
                              _isRestoringProgress = false;
                              _pendingRestoreProgress = null;
                            });
                            _restoreRetryTimer?.cancel();
                            _markReaderReadyIfPossible();
                          }
                        } else {
                          _restoreStuckAtZeroCount = 0;
                        }
                      }
                    }

                    _updatePageInfo(skipProgressSave: !_hasAppliedAudioProgress || _isRestoringProgress);

                    // Page-based restore detection:
                    // For books where epub.js always reports progress=0, the progress-based
                    // check above never succeeds. However, after the JS fix, the tracked page
                    // now correctly uses _pendingDirectJumpProgress. If the JS-reported page
                    // is close to the target page, the restore is complete.
                    if (_isRestoringProgress && _pendingRestoreProgress != null && _viewerTotalPages > 1 && _jsRawCurrentPage > 1) {
                      final targetPage = (_pendingRestoreProgress! * (_viewerTotalPages - 1) + 1).round().clamp(1, _viewerTotalPages);
                      if ((_jsRawCurrentPage - targetPage).abs() <= 3) {
                        log('✅ Restore complete via page-based detection (page $_jsRawCurrentPage ≈ target $targetPage)');
                        setState(() {
                          _isRestoringProgress = false;
                          _pendingRestoreProgress = null;
                        });
                        _restoreRetryTimer?.cancel();
                        _markReaderReadyIfPossible();
                      }
                    }

                    log('   totalPages after update: $_viewerTotalPages');
                    _updateCurrentChapter();
                  },
                  onLocationLoaded: () {
                    log('📍 Location loaded (page counts available)');
                    log('   Current state: totalPages=$_viewerTotalPages, currentPage=$_viewerCurrentPage');
                    log('   hasAppliedAudioProgress: $_hasAppliedAudioProgress');

                    Future.delayed(const Duration(milliseconds: 2200), () {
                      if (!mounted || _isReaderReady) return;
                      setState(() {
                        _isReaderReady = true;
                        // Only hide loading if VPP is locked; otherwise keep showing in page counter
                        if (_isVppLocked) {
                          _isLoadingPages = false;
                        }
                        if (!_isVppLocked) {
                          _useManualSwipeFallback = true;
                        }
                      });
                      log('⚡ Soft unlock after location load timeout (waiting for VPP/page info)');
                    });

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
                      final isHorizontalSwipe = dx >= 0.18 && dy <= 0.12 && dt > 0 && dt <= 900;
                      // Fire on any qualifying horizontal swipe — regardless of VPP lock state.
                      // The _jsRawCurrentPage guard inside _triggerManualPageTurn will abort
                      // if JS already handled the swipe (page already moved). This also covers
                      // the case where the WebView's native scroll steals the touch before
                      // epub.js can preventDefault(), leaving the page frozen even with VPP locked.
                      if (!_isProgressLongPressed && !_isLoadingPages && isHorizontalSwipe && _viewerTotalPages > 1) {
                        final pageBefore = _jsRawCurrentPage; // raw JS page, not Dart-stabilised
                        final cfiBefore = _currentCfi; // CFI before swipe — changes even when trackedPage stays at 1
                        final swipeToNext = x < _touchDownX;
                        final requestId = ++_manualSwipeRequestId;

                        Future.delayed(const Duration(milliseconds: 140), () {
                          if (!mounted || requestId != _manualSwipeRequestId) return;

                          // If JS raw page changed, JS swipe succeeded.
                          if (_jsRawCurrentPage != pageBefore) {
                            log('⏭️ Manual swipe fallback skipped (JS already moved page $pageBefore -> $_jsRawCurrentPage)');
                            return;
                          }

                          // Secondary CFI check: for progress=0 books where _trackedPage is clamped at 1
                          // even after moving (e.g., navigating backward within a TOC spine item),
                          // the relocated event still updates _currentCfi with a new position.
                          // If CFI changed, JS handled the swipe — do not fire a second prev()/next().
                          if (_currentCfi != cfiBefore && _currentCfi != null && cfiBefore != null) {
                            log('⏭️ Manual swipe fallback skipped (CFI changed: JS already handled swipe)');
                            return;
                          }

                          _triggerManualPageTurn(toNext: swipeToNext);
                        });
                        return;
                      }
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
              isResolvingInitialPage: _isRestoringProgress && _pendingRestoreProgress != null && _viewerCurrentPage <= 1 && _liveTotalPages > 1,
              onChapterDrawerTap: _showChapterDrawer,
              onThemeSettingsTap: _showThemeSettings,
              context: context,
              isProgressLongPressed: _isProgressLongPressed,
              tempSliderValue: _tempSliderValue,
              pendingJumpProgressFactor: _pendingJumpProgressFactor,
              isRegeneratingLocations: _isRegeneratingLocations,
              isVppCalibrating: !_isVppLocked && !_vppDisplayTimedOut,
              onHorizontalDragStart: (details) {
                _dragStartLocalX = details.localPosition.dx;
                final currentNormalized = _viewerTotalPages > 1 ? (_viewerCurrentPage - 1) / (_viewerTotalPages - 1) : 0.0;
                setState(() {
                  _isProgressLongPressed = true;
                  _pendingJumpProgressFactor = null;
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
                final effectiveTotalPages = _viewerTotalPages > 1 ? _viewerTotalPages : _liveTotalPages;
                final draggedProgress = _tempSliderValue.clamp(0.0, 1.0);
                int? optimisticTargetPage;
                if (effectiveTotalPages > 1) {
                  // Use same formula as _jumpToPage: page = progress * (total-1) + 1
                  final targetPage = (draggedProgress * (effectiveTotalPages - 1) + 1).round().clamp(1, effectiveTotalPages);
                  optimisticTargetPage = targetPage;
                  if (targetPage != _viewerCurrentPage) {
                    _pendingJumpProgressFactor = draggedProgress;
                    _jumpToPage(targetPage);
                  } else {
                    _pendingJumpProgressFactor = null;
                  }
                }
                setState(() {
                  _isProgressLongPressed = false;
                  if (optimisticTargetPage != null && optimisticTargetPage != _viewerCurrentPage) {
                    _viewerCurrentPage = optimisticTargetPage;
                  }
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
                      _buildReaderCoverImage(),
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
        systemNavigationBarColor: Colors.black,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: _epubSource == null
          ? _buildLoadingView()
          : Stack(
              children: [
                _buildReaderView(),
                if (!_isReaderReady) _buildLoadingOverlay(),
                // VPP calibration indicator now shown in bottom page counter instead of overlay dialog
              ],
            ),
    );
  }
}
