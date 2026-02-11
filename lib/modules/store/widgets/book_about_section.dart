import 'package:elkitap/core/constants/string_constants.dart';
import 'package:elkitap/modules/store/controllers/book_detail_controller.dart';
import 'package:elkitap/modules/store/views/detail_geners_view.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class BookAboutSection extends StatelessWidget {
  final BooksDetailController controller;
  final String bookId;
  final BuildContext context;

  const BookAboutSection({
    required this.controller,
    required this.bookId,
    required this.context,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).brightness == Brightness.dark
          ? Colors.grey[700]
          : Colors.white,
      child: Column(
        children: [
          const SizedBox(height: 24),
          _buildAboutTitle(),
          const SizedBox(height: 8),
          _buildDescription(context),
          _buildDivider(),
          GenreBooksDetailSection(bookId: bookId),
        ],
      ),
    );
  }

  Widget _buildAboutTitle() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          "about_t".tr,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontFamily: StringConstants.GilroyRegular,
            fontSize: 20,
          ),
        ),
      ),
    );
  }

  Widget _buildDescription(BuildContext context) {
    return Obx(() {
      final description = controller.getBookDescription();
      final isExpanded = controller.isDescriptionExpanded.value;

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: SizedBox(
          width: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  description.isNotEmpty
                      ? description
                      : 'no_description_available'.tr,
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.5,
                    fontFamily: StringConstants.SFPro,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.start,
                  maxLines: isExpanded ? null : 4,
                  overflow: isExpanded
                      ? TextOverflow.visible
                      : TextOverflow.ellipsis,
                ),
              ),
              if (description.isNotEmpty &&
                  _shouldShowMoreButton(description, context))
                GestureDetector(
                  onTap: () => controller.toggleDescription(),
                  child: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      isExpanded ? 'show_less_t'.tr : 'show_more_t'.tr,
                      style: const TextStyle(
                        fontSize: 15,
                        fontFamily: StringConstants.SFPro,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Divider(height: 1, color: Colors.grey[300]),
    );
  }

  bool _shouldShowMoreButton(String text, BuildContext context) {
    final textSpan = TextSpan(
      text: text,
      style: TextStyle(
        fontSize: 15,
        height: 1.5,
        fontFamily: StringConstants.SFPro,
        color: Colors.grey[100],
      ),
    );
    final textPainter = TextPainter(
      text: textSpan,
      maxLines: 4,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout(maxWidth: MediaQuery.of(context).size.width - 32);
    return textPainter.didExceedMaxLines;
  }
}