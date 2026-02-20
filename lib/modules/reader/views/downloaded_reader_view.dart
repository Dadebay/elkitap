import 'dart:io';
import 'dart:async';
import 'dart:developer';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:elkitap/core/constants/icon_constants.dart';
import 'package:elkitap/core/constants/string_constants.dart';
import 'package:elkitap/core/widgets/common/app_snackbar.dart';
import 'package:elkitap/core/widgets/common/custom_icon.dart';
import 'package:elkitap/core/widgets/states/loading_widget.dart';
import 'package:elkitap/modules/library/model/book_download_model.dart';
import 'package:elkitap/modules/reader/controllers/reader_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:flutter_epub_viewer/flutter_epub_viewer.dart' as epub;

class DownloadedEpubReaderScreen extends StatefulWidget {
  final BookDownload bookDownload;
  final String decryptedFilePath;

  const DownloadedEpubReaderScreen({
    required this.bookDownload,
    required this.decryptedFilePath,
    super.key,
  });

  @override
  State<DownloadedEpubReaderScreen> createState() => _DownloadedEpubReaderScreenState();
}

class _DownloadedEpubReaderScreenState extends State<DownloadedEpubReaderScreen> {
  final EpubController _controller = Get.put(EpubController());
  final GetStorage _storage = GetStorage();

  String loadingMessage = 'Opening book...';
  bool _hasError = false;
  String? _errorMessage;

  // flutter_epub_viewer state
  bool _isBookReady = false;
  final epub.EpubController _viewerController = epub.EpubController();
  epub.EpubSource? _epubSource;
  int _viewerCurrentPage = 1;
  int _viewerTotalPages = 1;
  int _liveTotalPages = 1;
  bool _isLoadingPages = true;

  Timer? _initialLoadingTimer;
  bool _showControls = true;
  String? _cachedLocations;
  int _fontSize = 18; // Default font size (currently not adjustable in downloaded reader)

  String get _uniqueBookId => '${widget.bookDownload.id}_downloaded';

  String? _getCachedLocations() {
    try {
      final sizeKey = '_fs$_fontSize';
      final key = 'epub_locations_$_uniqueBookId$sizeKey';
      return _storage.read<String>(key);
    } catch (e) {
      return null;
    }
  }

  void _saveCachedLocations(String locationsJson) {
    try {
      final sizeKey = '_fs$_fontSize';
      final key = 'epub_locations_$_uniqueBookId$sizeKey';
      _storage.write(key, locationsJson);
      log('💾 Downloaded reader: Cached locations for $_uniqueBookId at fontSize $_fontSize (${locationsJson.length} chars)');
    } catch (e) {
      log('⚠️ Error caching locations: $e');
    }
  }

  @override
  void initState() {
    super.initState();

    // Safety watchdog: keep loading state strict until VPP is ready
    _initialLoadingTimer = Timer(const Duration(seconds: 8), () {
      if (mounted && _isLoadingPages) {
        log('⏱️ Still waiting for VPP lock; keep loading visible (strict mode)');
      }
    });

    // Pre-load cached locations for fast reopening
    _cachedLocations = _getCachedLocations();
    if (_cachedLocations != null) {
      log('⚡ Downloaded reader: Found cached locations for $_uniqueBookId at fontSize $_fontSize (${_cachedLocations!.length} chars)');
    } else {
      log('📖 Downloaded reader: No cached locations for $_uniqueBookId at fontSize $_fontSize — first open or font changed');
    }
    _openBook();
  }

  Future<void> _openBook() async {
    try {
      setState(() {
        _hasError = false;
        _errorMessage = null;
        loadingMessage = 'Opening book...';
      });

      // Verify file exists
      final file = File(widget.decryptedFilePath);
      if (!await file.exists()) {
        throw Exception('Book file not found');
      }

      setState(() => loadingMessage = 'Loading ${widget.bookDownload.title}...');

      // Wait a frame to ensure context is valid
      await Future.delayed(Duration.zero);

      if (!mounted) return;

      // Create EpubSource and show reader
      setState(() {
        _epubSource = epub.EpubSource.fromFile(File(widget.decryptedFilePath));
        _isBookReady = true;
      });
    } catch (e) {
      _setError('Failed to open book: $e');
    }
  }

