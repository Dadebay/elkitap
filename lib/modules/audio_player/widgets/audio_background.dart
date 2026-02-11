import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:get/get.dart';
import 'package:elkitap/modules/audio_player/controllers/audio_player_controller.dart';

class AudioBackground extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AudioPlayerController>();

    return Stack(
      children: [
        Positioned.fill(
          child: Obx(() {
            final cover = controller.currentBookCover.value;
            if (cover.isNotEmpty) {
              return CachedNetworkImage(
                imageUrl: cover,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: const Color(0xFF8B5A3C),
                ),
                errorWidget: (context, url, error) {
                  return Container(
                    color: const Color(0xFF8B5A3C),
                  );
                },
              );
            }
            return Image.asset(
              'assets/images/b6.png',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: const Color(0xFF8B5A3C),
                );
              },
            );
          }),
        ),
        Positioned.fill(
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
        ),
      ],
    );
  }
}
