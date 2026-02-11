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
      final isDownloaded = downloadCtrl.downloadedBooks
          .any((book) => book.id == bookId.toString() && book.isAudio);

      return GestureDetector(
        onTap: () async {
          if (bookId == null || hlsUrl == null) {
            AppSnackbar.error('cannot_download_missing_info'.tr);
            return;
          }

          if (isDownloaded) {
            AppSnackbar.info('audiobook_already_downloaded'.tr);
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
        child: CustomIcon(
          title: isDownloaded
              ? IconConstants.a14
              : (downloadCtrl.isLoading.value
                  ? IconConstants.a9
                  : IconConstants.a13),
          height: 30,
          width: 30,
          color: isDownloaded ? Colors.green : Colors.white,
        ),
      );
    });
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
            AppSnackbar.info('book_details_not_available'.tr,
                duration: const Duration(seconds: 2));
          }
        },
      ),
    );
  }
}
