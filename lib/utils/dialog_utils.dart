// ignore_for_file: deprecated_member_use

import 'package:cached_network_image/cached_network_image.dart';
import 'package:elkitap/core/config/deeplink_service.dart';
import 'package:elkitap/core/constants/icon_constants.dart';
import 'package:elkitap/core/constants/string_constants.dart';
import 'package:elkitap/core/widgets/common/app_snackbar.dart';
import 'package:elkitap/core/widgets/common/custom_icon.dart';
import 'package:elkitap/modules/library/controllers/downloaded_controller.dart';
import 'package:elkitap/modules/store/controllers/book_detail_controller.dart';

import 'package:elkitap/modules/reader/views/reader_view.dart';
import 'package:elkitap/modules/store/model/book_item_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'dart:ui';

import 'package:share_plus/share_plus.dart';

class DialogUtils {
  static void showOptionsPopupMenu(
      BuildContext context, BooksDetailController controller) {
    showDialog(
      context: context,
      barrierColor: Colors.black26,
      builder: (context) => Stack(
        children: [
          // Positioned popup menu
          Positioned(
            top: 60,
            right: 16,
            child: Material(
              color: Colors.transparent,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    width: 300,
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.black.withOpacity(0.75)
                          : Colors.white.withOpacity(0.75),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.black.withOpacity(0.3)
                            : Colors.white.withOpacity(0.3),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildMenuOption(
                            icon: IconConstants.d1,
                            title: 'share'.tr,
                            onTap: () {
                              Navigator.pop(context);
                              // Handle share
                              shareBook(controller, context);
                            },
                            context: context),
                        Container(
                          height: 6,
                          color: Colors.grey[400],
                        ),
                        // Conditionally show "add to want to read" or "add to want to listen" based on media type
                        Obx(() => _buildMenuOption(
                            icon: controller.isAddedToWantToRead.value
                                ? IconConstants.d5
                                : IconConstants.d2,
                            title: controller.isAudio.value
                                ? 'add_to_want_to_listen'.tr
                                : 'add_to_want_to_read'.tr,
                            titleColor: controller.isAddedToWantToRead.value
                                ? const Color(0xFFFF5A3C)
                                : null,
                            iconColor: controller.isAddedToWantToRead.value
                                ? const Color(0xFFFF5A3C)
                                : null,
                            onTap: () async {
                              Navigator.pop(context);

                              await controller.toggleWantToRead();

                              if (controller.isAuth.value) {
                                showAddedDialog(
                                  context,
                                  controller.isAddedToWantToRead.value,
                                  controller.isAudio.value,
                                );
                              }
                            },
                            context: context)),

                        Divider(height: 1, color: Colors.grey.withOpacity(0.2)),
                        // NEW: Updated mark as finished with toggle functionality
                        // Conditionally show different text for audio vs text books
                        Obx(() => _buildMenuOption(
                            icon: controller.isMarkedAsFinished.value
                                ? IconConstants.d5 // checkmark icon
                                : IconConstants.d2,
                            title: controller.isMarkedAsFinished.value
                                ? (controller.isAudio.value
                                    ? 'unmark_as_listened'.tr
                                    : 'unmark_as_finished'.tr)
                                : (controller.isAudio.value
                                    ? 'mark_as_listened'.tr
                                    : 'mark_as_finished'.tr),
                            titleColor: controller.isMarkedAsFinished.value
                                ? const Color(0xFFFF5A3C)
                                : null,
                            iconColor: controller.isMarkedAsFinished.value
                                ? const Color(0xFFFF5A3C)
                                : null,
                            onTap: () async {
                              Navigator.pop(context);
                              final success = await controller.markAsFinished();
                              if (success) {
                                AppSnackbar.info(
                                  controller.isMarkedAsFinished.value
                                      ? (controller.isAudio.value
                                          ? 'audiobook_marked_finished_message'
                                              .tr
                                          : 'book_marked_finished_message'.tr)
                                      : (controller.isAudio.value
                                          ? 'audiobook_unmarked_finished_message'
                                              .tr
                                          : 'book_unmarked_finished_message'
                                              .tr),
                                  title: controller.isMarkedAsFinished.value
                                      ? (controller.isAudio.value
                                          ? 'marked_as_listened'.tr
                                          : 'marked_as_finished'.tr)
                                      : (controller.isAudio.value
                                          ? 'unmarked_as_listened'.tr
                                          : 'unmarked_as_finished'.tr),
                                  duration: const Duration(seconds: 2),
                                );
                              }
                            },
                            context: context)),
                        controller.isMarkedAsFinished.value
                            ? Container(
                                height: 6,
                                color: Colors.grey[400],
                              )
                            : SizedBox.shrink(),
                        // NEW: Updated remove with unlike functionality
                        controller.isMarkedAsFinished.value
                            ? _buildMenuOption(
                                icon: IconConstants.d6,
                                title: 'remove'.tr,
                                titleColor: const Color(0xFFFF5A3C),
                                iconColor: const Color(0xFFFF5A3C),
                                onTap: () async {
                                  Navigator.pop(context);
                                  final success =
                                      await controller.markAsFinished();
                                  if (success) {
                                    AppSnackbar.info(
                                      controller.isMarkedAsFinished.value
                                          ? (controller.isAudio.value
                                              ? 'audiobook_marked_finished_message'
                                                  .tr
                                              : 'book_marked_finished_message'
                                                  .tr)
                                          : (controller.isAudio.value
                                              ? 'audiobook_unmarked_finished_message'
                                                  .tr
                                              : 'book_unmarked_finished_message'
                                                  .tr),
                                      title: controller.isMarkedAsFinished.value
                                          ? (controller.isAudio.value
                                              ? 'marked_as_listened'.tr
                                              : 'marked_as_finished'.tr)
                                          : (controller.isAudio.value
                                              ? 'unmarked_as_listened'.tr
                                              : 'unmarked_as_finished'.tr),
                                      duration: const Duration(seconds: 2),
                                    );
                                  }
                                },
                                context: context)
                            : SizedBox.shrink(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static void shareBook(
      BooksDetailController controller, BuildContext context) {
    final book = controller.bookDetail.value;

    final box = context.findRenderObject() as RenderBox?;
    final rect = box != null
        ? box.localToGlobal(Offset.zero) & box.size
        : const Rect.fromLTWH(0, 0, 0, 0); // Fallback

    if (book != null) {
      String shareText = '';

      shareText += '${book.name}\n';
      shareText +=
          'by ${book.authors.map((author) => author.name).join(', ')}\n\n';

      // Generate deep link
      String deepLink = DeepLinkService.generateBookDeepLink(book.id);
      shareText += 'Open in ElKitap: $deepLink';

      // Share the book
      Share.share(
        shareText,
        subject: '${book.name}',
        sharePositionOrigin: rect,
      );
    } else {
      // Fallback if book details aren't available
      Share.share(
        'Check out this amazing book on ElKitap!',
        sharePositionOrigin: rect,
      );
    }
  }

  static void showAudioPopupMenu(
    BuildContext context,
    BooksDetailController controller,
  ) {
    showDialog(
      context: context,
      barrierColor: Colors.black26,
      builder: (context) => Stack(
        children: [
          // Positioned popup menu
          Positioned(
            top: 60,
            right: 16,
            child: Material(
              color: Colors.transparent,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    width: 300,
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.black.withOpacity(0.75)
                          : Color(0xFF3D3633).withOpacity(0.95),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Switch to book (navigate to book detail)
                        _buildMenuOption(
                            icon: IconConstants.m1,
                            title: 'switch_to_book'.tr,
                            titleColor:
                                const Color.fromARGB(255, 255, 255, 255),
                            onTap: () {
                              Navigator.pop(context);
                              _handleOpenReader(controller, context);
                            },
                            iconColor: Colors.white,
                            context: context),
                        Divider(height: 1, color: Colors.grey.withOpacity(0.2)),
                        // Book description (show bottom sheet)
                        _buildMenuOption(
                            icon: IconConstants.d11,
                            title: 'book_description'.tr,
                            titleColor:
                                const Color.fromARGB(255, 255, 255, 255),
                            onTap: () {
                              Navigator.pop(context);
                              showBookDetailsBottomSheet(context, controller);
                            },
                            iconColor: Colors.white,
                            context: context),
                        Divider(height: 1, color: Colors.grey.withOpacity(0.2)),
                        // Download audio book
                        Obx(() {
                          final downloadCtrl = Get.find<DownloadController>();
                          final bookId = controller.bookDetail.value?.id;
                          final isDownloaded = bookId != null &&
                              downloadCtrl.downloadedBooks.any((b) =>
                                  b.id == bookId.toString() && b.isAudio);

                          return _buildMenuOption(
                              icon: IconConstants.a10,
                              title: isDownloaded
                                  ? 'downloaded'.tr
                                  : 'download'.tr,
                              titleColor: isDownloaded
                                  ? Colors.green
                                  : const Color.fromARGB(255, 255, 255, 255),
                              onTap: () async {
                                Navigator.pop(context);

                                final hlsUrl = controller.audioHlsUrl.value;
                                final bookTitle = controller.getBookName();
                                final bookCover =
                                    controller.getBookCoverImage();
                                final bookAuthor =
                                    controller.getAuthorsString();

                                if (bookId == null || hlsUrl.isEmpty) {
                                  AppSnackbar.error(
                                      'cannot_download_missing_info'.tr);
                                  return;
                                }

                                if (isDownloaded) {
                                  AppSnackbar.info(
                                      'audiobook_already_downloaded'.tr);
                                  return;
                                }

                                try {
                                  await downloadCtrl
                                      .downloadAndEncryptAudioBook(
                                    bookId: bookId.toString(),
                                    bookTitle: bookTitle,
                                    imageUrl: bookCover,
                                    author: bookAuthor.isEmpty
                                        ? 'unknown_author'.tr
                                        : bookAuthor,
                                    hlsUrl: hlsUrl,
                                  );
                                } catch (e) {
                                  // Error already handled in controller
                                }
                              },
                              iconColor:
                                  isDownloaded ? Colors.green : Colors.white,
                              context: context);
                        }),
                        Divider(height: 1, color: Colors.grey.withOpacity(0.2)),

                        Obx(() => _buildMenuOption(
                            icon: controller.isAddedToWantToRead.value
                                ? IconConstants.d5
                                : IconConstants.a11,
                            title: 'add_to_want_to_listen'.tr,
                            titleColor: controller.isAddedToWantToRead.value
                                ? const Color(0xFFFF5A3C)
                                : const Color.fromARGB(255, 255, 255, 255),
                            onTap: () async {
                              Navigator.pop(context);
                              await controller.toggleWantToRead();
                              if (controller.isAuth.value) {
                                showAddedDialog(
                                  context,
                                  controller.isAddedToWantToRead.value,
                                  controller.isAudio.value,
                                );
                              }
                            },
                            iconColor: controller.isAddedToWantToRead.value
                                ? const Color(0xFFFF5A3C)
                                : Colors.white,
                            context: context)),
                        Divider(height: 1, color: Colors.grey.withOpacity(0.2)),
                        // Share
                        _buildMenuOption(
                            icon: IconConstants.d1,
                            title: 'share'.tr,
                            titleColor:
                                const Color.fromARGB(255, 255, 255, 255),
                            onTap: () {
                              Navigator.pop(context);
                              shareBook(controller, context);
                            },
                            iconColor: Colors.white,
                            context: context),
                        Divider(height: 1, color: Colors.grey.withOpacity(0.2)),
                        // Report an issue
                        _buildMenuOption(
                            icon: IconConstants.a12,
                            title: 'report_an_issue'.tr,
                            titleColor: const Color(0xFFFF5A3C),
                            iconColor: const Color(0xFFFF5A3C),
                            onTap: () {
                              Navigator.pop(context);
                              _showReportIssueDialog(context, controller);
                            },
                            context: context),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static void showAddedDialog(
      BuildContext context, bool isAdded, bool isAudioMode) {
    // Debug logging to verify parameters

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: SizedBox(
            width: 300,
            height: 220,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: isAdded ? const Color(0xFFFF5A3C) : Colors.black87,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isAdded ? Icons.check : Icons.close,
                      size: 30,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isAdded ? 'added'.tr : 'removed'.tr,
                    style: const TextStyle(
                      fontSize: 20,
                      fontFamily: StringConstants.SFPro,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    isAdded
                        ? (isAudioMode
                            ? 'book_added_to_want_to_listen_list'.tr
                            : 'book_added_to_want_to_read_list'.tr)
                        : (isAudioMode
                            ? 'book_removed_from_want_to_listen_list'.tr
                            : 'book_removed_from_want_to_read_list'.tr),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 15,
                      fontFamily: StringConstants.SFPro,
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

  static void showLanguagePopup(
    BuildContext context,
    BooksDetailController controller, {
    Offset? buttonPosition,
    Size? buttonSize,
  }) {
    // Get available translations from the book detail
    final translates = controller.bookDetail.value?.translates ?? [];

    // If no translations available, don't show the popup
    if (translates.isEmpty) return;

    // Calculate dialog position based on button position
    final screenSize = MediaQuery.of(context).size;
    final dialogWidth = 200.0;

    double dialogLeft, dialogTop;

    if (buttonPosition != null && buttonSize != null) {
      // Position dialog below the button, centered horizontally with it
      dialogLeft =
          buttonPosition.dx + (buttonSize.width / 2) - (dialogWidth / 2);
      dialogTop =
          buttonPosition.dy + buttonSize.height + 8; // 8px gap below button

      // Keep dialog within screen bounds
      if (dialogLeft < 16) dialogLeft = 16;
      if (dialogLeft + dialogWidth > screenSize.width - 16) {
        dialogLeft = screenSize.width - dialogWidth - 16;
      }

      // Ensure dialog doesn't go below visible screen
      if (dialogTop + 300 > screenSize.height - 50) {
        // Position above the button instead
        dialogTop = buttonPosition.dy - 8; // 8px gap above button
      }
    } else {
      // Fallback to center of screen
      dialogLeft = (screenSize.width - dialogWidth) / 2;
      dialogTop = screenSize.height / 2 - 100;
    }

    showDialog(
      context: context,
      barrierColor: Colors.black26,
      builder: (context) => Stack(
        children: [
          Positioned(
            top: dialogTop,
            left: dialogLeft,
            child: Material(
              color: Colors.transparent,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    width: 200,
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.black.withOpacity(0.85)
                          : Colors.white.withOpacity(0.85),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.black.withOpacity(
                                0.3) // Dark Mode: Use highly opaque white
                            : Colors.white.withOpacity(0.3),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: translates.asMap().entries.map((entry) {
                        final index = entry.key;
                        final translate = entry.value;
                        final language = translate.language;
                        final translateId = translate.id;
                        final isLast = index == translates.length - 1;

                        return Column(
                          children: [
                            Obx(() => InkWell(
                                  onTap: () {
                                    controller.changeLanguage(
                                        language, translateId);
                                    Navigator.pop(context);
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 16,
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            language,
                                            style: const TextStyle(
                                              fontSize: 17,
                                              fontFamily: StringConstants.SFPro,
                                              fontWeight: FontWeight.w400,
                                            ),
                                          ),
                                        ),
                                        if (controller
                                                .selectedTranslateId.value ==
                                            translateId)
                                          const Icon(
                                            Icons.check,
                                            size: 24,
                                          ),
                                      ],
                                    ),
                                  ),
                                )),
                            if (!isLast)
                              Divider(
                                height: 1,
                                color: Colors.grey.withOpacity(0.2),
                              ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static void showBookDetailsBottomSheet(
    BuildContext context,
    BooksDetailController controller,
  ) {
    final bookDetail = controller.bookDetail.value;
    if (bookDetail == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Color(0xFFF5F5F5),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Header with book cover and title
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(20)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Book cover - Dynamic
                    Container(
                      width: 70,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: controller.getBookCoverImage().isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: controller.getBookCoverImage(),
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(
                                  color: Colors.grey[300],
                                  child: const Center(
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
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
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Title and author - Dynamic
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            controller.getBookName(),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                              fontFamily: StringConstants.SFPro,
                              height: 1.3,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            controller.getAuthorsString(),
                            style: TextStyle(
                              fontSize: 16,
                              fontFamily: StringConstants.SFPro,
                              color: Colors.grey[600],
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    // Close button
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          size: 18,
                          color: Colors.black54,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1.5),
              // Scrollable content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  children: [
                    // About section - Dynamic description
                    if (controller.getBookDescription().isNotEmpty) ...[
                      Text(
                        'about_t'.tr,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                          fontFamily: StringConstants.SFPro,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        controller.getBookDescription(),
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.grey[600],
                          fontFamily: StringConstants.SFPro,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],

                    // Basic Info section
                    Text(
                      'basic_info'.tr,
                      style: const TextStyle(
                        fontSize: 20,
                        fontFamily: StringConstants.SFPro,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Dynamic info rows
                    if (controller.getAuthorsString().isNotEmpty)
                      _buildInfoRow('author'.tr, controller.getAuthorsString()),

                    if (controller.selectedLanguage.value.isNotEmpty)
                      _buildInfoRow(
                          'language'.tr, controller.selectedLanguage.value),

                    if (bookDetail.genres.isNotEmpty)
                      _buildInfoRow(
                        'genre'.tr,
                        bookDetail.genres.map((g) => g.name).join(', '),
                      ),

                    if (bookDetail.age != null)
                      _buildInfoRow(
                        'age'.tr,
                        '${bookDetail.age}+',
                      ),

                    if (bookDetail.year != null)
                      _buildInfoRow(
                        'publication_date'.tr,
                        '${bookDetail.year}',
                      ),

                    // Progress info (if exists)
                    if (bookDetail.progress != null &&
                        bookDetail.progress!.isNotEmpty)
                      _buildInfoRow(
                        'progress'.tr,
                        '${bookDetail.progress}%',
                      ),

                    // Available languages
                    if (bookDetail.translates.isNotEmpty)
                      _buildInfoRow(
                        'available_language'.tr,
                        bookDetail.translates
                            .map((t) => _getLanguageName(t.language))
                            .join(', '),
                        isLast: true,
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

  static void showIOSStylePopup(BuildContext context, Function onOpenBook,
      Function onShare, Function onEdit, Function onRemove) {
    showDialog(
      context: context,
      barrierColor: Theme.of(context).brightness == Brightness.dark
          ? Colors.white24 // light semi-transparent overlay in dark mode
          : Colors.black26,
      builder: (context) => Stack(
        children: [
          Positioned(
            top: 120,
            right: 40,
            child: Material(
              color: Colors.transparent,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    width: 200,
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.black.withOpacity(0.75)
                          : Colors.white.withOpacity(0.85),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.black.withOpacity(0.3)
                            : Colors.white.withOpacity(0.3),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildIOSMenuOption(
                          context,
                          iconPath: IconConstants.d11,
                          title: 'open_book'.tr,
                          onTap: () => onOpenBook(),
                        ),
                        Container(
                          height: 6,
                          color: Colors.grey[400],
                        ),
                        _buildIOSMenuOption(
                          context,
                          iconPath: IconConstants.d1,
                          title: 'share'.tr,
                          onTap: () => onShare(),
                        ),
                        Divider(
                          height: 1,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white.withOpacity(
                                  0.1) // subtle divider in dark mode
                              : Colors.grey.withOpacity(
                                  0.2), // light divider in light mode
                        ),
                        _buildIOSMenuOption(
                          context,
                          iconPath: IconConstants.d10,
                          title: 'edit'.tr,
                          onTap: () => onEdit(),
                        ),
                        Divider(height: 1, color: Colors.grey.withOpacity(0.2)),
                        _buildIOSMenuOption(
                          context,
                          iconPath: IconConstants.d6,
                          title: 'delete'.tr,
                          iconColor: const Color(0xFFFF5A3C),
                          titleColor: const Color(0xFFFF5A3C),
                          onTap: () => onRemove(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static void showIOSStylePopupAtPosition(
    BuildContext context,
    RelativeRect position,
    Function onOpenBook,
    Function onShare,
    Function onEdit,
    Function onRemove,
  ) {
    showDialog(
      context: context,
      barrierColor: Theme.of(context).brightness == Brightness.dark
          ? Colors.white24
          : Colors.black26,
      builder: (context) {
        final screenSize = MediaQuery.of(context).size;
        const menuWidth = 200.0;
        const menuPadding = 40.0;
        const menuHeightEstimate = 230.0;

        final left = (position.left)
            .clamp(menuPadding, screenSize.width - menuWidth - menuPadding);
        final top = (position.top).clamp(
            menuPadding, screenSize.height - menuHeightEstimate - menuPadding);

        return Stack(
          children: [
            Positioned(
              left: left,
              top: top + 20,
              child: Material(
                color: Colors.transparent,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                    child: Container(
                      width: menuWidth,
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.black.withOpacity(0.75)
                            : Colors.white.withOpacity(0.85),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.black.withOpacity(0.3)
                              : Colors.white.withOpacity(0.3),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 30,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildIOSMenuOption(
                            context,
                            iconPath: IconConstants.d11,
                            title: 'open_book'.tr,
                            onTap: () => onOpenBook(),
                          ),
                          Container(
                            height: 6,
                            color: Colors.grey[400],
                          ),
                          _buildIOSMenuOption(
                            context,
                            iconPath: IconConstants.d1,
                            title: 'share'.tr,
                            onTap: () => onShare(),
                          ),
                          Divider(
                            height: 1,
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white.withOpacity(0.1)
                                    : Colors.grey.withOpacity(0.2),
                          ),
                          _buildIOSMenuOption(
                            context,
                            iconPath: IconConstants.d10,
                            title: 'edit'.tr,
                            onTap: () => onEdit(),
                          ),
                          Divider(
                              height: 1, color: Colors.grey.withOpacity(0.2)),
                          _buildIOSMenuOption(
                            context,
                            iconPath: IconConstants.d6,
                            title: 'delete'.tr,
                            iconColor: const Color(0xFFFF5A3C),
                            titleColor: const Color(0xFFFF5A3C),
                            onTap: () => onRemove(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  static Widget _buildMenuOption({
    required String icon,
    required String title,
    required VoidCallback onTap,
    required BuildContext context,
    Color? titleColor,
    Color? iconColor,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 17,
                  color: titleColor,
                  fontFamily: StringConstants.SFPro,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            CustomIcon(
              title: icon,
              height: 24,
              width: 24,
              color: iconColor ??
                  (Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black),
            )
          ],
        ),
      ),
    );
  }

// Helper method to get language display name
  static String _getLanguageName(String languageCode) {
    switch (languageCode.toLowerCase()) {
      case 'tk':
      case 'tkm':
        return 'Türkmençe';
      case 'ru':
      case 'rus':
        return 'Русский';
      case 'en':
      case 'eng':
        return 'English';
      case 'tr':
      case 'tur':
        return 'Türkçe';
      default:
        return languageCode.toUpperCase();
    }
  }

  static Widget _buildInfoRow(String label, String value,
      {bool isLast = false}) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 140,
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 15,
                    fontFamily: StringConstants.SFPro,
                    color: Colors.grey[600],
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Colors.black87,
                    fontWeight: FontWeight.w500,
                    fontFamily: StringConstants.SFPro,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (!isLast)
          Divider(
            height: 1,
            color: Colors.grey.withOpacity(0.3),
          ),
      ],
    );
  }

  static Widget _buildIOSMenuOption(
    BuildContext context, {
    required String iconPath,
    required String title,
    required VoidCallback onTap,
    Color? iconColor,
    Color? titleColor,
  }) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        child: Row(
          children: [
            Text(
              title,
              style: TextStyle(
                  fontSize: 16,
                  color: titleColor ??
                      (Theme.of(context).brightness == Brightness.dark
                          ? Colors.white // white in dark mode
                          : Colors.black)),
            ),
            Spacer(),
            SvgPicture.asset(iconPath,
                width: 20,
                height: 20,
                color: iconColor ??
                    (Theme.of(context).brightness == Brightness.dark
                        ? Colors.white // white in dark mode
                        : Colors.black)),
          ],
        ),
      ),
    );
  }

  // Show report issue dialog
  static void _showReportIssueDialog(
      BuildContext context, BooksDetailController controller) {
    final TextEditingController problemController = TextEditingController();
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setState) {
          void safeSetState(VoidCallback fn) {
            if (context.mounted) {
              setState(fn);
            }
          }

          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header with close button
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'report_an_issue'.tr,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              fontFamily: StringConstants.SFPro,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () {
                              Navigator.pop(sheetContext);
                              Future.delayed(const Duration(milliseconds: 300),
                                  () {
                                problemController.dispose();
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'describe_your_issue'.tr,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          fontFamily: StringConstants.SFPro,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: problemController,
                        maxLines: 5,
                        decoration: InputDecoration(
                          hintText: 'enter_issue_description'.tr,
                          hintStyle: TextStyle(
                            color: Colors.grey[400],
                            fontFamily: StringConstants.SFPro,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                const BorderSide(color: Color(0xFFFF5A3C)),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                          contentPadding: const EdgeInsets.all(16),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Action buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                Navigator.pop(sheetContext);
                                Future.delayed(
                                    const Duration(milliseconds: 300), () {
                                  problemController.dispose();
                                });
                              },
                              style: OutlinedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                side: BorderSide(color: Colors.grey[300]!),
                              ),
                              child: Text(
                                'cancel'.tr,
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontFamily: StringConstants.SFPro,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: !isSubmitting
                                  ? () async {
                                      final problem =
                                          problemController.text.trim();
                                      if (problem.isEmpty) {
                                        AppSnackbar.error(
                                            'please_enter_issue_description'
                                                .tr);
                                        return;
                                      }

                                      safeSetState(() {
                                        isSubmitting = true;
                                      });

                                      final success = await controller
                                          .sendProblemReport(problem);

                                      if (success) {
                                        if (sheetContext.mounted) {
                                          Navigator.pop(sheetContext);
                                        }
                                        Future.delayed(
                                            const Duration(milliseconds: 300),
                                            () {
                                          problemController.dispose();
                                        });
                                        AppSnackbar.success(
                                            'issue_reported_successfully'.tr);
                                      } else {
                                        safeSetState(() {
                                          isSubmitting = false;
                                        });
                                        AppSnackbar.error(
                                            'failed_to_report_issue'.tr);
                                      }
                                    }
                                  : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFF5A3C),
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: isSubmitting
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                                Colors.white),
                                      ),
                                    )
                                  : Text(
                                      'submit'.tr,
                                      style: const TextStyle(
                                        fontFamily: StringConstants.SFPro,
                                        fontSize: 16,
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
          );
        },
      ),
    );
  }

  static Future<void> _handleOpenReader(
      BooksDetailController controller, BuildContext context) async {
    if (controller.bookDetail.value?.translates.isEmpty ?? true) {
      await controller.fetchBookDetail(controller.bookDetail.value?.id ?? 0);
    }

    final imageUrl = controller.getBookCoverImage();
    final translate = controller.getCurrentTranslate();

    final bookKey = translate?.bookKey;
    final bookId = controller.bookDetail.value?.id.toString() ?? '0';

    if (bookKey != null && bookKey.isNotEmpty && translate != null) {
      final bookDetail = controller.bookDetail.value!;
      final book = Book(
        id: bookDetail.id,
        name: bookDetail.name,
        image: bookDetail.image ?? bookDetail.translates.firstOrNull?.image,
        age: bookDetail.age,
        year: bookDetail.year,
        likedBookId: bookDetail.likedBookId,
        authors: bookDetail.authors
            .map((author) => BookAuthor(
                  id: author.id,
                  name: author.name,
                  image: author.image,
                ))
            .toList(),
      );

      Get.back(); // Close audio player

      await Get.to(
        () => EpubReaderScreen(
          imageUrl: imageUrl,
          epubPath: bookKey,
          bookDescription: translate.description ?? '',
          bookId: bookId,
          isAddedToWantToRead: controller.isAddedToWantToRead.value,
          isMarkedAsFinished: controller.isMarkedAsFinished.value,
          book: book,
          translateId: translate.id,
        ),
      );
    } else {
      AppSnackbar.error('bookFileNotAvailable'.tr);
    }
  }
}
