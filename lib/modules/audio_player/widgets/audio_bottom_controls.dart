// ignore_for_file: use_super_parameters

import 'package:elkitap/core/constants/icon_constants.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:elkitap/core/widgets/common/custom_icon.dart';
import 'package:elkitap/modules/audio_player/controllers/audio_player_controller.dart';

class AudioBottomControls extends StatelessWidget {
  final VoidCallback onSpeedTap;
  final VoidCallback onSleepTimerTap;
  final VoidCallback onBluetoothTap;
  final VoidCallback onDriverModeTap;

  const AudioBottomControls({
    Key? key,
    required this.onSpeedTap,
    required this.onSleepTimerTap,
    required this.onBluetoothTap,
    required this.onDriverModeTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AudioPlayerController>();

    return Obx(() {
      return Padding(
        padding: const EdgeInsets.only(left: 10, right: 10, top: 40),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            GestureDetector(
              onTap: onSpeedTap,
              child: Text(
                '${controller.playbackSpeed.value}x',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            GestureDetector(
              onTap: onSleepTimerTap,
              child: Obx(() {
                final hasTimer = controller.sleepTimerEndTime.value != null;
                final remainingTime = controller.sleepTimerRemaining.value;
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.bedtime_outlined,
                      size: 32,
                      color: hasTimer ? Colors.orange : Colors.white,
                    ),
                    if (hasTimer && remainingTime.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Text(
                        remainingTime,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                );
              }),
            ),
            GestureDetector(
              onTap: onBluetoothTap,
              child: CustomIcon(
                title: IconConstants.a6,
                height: 32,
                width: 32,
                color: Colors.white,
              ),
            ),
            GestureDetector(
              onTap: onDriverModeTap,
              child: CustomIcon(
                title: IconConstants.a7,
                height: 32,
                width: 32,
                color: Colors.white,
              ),
            ),
          ],
        ),
      );
    });
  }
}
