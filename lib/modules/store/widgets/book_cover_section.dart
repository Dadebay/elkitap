import 'package:cached_network_image/cached_network_image.dart';
import 'package:elkitap/core/constants/icon_constants.dart';
import 'package:elkitap/core/widgets/common/custom_icon.dart';
import 'package:elkitap/core/widgets/states/loading_widget.dart';
import 'package:elkitap/modules/store/controllers/book_detail_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class BookCoverSection extends StatelessWidget {
  final BooksDetailController controller;
  final int bookId;

  const BookCoverSection({
    required this.controller,
    required this.bookId,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildCoverImage(),
        const SizedBox(height: 16),
        _buildProgressBar(context),
      ],
    );
  }

  Widget _buildCoverImage() {
    return Obx(() {
      final imageUrl = controller.getBookCoverImage();
      final coverHeight = controller.isAudio.value ? 200.0 : 280.0;

      return Container(
        width: 200,
        height: coverHeight,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 12,
              spreadRadius: 1,
              offset: const Offset(0, 3),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              spreadRadius: 3,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: imageUrl.isNotEmpty
              ? CachedNetworkImage(
                  imageUrl: imageUrl,
                  width: 200,
                  height: coverHeight,
                  fit: BoxFit.fill,
                  placeholder: (context, url) => LoadingWidget(removeBackWhite: true),
                  errorWidget: (context, url, error) => _buildErrorPlaceholder(),
                )
              : _buildErrorPlaceholder(),
        ),
      );
    });
  }

  Widget _buildErrorPlaceholder() {
    return Container(
      color: Colors.grey[300],
      child: Center(
        child: CustomIcon(
          title: IconConstants.libraryFilled,
          height: 24,
          width: 24,
          color: Colors.black,
        ),
      ),
    );
  }

  Widget _buildProgressBar(BuildContext context) {
    return Obx(() {
      double progress = 0.0;
      if (controller.progress.value != null) {
        progress = (double.tryParse(controller.progress.value!) ?? 0.0) / 100;
      }

      return Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 10),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 170,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: LinearProgressIndicator(
                      value: progress.clamp(0.0, 1.0),
                      minHeight: 6,
                      backgroundColor: Colors.grey.withOpacity(0.3),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${(progress * 100).toInt()}%',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
          ],
        ),
      );
    });
  }
}
