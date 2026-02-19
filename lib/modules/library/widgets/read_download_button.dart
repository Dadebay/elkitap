import 'dart:developer';
import 'dart:ui';

import 'package:elkitap/core/constants/string_constants.dart';
import 'package:elkitap/core/widgets/common/app_snackbar.dart';
import 'package:elkitap/data/network/token_managet.dart';
import 'package:elkitap/core/widgets/states/loading_widget.dart';
import 'package:elkitap/modules/auth/widget/login_bottom_sheet.dart';
import 'package:elkitap/modules/library/controllers/downloaded_controller.dart';
import 'package:elkitap/modules/library/views/downloaded_book_view.dart';
import 'package:elkitap/modules/reader/controllers/reader_controller.dart';
import 'package:elkitap/modules/reader/views/reader_view.dart';
import 'package:elkitap/modules/store/controllers/book_detail_controller.dart';
import 'package:elkitap/modules/store/model/book_detail_model.dart';
import 'package:elkitap/modules/store/model/book_item_model.dart'; // Import Book model
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ReadDownloadButton extends StatefulWidget {
  final BooksDetailController controller;
  final BookDetail book;
  final Color accent;
  final BorderRadiusGeometry? borderRadius;
  final bool showProgress;
  final String? progressText;

  const ReadDownloadButton({
    required this.controller,
    required this.book,
    required this.accent,
    this.borderRadius,
    this.showProgress = false,
    this.progressText,
    super.key,
  });

  @override
  State<ReadDownloadButton> createState() => _ReadDownloadButtonState();
}

class _ReadDownloadButtonState extends State<ReadDownloadButton> {
  late EpubController epubCtrl;

  @override
  void initState() {
    super.initState();

    // Use lazyPut to ensure controller exists
    if (!Get.isRegistered<EpubController>()) {
      Get.lazyPut<EpubController>(() => EpubController());
    }
    epubCtrl = Get.find<EpubController>();
  }

  Future<void> _handleRead() async {
    if (widget.controller.bookDetail.value?.translates.isEmpty ?? true) {
      await widget.controller.fetchBookDetail(widget.book.id);
    }

    final imageUrl = widget.controller.getBookCoverImage();
    final translate = widget.controller.getCurrentTranslate();

    final bookKey = translate?.bookKey;
    final bookId = widget.controller.bookDetail.value?.id.toString() ?? '0';

    // Log the translation being used
    log('=== OPENING EPUB READER ===');
    log('Selected Language: ${widget.controller.selectedLanguage.value}');
    log('Selected Translate ID: ${widget.controller.selectedTranslateId.value}');
    log('Current Translation: ${translate?.language}, ID: ${translate?.id}');
    log('BookKey: $bookKey');
    log('Unique BookId for CosmosEpub: ${bookId}_t${translate?.id}');
    log('========================');

    if (bookKey != null && bookKey.isNotEmpty && translate != null) {
      final book = Book(
        id: widget.book.id,
        name: widget.book.name,
        image: widget.book.image ?? widget.book.translates.firstOrNull?.image,
        age: widget.book.age,
        year: widget.book.year,
        likedBookId: widget.book.likedBookId,
        authors: widget.book.authors
            .map((author) => BookAuthor(
                  id: author.id,
                  name: author.name,
                  image: author.image,
                ))
            .toList(),
      );

      await Get.to(
        () => EpubReaderScreen(
          imageUrl: imageUrl,
          epubPath: bookKey,
          bookDescription: translate.description ?? '',
          bookId: bookId,
          isAddedToWantToRead: widget.controller.isAddedToWantToRead.value,
          isMarkedAsFinished: widget.controller.isMarkedAsFinished.value,
          book: book,
          translateId: translate.id,
        ),
      );

      // Refresh progress immediately after returning from reader
      log('�🔙🔙 ============================================');
      log('🔙 RETURNED FROM EPUB READER - STARTING REFRESH');
      log('🔙 Current progress value BEFORE refresh: ${widget.controller.progress.value}');
      log('🔙 ============================================');

      await widget.controller.fetchProgress();

      log('✅✅✅ ============================================');
      log('✅ PROGRESS REFRESH COMPLETED');
      log('✅ Current progress value AFTER refresh: ${widget.controller.progress.value}');
      log('✅ ============================================');

      await widget.controller.refreshBookDetail();
    } else {
      AppSnackbar.error('bookFileNotAvailable'.tr);
    }
  }

