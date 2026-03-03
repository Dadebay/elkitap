import 'dart:async';

import 'package:elkitap/core/constants/string_constants.dart';
import 'package:elkitap/core/theme/app_colors.dart';
import 'package:elkitap/modules/search/controllers/filter_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconly/iconly.dart';

class FilterBottomSheet extends StatefulWidget {
  final VoidCallback onApply;

  const FilterBottomSheet({super.key, required this.onApply});

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  late final FilterController filterController;
  Timer? _authorDebounce;

  @override
  void initState() {
    super.initState();
    filterController = Get.find<FilterController>();
    filterController.resetTempToApplied();
  }

  @override
  void dispose() {
    _authorDebounce?.cancel();
    super.dispose();
  }

  void _onAuthorSearchChanged(String value) {
    _authorDebounce?.cancel();
    _authorDebounce = Timer(const Duration(milliseconds: 500), () {
      filterController.authorSearchQuery.value = value;
      filterController.searchAuthorsForFilter(value);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final cardColor = isDark ? const Color(0xFF2C2C2E) : Colors.grey[50]!;
    final textColor = isDark ? Colors.white : Colors.black;
    final subTextColor = isDark ? Colors.grey[400]! : Colors.grey[600]!;

    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'filter'.tr,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      fontFamily: StringConstants.GilroyBold,
                      color: textColor,
                    ),
                  ),
                  Row(
                    children: [
                      // Clear button
                      Obx(() {
                        final hasTemp = filterController.tempLanguageId.value != null ||
                            filterController.tempAuthorIds.isNotEmpty ||
                            filterController.tempGenreIds.isNotEmpty ||
                            filterController.isAgeFilterEnabled.value ||
                            filterController.isYearFilterEnabled.value;
                        if (!hasTemp) return const SizedBox.shrink();
                        return TextButton(
                          onPressed: () {
                            filterController.clearTempFilters();
                          },
                          child: Text(
                            'clear'.tr,
                            style: TextStyle(
                              fontSize: 14,
                              fontFamily: StringConstants.GilroyMedium,
                              color: AppColors.mainColor,
                            ),
                          ),
                        );
                      }),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(Icons.close, color: subTextColor, size: 24),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ---- Language Section ----
                    _buildSectionTitle('language'.tr, IconlyLight.document, textColor),
                    const SizedBox(height: 12),
                    _buildLanguageChips(cardColor, textColor),

                    const SizedBox(height: 24),

                    // ---- Genres Section ----
                    _buildSectionTitle('genres'.tr, IconlyLight.category, textColor),
                    const SizedBox(height: 12),
                    _buildGenreSection(textColor, subTextColor),

                    const SizedBox(height: 24),

                    // ---- Authors Section ----
                    _buildSectionTitle('authors_title_t'.tr, IconlyLight.user, textColor),
                    const SizedBox(height: 12),
                    _buildAuthorSearch(isDark, cardColor, textColor, subTextColor),

                    const SizedBox(height: 24),

                    // ---- Age Range Section ----
                    _buildAgeSection(textColor, subTextColor),

                    const SizedBox(height: 24),

                    // ---- Year Range Section ----
                    _buildYearSection(textColor, subTextColor),

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),

            // Apply button
            Padding(
              padding: EdgeInsets.fromLTRB(24, 8, 24, MediaQuery.of(context).padding.bottom + 16),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    filterController.applyFilters();
                    Navigator.pop(context);
                    widget.onApply();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.mainColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    'apply_filter'.tr,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      fontFamily: StringConstants.GilroySemiBold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon, Color textColor) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.mainColor),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            fontFamily: StringConstants.GilroySemiBold,
            color: textColor,
          ),
        ),
      ],
    );
  }

  Widget _buildLanguageChips(Color cardColor, Color textColor) {
    return Obx(() {
      if (filterController.isLoadingLanguages.value) {
        return const SizedBox(
          height: 36,
          child: Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.mainColor,
              ),
            ),
          ),
        );
      }

      return Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          // "All" chip
          _buildChip(
            label: 'all'.tr,
            isSelected: filterController.tempLanguageId.value == null,
            onTap: () => filterController.tempLanguageId.value = null,
            textColor: textColor,
          ),
          ...filterController.languages.map((lang) {
            final isSelected = filterController.tempLanguageId.value == lang.id;
            return _buildChip(
              label: filterController.languageDisplayName(lang),
              isSelected: isSelected,
              onTap: () {
                if (isSelected) {
                  filterController.tempLanguageId.value = null;
                } else {
                  filterController.tempLanguageId.value = lang.id;
                }
              },
              textColor: textColor,
            );
          }),
        ],
      );
    });
  }

  Widget _buildChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required Color textColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.mainColor : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.mainColor : Colors.grey[300]!,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontFamily: StringConstants.GilroyMedium,
            color: isSelected ? Colors.white : textColor,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }

  Widget _buildGenreSection(Color textColor, Color subTextColor) {
    return Obx(() {
      if (filterController.isLoadingGenres.value) {
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.mainColor,
              ),
            ),
          ),
        );
      }

      if (filterController.allGenres.isEmpty) {
        return const SizedBox.shrink();
      }

      return Wrap(
        spacing: 10,
        runSpacing: 10,
        children: filterController.allGenres.map((genre) {
          final isSelected = filterController.tempGenreIds.contains(genre.id);
          return GestureDetector(
            onTap: () => filterController.toggleGenre(genre.id),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.mainColor : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? AppColors.mainColor : Colors.grey[300]!,
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isSelected) ...[
                    const Icon(Icons.check, size: 14, color: Colors.white),
                    const SizedBox(width: 4),
                  ],
                  Text(
                    genre.name,
                    style: TextStyle(
                      fontSize: 13,
                      fontFamily: StringConstants.GilroyMedium,
                      color: isSelected ? Colors.white : textColor,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      );
    });
  }

  Widget _buildAuthorSearch(
    bool isDark,
    Color cardColor,
    Color textColor,
    Color subTextColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Selected authors chips
        Obx(() {
          if (filterController.tempAuthorIds.isEmpty) {
            return const SizedBox.shrink();
          }
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: filterController.tempAuthorIds.map((id) {
                // Find the author name
                final author = filterController.allAuthors.firstWhereOrNull(
                  (a) => a.id == id,
                );
                final name = author?.name ?? 'ID: $id';
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.mainColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.mainColor.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          fontSize: 13,
                          fontFamily: StringConstants.GilroyMedium,
                          color: AppColors.mainColor,
                        ),
                      ),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: () => filterController.toggleAuthor(id),
                        child: Icon(
                          Icons.close,
                          size: 16,
                          color: AppColors.mainColor,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          );
        }),

        // Search field
        Container(
          height: 45,
          decoration: BoxDecoration(
            color: isDark ? Colors.grey[800] : Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 14, right: 10),
                child: Icon(IconlyLight.search, size: 20, color: Colors.grey),
              ),
              Expanded(
                child: TextField(
                  controller: filterController.authorSearchController,
                  style: TextStyle(
                    fontSize: 14,
                    fontFamily: StringConstants.SFPro,
                    color: textColor,
                  ),
                  decoration: InputDecoration(
                    hintText: 'search_author'.tr,
                    hintStyle: TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    isDense: true,
                  ),
                  onChanged: _onAuthorSearchChanged,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // Author results list
        Obx(() {
          if (filterController.isLoadingAuthors.value) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.mainColor,
                  ),
                ),
              ),
            );
          }

          if (filterController.authorSearchQuery.value.isNotEmpty && filterController.allAuthors.isEmpty) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'no_authors_found'.tr,
                style: TextStyle(
                  fontSize: 13,
                  color: subTextColor,
                  fontFamily: StringConstants.GilroyRegular,
                ),
              ),
            );
          }

          if (filterController.allAuthors.isEmpty) {
            return const SizedBox.shrink();
          }

          return ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 200),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: filterController.allAuthors.length,
              padding: EdgeInsets.zero,
              itemBuilder: (context, index) {
                final author = filterController.allAuthors[index];
                return Obx(() {
                  final isSelected = filterController.tempAuthorIds.contains(author.id);
                  return InkWell(
                    onTap: () => filterController.toggleAuthor(author.id),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 4,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.mainColor : Colors.transparent,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: isSelected ? AppColors.mainColor : Colors.grey[400]!,
                                width: 1.5,
                              ),
                            ),
                            child: isSelected
                                ? const Icon(
                                    Icons.check,
                                    size: 14,
                                    color: Colors.white,
                                  )
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              author.name,
                              style: TextStyle(
                                fontSize: 14,
                                fontFamily: StringConstants.GilroyMedium,
                                color: textColor,
                              ),
                            ),
                          ),
                          Text(
                            '${author.bookCount} ${'books_count'.tr}',
                            style: TextStyle(
                              fontSize: 12,
                              color: subTextColor,
                              fontFamily: StringConstants.GilroyRegular,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                });
              },
            ),
          );
        }),
      ],
    );
  }

  Widget _buildAgeSection(Color textColor, Color subTextColor) {
    return Obx(() {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSectionTitle('age_range'.tr, IconlyLight.user_1, textColor),
              Switch(
                value: filterController.isAgeFilterEnabled.value,
                onChanged: (val) {
                  filterController.isAgeFilterEnabled.value = val;
                },
                activeColor: AppColors.mainColor,
              ),
            ],
          ),
          if (filterController.isAgeFilterEnabled.value) ...[
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${filterController.tempAgeRange.value.start.round()} ${'years_old'.tr}',
                  style: TextStyle(
                    fontSize: 13,
                    fontFamily: StringConstants.GilroyMedium,
                    color: subTextColor,
                  ),
                ),
                Text(
                  '${filterController.tempAgeRange.value.end.round()} ${'years_old'.tr}',
                  style: TextStyle(
                    fontSize: 13,
                    fontFamily: StringConstants.GilroyMedium,
                    color: subTextColor,
                  ),
                ),
              ],
            ),
            SliderTheme(
              data: SliderThemeData(
                activeTrackColor: AppColors.mainColor,
                inactiveTrackColor: Colors.grey[300],
                thumbColor: AppColors.mainColor,
                overlayColor: AppColors.mainColor.withOpacity(0.1),
                trackHeight: 3,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
              ),
              child: RangeSlider(
                values: filterController.tempAgeRange.value,
                min: 0,
                max: 18,
                divisions: 18,
                labels: RangeLabels(
                  '${filterController.tempAgeRange.value.start.round()}',
                  '${filterController.tempAgeRange.value.end.round()}',
                ),
                onChanged: (values) {
                  filterController.tempAgeRange.value = values;
                },
              ),
            ),
          ],
        ],
      );
    });
  }

  Widget _buildYearSection(Color textColor, Color subTextColor) {
    final currentYear = DateTime.now().year;
    return Obx(() {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSectionTitle(
                'year_range'.tr,
                IconlyLight.calendar,
                textColor,
              ),
              Switch(
                value: filterController.isYearFilterEnabled.value,
                onChanged: (val) {
                  filterController.isYearFilterEnabled.value = val;
                },
                activeColor: AppColors.mainColor,
              ),
            ],
          ),
          if (filterController.isYearFilterEnabled.value) ...[
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${filterController.tempYearRange.value.start.round()}',
                  style: TextStyle(
                    fontSize: 13,
                    fontFamily: StringConstants.GilroyMedium,
                    color: subTextColor,
                  ),
                ),
                Text(
                  '${filterController.tempYearRange.value.end.round()}',
                  style: TextStyle(
                    fontSize: 13,
                    fontFamily: StringConstants.GilroyMedium,
                    color: subTextColor,
                  ),
                ),
              ],
            ),
            SliderTheme(
              data: SliderThemeData(
                activeTrackColor: AppColors.mainColor,
                inactiveTrackColor: Colors.grey[300],
                thumbColor: AppColors.mainColor,
                overlayColor: AppColors.mainColor.withOpacity(0.1),
                trackHeight: 3,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
              ),
              child: RangeSlider(
                values: filterController.tempYearRange.value,
                min: 1300,
                max: currentYear.toDouble(),
                divisions: currentYear - 1300,
                labels: RangeLabels(
                  '${filterController.tempYearRange.value.start.round()}',
                  '${filterController.tempYearRange.value.end.round()}',
                ),
                onChanged: (values) {
                  filterController.tempYearRange.value = values;
                },
              ),
            ),
          ],
        ],
      );
    });
  }
}
