import 'dart:ui';
import 'package:elkitap/core/constants/string_constants.dart';
import 'package:elkitap/core/init/translation_service.dart';
import 'package:elkitap/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class LanguageSelector extends StatefulWidget {
  const LanguageSelector({super.key});

  @override
  State<LanguageSelector> createState() => _LanguageSelectorState();
}

class _LanguageSelectorState extends State<LanguageSelector> {
  final _box = GetStorage();
  final _languageKey = 'selectedLanguage';
  String selectedLanguage = 'turkmen'.tr;

  final List<String> _languages = ['Türkmençe', 'Русский', 'English'];

  @override
  void initState() {
    super.initState();
    _loadSelectedLanguage();
  }

  void _saveSelectedLanguage(String lang) {
    _box.write('selectedLanguage', lang);
  }

  void _loadSelectedLanguage() {
    final storedLanguage = _box.read('selectedLanguage');
    if (storedLanguage != null) {
      setState(() {
        selectedLanguage = storedLanguage;
      });

      // Apply locale immediately when app opens
      final TranslationService translationService = Get.find<TranslationService>();
      translationService.changeLocale(storedLanguage);
    } else {
      _saveSelectedLanguage(selectedLanguage);
    }
  }

  void _showLanguageMenu(BuildContext context) async {
    final selected = await showDialog<String>(
      context: context,
      barrierColor: Colors.transparent,
      builder: (context) {
        return Stack(
          children: [
            Positioned(
              top: 60,
              left: 0,
              right: 0,
              child: Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                    child: Container(
                      width: 160,
                      color: Colors.grey[100],
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: _languages.map((lang) {
                          final isSelected = lang == selectedLanguage;
                          return Column(
                            children: [
                              GestureDetector(
                                onTap: () {
                                  Navigator.pop(context, lang);
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 18),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        lang,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontFamily: StringConstants.SFPro,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.black,
                                        ),
                                      ),
                                      if (isSelected) const Icon(Icons.check, size: 18, color: Colors.black),
                                    ],
                                  ),
                                ),
                              ),
                              if (lang != _languages.last) Divider(color: AppColors.dividerColor)
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );

    if (selected != null) {
      setState(() {
        selectedLanguage = selected;
      });
      _saveSelectedLanguage(selected);
      final TranslationService translationService = Get.find<TranslationService>();
      translationService.changeLocale(selected);
      _box.write(_languageKey, selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showLanguageMenu(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF2F2F7),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.language, size: 20),
            const SizedBox(width: 6),
            Text(
              selectedLanguage,
              style: const TextStyle(
                fontSize: 15,
                fontFamily: StringConstants.SFPro,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
