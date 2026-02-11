import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:elkitap/core/constants/icon_constants.dart';
import 'package:elkitap/core/constants/string_constants.dart';
import 'package:elkitap/core/widgets/common/custom_icon.dart';
import 'package:elkitap/modules/audio_player/controllers/audio_player_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class FullWidthSliderTrackShape extends RoundedRectSliderTrackShape {
  @override
  Rect getPreferredRect({
    required RenderBox parentBox,
    Offset offset = Offset.zero,
    required SliderThemeData sliderTheme,
    bool isEnabled = false,
    bool isDiscrete = false,
  }) {
    final double trackHeight = sliderTheme.trackHeight!;
    final double trackLeft = offset.dx;
    final double trackTop = offset.dy + (parentBox.size.height - trackHeight) / 2;
    final double trackWidth = parentBox.size.width;
    return Rect.fromLTWH(trackLeft, trackTop, trackWidth, trackHeight);
  }
}

class DriverModeScreen extends StatefulWidget {
  const DriverModeScreen({Key? key}) : super(key: key);

  @override
  State<DriverModeScreen> createState() => _DriverModeScreenState();
}

class _DriverModeScreenState extends State<DriverModeScreen> {
  @override
  void initState() {
    super.initState();
    // Allow both portrait and landscape modes
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  void dispose() {
    // Restore all orientations when leaving this screen
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AudioPlayerController>();

    return Scaffold(
      body: Stack(
        children: [
          _buildBackgroundImage(controller),
          _buildBlurOverlay(),
          _buildContent(controller),
        ],
      ),
    );
  }

  // Arka plan resmi
  Widget _buildBackgroundImage(AudioPlayerController controller) {
    return Positioned.fill(
      child: Obx(() {
        final cover = controller.currentBookCover.value;
        if (cover.isNotEmpty) {
          return CachedNetworkImage(
            imageUrl: cover,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              color: const Color(0xFF8B5A3C),
            ),
            errorWidget: (context, url, error) => Container(
              color: const Color(0xFF8B5A3C),
            ),
          );
        }
        return Image.asset(
          'assets/images/b6.png',
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(
            color: const Color(0xFF8B5A3C),
          ),
        );
      }),
    );
  }

