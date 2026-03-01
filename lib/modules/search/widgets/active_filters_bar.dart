import 'package:elkitap/core/constants/string_constants.dart';
import 'package:elkitap/core/theme/app_colors.dart';
import 'package:elkitap/modules/search/controllers/filter_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ActiveFiltersBar extends StatelessWidget {
  final VoidCallback onClearAll;

  const ActiveFiltersBar({super.key, required this.onClearAll});

  @override
  Widget build(BuildContext context) {
    final filterController = Get.find<FilterController>();

    return Obx(() {
      if (!filterController.hasActiveFilters) {
        return const SizedBox.shrink();
      }

      final chips = <Widget>[];

      // Language chip
      final langName = filterController.getSelectedLanguageName();
      if (langName != null) {
        chips.add(_buildActiveChip(
          langName,
          () => filterController.selectedLanguageId.value = null,
        ));
      }

      // Format chip
      if (filterController.selectedFormat.value != 'all') {
        final fmt = filterController.selectedFormat.value;
        chips.add(_buildActiveChip(
          fmt == 'audio' ? 'format_audio'.tr : 'format_text'.tr,
          () => filterController.selectedFormat.value = 'all',
        ));
      }

      // Authors chip
      if (filterController.selectedAuthorIds.isNotEmpty) {
        final count = filterController.selectedAuthorIds.length;
        chips.add(_buildActiveChip(
          '$count ${'authors_title_t'.tr}',
          () {
            filterController.selectedAuthorIds.clear();
            filterController.tempAuthorIds.clear();
          },
        ));
      }

      // Genres chip
      if (filterController.selectedGenreIds.isNotEmpty) {
        final count = filterController.selectedGenreIds.length;
        chips.add(_buildActiveChip(
          '$count ${'genres'.tr}',
          () {
            filterController.selectedGenreIds.clear();
            filterController.tempGenreIds.clear();
          },
        ));
      }

      // Age chip
      if (filterController.minAge.value != null || filterController.maxAge.value != null) {
        chips.add(_buildActiveChip(
          '${filterController.minAge.value ?? 0}-${filterController.maxAge.value ?? 18} ${'years_old'.tr}',
          () {
            filterController.minAge.value = null;
            filterController.maxAge.value = null;
            filterController.isAgeFilterEnabled.value = false;
          },
        ));
      }

      // Year chip
      if (filterController.startYear.value != null || filterController.endYear.value != null) {
        chips.add(_buildActiveChip(
          '${filterController.startYear.value ?? 1900}-${filterController.endYear.value ?? DateTime.now().year}',
          () {
            filterController.startYear.value = null;
            filterController.endYear.value = null;
            filterController.isYearFilterEnabled.value = false;
          },
        ));
      }

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              // Clear all button
              GestureDetector(
                onTap: () {
                  filterController.clearAllFilters();
                  onClearAll();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.close, size: 14, color: Colors.grey[700]),
                      const SizedBox(width: 4),
                      Text(
                        'clear'.tr,
                        style: TextStyle(
                          fontSize: 12,
                          fontFamily: StringConstants.GilroyMedium,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ...chips,
            ],
          ),
        ),
      );
    });
  }

  Widget _buildActiveChip(String label, VoidCallback onRemove) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.mainColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.mainColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontFamily: StringConstants.GilroyMedium,
              color: AppColors.mainColor,
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(
              Icons.close,
              size: 14,
              color: AppColors.mainColor,
            ),
          ),
        ],
      ),
    );
  }
}
