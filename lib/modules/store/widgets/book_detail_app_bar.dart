import 'dart:ui';
import 'package:elkitap/core/constants/string_constants.dart';
import 'package:elkitap/core/widgets/common/app_snackbar.dart';
import 'package:elkitap/core/widgets/states/loading_widget.dart';
import 'package:elkitap/modules/library/controllers/downloaded_controller.dart';
import 'package:elkitap/modules/library/views/downloaded_book_view.dart';
import 'package:elkitap/modules/paymant/controller/payment_controller.dart';
import 'package:elkitap/modules/store/controllers/book_detail_controller.dart';
import 'package:elkitap/utils/dialog_utils.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconly/iconly.dart';

class BookDetailAppBar extends StatelessWidget implements PreferredSizeWidget {
  final BooksDetailController controller;
  final PaymentController paymentController;
  final Color accent;
  final BuildContext context;

  const BookDetailAppBar({
    required this.controller,
    required this.paymentController,
    required this.accent,
    required this.context,
    super.key,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E1E1E) : const Color(0xFFF5F5F5),
      elevation: 0,
      leadingWidth: 45,
      centerTitle: true,
      leading: _buildCloseButton(context),
      title: !paymentController.isPaymentActive.value ? SizedBox(width: 60) : _buildMediaTypeToggle(context),
      automaticallyImplyLeading: false,
      actions: [
        _buildAddToLibraryButton(context),
        _buildMoreOptionsButton(context),
      ],
    );
  }

  Widget _buildCloseButton(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Container(
        width: 34,
        height: 34,
        margin: const EdgeInsets.only(left: 10),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[700] : Colors.grey[200],
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.close, size: 18),
      ),
    );
  }

  Widget _buildMediaTypeToggle(BuildContext context) {
    return Obx(() {
      if (!controller.hasBothVersions()) {
        return const SizedBox.shrink();
      }

      final isDark = Theme.of(context).brightness == Brightness.dark;

      return Container(
        height: 32,
        width: 126,
        decoration: BoxDecoration(
          color: isDark ? Colors.black.withOpacity(0.9) : Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(25),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildToggleButton(
              context: context,
              label: "media_type_text_t".tr,
              isSelected: !controller.isAudio.value,
              onTap: controller.toggleToText,
            ),
            _buildToggleButton(
              context: context,
              label: "media_type_audio_t".tr,
              isSelected: controller.isAudio.value,
              onTap: controller.toggleToAudio,
            ),
          ],
        ),
      );
    });
  }

  Widget _buildToggleButton({
    required BuildContext context,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(1.5),
        child: Container(
          width: 60,
          decoration: BoxDecoration(
            color: isSelected ? (isDark ? Colors.grey[700] : Colors.grey[200]) : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontFamily: StringConstants.SFPro,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAddToLibraryButton(BuildContext context) {
    final downloadController = Get.find<DownloadController>();

    return Obx(() {
      final isAudioTab = controller.isAudio.value;
      final isLoading = downloadController.isLoading.value;
      final progress = downloadController.downloadProgress.value;

      if (isAudioTab) {
        // ── AUDIO TAB ──────────────────────────────────────────────────────
        final baseBookId = controller.bookDetail.value?.id.toString() ?? '0';
        final isDownloaded = downloadController.downloadedBooks.any(
          (b) => b.id == baseBookId && b.isAudio,
        );

        return GestureDetector(
          onTap: () async {
            if (isLoading) {
              _showCancelDownloadDialog(downloadController);
              return;
            }

            if (isDownloaded) {
              Get.to(() => const DownloadedListScreen());
              return;
            }

            // Fetch HLS URL if not yet loaded
            String hlsUrl = controller.audioHlsUrl.value;
            if (hlsUrl.isEmpty) {
              await controller.fetchAudioHlsUrl();
              hlsUrl = controller.audioHlsUrl.value;
            }

            if (hlsUrl.isEmpty) {
              AppSnackbar.error('bookFileNotAvailable'.tr);
              return;
            }

            final book = controller.bookDetail.value;
            final translate = controller.getCurrentTranslate();
            final bookTitle = translate?.name ?? 'unknown_title'.tr;
            final imageUrl = controller.getBookCoverImage();
            final author = book?.authors.isNotEmpty == true ? book!.authors.first.name : 'unknown_author'.tr;

            final confirmed = await _showDownloadConfirmationDialog(context, bookTitle, isAudio: true);
            if (confirmed != true) return;

            try {
              await downloadController.downloadAndEncryptAudioBook(
                bookId: baseBookId,
                bookTitle: bookTitle,
                imageUrl: imageUrl,
                author: author,
                hlsUrl: hlsUrl,
              );
              final didDownload = downloadController.downloadedBooks.any(
                (b) => b.id == baseBookId && b.isAudio,
              );
              if (didDownload) {
                _showSuccessDialog(context, bookTitle);
              }
            } catch (e) {
              AppSnackbar.error('failedToDownload'.trParams({'error': e.toString()}));
            }
          },
          child: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: isDownloaded
                  ? const Color(0xFF34C759)
                  : Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey[700]
                      : Colors.grey[200],
              shape: BoxShape.circle,
            ),
            child: isLoading
                ? SizedBox(
                    height: 24,
                    width: 24,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircularProgressIndicator(
                          value: progress > 0 && progress < 1.0 ? progress : null,
                          strokeWidth: 2.5,
                          color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                          backgroundColor: Colors.white24,
                        ),
                        if (progress > 0 && progress < 1.0)
                          Text(
                            '${(progress * 100).toInt()}%',
                            style: TextStyle(
                              color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                              fontSize: 7,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                      ],
                    ),
                  )
                : Icon(
                    isDownloaded ? Icons.download_done : IconlyLight.download,
                    size: 18,
                    color: isDownloaded
                        ? Colors.white
                        : Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : Colors.black54,
                  ),
          ),
        );
      } else {
        // ── BOOK TAB ───────────────────────────────────────────────────────
        final translate = controller.getCurrentTranslate();
        final bookKey = translate?.bookKey;
        final baseBookId = controller.bookDetail.value?.id.toString() ?? '0';
        final bookId = translate != null ? '${baseBookId}_t${translate.id}' : baseBookId;

        final isDownloaded = downloadController.downloadedBooks.any(
          (b) => b.id == bookId && !b.isAudio,
        );

        return GestureDetector(
          onTap: () async {
            if (isLoading || isDownloaded) {
              Get.to(() => const DownloadedListScreen());
              return;
            }

            if (bookKey == null || bookKey.isEmpty) {
              AppSnackbar.error('bookFileNotAvailable'.tr);
              return;
            }

            final bookTitle = translate != null ? '${translate.name} (${translate.language})' : (translate?.name ?? 'unknown'.tr);
            final imageUrl = controller.getBookCoverImage();
            final book = controller.bookDetail.value;
            final author = book?.authors.isNotEmpty == true ? book!.authors.first.name : 'unknown_author'.tr;

            final confirmed = await _showDownloadConfirmationDialog(context, bookTitle, isAudio: false);
            if (confirmed != true) return;

            try {
              _showLoadingDialog(context);
              await downloadController.downloadAndEncryptBook(
                bookId: bookId,
                bookKey: bookKey,
                bookTitle: bookTitle,
                imageUrl: imageUrl,
                author: author,
              );
              if (Get.isDialogOpen ?? false) Get.back();
              _showSuccessDialog(context, bookTitle);
            } catch (e) {
              if (Get.isDialogOpen ?? false) Get.back();
              AppSnackbar.error('failedToDownload'.trParams({'error': e.toString()}));
            }
          },
          child: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: isDownloaded
                  ? const Color(0xFF34C759)
                  : Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey[700]
                      : Colors.grey[200],
              shape: BoxShape.circle,
            ),
            child: isLoading
                ? SizedBox(
                    height: 24,
                    width: 24,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircularProgressIndicator(
                          value: progress > 0 && progress < 1.0 ? progress : null,
                          strokeWidth: 2.5,
                          color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                          backgroundColor: Colors.white24,
                        ),
                        if (progress > 0 && progress < 1.0)
                          Text(
                            '${(progress * 100).toInt()}%',
                            style: TextStyle(
                              color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                              fontSize: 7,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                      ],
                    ),
                  )
                : Icon(
                    isDownloaded ? Icons.download_done : IconlyLight.download,
                    size: 18,
                    color: isDownloaded
                        ? Colors.white
                        : Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : Colors.black54,
                  ),
          ),
        );
      }
    });
  }

  Future<bool?> _showDownloadConfirmationDialog(
    BuildContext context,
    String bookTitle, {
    bool isAudio = false,
  }) {
    return Get.dialog<bool>(
      Dialog(
        backgroundColor: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark ? Colors.black.withOpacity(0.85) : Colors.white.withOpacity(0.95),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05),
                  width: 1,
                ),
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF5A3C).withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.download_rounded,
                      size: 30,
                      color: Color(0xFFFF5A3C),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    isAudio ? 'downloadAudioTitle'.tr : 'downloadBookTitle'.tr,
                    style: TextStyle(
                      fontFamily: StringConstants.SFPro,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    isAudio ? 'downloadAudioContent'.trParams({'bookTitle': bookTitle}) : 'downloadBookContent'.trParams({'bookTitle': bookTitle}),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: StringConstants.SFPro,
                      fontSize: 15,
                      color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Get.back(result: false),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[700]! : Colors.grey[300]!,
                              ),
                            ),
                          ),
                          child: Text(
                            'cancel'.tr,
                            style: TextStyle(
                              fontFamily: StringConstants.SFPro,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[400] : Colors.grey[600],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Get.back(result: true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF5A3C),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            'download'.tr,
                            style: const TextStyle(
                              fontFamily: StringConstants.SFPro,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showLoadingDialog(BuildContext context) {
    Get.dialog(
      WillPopScope(
        onWillPop: () async => false,
        child: Center(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Material(
                color: Theme.of(context).brightness == Brightness.dark ? Colors.black.withOpacity(0.85) : Colors.white.withOpacity(0.95),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  width: 280,
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark ? Colors.black.withOpacity(0.85) : Colors.white.withOpacity(0.95),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05),
                      width: 1,
                    ),
                  ),
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        padding: EdgeInsets.all(10),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const LoadingWidget(removeBackWhite: true),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'downloadingAndEncrypting'.tr,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: StringConstants.SFPro,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }

  void _showSuccessDialog(BuildContext context, String bookTitle) {
    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark ? Colors.black.withOpacity(0.85) : Colors.white.withOpacity(0.95),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05),
                  width: 1,
                ),
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: const Color(0xFF34C759).withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_circle_rounded,
                      size: 30,
                      color: Color(0xFF34C759),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'success'.tr,
                    style: TextStyle(
                      fontFamily: StringConstants.SFPro,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'bookDownloadedSuccessfully'.trParams({'bookTitle': bookTitle}),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: StringConstants.SFPro,
                      fontSize: 15,
                      color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Get.back(),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[700]! : Colors.grey[300]!,
                              ),
                            ),
                          ),
                          child: Text(
                            'ok'.tr,
                            style: TextStyle(
                              fontFamily: StringConstants.SFPro,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[400] : Colors.grey[600],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Get.back();
                            Get.to(() => const DownloadedListScreen());
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF5A3C),
                            padding: const EdgeInsets.symmetric(
                              vertical: 14,
                              horizontal: 6,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            'viewDownloads'.tr,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: StringConstants.SFPro,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showCancelDownloadDialog(DownloadController downloadCtrl) {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.warning_rounded,
                  color: Colors.orange.shade700,
                  size: 32,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'cancel_download'.tr,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'cancel_download_confirmation'.tr,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Get.back(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                      child: Text(
                        'no'.tr,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        downloadCtrl.cancelDownload();
                        Get.back();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'yes'.tr,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: true,
    );
  }

  Widget _buildMoreOptionsButton(BuildContext context) {
    return GestureDetector(
      onTap: () => DialogUtils.showOptionsPopupMenu(context, controller),
      child: Container(
        width: 34,
        height: 34,
        margin: const EdgeInsets.only(left: 8, right: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[700] : Colors.grey[200],
          shape: BoxShape.circle,
        ),
        child: const Icon(size: 18, Icons.more_horiz),
      ),
    );
  }
}