  // Blur efekti ve gradient
  Widget _buildBlurOverlay() {
    return Positioned.fill(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.grey.shade900.withOpacity(0.7),
                Colors.grey.shade800.withOpacity(0.75),
                Colors.grey.shade900.withOpacity(0.8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Ana içerik
  Widget _buildContent(AudioPlayerController controller) {
    return SafeArea(
      child: OrientationBuilder(
        builder: (context, orientation) {
          return orientation == Orientation.landscape ? _buildLandscapeLayout(context, controller) : _buildPortraitLayout(context, controller);
        },
      ),
    );
  }

  // Üst bar (kapatma butonu)
  Widget _buildTopBar(AudioPlayerController controller) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () {
              controller.disableDriverMode();
              Get.back();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade800,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.close,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Yatay (landscape) düzen
  Widget _buildLandscapeLayout(BuildContext context, AudioPlayerController controller) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 20, bottom: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () {
                  controller.disableDriverMode();
                  Get.back();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade800,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
        _buildLandscapeControls(context, controller),
        _buildTimeAndProgress(controller, horizontalPadding: 0),
      ],
    );
  }

  // Yatay mod kontrolleri (15s geri - kapak - 15s ileri)
  Widget _buildLandscapeControls(BuildContext context, AudioPlayerController controller) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(
          child: _buildSeekButton(
            onTap: controller.seekBackward,
            icon: IconConstants.a1,
            size: 80,
          ),
        ),
        _buildBookCoverWithPlayButton(
          context,
          controller,
          size: MediaQuery.of(context).size.height * 0.50,
          borderRadius: 15,
          playButtonSize: 80,
          playIconSize: 50,
        ),
        Expanded(
          child: _buildSeekButton(
            onTap: controller.seekForward,
            icon: IconConstants.a2,
            size: 80,
          ),
        ),
      ],
    );
  }

  // Dikey (portrait) düzen
  Widget _buildPortraitLayout(BuildContext context, AudioPlayerController controller) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildTopBar(controller),
        _buildBookCoverWithPlayButton(
          context,
          controller,
          size: MediaQuery.of(context).size.width * 0.85,
          borderRadius: 20,
          playButtonSize: 120,
          playIconSize: 70,
          topPadding: 100,
        ),
        const SizedBox(height: 40),
        _buildTimeDisplay(controller, fontSize: 34),
        const SizedBox(height: 20),
        _buildProgressSlider(controller, trackHeight: 6),
        const SizedBox(height: 60),
        _buildPortraitControls(controller),
      ],
    );
  }

  // Kitap kapağı ve play butonu
  Widget _buildBookCoverWithPlayButton(
    BuildContext context,
    AudioPlayerController controller, {
    required double size,
    required double borderRadius,
    required double playButtonSize,
    required double playIconSize,
    double? topPadding,
  }) {
    return Stack(
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: borderRadius == 15 ? 20 : 30,
                offset: Offset(0, borderRadius == 15 ? 8 : 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(borderRadius),
            child: _buildCoverImage(controller, borderRadius == 15 ? 50.0 : 80.0),
          ),
        ),
        Positioned.fill(
          child: Center(
            child: _buildPlayPauseButton(
              controller,
              playButtonSize,
              playIconSize,
              borderRadius == 15 ? 0.5 : 0.4,
            ),
          ),
        ),
      ],
    );
  }

  // Kapak resmi
  Widget _buildCoverImage(AudioPlayerController controller, double iconSize) {
    return Obx(() {
      final cover = controller.currentBookCover.value;
      if (cover.isNotEmpty) {
        return CachedNetworkImage(
          imageUrl: cover,
          fit: BoxFit.cover,
          placeholder: (context, url) => _buildPlaceholder(),
          errorWidget: (context, url, error) => _buildErrorWidget(iconSize),
        );
      }
      return Image.asset(
        'assets/images/b6.png',
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildErrorWidget(iconSize),
      );
    });
  }

  // Placeholder widget
  Widget _buildPlaceholder() {
    return Container(
      color: Colors.grey.shade800,
      child: const Center(
        child: CircularProgressIndicator(color: Colors.white),
      ),
    );
  }

  // Hata widget'ı
  Widget _buildErrorWidget(double iconSize) {
    return Container(
      color: Colors.grey.shade800,
      child: Center(
        child: Icon(
          Icons.music_note,
          size: iconSize,
          color: Colors.white30,
        ),
      ),
    );
  }

  // Play/Pause butonu
  Widget _buildPlayPauseButton(
    AudioPlayerController controller,
    double size,
    double iconSize,
    double opacity,
  ) {
    return GestureDetector(
      onTap: controller.playPause,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(opacity),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Obx(() {
            return CustomIcon(
              title: controller.isPlaying.value ? IconConstants.a4 : IconConstants.a3,
              height: iconSize,
              width: iconSize,
              color: Colors.white,
            );
          }),
        ),
      ),
    );
  }

  // Seek butonu (15s ileri/geri)
  Widget _buildSeekButton({
    required VoidCallback onTap,
    required String icon,
    required double size,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: size,
        height: size,
        child: Center(
          child: CustomIcon(
            title: icon,
            width: size,
            height: size,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  // Süre ve progress bar
  Widget _buildTimeAndProgress(
    AudioPlayerController controller, {
    double horizontalPadding = 0,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 15),
      child: Column(
        children: [
          _buildTimeDisplay(controller, fontSize: 32),
          const SizedBox(height: 15),
          _buildProgressSlider(controller, trackHeight: 5),
        ],
      ),
    );
  }

  // Süre gösterimi
  Widget _buildTimeDisplay(
    AudioPlayerController controller, {
    required double fontSize,
  }) {
    return Obx(() {
      return Text(
        controller.formatDuration(controller.position.value),
        style: TextStyle(
          color: Colors.white,
          fontSize: fontSize,
          fontFamily: StringConstants.SFPro,
          fontWeight: FontWeight.bold,
        ),
      );
    });
  }

  // Progress slider
  Widget _buildProgressSlider(
    AudioPlayerController controller, {
    required double trackHeight,
  }) {
    return Obx(() {
      final duration = controller.duration.value;
      final position = controller.position.value;
      final durationSeconds = duration.inSeconds.toDouble();
      final positionSeconds = position.inSeconds.toDouble().clamp(
            0.0,
            durationSeconds > 0 ? durationSeconds : 1.0,
          );

      return SliderTheme(
        data: SliderThemeData(
          trackHeight: trackHeight,
          trackShape: FullWidthSliderTrackShape(),
          thumbShape: SliderComponentShape.noThumb,
          overlayShape: SliderComponentShape.noOverlay,
        ),
        child: Slider(
          value: positionSeconds,
          min: 0.0,
          max: durationSeconds > 0 ? durationSeconds : 1.0,
          activeColor: Colors.white,
          inactiveColor: Colors.white30,
          onChanged: (value) {
            controller.seek(Duration(seconds: value.toInt()));
          },
        ),
      );
    });
  }

  // Dikey mod kontrolleri
  Widget _buildPortraitControls(AudioPlayerController controller) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildSeekButton(
          onTap: controller.seekBackward,
          icon: IconConstants.a1,
          size: 96,
        ),
        const SizedBox(width: 40),
        Container(
          height: 150,
          width: 1,
          color: Colors.grey[200],
        ),
        const SizedBox(width: 40),
        _buildSeekButton(
          onTap: controller.seekForward,
          icon: IconConstants.a2,
          size: 96,
        ),
      ],
    );
  }
}
