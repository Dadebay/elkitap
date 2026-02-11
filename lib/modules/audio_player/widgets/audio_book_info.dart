import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:elkitap/core/constants/string_constants.dart';
import 'package:elkitap/modules/audio_player/controllers/audio_player_controller.dart';

class AudioBookInfo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AudioPlayerController>();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Obx(() => Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      controller.currentBookTitle.value.isNotEmpty
                          ? controller.currentBookTitle.value
                          : ' ',
                      style: const TextStyle(
                        color: Colors.white,
                        fontFamily: StringConstants.GilroyRegular,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      controller.currentBookAuthor.value.isNotEmpty
                          ? controller.currentBookAuthor.value
                          : 'unknown_author'.tr,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontFamily: StringConstants.SFPro,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