  Future<void> _updatePageInfo() async {
    try {
      final pageInfo = await _viewerController.getPageInfo();
      final currentPage = (pageInfo['currentPage'] as num?)?.toInt() ?? 1;
      final totalPages = (pageInfo['totalPages'] as num?)?.toInt() ?? 1;
      final vppReady = pageInfo['vppReady'] == true;
      final vppSampleCount = (pageInfo['vppSampleCount'] as num?)?.toInt() ?? 0;

      _liveTotalPages = totalPages;

      if (mounted) {
        setState(() {
          _viewerCurrentPage = currentPage;

          // Update total pages and dismiss loading ONLY when VPP is locked
          if (totalPages > 1 && vppReady) {
            _viewerTotalPages = totalPages;

            if (_isLoadingPages) {
              _isLoadingPages = false;
              _initialLoadingTimer?.cancel();
              debugPrint('✅ VPP locked - showing page count and enabling progress save: $totalPages pages');
            }
          } else if (totalPages > 1 && !vppReady) {
            debugPrint('⏳ VPP calibrating (samples=$vppSampleCount) - keeping loading spinner visible...');
          }
        });
      }

      // Save progress only after VPP is ready (fully calibrated)
      if (totalPages > 1 && vppReady) {
        _controller.onPageFlip(currentPage, totalPages);
      } else if (totalPages > 1) {
        debugPrint('⏸️ Waiting VPP lock before save (samples=$vppSampleCount, pending=$totalPages pages)');
      }
    } catch (e) {
      // Ignore page info errors
    }
  }

  /// Retry fetching page info until we get valid total pages
  Future<void> _retryPageInfoUntilValid() async {
    int retries = 0;
    const maxRetries = 10;
    const retryDelay = Duration(milliseconds: 300);

    while (retries < maxRetries && mounted) {
      await Future.delayed(retryDelay);
      retries++;
      debugPrint('🔄 Retry #$retries: Fetching page info...');
      await _updatePageInfo();

      if (_viewerTotalPages > 10) {
        debugPrint('✅ Valid total pages found: $_viewerTotalPages');
        break;
      }
    }

    if (_viewerTotalPages <= 1 && retries >= maxRetries) {
      debugPrint('⚠️ Page info retries exhausted (liveTotal=$_liveTotalPages)');
    }
  }

  Future<void> _handleClose() async {
    try {
      // Force-save current position when VPP never locked during this session.
      if (_controller.currentPage.value == 0) {
        final effectiveTotal = _viewerTotalPages > 1 ? _viewerTotalPages : _liveTotalPages;
        if (effectiveTotal > 1 && _viewerCurrentPage > 0) {
          log('💾 Pre-close force save (VPP never locked): page $_viewerCurrentPage / $effectiveTotal');
          _controller.onPageFlip(_viewerCurrentPage, effectiveTotal);
        }
      }
      await _controller.saveProgressAndClose();
    } catch (e) {
      // Ignore close errors
    }
    _cleanupTempFile();
    if (mounted) {
      Get.back();
    }
  }

  void _setError(String message) {
    if (!mounted) return;

    setState(() {
      _hasError = true;
      _errorMessage = message;
    });

    AppSnackbar.error(message, duration: const Duration(seconds: 4));
  }

  @override
  Widget build(BuildContext context) {
    if (_isBookReady && _epubSource != null) {
      return _buildReaderView();
    }
    return _buildLoadingView();
  }

