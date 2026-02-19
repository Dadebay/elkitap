import 'package:cached_network_image/cached_network_image.dart';
import 'package:elkitap/core/constants/icon_constants.dart';
import 'package:elkitap/core/constants/string_constants.dart';
import 'package:elkitap/data/network/api_edpoints.dart';
import 'package:elkitap/core/widgets/common/custom_icon.dart';
import 'package:elkitap/modules/store/model/book_item_model.dart';
import 'package:flutter/material.dart';

class BookCardGridView extends StatelessWidget {
  final Book book;
  final VoidCallback? onTap;
  final int? discountPercentage;
  final int tabIndex;

  const BookCardGridView({
    super.key,
    required this.book,
    this.onTap,
    this.discountPercentage,
    this.tabIndex = 0,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          book.withAudio
              ? SizedBox(
                  width: 148,
                  height: 148,
                  child: _buildBookCoverContent(),
                )
              : Expanded(
                  child: _buildBookCoverContent(),
                ),
          const SizedBox(height: 8),
          SizedBox(
            width: 148,
            child: Text(
              book.name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontFamily: StringConstants.SFPro,
                fontSize: 17,
              ),
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: 148,
            child: Text(
              book.authors.isNotEmpty ? book.authors.first.name : 'Unknown',
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.grey[600],
                fontFamily: StringConstants.SFPro,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookCoverContent() {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 300),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.scale(
            scale: 0.9 + (0.1 * value),
            child: child,
          ),
        );
      },
      child: Container(
        width: 150,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: () {
            // Determine which image to use
            String? imageToUse;
            if (book.withAudio) {
              imageToUse = book.audioImage;
            } else {
              imageToUse = book.image;
            }

            // If no image available, show placeholder
            if (imageToUse == null || imageToUse.isEmpty) {
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
                child: Center(
                  child: CustomIcon(
                    title: IconConstants.libraryFilled,
                    height: 32,
                    width: 32,
                    color: Colors.grey[400],
                  ),
                ),
              );
            }

            return CachedNetworkImage(
              imageUrl: ApiEndpoints.imageBaseUrl + imageToUse,
              fit: BoxFit.fill,
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
                    height: 32,
                    width: 32,
                    color: Colors.grey[400],
                  ),
                ),
              ),
            );
          }(),
        ),
      ),
    );
  }
}
