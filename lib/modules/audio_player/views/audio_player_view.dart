import 'package:elkitap/modules/audio_player/widgets/audio_background.dart';
import 'package:elkitap/modules/audio_player/widgets/audio_book_cover.dart';
import 'package:elkitap/modules/audio_player/widgets/audio_book_info.dart';
import 'package:elkitap/modules/audio_player/widgets/audio_bottom_controls.dart';
import 'package:elkitap/modules/audio_player/widgets/audio_playback_controls.dart';
import 'package:elkitap/modules/audio_player/widgets/audio_progress_bar.dart';
import 'package:elkitap/modules/audio_player/widgets/audio_top_bar.dart';
import 'package:elkitap/modules/audio_player/widgets/bluetooth_popup.dart';
import 'package:elkitap/modules/audio_player/widgets/sleep_timer_popup.dart';
import 'package:elkitap/modules/audio_player/widgets/speed_popup.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:elkitap/modules/audio_player/controllers/audio_player_controller.dart';
import 'package:elkitap/modules/audio_player/views/driver_mode_screen.dart';
import 'package:elkitap/modules/store/controllers/book_detail_controller.dart';

class AudiobookPlayerScreen extends StatelessWidget {
  final String? bookTitle;
  final String? bookAuthor;
  final String? bookCover;
  final String? hlsUrl;
  final int? bookId;
  final double? initialProgress;

  const AudiobookPlayerScreen({
    Key? key,
    this.bookTitle,
    this.bookAuthor,
    this.bookCover,
    this.hlsUrl,
    this.bookId,
    this.initialProgress,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(AudioPlayerController());
    final globalMiniCtrl = Get.find<GlobalMiniPlayerController>();
    BooksDetailController? bookDetailController;

    if (bookId != null) {
      final controllerTag = bookId.toString();
      if (Get.isRegistered<BooksDetailController>(tag: controllerTag)) {
        bookDetailController =
            Get.find<BooksDetailController>(tag: controllerTag);
      } else {
        bookDetailController = Get.put(
          BooksDetailController(),
          tag: controllerTag,
        );
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        bookDetailController!.fetchBookDetail(bookId!);
        bookDetailController.isAudio.value = true;
        if (hlsUrl != null) {
          bookDetailController.audioHlsUrl.value = hlsUrl!;
        }
      });
    }

    if (hlsUrl != null && hlsUrl!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        controller.loadBookAudio(
          hlsUrl: hlsUrl!,
          bookTitle: bookTitle ?? 'unknown_title'.tr,
          bookAuthor: bookAuthor ?? 'unknown_author'.tr,
          bookCover: bookCover ?? '',
          bookId: bookId ?? 0,
          initialProgress: initialProgress,
        );
      });
    }

    Future<bool> _onWillPop() async {
      controller.isPlaying.value ? globalMiniCtrl.show() : null;
      return true;
    }

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        body: Stack(
          children: [
            AudioBackground(),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    AudioTopBar(
                      bookId: bookId,
                      hlsUrl: hlsUrl,
                      bookTitle: bookTitle,
                      bookCover: bookCover,
                      bookAuthor: bookAuthor,
                      bookDetailController: bookDetailController,
                      globalMiniCtrl: globalMiniCtrl,
                    ),
                    AudioBookCover(),
                    AudioBookInfo(),
                    AudioProgressBar(),
                    AudioPlaybackControls(),
                    AudioBottomControls(
                      onSpeedTap: () => SpeedPopup.show(context, controller),
                      onSleepTimerTap: () =>
                          SleepTimerPopup.show(context, controller),
                      onBluetoothTap: () => BluetoothPopup.show(context),
                      onDriverModeTap: () {
                        controller.enableDriverMode();
                        Get.to(() => const DriverModeScreen());
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
