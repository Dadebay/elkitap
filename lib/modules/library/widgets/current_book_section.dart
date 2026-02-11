import 'package:elkitap/core/constants/icon_constants.dart';
import 'package:elkitap/data/network/api_edpoints.dart';
import 'package:elkitap/core/widgets/common/custom_icon.dart';
import 'package:elkitap/modules/store/model/book_item_model.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:get_storage/get_storage.dart';

class CurrentBookSection extends StatelessWidget {
  final Book book;

  const CurrentBookSection({
    super.key,
    required this.book,
  });

  @override
  Widget build(BuildContext context) {
    // Read progress from GetStorage (stored per book ID)
    final storage = GetStorage();
    storage.read('book_${book.id}_progress');

    // Parse progress string - already in percentage format (e.g., "45.5" means 45.5%)
    // Try stored progress first, then fall back to book.progress

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0).copyWith(bottom: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 210,
            width: 143,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 12,
                  spreadRadius: 0,
                  offset: const Offset(0, 3),
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  spreadRadius: 0,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: book.getFullImageUrl(ApiEndpoints.imageBaseUrl) ?? '',
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: Colors.grey[50],
                  child: Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.grey[400]!,
                      ),
                    ),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.grey[100]!,
                        Colors.grey[200]!,
                      ],
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CustomIcon(
                        title: IconConstants.libraryFilled,
                        height: 32,
                        width: 32,
                        color: Colors.grey[400],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // const SizedBox(height: 16),
          // _buildProgressBar(context, progressValue),
        ],
      ),
    );
  }

  // Widget _buildProgressBar(BuildContext context, double progressPercentage) {
  //   // Convert percentage to 0-1 range (e.g., 45.5 -> 0.455)
  //   final progress = progressPercentage / 100;

  //   return Center(
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.center,
  //       children: [
  //         const SizedBox(height: 10),
  //         Row(
  //           mainAxisSize: MainAxisSize.min,
  //           children: [
  //             SizedBox(
  //               width: 143,
  //               child: ClipRRect(
  //                 borderRadius: BorderRadius.circular(12),
  //                 child: LinearProgressIndicator(
  //                   value: progress.clamp(0.0, 1.0),
  //                   minHeight: 6,
  //                   backgroundColor: Colors.grey.withOpacity(0.3),
  //                   valueColor: AlwaysStoppedAnimation<Color>(
  //                     Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
  //                   ),
  //                 ),
  //               ),
  //             ),
  //             const SizedBox(width: 8),
  //             Text(
  //               '${(progress * 100).toInt()}%',
  //               style: TextStyle(
  //                 fontSize: 13,
  //                 fontWeight: FontWeight.w500,
  //                 color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.black87,
  //               ),
  //             ),
  //           ],
  //         ),
  //         const SizedBox(height: 4),
  //       ],
  //     ),
  //   );
  // }
}
