// ignore_for_file: deprecated_member_use

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:elkitap/modules/audio_player/controllers/audio_player_controller.dart';

class SleepTimerPopup {
  static void show(BuildContext context, AudioPlayerController controller) {
    final timers = [
      {'duration': const Duration(hours: 1), 'label': '1 ${'hour_t'.tr}'},
      {'duration': const Duration(minutes: 45), 'label': '45 ${'minute_t'.tr}'},
      {'duration': const Duration(minutes: 15), 'label': '15 ${'minute_t'.tr}'},
      {'duration': const Duration(minutes: 10), 'label': '10 ${'minute_t'.tr}'},
      {'duration': const Duration(minutes: 5), 'label': '5 ${'minute_t'.tr}'},
      {'duration': null, 'label': 'Off'},
    ];

    showDialog(
      context: context,
      barrierColor: Colors.black26,
      builder: (context) => Stack(
        children: [
          Positioned(
            bottom: 80,
            left: 20,
            child: Material(
              color: Colors.transparent,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    width: 240,
                    decoration: BoxDecoration(
                      color: const Color(0xFF3D3633).withOpacity(0.95),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            'chapter_end_t'.tr,
                            style: const TextStyle(
                              fontSize: 17,
                              fontFamily: 'SF Pro',
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Divider(
                          height: 1,
                          thickness: 0.5,
                          color: Colors.white.withOpacity(0.15),
                        ),
                        ...timers.map((timer) {
                          final isLast = timer == timers.last;
                          final timerDuration = timer['duration'] as Duration?;
                          final timerLabel = timer['label'] as String;

                          return Column(
                            children: [
                              Obx(() {
                                final isActive = controller.sleepTimerDuration.value == timerDuration;
                                final showCountdown = isActive && timerDuration != null && controller.sleepTimerRemaining.value.isNotEmpty;

                                return InkWell(
                                  onTap: () {
                                    controller.setSleepTimer(timerDuration);
                                    Navigator.pop(context);
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 16,
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Row(
                                            children: [
                                              Text(
                                                timerLabel,
                                                style: const TextStyle(
                                                  fontSize: 17,
                                                  fontWeight: FontWeight.w400,
                                                  color: Colors.white,
                                                ),
                                              ),
                                              if (showCountdown) ...[
                                                const SizedBox(width: 8),
                                                Text(
                                                  '(${controller.sleepTimerRemaining.value})',
                                                  style: TextStyle(
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.w400,
                                                    color: Colors.white.withOpacity(0.6),
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                        if (isActive)
                                          const Icon(
                                            Icons.check,
                                            size: 24,
                                            color: Colors.white,
                                          ),
                                      ],
                                    ),
                                  ),
                                );
                              }),
                              if (!isLast)
                                Divider(
                                  height: 1,
                                  thickness: 0.5,
                                  color: Colors.white.withOpacity(0.15),
                                ),
                            ],
                          );
                        }),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