  Future<void> _handleDownload() async {
    final translate = widget.controller.getCurrentTranslate();
    final bookKey = translate?.bookKey;
    final baseBookId = widget.controller.bookDetail.value?.id.toString() ?? '0';
    // Create unique bookId that includes translation to allow downloading multiple translations
    final bookId = translate != null ? '${baseBookId}_t${translate.id}' : baseBookId;
    // Include language in title to distinguish downloads
    final bookTitle = translate != null ? '${translate.name} (${translate.language})' : (translate?.name ?? 'unknown'.tr);
    final imageUrl = widget.controller.getBookCoverImage();
    final author = widget.book.authors.isNotEmpty ? widget.book.authors.first.name : 'unknown_author'.tr;

    // Log download info
    log('=== DOWNLOADING BOOK ===');
    log('Selected Language: ${widget.controller.selectedLanguage.value}');
    log('Translate ID: ${translate?.id}');
    log('BookKey: $bookKey');
    log('Unique BookId for download: $bookId');
    log('========================');

    if (bookKey == null || bookKey.isEmpty) {
      AppSnackbar.error('bookFileNotAvailable'.tr);
      return;
    }

    // Show confirmation dialog
    final confirmed = await Get.dialog<bool>(
      Dialog(
        backgroundColor: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(Get.context!).brightness == Brightness.dark ? Colors.black.withOpacity(0.85) : Colors.white.withOpacity(0.95),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Theme.of(Get.context!).brightness == Brightness.dark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05),
                  width: 1,
                ),
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF5A3C).withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.download_rounded,
                      size: 30,
                      color: Color(0xFFFF5A3C),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'downloadBookTitle'.tr,
                    style: TextStyle(
                      fontFamily: StringConstants.SFPro,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(Get.context!).brightness == Brightness.dark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'downloadBookContent'.trParams({'bookTitle': bookTitle}),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: StringConstants.SFPro,
                      fontSize: 15,
                      color: Theme.of(Get.context!).brightness == Brightness.dark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Get.back(result: false),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: Theme.of(Get.context!).brightness == Brightness.dark ? Colors.grey[700]! : Colors.grey[300]!,
                              ),
                            ),
                          ),
                          child: Text(
                            'cancel'.tr,
                            style: TextStyle(
                              fontFamily: StringConstants.SFPro,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(Get.context!).brightness == Brightness.dark ? Colors.grey[400] : Colors.grey[600],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Get.back(result: true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF5A3C),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            'download'.tr,
                            style: const TextStyle(
                              fontFamily: StringConstants.SFPro,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
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

    if (confirmed != true) return;

    try {
      // Show loading dialog
      Get.dialog(
        WillPopScope(
          onWillPop: () async => false,
          child: Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  width: 280,
                  decoration: BoxDecoration(
                    color: Theme.of(Get.context!).brightness == Brightness.dark ? Colors.black.withOpacity(0.85) : Colors.white.withOpacity(0.95),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Theme.of(Get.context!).brightness == Brightness.dark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05),
                      width: 1,
                    ),
                  ),
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF5A3C).withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const LoadingWidget(),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'downloadingAndEncrypting'.tr,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: StringConstants.SFPro,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(Get.context!).brightness == Brightness.dark ? Colors.white : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        barrierDismissible: false,
      );

      // Get download controller
      final downloadController = Get.find<DownloadController>();

      // Download and encrypt book with unique ID per translation
      await downloadController.downloadAndEncryptBook(
        bookId: bookId,
        bookKey: bookKey,
        bookTitle: bookTitle,
        imageUrl: imageUrl,
        author: author,
      );

      // Close loading dialog
      Get.back();

      // Show success dialog with option to view downloads
      Get.dialog(
        Dialog(
          backgroundColor: Colors.transparent,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(Get.context!).brightness == Brightness.dark ? Colors.black.withOpacity(0.85) : Colors.white.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Theme.of(Get.context!).brightness == Brightness.dark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05),
                    width: 1,
                  ),
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: const Color(0xFF34C759).withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_circle_rounded,
                        size: 30,
                        color: Color(0xFF34C759),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'success'.tr,
                      style: TextStyle(
                        fontFamily: StringConstants.SFPro,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(Get.context!).brightness == Brightness.dark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'bookDownloadedSuccessfully'.trParams({'bookTitle': bookTitle}),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: StringConstants.SFPro,
                        fontSize: 15,
                        color: Theme.of(Get.context!).brightness == Brightness.dark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Get.back(),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                  color: Theme.of(Get.context!).brightness == Brightness.dark ? Colors.grey[700]! : Colors.grey[300]!,
                                ),
                              ),
                            ),
                            child: Text(
                              'ok'.tr,
                              style: TextStyle(
                                fontFamily: StringConstants.SFPro,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(Get.context!).brightness == Brightness.dark ? Colors.grey[400] : Colors.grey[600],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Get.back();
                              Get.to(() => const DownloadedListScreen());
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFF5A3C),
                              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 0,
                            ),
                            child: Text(
                              'viewDownloads'.tr,
                              style: const TextStyle(
                                fontFamily: StringConstants.SFPro,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
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
    } catch (e) {
      // Close loading dialog if open
      if (Get.isDialogOpen ?? false) {
        Get.back();
      }

      AppSnackbar.error('failedToDownload'.trParams({'error': e.toString()}));
    }
  }

  void _showLoginBottomSheet() {
    Get.bottomSheet(
      const LoginBottomSheet(),
      isDismissible: true,
      enableDrag: true,
      isScrollControlled: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final TokenManager tokenManager = Get.find<TokenManager>();
    return GestureDetector(
      onTap: () {
        if (tokenManager.isAuthenticated.value) {
          _handleRead();
        } else {
          _showLoginBottomSheet();
        }
      },
      onLongPress: _handleDownload,
      child: Container(
        height: 50,
        width: double.infinity,
        decoration: BoxDecoration(
          color: widget.accent,
          borderRadius: widget.borderRadius ??
              const BorderRadius.only(
                topLeft: Radius.circular(12),
                bottomLeft: Radius.circular(12),
              ),
        ),
        child: Center(
          child: Text(
            "read_button_action_t".tr,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontFamily: StringConstants.SFPro,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
