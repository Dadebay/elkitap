// ignore_for_file: use_key_in_widget_constructors

import 'package:elkitap/core/constants/icon_constants.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:elkitap/core/widgets/common/custom_icon.dart';
import 'package:elkitap/modules/audio_player/controllers/audio_player_controller.dart';

class AudioPlaybackControls extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AudioPlayerController>();

    return Obx(() {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: () => controller.seekBackward(),
            child: CustomIcon(
              title: 'assets/icons/a1.svg',
              height: 40,
              width: 40,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 40),
          CircleAvatar(
            radius: 40,
            backgroundColor: Colors.grey.shade900,
            child: GestureDetector(
              onTap: () => controller.playPause(),
              child: CustomIcon(
                title: controller.isPlaying.value ? 'assets/icons/a4.svg' : 'assets/icons/a3.svg',
                height: 40,
                width: 40,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 40),
          GestureDetector(
            onTap: () => controller.seekForward(),
            child: CustomIcon(
              title: IconConstants.a2,
              height: 40,
              width: 40,
              color: Colors.white,
            ),
          ),
        ],
      );
    });
  }
}
