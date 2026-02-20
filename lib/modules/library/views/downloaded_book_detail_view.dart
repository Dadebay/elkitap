import 'package:cached_network_image/cached_network_image.dart';
import 'package:elkitap/core/constants/icon_constants.dart';
import 'package:elkitap/core/constants/string_constants.dart';
import 'package:elkitap/core/widgets/common/app_snackbar.dart';
import 'package:elkitap/core/widgets/common/custom_icon.dart';
import 'package:elkitap/core/widgets/states/loading_widget.dart';
import 'package:elkitap/modules/audio_player/controllers/audio_player_controller.dart';
import 'package:elkitap/modules/audio_player/views/audio_player_view.dart';
import 'package:elkitap/modules/library/controllers/downloaded_controller.dart';
import 'package:elkitap/modules/library/model/book_download_model.dart';
import 'package:elkitap/modules/reader/controllers/reader_controller.dart';
import 'package:elkitap/modules/reader/views/downloaded_reader_view.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:io';
import 'package:iconly/iconly.dart';

class DownloadedBookDetailView extends StatefulWidget {
  final String bookId;

  const DownloadedBookDetailView({
    required this.bookId,
    super.key,
  });

  @override
  State<DownloadedBookDetailView> createState() => _DownloadedBookDetailViewState();
}

class _DownloadedBookDetailViewState extends State<DownloadedBookDetailView> {
  late DownloadController downloadCtrl;
  late GlobalMiniPlayerController globalMiniCtrl;
  late EpubController epubCtrl;

  final Color accent = const Color(0xFFFF5A3C);
  BookDownload? textBook;
  BookDownload? audioBook;

  @override
  void initState() {
    super.initState();

    downloadCtrl = Get.find<DownloadController>();
    globalMiniCtrl = Get.find<GlobalMiniPlayerController>();
    epubCtrl = Get.find<EpubController>();

    // Find both text and audio versions
    final allBooks = downloadCtrl.downloadedBooks.where((book) => book.id == widget.bookId).toList();

    for (var book in allBooks) {
      if (book.isAudio) {
        audioBook = book;
      } else {
        textBook = book;
      }
    }
  }

  // Get the primary book (prefer text, fallback to audio)
  BookDownload? get primaryBook => textBook ?? audioBook;

  Future<void> _openBookReader() async {
    if (textBook == null) return;

    try {
      final tempPath = await downloadCtrl.openEncryptedBook(textBook!);

      if (tempPath == null) {
        throw Exception('Failed to decrypt book');
      }

      final file = File(tempPath);
      if (!await file.exists()) {
        throw Exception('Decrypted file not found');
      }

      await Future.delayed(const Duration(milliseconds: 100));

      if (!mounted) return;

      await Get.to(() => DownloadedEpubReaderScreen(
            bookDownload: textBook!,
            decryptedFilePath: tempPath,
          ));
    } catch (e) {
      AppSnackbar.error('Failed to open book: $e', duration: const Duration(seconds: 4));
    }
  }

  void _openAudioPlayer() {
    if (audioBook == null || audioBook!.hlsUrl == null) return;

    Get.to(() => AudiobookPlayerScreen(
          bookTitle: audioBook!.title,
          bookAuthor: audioBook!.author,
          bookCover: audioBook!.coverUrl,
          hlsUrl: audioBook!.hlsUrl,
          bookId: int.tryParse(audioBook!.id),
        ));
    globalMiniCtrl.hide();
  }

