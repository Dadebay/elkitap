import 'package:elkitap/core/constants/icon_constants.dart';
import 'package:elkitap/core/widgets/common/custom_icon.dart';
import 'package:elkitap/modules/audio_player/model/chapter.dart';
import 'package:flutter/material.dart';

class ChapterTile extends StatelessWidget {
  final Chapter chapter;

  const ChapterTile({super.key, required this.chapter});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 10,
        ),
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.only(left: 30, right: 16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      chapter.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${chapter.duration} • ${chapter.size}',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              CustomIcon(title: IconConstants.a9, height: 24, width: 24, color: chapter.isDownloaded ? Colors.white : const Color(0xFFFF5722))
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 30),
          child: Divider(
            height: 0.5,
            color: Colors.grey,
          ),
        )
      ],
    );
  }
}
