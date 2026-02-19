// ignore_for_file: use_super_parameters

import 'package:elkitap/core/constants/icon_constants.dart';
import 'package:elkitap/core/constants/string_constants.dart';
import 'package:elkitap/core/widgets/common/custom_icon.dart';
import 'package:elkitap/modules/library/widgets/suggest_content_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';

/// Generic empty state widget for no data scenarios
class EmptyStateWidget extends StatelessWidget {
  final String? title;
  final String? subtitle;
  final String? iconPath;
  final double? iconSize;
  final Color? iconColor;
  final VoidCallback? onActionPressed;
  final String? actionButtonText;

  const EmptyStateWidget({
    Key? key,
    this.title,
    this.subtitle,
    this.iconPath,
    this.iconSize = 48,
    this.iconColor,
    this.onActionPressed,
    this.actionButtonText,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (iconPath != null)
              CustomIcon(
                title: iconPath!,
                height: iconSize!,
                width: iconSize!,
                color: iconColor ?? (isDark ? Colors.white : Colors.black),
              ),
            if (iconPath != null) const SizedBox(height: 24),
            if (title != null)
              Text(
                title!,
                style: const TextStyle(
                  fontSize: 20,
                  fontFamily: StringConstants.SFPro,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            if (subtitle != null) const SizedBox(height: 12),
            if (subtitle != null)
              Text(
                subtitle!,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                  fontFamily: StringConstants.SFPro,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            if (onActionPressed != null && actionButtonText != null) ...[
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: onActionPressed,
                child: Text(actionButtonText!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Empty state for no genres/books available
class NoGenresAvailable extends StatelessWidget {
  final String? title;
  const NoGenresAvailable({this.title, super.key});

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      iconPath: IconConstants.libraryFilled,
      iconSize: 24,
      subtitle: title,
    );
  }
}

/// Empty state for search results
class NoSearchResults extends StatelessWidget {
  const NoSearchResults({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SvgPicture.asset(
          IconConstants.search,
          // size: 64,
          width: 70,
          color: isDark ? Colors.grey[600] : Colors.black,
        ),
        const SizedBox(height: 24),
        Text(
          'no_results_search'.tr,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            fontFamily: StringConstants.GilroyBold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Text(
            'try_different_keywords'.tr,
            style: TextStyle(
              fontSize: 15,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
              fontFamily: StringConstants.SFPro,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 32),
        ElevatedButton(
          onPressed: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) => const SuggestContentDialog(),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFF5A3C),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            elevation: 0,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 10, top: 2),
                child: Image.asset(
                  'assets/images/book_sugges.png',
                  height: 22,
                  width: 22,
                  color: Colors.white,
                ),
              ),
              Text(
                'suggest_content_button'.tr,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  // fontFamily: StringConstants.SFPro,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Empty state for library collections
class EmptyCollectionWidget extends StatelessWidget {
  final String descriptionKey;

  const EmptyCollectionWidget({
    Key? key,
    required this.descriptionKey,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      iconPath: IconConstants.libraryFilled,
      iconSize: 48,
      title: 'emptyCollection'.tr,
      subtitle: descriptionKey.tr,
    );
  }
}

/// Empty state for no downloads
class NoDownloadsWidget extends StatelessWidget {
  const NoDownloadsWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      iconPath: IconConstants.d11,
      iconSize: 48,
      title: 'no_downloads'.tr,
      subtitle: 'start_downloading_books'.tr,
    );
  }
}

/// Empty state for no notes
class NoNotesWidget extends StatelessWidget {
  const NoNotesWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      iconPath: IconConstants.libraryFilled,
      iconSize: 48,
      title: 'no_notes'.tr,
      subtitle: 'start_taking_notes'.tr,
    );
  }
}

/// Empty state for no books found
class NoBooksFoundWidget extends StatelessWidget {
  final String? message;

  const NoBooksFoundWidget({Key? key, this.message}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      iconPath: IconConstants.libraryFilled,
      iconSize: 32,
      title: message ?? 'no_books_found'.tr,
    );
  }
}

/// Empty state for no professional readers
class NoProfessionalReadersWidget extends StatelessWidget {
  const NoProfessionalReadersWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      iconPath: IconConstants.libraryFilled,
      iconSize: 32,
      title: 'no_professional_reads_available'.tr,
    );
  }
}
