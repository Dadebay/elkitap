import 'dart:developer';

import 'package:elkitap/core/constants/string_constants.dart';
import 'package:elkitap/core/widgets/common/app_snackbar.dart';
import 'package:elkitap/modules/store/controllers/book_detail_controller.dart';
import 'package:elkitap/modules/store/views/author_view.dart';
import 'package:elkitap/utils/dialog_utils.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class BookInfoSection extends StatelessWidget {
  final BooksDetailController controller;
  final dynamic bookDetail;
  final BuildContext context;

  const BookInfoSection({
    required this.controller,
    required this.bookDetail,
    required this.context,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Obx(() {
          final translates = controller.bookDetail.value?.translates ?? [];
          final translatesInfo = translates
              .map((e) =>
                  'Lang: ${e.language}, ID: ${e.id}, BookKey: ${e.bookKey}')
              .join('; ');
          log("Book Info - ID: ${controller.bookDetail.value?.id}, Translates: [$translatesInfo]");

          // Log currently selected translation
          final currentTranslate = controller.getCurrentTranslate();
          if (currentTranslate != null) {
            log("Selected Translation - Lang: ${currentTranslate.language}, ID: ${currentTranslate.id}, BookKey: ${currentTranslate.bookKey}");
          }
          final translatesCount =
              controller.bookDetail.value?.translates.length ?? 0;
          // Show language selector if there are translations
          if (translatesCount > 0) {
            return Column(
              children: [
                _buildLanguageSelector(context),
                const SizedBox(height: 12),
              ],
            );
          }
          return const SizedBox.shrink();
        }),
        _buildBookTitle(context),
        _buildAuthors(context),
        _buildGenresAndAgeRating(),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildLanguageSelector(BuildContext context) {
    return Obx(() {
      final translatesCount =
          controller.bookDetail.value?.translates.length ?? 0;
      final hasMultipleTranslations = translatesCount > 0;

      log("traslation $hasMultipleTranslations");

      return GestureDetector(
        onTap: () {
          if (hasMultipleTranslations) {
            DialogUtils.showLanguagePopup(context, controller);
          } else if (translatesCount > 0) {
            AppSnackbar.info('only_one_language_available'.tr);
          }
        },
        child: Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.grey[700]
                : Colors.grey[200],
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.language, size: 18),
              const SizedBox(width: 6),
              Text(
                controller.selectedLanguage.value,
                style: const TextStyle(
                  fontSize: 14,
                  fontFamily: StringConstants.SFPro,
                ),
              ),
              if (hasMultipleTranslations) ...[
                const SizedBox(width: 4),
                Icon(Icons.arrow_drop_down, size: 18),
              ],
            ],
          ),
        ),
      );
    });
  }

  Widget _buildBookTitle(BuildContext context) {
    return Obx(() => GestureDetector(
          onTap: () => DialogUtils.showBookDetailsBottomSheet(
            context,
            controller,
          ),
          child: SizedBox(
            width: MediaQuery.of(context).size.width * 0.7,
            child: Text(
              controller.getBookName(),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontFamily: StringConstants.GilroyRegular,
                fontSize: 22,
                height: 1.3,
              ),
            ),
          ),
        ));
  }

  Widget _buildAuthors(BuildContext context) {
    return Obx(() {
      final authorsText = controller.getAuthorsString();
      if (authorsText.isEmpty) return const SizedBox();

      return GestureDetector(
        onTap: () {
          if (bookDetail.authors.isNotEmpty) {
            Get.to(() => BookAuthorView(author: bookDetail.authors.first),
                arguments: {'authorId': bookDetail.authors.first.id});
          }
        },
        child: Container(
          margin: EdgeInsets.symmetric(vertical: 8),
          width: MediaQuery.of(context).size.width * 0.7,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  authorsText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 16, fontFamily: StringConstants.SFPro),
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right, size: 18),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildGenresAndAgeRating() {
    return Obx(() {
      final genres = controller.getGenresString();
      final ageRating = controller.getAgeRating();
      final text = genres.isNotEmpty
          ? "$genres${ageRating.isNotEmpty ? ' • $ageRating' : ''}"
          : ageRating;

      if (text.isEmpty) return const SizedBox();

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.7,
          child: Text(
            text,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 14,
              fontFamily: StringConstants.SFPro,
              color: Colors.grey[400],
            ),
          ),
        ),
      );
    });
  }
}
