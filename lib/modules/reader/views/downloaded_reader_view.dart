import 'dart:io';
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
import 'package:cosmos_epub/cosmos_epub.dart';

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

  String loadingMessage = 'Opening book...';
  bool _hasError = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _openBook();
  }

  Future<void> _openBook() async {
    try {
      setState(() {
        _hasError = false;
        _errorMessage = null;
        loadingMessage = 'Opening book...';
      });

      try {
        await CosmosEpub.initialize();
      } catch (e) {
        // Not fatal, continue
      }

      // Verify file exists
      final file = File(widget.decryptedFilePath);
      if (!await file.exists()) {
        throw Exception('Book file not found');
      }

      setState(() => loadingMessage = 'Loading ${widget.bookDownload.title}...');

      // IMPORTANT: Wait a frame to ensure context is valid
      await Future.delayed(Duration.zero);

      if (!mounted) return;

      // Open the decrypted EPUB file directly
      CosmosEpub.openLocalBook(
        localPath: widget.decryptedFilePath,
        context: context,
        imageUrl: widget.bookDownload.coverUrl ?? '',
        bookId: widget.bookDownload.id,
        onPageFlip: (currentPage, totalPages) {
          _controller.onPageFlip(currentPage, totalPages);
        },
        onLastPage: (lastPageIndex) {
          _controller.onLastPage(lastPageIndex);
        },
      ).then((_) {
        if (mounted) {
          Get.back();
          Get.back();
          Get.back();
        }
      });
    } catch (e) {
      _setError('Failed to open book: $e');
    }
  }

  void _setError(String message) {
    Get.back();
    if (!mounted) return;

    setState(() {
      Get.back();
      _hasError = true;
      _errorMessage = message;
    });

    AppSnackbar.error(message, duration: const Duration(seconds: 4));
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        // Clean up temp file when going back
        _cleanupTempFile();
        Get.back();
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
    _cleanupTempFile();
    super.dispose();
  }

  Future<void> _cleanupTempFile() async {
    try {
      final file = File(widget.decryptedFilePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      // Silently ignore cleanup errors
    }
  }
}
