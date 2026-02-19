import 'dart:developer';

import 'package:elkitap/core/constants/icon_constants.dart';
import 'package:elkitap/core/constants/string_constants.dart';
import 'package:elkitap/core/widgets/common/app_snackbar.dart';
import 'package:elkitap/data/network/token_managet.dart';
import 'package:elkitap/core/widgets/common/custom_icon.dart';
import 'package:elkitap/modules/library/widgets/read_download_button.dart';
import 'package:elkitap/modules/paymant/controller/payment_controller.dart';
import 'package:elkitap/modules/store/controllers/book_detail_controller.dart';
import 'package:elkitap/modules/store/services/book_detail_audio_service.dart';
import 'package:elkitap/modules/store/views/ai_descrition_view.dart';
import 'package:elkitap/modules/auth/controllers/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class BookActionButtons extends StatelessWidget {
  final BooksDetailController controller;
  final PaymentController paymentController;
  final dynamic bookDetail;
  final TokenManager tokenManager;
  final BookDetailAudioService audioService;
  final String bookId;
  final BuildContext context;

  const BookActionButtons({
    required this.controller,
    required this.paymentController,
    required this.bookDetail,
    required this.tokenManager,
    required this.audioService,
    required this.bookId,
    required this.context,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildReadListenButtons(context),
        _buildAiContentButton(context),
      ],
    );
  }

  Widget _buildReadListenButtons(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Obx(() {
        final hasText = controller.hasTextVersion();
        final hasAudio = controller.hasAudioVersion();
        final isAudioMode = controller.isAudio.value;
        final progress = controller.getProgressPercentage();
        final showProgress = controller.bookDetail.value?.progress != null;

        return Column(
          children: [
            // Show Read button only when text tab is selected
            if (!isAudioMode && hasText)
              _buildReadButton(
                hasText,
                context,
                showProgress: showProgress,
                progressText: progress,
              ),
            // Show Listen button only when audio tab is selected
            if (isAudioMode && hasAudio)
              _buildListenButton(
                hasAudio,
                context,
                showProgress: showProgress,
                progressText: progress,
              ),
          ],
        );
      }),
    );
  }

  Widget _buildReadButton(
    bool hasText,
    BuildContext context, {
    bool showProgress = false,
    String? progressText,
  }) {
    // Shared style for uniform look
    final borderRadius = BorderRadius.circular(12);
    final color = const Color(0xFFFF5A3C);

    if (hasText) {
      final AuthController authController = Get.find<AuthController>();
      final isSubscribed =
          authController.currentUser.value?.subscription?.isActive ?? false;

      if (isSubscribed) {
        log("isSubscribed");
        return ReadDownloadButton(
          controller: controller,
          book: bookDetail,
          accent: color,
          borderRadius: borderRadius,
          showProgress: showProgress,
          progressText: progressText,
        );
      } else {
        log("notSubscribed");
        if (paymentController.isPaymentActive.value) {
          return ReadDownloadButton(
            controller: controller,
            book: bookDetail,
            accent: color,
            borderRadius: borderRadius,
            showProgress: showProgress,
            progressText: progressText,
          );
        }
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            AppSnackbar.custom(
              message: "please_subscribe_t".tr,
              title: "premium_feature_t".tr,
              backgroundColor: const Color(0xFFFF5A26),
            );
          },
          child: IgnorePointer(
            child: ReadDownloadButton(
              controller: controller,
              book: bookDetail,
              accent: color,
              borderRadius: borderRadius,
              showProgress: showProgress,
              progressText: progressText,
            ),
          ),
        );
      }
    }

    // Disabled state
    return Container(
      height: 50,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.3),
        borderRadius: borderRadius,
      ),
      child: Center(
        child: Text(
          "read_button_t".tr,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontFamily: StringConstants.SFPro,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildListenButton(
    bool hasAudio,
    BuildContext context, {
    bool showProgress = false,
    String? progressText,
  }) {
    final borderRadius = BorderRadius.circular(12);
    final color = const Color(0xFFFF5A3C);
    final AuthController authController = Get.find<AuthController>();

    // Subscription Check
    final isSubscribed =
        authController.currentUser.value?.subscription?.isActive ?? false;

    return GestureDetector(
      onTap: hasAudio
          ? () {
              if (isSubscribed) {
                audioService.handleListenButtonTap(
                  bookDetail,
                  tokenManager,
                );
              } else {
                AppSnackbar.custom(
                  message: "please_subscribe_t".tr,
                  title: "premium_feature_t".tr,
                  backgroundColor: const Color(0xFFFF5A26),
                );
              }
            }
          : null,
      child: Container(
        height: 50,
        width: double.infinity,
        decoration: BoxDecoration(
          color: hasAudio ? color : Colors.grey.withOpacity(0.3),
          borderRadius: borderRadius,
        ),
        child: Center(
          child: controller.isLoadingAudio.value && hasAudio
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(
                  "listen_button_t".tr,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontFamily: StringConstants.SFPro,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildAiContentButton(BuildContext context) {
    return Obx(() {
      final aiDescription = controller.getCurrentTranslate()?.aiDescription;
      // Check if AI description exists and is not empty or just whitespace
      final hasAiDescription =
          aiDescription != null && aiDescription.trim().isNotEmpty;

      print(
          '🤖 AI Button Check - hasAiDescription: $hasAiDescription, length: ${aiDescription?.length ?? 0}');

      if (!hasAiDescription) {
        return const SizedBox();
      }

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32).copyWith(top: 12),
        child: GestureDetector(
          onTap: () async {
            if (controller.isAuth.value) {
              Get.to(() => AiDescriptionScreen(bookId: bookId));
            }
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              image: const DecorationImage(
                  image: AssetImage('assets/images/bg1.png'),
                  fit: BoxFit.cover),
            ),
            alignment: Alignment.center,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CustomIcon(
                  title: IconConstants.d7,
                  height: 24,
                  width: 24,
                  color: Colors.white,
                ),
                const SizedBox(width: 8),
                Text(
                  "ai_content_t".tr,
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: StringConstants.SFPro,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}
