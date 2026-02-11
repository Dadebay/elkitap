import 'package:cached_network_image/cached_network_image.dart';
import 'package:elkitap/core/constants/icon_constants.dart';
import 'package:elkitap/core/widgets/common/custom_icon.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:elkitap/modules/audio_player/controllers/audio_player_controller.dart';
import 'package:elkitap/modules/audio_player/views/audio_player_view.dart';

class GlobalMiniPlayer extends StatefulWidget {
  const GlobalMiniPlayer({Key? key}) : super(key: key);

  @override
  State<GlobalMiniPlayer> createState() => _GlobalMiniPlayerState();
}

class _GlobalMiniPlayerState extends State<GlobalMiniPlayer> {
  late GlobalMiniPlayerController globalMiniCtrl;
  late AudioPlayerController audioCtrl;
  double _dragOffsetX = 0.0; // for swipe detection
  double _opacity = 1.0;

  @override
  void initState() {
    super.initState();
    globalMiniCtrl = Get.find<GlobalMiniPlayerController>();
    audioCtrl = Get.find<AudioPlayerController>();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final size = MediaQuery.of(context).size;
      final playerWidth = size.width - 30;
      const playerHeight = 70.0;

      final initialTop = size.height - playerHeight - 100;
      final initialLeft = (size.width / 2) - (playerWidth / 2);
      globalMiniCtrl.setPosition(initialTop, initialLeft);
    });
  }

  bool _shouldShowPlayer() {
    final currentRoute = Get.currentRoute;
    final excludedRoutes = [
      '/audiobook-player',
      '/AudiobookPlayerScreen',
      '/driver-mode',
      '/DriverModeScreen',
    ];
    return !excludedRoutes.any((r) => currentRoute.contains(r));
  }

  @override
  Widget build(BuildContext context) {
    if (!_shouldShowPlayer()) return const SizedBox.shrink();

    late AudioPlayerController controller;
    try {
      controller = Get.find<AudioPlayerController>();
    } catch (_) {
      return const SizedBox.shrink();
    }

    return Obx(() {
      if (!globalMiniCtrl.isVisible.value || controller.duration.value == Duration.zero) {
        return const SizedBox.shrink();
      }

      final screenSize = MediaQuery.of(context).size;
      final playerWidth = screenSize.width - 30;
      const playerHeight = 70.0;

      return GestureDetector(
        onPanUpdate: (details) {
          // Horizontal swipe detection
          _dragOffsetX += details.delta.dx;

          // If horizontal drag is strong enough → hide
          if (_dragOffsetX.abs() > 100) {
            setState(() => _opacity = 0.0);
            Future.delayed(const Duration(milliseconds: 150), () {
              globalMiniCtrl.hide();
              audioCtrl.stopAudio();
              _dragOffsetX = 0.0;
              _opacity = 1.0;
            });
            return;
          }

          // Normal dragging
          final newTop = (globalMiniCtrl.top.value + details.delta.dy).clamp(0.0, screenSize.height - playerHeight - 20);
          final newLeft = (globalMiniCtrl.left.value + details.delta.dx).clamp(0.0, screenSize.width - playerWidth - 10);
          globalMiniCtrl.setPosition(newTop, newLeft);
        },
        onPanEnd: (_) {
          _dragOffsetX = 0.0;
          double snapLeft = globalMiniCtrl.left.value;
          double snapTop = globalMiniCtrl.top.value;
          const snapDistance = 40.0;

          if (snapLeft < snapDistance) snapLeft = 10;
          if (snapLeft > screenSize.width - playerWidth - snapDistance) {
            snapLeft = screenSize.width - playerWidth - 10;
          }
          if (snapTop < snapDistance) snapTop = 20;
          if (snapTop > screenSize.height - playerHeight - snapDistance) {
            snapTop = screenSize.height - playerHeight - 20;
          }

          globalMiniCtrl.setPosition(snapTop, snapLeft);
        },
        onTap: () {
          Get.to(() => const AudiobookPlayerScreen());
          globalMiniCtrl.hide();
        },
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: _opacity,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: playerHeight,
            width: playerWidth,
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Obx(() {
                      final coverUrl = controller.currentBookCover.value;
                      return coverUrl.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: coverUrl,
                              width: 45,
                              height: 45,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                width: 45,
                                height: 45,
                                color: Colors.grey.shade300,
                                child: const Center(
                                  child: SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                ),
                              ),
                              errorWidget: (context, url, error) => Image.asset(
                                'assets/images/b6.png',
                                width: 45,
                                height: 45,
                                fit: BoxFit.cover,
                              ),
                            )
                          : Image.asset(
                              'assets/images/b6.png',
                              width: 45,
                              height: 45,
                              fit: BoxFit.cover,
                            );
                    }),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Obx(() => DefaultTextStyle(
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                            ),
                            child: Text(
                              controller.currentBookTitle.value.isNotEmpty ? controller.currentBookTitle.value : '...',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          )),
                      const SizedBox(height: 4),
                      Obx(() => DefaultTextStyle(
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                            child: Text(
                              '${controller.formatDuration(controller.position.value)}',
                            ),
                          )),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: controller.seekBackward,
                  child: CustomIcon(
                    title: IconConstants.a1,
                    height: 28,
                    width: 28,
                    color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: controller.playPause,
                  child: Obx(() => CustomIcon(
                        title: controller.isPlaying.value ? IconConstants.a4 : IconConstants.a3,
                        height: 28,
                        width: 28,
                        color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                      )),
                ),
                const SizedBox(width: 12),
              ],
            ),
          ),
        ),
      );
    });
  }
}
