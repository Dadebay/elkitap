import 'package:elkitap/core/constants/string_constants.dart';
import 'package:elkitap/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class EpubLoadingWidget extends StatelessWidget {
  final String imageUrl;
  final String loadingMessage;
  final double downloadProgress;
  final bool hasError;
  final String? errorMessage;
  final VoidCallback onRetry;

  const EpubLoadingWidget({
    required this.imageUrl,
    required this.loadingMessage,
    required this.downloadProgress,
    required this.hasError,
    this.errorMessage,
    required this.onRetry,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
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
                    Image.network(
                      imageUrl,
                      width: 220,
                      height: 330,
                      fit: BoxFit.cover,
                    ),
                    const SizedBox(height: 80),
                    Image.asset(
                      'assets/images/l1.png',
                      width: 60,
                      height: 30,
                      fit: BoxFit.cover,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'loading_t'.tr,
                      style: const TextStyle(
                        fontSize: 15,
                        fontFamily: StringConstants.SFPro,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Text(
              loadingMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (downloadProgress > 0 && downloadProgress < 1)
              _buildProgressIndicator(),
            if (hasError) _buildErrorSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Padding(
      padding: const EdgeInsets.only(top: 20.0),
      child: Column(
        children: [
          LinearProgressIndicator(
            value: downloadProgress,
            backgroundColor: Colors.grey[800],
            valueColor: const AlwaysStoppedAnimation<Color>(
              AppColors.mainColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${(downloadProgress * 100).toStringAsFixed(0)}%',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
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
