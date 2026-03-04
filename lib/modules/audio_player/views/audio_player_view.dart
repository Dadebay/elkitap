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

class AudiobookPlayerScreen extends StatefulWidget {
  final String? bookTitle;
  final String? bookAuthor;
  final String? bookCover;
  final String? hlsUrl;
  final int? bookId;
  final double? initialProgress;

  /// true → opened from DownloadedListScreen, always play local file
  final bool forceOffline;

  const AudiobookPlayerScreen({
    Key? key,
    this.bookTitle,
    this.bookAuthor,
    this.bookCover,
    this.hlsUrl,
    this.bookId,
    this.initialProgress,
    this.forceOffline = false,
  }) : super(key: key);

  @override
  State<AudiobookPlayerScreen> createState() => _AudiobookPlayerScreenState();
}

class _AudiobookPlayerScreenState extends State<AudiobookPlayerScreen> {
  late AudioPlayerController _controller;
  late GlobalMiniPlayerController _globalMiniCtrl;
  BooksDetailController? _bookDetailController;

  @override
  void initState() {
    super.initState();
    _controller = Get.put(AudioPlayerController());
    _globalMiniCtrl = Get.find<GlobalMiniPlayerController>();

    if (widget.bookId != null) {
      final controllerTag = widget.bookId.toString();
      if (Get.isRegistered<BooksDetailController>(tag: controllerTag)) {
        _bookDetailController = Get.find<BooksDetailController>(tag: controllerTag);
      } else {
        _bookDetailController = Get.put(
          BooksDetailController(),
          tag: controllerTag,
        );
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _bookDetailController!.fetchBookDetail(widget.bookId!);
        _bookDetailController!.isAudio.value = true;
        if (widget.hlsUrl != null) {
          _bookDetailController!.audioHlsUrl.value = widget.hlsUrl!;
        }
      });
    }

    if (widget.hlsUrl != null && widget.hlsUrl!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _controller.loadBookAudio(
          hlsUrl: widget.hlsUrl!,
          bookTitle: widget.bookTitle ?? 'unknown_title'.tr,
          bookAuthor: widget.bookAuthor ?? 'unknown_author'.tr,
          bookCover: widget.bookCover ?? '',
          bookId: widget.bookId ?? 0,
          initialProgress: widget.initialProgress,
          forceOffline: widget.forceOffline,
        );
      });
    }
  }

  @override
  void dispose() {
    // Route transition animasyonu bitmeden show() çağrılırsa
    // _shouldShowPlayer() hâlâ AudiobookPlayerScreen route'unu görür ve gizler.
    // Kısa bir gecikme ile navigasyon tamamlandıktan sonra gösteriyoruz.
    try {
      if (_controller.isPlaying.value) {
        Future.delayed(const Duration(milliseconds: 200), () {
          try {
            _globalMiniCtrl.show();
          } catch (_) {}
        });
      }
    } catch (_) {}
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          AudioBackground(),
          SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    AudioTopBar(
                      bookId: widget.bookId,
                      hlsUrl: widget.hlsUrl,
                      bookTitle: widget.bookTitle,
                      bookCover: widget.bookCover,
                      bookAuthor: widget.bookAuthor,
                      bookDetailController: _bookDetailController,
                      globalMiniCtrl: _globalMiniCtrl,
                    ),
                    AudioBookCover(),
                    AudioBookInfo(),
                    AudioProgressBar(),
                    AudioPlaybackControls(),
                    AudioBottomControls(
                      onSpeedTap: () => SpeedPopup.show(context, _controller),
                      onSleepTimerTap: () => SleepTimerPopup.show(context, _controller),
                      onBluetoothTap: () => BluetoothPopup.show(context),
                      onDriverModeTap: () {
                        _controller.enableDriverMode();
                        Get.to(() => const DriverModeScreen());
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
