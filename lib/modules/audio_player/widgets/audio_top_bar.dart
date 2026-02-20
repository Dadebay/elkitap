// ignore_for_file: use_super_parameters

import 'package:elkitap/core/constants/icon_constants.dart';
import 'package:elkitap/core/widgets/common/app_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:elkitap/core/widgets/common/custom_icon.dart';
import 'package:elkitap/modules/audio_player/controllers/audio_player_controller.dart';
import 'package:elkitap/modules/library/controllers/downloaded_controller.dart';
import 'package:elkitap/modules/store/controllers/book_detail_controller.dart';
import 'package:elkitap/utils/dialog_utils.dart';

class AudioTopBar extends StatelessWidget {
  final int? bookId;
  final String? hlsUrl;
  final String? bookTitle;
  final String? bookCover;
  final String? bookAuthor;
  final BooksDetailController? bookDetailController;
  final GlobalMiniPlayerController globalMiniCtrl;

  const AudioTopBar({
    Key? key,
    required this.bookId,
    required this.hlsUrl,
    required this.bookTitle,
    required this.bookCover,
    required this.bookAuthor,
    required this.bookDetailController,
    required this.globalMiniCtrl,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AudioPlayerController>();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        CircleAvatar(
          backgroundColor: Colors.grey.shade800,
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              Get.back();
              controller.isPlaying.value ? globalMiniCtrl.show() : null;
            },
          ),
        ),
        Row(
          children: [
            _buildDownloadButton(),
            const SizedBox(width: 10),
            _buildMoreButton(context),
          ],
        ),
      ],
    );
  }

  Widget _buildDownloadButton() {
    return Obx(() {
      final downloadCtrl = Get.find<DownloadController>();
      final isDownloaded = downloadCtrl.downloadedBooks.any((book) => book.id == bookId.toString() && book.isAudio);
      final isLoading = downloadCtrl.isLoading.value;
      final progress = downloadCtrl.downloadProgress.value;

      return GestureDetector(
        onTap: () async {
          if (isLoading) {
            // Show cancel confirmation dialog
            _showCancelDownloadDialog(downloadCtrl);
            return;
          }

          if (bookId == null || hlsUrl == null) {
            AppSnackbar.error('cannot_download_missing_info'.tr);
            return;
          }

          if (isDownloaded) {
            AppSnackbar.info('audiobook_already_downloaded'.tr);
            return;
          }

          // Prevent duplicate downloads
          if (downloadCtrl.isLoading.value) {
            return;
          }

          try {
            await downloadCtrl.downloadAndEncryptAudioBook(
              bookId: bookId.toString(),
              bookTitle: bookTitle ?? 'unknown_title'.tr,
              imageUrl: bookCover ?? '',
              author: bookAuthor ?? 'unknown_author'.tr,
              hlsUrl: hlsUrl!,
            );
          } catch (e) {
            // Error already handled
          }
        },
        child: isLoading
            ? SizedBox(
                height: 30,
                width: 30,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      // Indeterminate when encrypting (progress == 1.0)
                      value: progress > 0 && progress < 1.0 ? progress : null,
                      strokeWidth: 2.5,
                      color: Colors.white,
                      backgroundColor: Colors.white24,
                    ),
                    if (progress > 0)
                      Text(
                        '${(progress * 100).toInt()}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ],
                ),
              )
            : CustomIcon(
                title: isDownloaded ? IconConstants.a14 : IconConstants.a13,
                height: 30,
                width: 30,
                color: Colors.white,
              ),
      );
    });
  }

  void _showCancelDownloadDialog(DownloadController downloadCtrl) {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.warning_rounded,
                  color: Colors.orange.shade700,
                  size: 32,
                ),
              ),
              const SizedBox(height: 20),

              // Title
              Text(
                'cancel_download'.tr,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

              // Message
              Text(
                'cancel_download_confirmation'.tr,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Get.back(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                      child: Text(
                        'no'.tr,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        downloadCtrl.cancelDownload();
                        Get.back();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'yes'.tr,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
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
      barrierDismissible: true,
    );
  }

  Widget _buildMoreButton(BuildContext context) {
    return CircleAvatar(
      backgroundColor: Colors.grey.shade800,
      child: IconButton(
        icon: const Icon(Icons.more_horiz, color: Colors.white),
        onPressed: () {
          if (bookDetailController != null) {
            DialogUtils.showAudioPopupMenu(context, bookDetailController!);
          } else {
            AppSnackbar.info('book_details_not_available'.tr, duration: const Duration(seconds: 2));
          }
        },
      ),
    );
  }
}
