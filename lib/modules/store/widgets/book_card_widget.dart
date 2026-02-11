import 'package:cached_network_image/cached_network_image.dart';
import 'package:elkitap/core/constants/icon_constants.dart';
import 'package:elkitap/data/network/api_edpoints.dart';
import 'package:elkitap/core/widgets/common/custom_icon.dart';
import 'package:elkitap/modules/store/model/book_item_model.dart';
import 'package:flutter/material.dart';

class BookCard extends StatelessWidget {
  final Book book;
  final int index;
  final int tabIndex;
  final double width;
  final double? height;
  final double borderRadius;
  final VoidCallback? onTap;
  final int? discountPercentage;

  const BookCard({
    super.key,
    required this.book,
    required this.index,
    required this.tabIndex,
    this.width = 110,
    this.height,
    this.borderRadius = 8,
    this.onTap,
    this.discountPercentage,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate height based on tabIndex if not explicitly provided
    double baseHeight = height ?? (tabIndex == 1 ? 124.0 : 164.0);

    // If withAudio is true, make it square (height = width)
    final cardHeight = book.withAudio ? width : baseHeight;

    return GestureDetector(
        onTap: onTap,
        child: Container(
          width: 144,
          height: cardHeight,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(6),
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
            borderRadius: BorderRadius.circular(6),
            child: Stack(
              children: [
                // Book cover image
                CachedNetworkImage(
                  imageUrl: '${ApiEndpoints.imageBaseUrl}${_getImageUrl()}',
                  fit: BoxFit.fill,
                  width: double.infinity,
                  height: double.infinity,
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
                        const SizedBox(height: 8),
                        Text(
                          'No Image',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[500],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Audiobook badge (only show when tabIndex == 1)
              ],
            ),
          ),
        ));
  }

  // Helper method to get the correct image URL
  String _getImageUrl() {
    // If this is audiobook tab (tabIndex == 1) and audio_image is available, use it
    if (tabIndex == 1 && book.audioImage != null && book.audioImage!.isNotEmpty) {
      return book.audioImage!;
    }
    // Otherwise, use regular image
    return book.image ?? '';
  }
}

// Custom painter for the yellow triangle badge
class TrianglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFFC107) // Yellow color similar to Audible
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(size.width, 0) // Top right
      ..lineTo(size.width, size.height) // Bottom right
      ..lineTo(0, size.height) // Bottom left
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class BookCardReOpen extends StatelessWidget {
  static const double defaultWidth = 90;
  static const double defaultHeight = 135;
  static const double defaultBorderRadius = 6;

  final Book book;
  final int index;
  final int tabIndex;
  final double width;
  final double height;
  final double borderRadius;
  final VoidCallback? onTap;
  final double? progress;

  const BookCardReOpen({
    super.key,
    required this.book,
    required this.index,
    required this.tabIndex,
    this.width = defaultWidth,
    this.height = defaultHeight,
    this.borderRadius = defaultBorderRadius,
    this.onTap,
    this.progress,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate dimensions based on withAudio property
    final cardWidth = width;
    final cardHeight = book.withAudio ? width : height;

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: cardWidth,
        height: cardHeight,
        child: Stack(
          children: [
            // Book cover
            Container(
              width: cardWidth,
              height: cardHeight,
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(borderRadius),
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
                borderRadius: BorderRadius.circular(borderRadius),
                child: CachedNetworkImage(
                  imageUrl: '${ApiEndpoints.imageBaseUrl}${book.withAudio ? book.audioImage : book.image ?? ''}',
                  fit: BoxFit.cover,
                  alignment: Alignment.bottomCenter,
                  placeholder: (context, url) => Container(
                    color: Colors.grey[50],
                    child: Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2.0,
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
                    child: Center(
                      child: CustomIcon(
                        title: IconConstants.libraryFilled,
                        height: 24,
                        width: 24,
                        color: Colors.grey[400],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Discount badge at bottom left
            if (progress != null && progress! * 100 > 3)
              Positioned(
                left: -3,
                bottom: 0,
                child: DiscountBadgeMini(
                  percentage: (progress! * 100).toInt(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class DiscountBadge extends StatelessWidget {
  final int percentage;

  const DiscountBadge({
    super.key,
    required this.percentage,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 37,
      decoration: const BoxDecoration(
        image: DecorationImage(
            image: AssetImage(
              'assets/images/bg2.png',
            ),
            fit: BoxFit.cover),
      ),
      child: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Text(
          '$percentage%',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

class DiscountBadgeMini extends StatelessWidget {
  final int percentage;

  const DiscountBadgeMini({
    super.key,
    required this.percentage,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      child: Text(
        '$percentage%',
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 12,
          color: Colors.grey[700],
          height: 1,
        ),
      ),
    );
  }
}
