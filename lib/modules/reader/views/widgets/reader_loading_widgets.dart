import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:elkitap/core/constants/string_constants.dart';
import 'package:elkitap/core/theme/app_colors.dart';

class ReaderLoadingBody extends StatelessWidget {
  const ReaderLoadingBody({
    required this.imageUrl,
    required this.downloadProgress,
    required this.isReaderReady,
    required this.hasError,
    required this.onRetry,
    this.errorMessage,
    super.key,
  });

  final String imageUrl;
  final double downloadProgress;
  final bool isReaderReady;
  final bool hasError;
  final String? errorMessage;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
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
                      Image.network(imageUrl, width: 220, height: 330, fit: BoxFit.cover),
                      const SizedBox(height: 80),
                      Image.asset('assets/images/l1.png', width: 60, height: 30, fit: BoxFit.cover),
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
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: LinearProgressIndicator(
                        value: (downloadProgress >= 0.90 && !isReaderReady) ? null : downloadProgress,
                        backgroundColor: Colors.grey[800],
                        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.mainColor),
                        minHeight: 6,
                      ),
                    ),
                    Container(
                      width: 60,
                      alignment: Alignment.centerRight,
                      child: Text(
                        (downloadProgress >= 0.90 && !isReaderReady) ? '...' : '${(downloadProgress * 100).toStringAsFixed(0)}%',
                        textAlign: TextAlign.end,
                        style: const TextStyle(
                          color: AppColors.mainColor,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (downloadProgress >= 0.90 && !isReaderReady)
                const Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Text(
                    'Preparing...',
                    style: TextStyle(
                      color: AppColors.mainColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              if (hasError)
                Padding(
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
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class ReaderLoadingOverlay extends StatelessWidget {
  const ReaderLoadingOverlay({
    required this.backgroundColor,
    required this.child,
    super.key,
  });

  final Color backgroundColor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Material(
        color: backgroundColor,
        child: child,
      ),
    );
  }
}

class ReaderLoadingView extends StatelessWidget {
  const ReaderLoadingView({
    required this.backgroundColor,
    required this.body,
    required this.onClose,
    super.key,
  });

  final Color backgroundColor;
  final Widget body;
  final Future<void> Function() onClose;

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        await onClose();
        return false;
      },
      child: Scaffold(
        backgroundColor: backgroundColor,
        body: body,
      ),
    );
  }
}
