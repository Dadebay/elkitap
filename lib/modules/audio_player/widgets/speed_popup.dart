// ignore_for_file: deprecated_member_use

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:elkitap/modules/audio_player/controllers/audio_player_controller.dart';

class SpeedPopup {
  static void show(BuildContext context, AudioPlayerController controller) {
    final speeds = [
      {'value': 0.5, 'label': '0.5x'},
      {'value': 0.75, 'label': '0.75x'},
      {'value': 1.0, 'label': '1x'},
      {'value': 1.5, 'label': '1.5x'},
      {'value': 2.0, 'label': '2x'},
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
                    width: 200,
                    decoration: BoxDecoration(
                      color: const Color(0xFF3D3633).withOpacity(0.95),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.4),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Sleep timer display at the top
                        Obx(() {
                          final hasTimer = controller.sleepTimerEndTime.value != null;
                          final remainingTime = controller.sleepTimerRemaining.value;

                          if (!hasTimer || remainingTime.isEmpty) {
                            return const SizedBox.shrink();
                          }

                          return Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 16,
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.bedtime_outlined,
                                      size: 20,
                                      color: Colors.orange,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        'sleep_timer_t'.tr,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w400,
                                          color: Colors.white70,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      remainingTime,
                                      style: const TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.orange,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Divider(
                                height: 1,
                                color: Colors.grey.withOpacity(0.2),
                              ),
                            ],
                          );
                        }),

                        // Speed options
                        ...speeds.map((speed) {
                          final isLast = speed == speeds.last;
                          final speedValue = speed['value'] as double;
                          final speedLabel = speed['label'] as String;

                          return Column(
                            children: [
                              Obx(() => InkWell(
                                    onTap: () {
                                      controller.setSpeed(speedValue);
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
                                            child: Text(
                                              speedLabel,
                                              style: const TextStyle(
                                                fontSize: 17,
                                                fontWeight: FontWeight.w400,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                          if (controller.playbackSpeed.value == speedValue)
                                            const Icon(
                                              Icons.check,
                                              size: 24,
                                              color: Colors.white,
                                            ),
                                        ],
                                      ),
                                    ),
                                  )),
                              if (!isLast)
                                Divider(
                                  height: 1,
                                  color: Colors.grey.withOpacity(0.2),
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