  Widget _buildReaderView() {
    return WillPopScope(
      onWillPop: () async {
        await _handleClose();
        return false;
      },
      child: Scaffold(
        body: Stack(
          children: [
            // Full screen EpubViewer
            Container(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).viewPadding.top + 20,
              ),
              child: epub.EpubViewer(
                epubController: _viewerController,
                epubSource: _epubSource!,
                displaySettings: epub.EpubDisplaySettings(
                  flow: epub.EpubFlow.paginated,
                  snap: true,
                ),
                cachedLocations: _cachedLocations,
                onLocationsCached: (locationsJson) {
                  log('💾 Downloaded reader: Received locations from epub.js (${locationsJson.length} chars)');
                  _saveCachedLocations(locationsJson);
                  _cachedLocations = locationsJson;
                },
                onEpubLoaded: () {
                  debugPrint('EPUB loaded successfully');
                },
                onChaptersLoaded: (chapters) {
                  if (mounted) {
                    setState(() {
                      _isLoadingPages = false;
                    });
                  }
                },
                onRelocated: (location) {
                  _updatePageInfo();
                },
                onLocationLoaded: () {
                  _updatePageInfo();
                  // Retry page info after a short delay to get correct total pages
                  _retryPageInfoUntilValid();
                },
                onTextSelected: (selection) {
                  debugPrint('Text selected: ${selection.selectedText}');
                },
                onTouchDown: (x, y) {},
                onTouchUp: (x, y) {
                  if (mounted) {
                    setState(() {
                      _showControls = !_showControls;
                    });
                  }
                },
              ),
            ),

            // Top overlay bar
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              top: _showControls ? 0 : -100,
              left: 0,
              right: 0,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.7),
                      Colors.black.withOpacity(0.0),
                    ],
                  ),
                ),
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => _handleClose(),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.3),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Bottom overlay bar with page info
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              bottom: _showControls ? 0 : -80,
              left: 0,
              right: 0,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withOpacity(0.7),
                      Colors.black.withOpacity(0.0),
                    ],
                  ),
                ),
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12).copyWith(bottom: 30),
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: _isLoadingPages
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : Text(
                                '$_viewerCurrentPage / $_viewerTotalPages',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingView() {
    return WillPopScope(
      onWillPop: () async {
        _cleanupTempFile();
        Get.back();
        return true;
      },
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Book Cover
                  if (widget.bookDownload.coverUrl?.isNotEmpty ?? false)
                    widget.bookDownload.coverUrl?.isNotEmpty ?? false
                        ? CachedNetworkImage(
                            imageUrl: widget.bookDownload.coverUrl!,
                            width: 200,
                            height: 280,
                            fit: BoxFit.fill,
                            placeholder: (context, url) => Container(
                              color: Colors.grey[300],
                              child: const Center(
                                child: LoadingWidget(),
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: Colors.grey[300],
                              child: CustomIcon(
                                title: IconConstants.libraryFilled,
                                height: 24,
                                width: 24,
                                color: Colors.black,
                              ),
                            ),
                          )
                        : Container(
                            color: Colors.grey[300],
                            child: CustomIcon(
                              title: IconConstants.libraryFilled,
                              height: 24,
                              width: 24,
                              color: Colors.black,
                            ),
                          ),

                  const SizedBox(height: 80),

                  // Animated Loading Eyes
                  Image.asset('assets/images/l1.png', width: 60, height: 30, fit: BoxFit.cover),

                  const SizedBox(height: 20),

                  // Loading Text
                  Text(
                    'loading_t'.tr,
                    style: TextStyle(
                      fontSize: 15,
                      fontFamily: StringConstants.SFPro,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),

                  // Error UI
                  if (_hasError)
                    Column(
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Colors.red,
                          size: 60,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage ?? 'Unknown error',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton.icon(
                              onPressed: () => Get.back(),
                              icon: const Icon(Icons.arrow_back),
                              label: Text('leading_text'.tr),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey[800],
                              ),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton.icon(
                              onPressed: () {
                                setState(() {
                                  _hasError = false;
                                  _errorMessage = null;
                                });
                                _openBook();
                              },
                              icon: const Icon(Icons.refresh),
                              label: const Text('Retry'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _initialLoadingTimer?.cancel();
    _cleanupTempFile();
    super.dispose();
  }

  Future<void> _cleanupTempFile() async {
    try {
      final file = File(widget.decryptedFilePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {}
  }
}
