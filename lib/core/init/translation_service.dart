
import 'package:get/get.dart';
import 'package:flutter/material.dart';

// Import the separated translation files
import 'translations/en_us.dart';
import 'translations/tr_tr.dart';
import 'translations/ru_ru.dart';

class TranslationService extends Translations {
  static final locale = Locale('tr', 'TR');
  static final fallbackLocale = Locale('tr', 'TR');

  static final langs = ['Türkmençe', 'English', 'Русский'];
  static final locales = [
    Locale('tr', 'TR'),
    Locale('en', 'US'),
    Locale('ru', 'RU'),
  ];

  @override
  Map<String, Map<String, String>> get keys => {
        'tr_TR': trTR,
        'en_US': enUS,
        'ru_RU': ruRU,
      };

  void changeLocale(String lang) {
    final locale = _getLocaleFromLanguage(lang);

    // Defer the locale update to avoid setState() during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.updateLocale(locale);
      
    });
  }

  Locale _getLocaleFromLanguage(String lang) {
    for (int i = 0; i < langs.length; i++) {
      if (lang == langs[i]) return locales[i];
    }
    return Get.locale ?? fallbackLocale;
  }
}
