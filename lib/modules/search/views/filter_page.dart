import 'dart:async';

import 'package:elkitap/core/constants/string_constants.dart';
import 'package:elkitap/core/theme/app_colors.dart';
import 'package:elkitap/modules/search/controllers/filter_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconly/iconly.dart';

class FilterPage extends StatefulWidget {
  final VoidCallback onApply;

  const FilterPage({super.key, required this.onApply});

  @override
  State<FilterPage> createState() => _FilterPageState();
}

class _FilterPageState extends State<FilterPage> {
  late final FilterController fc;
  Timer? _authorDebounce;

  @override
  void initState() {
    super.initState();
    fc = Get.find<FilterController>();
    fc.resetTempToApplied();
  }

  @override
  void dispose() {
    _authorDebounce?.cancel();
    super.dispose();
  }

  void _onAuthorSearchChanged(String value) {
    _authorDebounce?.cancel();
    _authorDebounce = Timer(const Duration(milliseconds: 500), () {
      fc.authorSearchQuery.value = value;
      fc.searchAuthorsForFilter(value);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF6F6F6);
    final cardColor = isDark ? const Color(0xFF2C2C2E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;
    final subTextColor = isDark ? Colors.grey[400]! : Colors.grey[600]!;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: GestureDetector(
          onTap: () async {
            _authorDebounce?.cancel();
            Get.back();
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.only(left: 16),
                child: Icon(
                  Icons.arrow_back_ios,
                  size: 18,
                ),
              ),
              Expanded(
                child: Text(
                  'leading_text'.tr,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 16,
                    fontFamily: StringConstants.SFPro,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
              ),
            ],
          ),
        ),
        centerTitle: true,
        leadingWidth: 120,
        title: Text(
          'filter'.tr,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            fontFamily: StringConstants.GilroyBold,
            color: textColor,
          ),
        ),
        actions: [
          Obx(() {
            final hasTemp = fc.tempLanguageId.value != null ||
                fc.tempAuthorIds.isNotEmpty ||
                fc.tempGenreIds.isNotEmpty ||
                fc.tempFormat.value != 'all' ||
                fc.isAgeFilterEnabled.value ||
                fc.isYearFilterEnabled.value;
            if (!hasTemp) return const SizedBox.shrink();
            return TextButton(
              onPressed: fc.clearTempFilters,
              child: Text(
                'clear'.tr,
                style: const TextStyle(
                  fontSize: 14,
                  fontFamily: StringConstants.GilroyMedium,
                  color: AppColors.mainColor,
                ),
              ),
            );
          }),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Format ──────────────────────────────────────────
                  _buildCard(
                    cardColor,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle('format'.tr, IconlyLight.paper, textColor),
                        const SizedBox(height: 14),
                        _buildFormatSegment(textColor),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ── Language ─────────────────────────────────────────
                  _buildCard(
                    cardColor,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle('language'.tr, IconlyLight.document, textColor),
                        const SizedBox(height: 12),
                        _buildLanguageChips(textColor),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ── Genres ───────────────────────────────────────────
                  _buildCard(
                    cardColor,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle('genres'.tr, IconlyLight.category, textColor),
                        const SizedBox(height: 12),
                        _buildGenreSection(textColor),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ── Authors ──────────────────────────────────────────
                  _buildCard(
                    cardColor,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle('authors_title_t'.tr, IconlyLight.user, textColor),
                        const SizedBox(height: 12),
                        _buildAuthorSearch(isDark, textColor, subTextColor),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ── Age range ────────────────────────────────────────
                  _buildCard(
                    cardColor,
                    child: _buildAgeSection(textColor, subTextColor),
                  ),

                  const SizedBox(height: 12),

                  // ── Year range ───────────────────────────────────────
                  _buildCard(
                    cardColor,
                    child: _buildYearSection(textColor, subTextColor),
                  ),

                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),

          // ── Apply button ─────────────────────────────────────────────
          Container(
            color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
            padding: EdgeInsets.fromLTRB(
              20,
              12,
              20,
              MediaQuery.of(context).padding.bottom + 16,
            ),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  fc.applyFilters();
                  Get.back();
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
    );
  }

  // ─── helpers ───────────────────────────────────────────────────────────────

  Widget _buildCard(Color cardColor, {required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: child,
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

  Widget _buildFormatSegment(Color textColor) {
    final segments = [
      ('all', 'format_all'.tr),
      ('text', 'format_text'.tr),
      ('audio', 'format_audio'.tr),
    ];
    return Obx(() {
      return Container(
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(4),
        child: Row(
          children: segments.map((seg) {
            final isSelected = fc.tempFormat.value == seg.$1;
            return Expanded(
              child: GestureDetector(
                onTap: () => fc.tempFormat.value = seg.$1,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.mainColor : Colors.transparent,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Text(
                    seg.$2,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      fontFamily: StringConstants.GilroyMedium,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                      color: isSelected ? Colors.white : textColor,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      );
    });
  }

  Widget _buildLanguageChips(Color textColor) {
    return Obx(() {
      if (fc.isLoadingLanguages.value) {
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
          _buildChip(
            label: 'all'.tr,
            isSelected: fc.tempLanguageId.value == null,
            onTap: () => fc.tempLanguageId.value = null,
            textColor: textColor,
          ),
          ...fc.languages.map((lang) {
            final isSelected = fc.tempLanguageId.value == lang.id;
            return _buildChip(
              label: fc.languageDisplayName(lang),
              isSelected: isSelected,
              onTap: () => fc.tempLanguageId.value = isSelected ? null : lang.id,
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

  Widget _buildGenreSection(Color textColor) {
    return Obx(() {
      if (fc.isLoadingGenres.value) {
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
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
      if (fc.allGenres.isEmpty) return const SizedBox.shrink();
      return Wrap(
        spacing: 10,
        runSpacing: 10,
        children: fc.allGenres.map((genre) {
          final isSelected = fc.tempGenreIds.contains(genre.id);
          return GestureDetector(
            onTap: () => fc.toggleGenre(genre.id),
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

  Widget _buildAuthorSearch(bool isDark, Color textColor, Color subTextColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Obx(() {
          if (fc.tempAuthorIds.isEmpty) return const SizedBox.shrink();
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: fc.tempAuthorIds.map((id) {
                final name = fc.authorDisplayName(id);
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.mainColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.mainColor.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(name,
                          style: TextStyle(
                            fontSize: 13,
                            fontFamily: StringConstants.GilroyMedium,
                            color: AppColors.mainColor,
                          )),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: () => fc.toggleAuthor(id),
                        child: const Icon(Icons.close, size: 16, color: AppColors.mainColor),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          );
        }),
        Container(
          height: 45,
          decoration: BoxDecoration(
            color: isDark ? Colors.grey[800] : Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Padding(
                padding: EdgeInsets.only(left: 14, right: 10),
                child: Icon(IconlyLight.search, size: 20, color: Colors.grey),
              ),
              Expanded(
                child: TextField(
                  controller: fc.authorSearchController,
                  style: TextStyle(
                    fontSize: 14,
                    fontFamily: StringConstants.SFPro,
                    color: textColor,
                  ),
                  decoration: InputDecoration(
                    hintText: 'search_author'.tr,
                    hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
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
        Obx(() {
          if (fc.isLoadingAuthors.value) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.mainColor),
                ),
              ),
            );
          }
          if (fc.authorSearchQuery.value.isNotEmpty && fc.allAuthors.isEmpty) {
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
          if (fc.allAuthors.isEmpty) return const SizedBox.shrink();
          return ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: fc.allAuthors.length,
            padding: EdgeInsets.zero,
            itemBuilder: (context, index) {
              final author = fc.allAuthors[index];
              return Obx(() {
                final isSelected = fc.tempAuthorIds.contains(author.id);
                return InkWell(
                  onTap: () => fc.toggleAuthor(author.id),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
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
                          child: isSelected ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
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
                value: fc.isAgeFilterEnabled.value,
                onChanged: (val) => fc.isAgeFilterEnabled.value = val,
                activeColor: AppColors.mainColor,
              ),
            ],
          ),
          if (fc.isAgeFilterEnabled.value) ...[
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${fc.tempAgeRange.value.start.round()} ${'years_old'.tr}',
                  style: TextStyle(fontSize: 13, fontFamily: StringConstants.GilroyMedium, color: subTextColor),
                ),
                Text(
                  '${fc.tempAgeRange.value.end.round()} ${'years_old'.tr}',
                  style: TextStyle(fontSize: 13, fontFamily: StringConstants.GilroyMedium, color: subTextColor),
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
                values: fc.tempAgeRange.value,
                min: 0,
                max: 18,
                divisions: 18,
                labels: RangeLabels(
                  '${fc.tempAgeRange.value.start.round()}',
                  '${fc.tempAgeRange.value.end.round()}',
                ),
                onChanged: (v) => fc.tempAgeRange.value = v,
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
              _buildSectionTitle('year_range'.tr, IconlyLight.calendar, textColor),
              Switch(
                value: fc.isYearFilterEnabled.value,
                onChanged: (val) => fc.isYearFilterEnabled.value = val,
                activeColor: AppColors.mainColor,
              ),
            ],
          ),
          if (fc.isYearFilterEnabled.value) ...[
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${fc.tempYearRange.value.start.round()}',
                  style: TextStyle(fontSize: 13, fontFamily: StringConstants.GilroyMedium, color: subTextColor),
                ),
                Text(
                  '${fc.tempYearRange.value.end.round()}',
                  style: TextStyle(fontSize: 13, fontFamily: StringConstants.GilroyMedium, color: subTextColor),
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
                values: fc.tempYearRange.value,
                min: 1300,
                max: currentYear.toDouble(),
                divisions: currentYear - 1300,
                labels: RangeLabels(
                  '${fc.tempYearRange.value.start.round()}',
                  '${fc.tempYearRange.value.end.round()}',
                ),
                onChanged: (v) => fc.tempYearRange.value = v,
              ),
            ),
          ],
        ],
      );
    });
  }
}