  void _showDeleteOptions() {
    final hasText = textBook != null;
    final hasAudio = audioBook != null;

    if (!hasText && !hasAudio) return;

    // If only one version exists, delete it directly
    if (hasText && !hasAudio) {
      downloadCtrl.showRemoveDialogForBook(context, widget.bookId);
      return;
    }
    if (!hasText && hasAudio) {
      downloadCtrl.showRemoveDialogForBook(context, widget.bookId);
      return;
    }

    // Both versions exist - show options
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: theme.dialogBackgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'delete_options'.tr,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: StringConstants.SFPro,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: Icon(
                  Icons.book_outlined,
                  color: colorScheme.onSurface,
                ),
                title: Text(
                  'delete_text_version'.tr,
                  style: TextStyle(color: colorScheme.onSurface),
                ),
                onTap: () {
                  Get.back();
                  downloadCtrl.deleteDownload(widget.bookId, isAudio: false);
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.headphones_outlined,
                  color: colorScheme.onSurface,
                ),
                title: Text(
                  'delete_audio_version'.tr,
                  style: TextStyle(color: colorScheme.onSurface),
                ),
                onTap: () {
                  Get.back();
                  downloadCtrl.deleteDownload(widget.bookId, isAudio: true);
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.delete_outline,
                  color: colorScheme.error,
                ),
                title: Text(
                  'delete_both_versions'.tr,
                  style: TextStyle(color: colorScheme.error),
                ),
                onTap: () async {
                  Get.back();
                  await downloadCtrl.deleteDownload(widget.bookId, isAudio: false);
                  await downloadCtrl.deleteDownload(widget.bookId, isAudio: true);
                  Get.back(); // Go back to library
                },
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => Get.back(),
                child: Text(
                  'cancel_button_t'.tr,
                  style: TextStyle(color: colorScheme.primary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (primaryBook == null) {
      return Scaffold(
        backgroundColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E1E1E) : const Color(0xFFF5F5F5),
        body: const Center(
          child: Text('Book not found'),
        ),
      );
    }

    final hasText = textBook != null;
    final hasAudio = audioBook != null;

    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E1E1E) : const Color(0xFFF5F5F5),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(46),
        child: AppBar(
          backgroundColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E1E1E) : const Color(0xFFF5F5F5),
          elevation: 0,
          automaticallyImplyLeading: false,
          flexibleSpace: Padding(
            padding: const EdgeInsets.only(top: 0, left: 16, right: 16),
            child: SafeArea(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Close button
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[700] : Colors.grey[200],
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close, size: 18),
                    ),
                  ),

                  // Delete button
                  GestureDetector(
                    onTap: _showDeleteOptions,
                    child: Container(
                      width: 36,
                      height: 36,
                      margin: EdgeInsets.only(top: 6),
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[700] : Colors.grey[200],
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        IconlyLight.delete,
                        size: 18,
                        color: Colors.red,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),

            // Book Cover
            Container(
              width: 200,
              height: 280,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: primaryBook!.coverUrl?.isNotEmpty ?? false
                    ? CachedNetworkImage(
                        imageUrl: primaryBook!.coverUrl!,
                        width: 200,
                        height: 280,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: Colors.grey[300],
                          child: const Center(child: LoadingWidget()),
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
            const SizedBox(height: 16),

            const SizedBox(height: 32),

            // Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: SizedBox(
                width: MediaQuery.of(context).size.width * 0.8,
                child: Text(
                  primaryBook!.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontFamily: StringConstants.GilroyRegular,
                    fontSize: 22,
                    height: 1.3,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 8),

            // Author
            SizedBox(
              width: MediaQuery.of(context).size.width * 0.8,
              child: Text(
                primaryBook!.author,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  color: Colors.grey,
                  fontFamily: StringConstants.SFPro,
                ),
              ),
            ),

            const SizedBox(height: 16),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                children: [
                  if (hasText)
                    GestureDetector(
                      onTap: _openBookReader,
                      child: Container(
                        width: double.infinity,
                        height: 50,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF5A3C),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          "read_button_t".tr,
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
                  if (hasText && hasAudio) const SizedBox(height: 12),
                  if (hasAudio)
                    GestureDetector(
                      onTap: _openAudioPlayer,
                      child: Container(
                        width: double.infinity,
                        height: 50,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF5A3C),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          "listen_button_t".tr,
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
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Download Info Section
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'download_information'.tr,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontFamily: StringConstants.GilroyRegular,
                        fontSize: 20,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Show info for both versions if available
                if (hasText) ...[
                  const SizedBox(height: 8),
                  _buildDownloadInfo(context, textBook!),
                  if (hasAudio) const SizedBox(height: 16),
                ],

                if (hasAudio) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Audio Version',
                        style: TextStyle(
                          fontSize: 14,
                          fontFamily: StringConstants.SFPro,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildDownloadInfo(context, audioBook!),
                ],

                const SizedBox(height: 50),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDownloadInfo(BuildContext context, BookDownload book) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'downloaded_on'.tr,
                style: TextStyle(
                  fontSize: 15,
                  fontFamily: StringConstants.SFPro,
                  color: colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              Text(
                '${book.downloadDate.day}/${book.downloadDate.month}/${book.downloadDate.year}',
                style: TextStyle(
                  fontSize: 15,
                  fontFamily: StringConstants.SFPro,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'file_size'.tr,
                style: TextStyle(
                  fontSize: 15,
                  fontFamily: StringConstants.SFPro,
                  color: colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              Text(
                book.isAudio ? 'Streaming' : '${(book.fileSize / (1024 * 1024)).toStringAsFixed(2)} MB',
                style: TextStyle(
                  fontSize: 15,
                  fontFamily: StringConstants.SFPro,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
