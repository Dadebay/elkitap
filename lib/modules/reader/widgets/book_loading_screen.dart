import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:elkitap/core/constants/string_constants.dart';
import 'package:elkitap/core/theme/app_colors.dart';

/// Loading screen widget for book reader
/// Displays book cover, loading animation, progress message and percentage
class BookLoadingScreen extends StatelessWidget {
  final String imageUrl;
  final String loadingMessage;
  final double downloadProgress;
  final bool hasError;
  final String? errorMessage;
  final VoidCallback onRetry;
  final VoidCallback onClose;

  const BookLoadingScreen({
    required this.imageUrl,
    required this.loadingMessage,
    required this.downloadProgress,
    required this.hasError,
    required this.onRetry,
    required this.onClose,
    this.errorMessage,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        onClose();
        return false;
      },
      child: Scaffold(
        body: SafeArea(
          child: SizedBox.expand(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildBookCover(),
                          const SizedBox(height: 80),
                          _buildLoadingAnimation(),
                          const SizedBox(height: 20),
                          _buildLoadingTitle(),
                        ],
                      ),
                    ),
                  ),
                  _buildProgressSection(),
                  if (hasError) _buildErrorSection(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBookCover() {
    return Image.network(
      imageUrl,
      width: 220,
      height: 330,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          width: 220,
          height: 330,
          color: Colors.grey[800],
          child: const Icon(Icons.book, size: 80, color: Colors.white54),
        );
      },
    );
  }

  Widget _buildLoadingAnimation() {
    return Image.asset(
      'assets/images/l1.png',
      width: 60,
      height: 30,
      fit: BoxFit.cover,
    );
  }

  Widget _buildLoadingTitle() {
    return Text(
      'loading_t'.tr,
      style: const TextStyle(
        fontSize: 15,
        fontFamily: StringConstants.SFPro,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildProgressSection() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  loadingMessage,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: downloadProgress,
                  backgroundColor: Colors.grey[800],
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppColors.mainColor,
                  ),
                  minHeight: 6,
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Text(
            '${(downloadProgress * 100).toStringAsFixed(0)}%',
            style: const TextStyle(
              color: AppColors.mainColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorSection() {
    return Padding(
      padding: const EdgeInsets.only(top: 24.0),
      child: Column(
        children: [
          Text(
            errorMessage ?? 'Unknown error',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: onRetry,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
