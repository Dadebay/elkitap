import 'package:cached_network_image/cached_network_image.dart';
import 'package:elkitap/core/constants/icon_constants.dart';
import 'package:elkitap/data/network/api_edpoints.dart';
import 'package:elkitap/core/widgets/common/custom_icon.dart';
import 'package:elkitap/modules/store/model/book_item_model.dart';
import 'package:flutter/material.dart';

class BookCardAudio extends StatelessWidget {
  static const double defaultWidth = 90;
  static const double defaultHeight = 165;
  static const double defaultBorderRadius = 4;
  static const double iconSize = 28;
  static const double placeholderStrokeWidth = 2.0;

  final Book book;
  final int index;
  final int tabIndex;
  final double width;
  final double height;
  final double borderRadius;
  final VoidCallback? onTap;
  final int? discountPercentage;

  const BookCardAudio({
    super.key,
    required this.book,
    required this.index,
    required this.tabIndex,
    this.width = defaultWidth,
    this.height = defaultHeight,
    this.borderRadius = defaultBorderRadius,
    this.onTap,
    this.discountPercentage,
  });

  @override
  Widget build(BuildContext context) {
    // Use square dimensions for audio books (when withAudio is true)
    final effectiveHeight = book.withAudio ? width : height;

    return GestureDetector(
      onTap: () {
        onTap?.call();
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: width,
        height: effectiveHeight,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 15,
              spreadRadius: 0,
              offset: const Offset(0, 4),
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
          borderRadius: BorderRadius.circular(borderRadius),
          child: () {
            // Determine which image to use
            String? imageToUse;
            if (book.withAudio) {
              imageToUse = book.audioImage;
            } else {
              imageToUse = book.image;
            }

            // If no image available, show error widget
            if (imageToUse == null || imageToUse.isEmpty) {
              return _buildErrorWidget();
            }

            return CachedNetworkImage(
              imageUrl: ApiEndpoints.imageBaseUrl + imageToUse,
              fit: BoxFit.fill,
              placeholder: (context, url) => _buildPlaceholder(),
              errorWidget: (context, url, error) => _buildErrorWidget(),
            );
          }(),
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: Colors.grey[50],
      child: Center(
        child: CircularProgressIndicator(
          strokeWidth: placeholderStrokeWidth,
          valueColor: AlwaysStoppedAnimation<Color>(
            Colors.grey[400]!,
          ),
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
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
            height: iconSize,
            width: iconSize,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 6),
          Text(
            'No Image',
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[500],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
