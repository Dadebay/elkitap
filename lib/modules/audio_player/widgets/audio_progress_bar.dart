// ignore_for_file: use_key_in_widget_constructors

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:elkitap/core/constants/string_constants.dart';
import 'package:elkitap/modules/audio_player/controllers/audio_player_controller.dart';

class AudioProgressBar extends StatefulWidget {
  @override
  State<AudioProgressBar> createState() => _AudioProgressBarState();
}

class _AudioProgressBarState extends State<AudioProgressBar> {
  double? _draggingValue;

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AudioPlayerController>();

    return Obx(() {
      final duration = controller.duration.value;
      final position = controller.position.value;
      final durationSeconds = duration.inSeconds.toDouble();
      final positionSeconds = position.inSeconds.toDouble().clamp(0.0, durationSeconds > 0 ? durationSeconds : 1.0);

      final displayValue = _draggingValue ?? positionSeconds;

      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          children: [
            SliderTheme(
              data: SliderThemeData(
                trackHeight: 4,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
              ),
              child: Slider(
                value: displayValue,
                min: 0.0,
                max: durationSeconds > 0 ? durationSeconds : 1.0,
                activeColor: Colors.white,
                inactiveColor: Colors.white30,
                onChanged: (value) {
                  setState(() {
                    _draggingValue = value;
                  });
                },
                onChangeEnd: (value) {
                  controller.seek(Duration(seconds: value.toInt()));
                  setState(() {
                    _draggingValue = null;
                  });
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Text(
                    controller.formatDuration(Duration(seconds: displayValue.toInt())),
                    textAlign: TextAlign.left,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontFamily: StringConstants.SFPro,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      controller.formatFullDuration(duration),
                      maxLines: 1,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontFamily: StringConstants.SFPro,
                      ),
                    ),
                  ),
                  Text(
                    controller.formatRemainingTime(duration - Duration(seconds: displayValue.toInt())),
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontFamily: StringConstants.SFPro,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }
}
