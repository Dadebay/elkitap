import 'dart:developer';

import 'package:elkitap/data/network/api_edpoints.dart';
import 'package:elkitap/data/network/network_manager.dart';
import 'package:elkitap/modules/search/models/authors_model.dart';
import 'package:elkitap/modules/store/model/geners_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// A language entry from /book-languages API.
/// [name] is a map with locale keys: 'tk', 'ru', 'en'.
class BookLanguage {
  final int id;
  final Map<String, String> name;

  const BookLanguage({required this.id, required this.name});

  factory BookLanguage.fromJson(Map<String, dynamic> json) {
    final rawName = json['name'] as Map<String, dynamic>? ?? {};
    return BookLanguage(
      id: json['id'] as int,
      name: rawName.map((k, v) => MapEntry(k, v?.toString() ?? '')),
    );
  }

  /// Returns the display name for the given locale code (tk/ru/en).
  /// Falls back: requested → tk → en → first available.
  String localizedName(String localeCode) {
    return name[localeCode] ?? name['tk'] ?? name['en'] ?? name.values.first;
  }
}

class FilterController extends GetxController {
  final NetworkManager _networkManager = Get.find<NetworkManager>();

  // ---- Filter state ----

  /// Selected language id (null = all)
  final RxnInt selectedLanguageId = RxnInt(null);

  /// Selected author IDs
  final RxList<int> selectedAuthorIds = <int>[].obs;

  /// Selected genre IDs
  final RxList<int> selectedGenreIds = <int>[].obs;

  /// Age range
  final RxnInt minAge = RxnInt(null);
  final RxnInt maxAge = RxnInt(null);

  /// Year range
  final RxnInt startYear = RxnInt(null);
  final RxnInt endYear = RxnInt(null);

  // ---- Data lists ----
  final RxList<Author> allAuthors = <Author>[].obs;
  final RxBool isLoadingAuthors = false.obs;
  final RxInt authorPage = 1.obs;
  final RxBool hasMoreAuthors = true.obs;
  final TextEditingController authorSearchController = TextEditingController();
  final RxString authorSearchQuery = ''.obs;

  /// Cache of authors that have been selected — survives allAuthors.clear()
  final Map<int, Author> _authorCache = {};

  final RxList<Genre> allGenres = <Genre>[].obs;
  final RxBool isLoadingGenres = false.obs;

  // ---- Temp state (used inside bottom sheet before "Apply") ----
  final RxnInt tempLanguageId = RxnInt(null);
  final RxList<int> tempAuthorIds = <int>[].obs;
  final RxList<int> tempGenreIds = <int>[].obs;
  final Rx<RangeValues> tempAgeRange = Rx<RangeValues>(const RangeValues(0, 18));
  final Rx<RangeValues> tempYearRange = Rx<RangeValues>(RangeValues(1300, DateTime.now().year.toDouble()));
  final RxBool isAgeFilterEnabled = false.obs;
  final RxBool isYearFilterEnabled = false.obs;

  /// Format: 'all' | 'text' | 'audio'
  final RxString selectedFormat = 'all'.obs;
  final RxString tempFormat = 'all'.obs;

  /// Fetched from /book-languages
  final RxList<BookLanguage> languages = <BookLanguage>[].obs;
  final RxBool isLoadingLanguages = false.obs;

  @override
  void onInit() {
    super.onInit();
    _initTempFromCurrent();
    fetchGenresForFilter();
    fetchLanguagesForFilter();
  }

  @override
  void onClose() {
    authorSearchController.dispose();
    super.onClose();
  }

  /// Copy current applied filters into temp state (for bottom sheet editing)
  void _initTempFromCurrent() {
    tempLanguageId.value = selectedLanguageId.value;
    tempAuthorIds.assignAll(selectedAuthorIds);
    tempGenreIds.assignAll(selectedGenreIds);
    tempFormat.value = selectedFormat.value;

    if (minAge.value != null && maxAge.value != null) {
      isAgeFilterEnabled.value = true;
      tempAgeRange.value = RangeValues(
        minAge.value!.toDouble(),
        maxAge.value!.toDouble(),
      );
    } else {
      isAgeFilterEnabled.value = false;
      tempAgeRange.value = const RangeValues(0, 18);
    }

    if (startYear.value != null && endYear.value != null) {
      isYearFilterEnabled.value = true;
      tempYearRange.value = RangeValues(
        startYear.value!.toDouble(),
        endYear.value!.toDouble(),
      );
    } else {
      isYearFilterEnabled.value = false;
      tempYearRange.value = RangeValues(1300, DateTime.now().year.toDouble());
    }
  }

  /// Called when bottom sheet opens
  void resetTempToApplied() {
    _initTempFromCurrent();
    authorSearchController.clear();
    authorSearchQuery.value = '';
    if (allGenres.isEmpty) fetchGenresForFilter();
    if (languages.isEmpty) fetchLanguagesForFilter();
  }

  /// Apply temp filters to the real filter state
  void applyFilters() {
    selectedLanguageId.value = tempLanguageId.value;
    selectedAuthorIds.assignAll(tempAuthorIds);
    selectedGenreIds.assignAll(tempGenreIds);
    selectedFormat.value = tempFormat.value;

    if (isAgeFilterEnabled.value) {
      minAge.value = tempAgeRange.value.start.round();
      maxAge.value = tempAgeRange.value.end.round();
    } else {
      minAge.value = null;
      maxAge.value = null;
    }

    if (isYearFilterEnabled.value) {
      startYear.value = tempYearRange.value.start.round();
      endYear.value = tempYearRange.value.end.round();
    } else {
      startYear.value = null;
      endYear.value = null;
    }
  }

  /// Clear all filters
  void clearAllFilters() {
    selectedLanguageId.value = null;
    selectedAuthorIds.clear();
    selectedGenreIds.clear();
    selectedFormat.value = 'all';
    minAge.value = null;
    maxAge.value = null;
    startYear.value = null;
    endYear.value = null;

    _initTempFromCurrent();
  }

  /// Clear temp filters (inside bottom sheet)
  void clearTempFilters() {
    tempLanguageId.value = null;
    tempAuthorIds.clear();
    _authorCache.clear();
    tempGenreIds.clear();
    tempFormat.value = 'all';
    isAgeFilterEnabled.value = false;
    isYearFilterEnabled.value = false;
    tempAgeRange.value = const RangeValues(0, 18);
    tempYearRange.value = RangeValues(1300, DateTime.now().year.toDouble());
  }

  /// Build query parameters map for API call
  Map<String, String> buildFilterParams() {
    final Map<String, String> params = {};

    if (selectedLanguageId.value != null) {
      params['language_id'] = selectedLanguageId.value.toString();
    }

    if (selectedAuthorIds.isNotEmpty) {
      params['authors'] = selectedAuthorIds.join(',');
    }

    if (selectedGenreIds.isNotEmpty) {
      params['genres'] = selectedGenreIds.join(',');
    }

    if (selectedFormat.value == 'audio') {
      params['with_audio'] = 'true';
    } else if (selectedFormat.value == 'text') {
      params['with_audio'] = 'false';
    }

    if (minAge.value != null) {
      params['min_age'] = minAge.value.toString();
    }

    if (maxAge.value != null) {
      params['max_age'] = maxAge.value.toString();
    }

    if (startYear.value != null) {
      params['start_year'] = startYear.value.toString();
    }

    if (endYear.value != null) {
      params['end_year'] = endYear.value.toString();
    }

    log('🔧 [buildFilterParams] result: $params');
    log('🔧 [buildFilterParams] raw selectedGenreIds: $selectedGenreIds');
    log('🔧 [buildFilterParams] raw selectedAuthorIds: $selectedAuthorIds');
    log('🔧 [buildFilterParams] selectedLanguageId: ${selectedLanguageId.value}');
    log('🔧 [buildFilterParams] selectedFormat: ${selectedFormat.value}');

    return params;
  }

  /// Count of active filters
  int get activeFilterCount {
    int count = 0;
    if (selectedLanguageId.value != null) count++;
    if (selectedAuthorIds.isNotEmpty) count++;
    if (selectedGenreIds.isNotEmpty) count++;
    if (selectedFormat.value != 'all') count++;
    if (minAge.value != null || maxAge.value != null) count++;
    if (startYear.value != null || endYear.value != null) count++;
    return count;
  }

  bool get hasActiveFilters => activeFilterCount > 0;

  // ---- Author search for filter ----

  Future<void> searchAuthorsForFilter(String query) async {
    log('🔍 [AuthorSearch] query: "$query"');
    if (query.trim().isEmpty) {
      allAuthors.clear();
      log('🔍 [AuthorSearch] empty query → cleared');
      return;
    }

    try {
      isLoadingAuthors.value = true;
      authorPage.value = 1;

      log('🔍 [AuthorSearch] endpoint: ${ApiEndpoints.searchAuthors}');

      final response = await _networkManager.get(
        ApiEndpoints.searchAuthors,
        sendToken: true,
        // languageOverride: 'tk',
        queryParameters: {
          'search': query,
          'page': '1',
          'size': '20',
        },
      );

      log('🔍 [AuthorSearch] response keys: ${response.keys.toList()}');
      log('🔍 [AuthorSearch] success: ${response['success']}');
      log('🔍 [AuthorSearch] data type: ${response['data']?.runtimeType}');
      log('🔍 [AuthorSearch] data: ${response['data']}');

      if (response['success'] == true) {
        final data = response['data'];
        if (data != null && data is List) {
          log('🔍 [AuthorSearch] data is List, count: ${data.length}');
          allAuthors.assignAll(
            data.map((json) => Author.fromJson(json)).toList(),
          );
        } else if (data != null && data is Map<String, dynamic>) {
          final List<dynamic> items = data['items'] ?? data['results'] ?? data['authors'] ?? [];
          log('🔍 [AuthorSearch] data is Map, items count: ${items.length}, map keys: ${data.keys.toList()}');
          allAuthors.assignAll(
            items.map((json) => Author.fromJson(json)).toList(),
          );
        } else {
          log('🔍 [AuthorSearch] data is null or unknown type: ${data?.runtimeType}');
        }
      } else {
        log('🔍 [AuthorSearch] success=false, full response: $response');
      }
      log('🔍 [AuthorSearch] allAuthors.length after parse: ${allAuthors.length}');
    } catch (e, st) {
      log('❌ [AuthorSearch] ERROR: $e', error: e, stackTrace: st);
    } finally {
      isLoadingAuthors.value = false;
    }
  }

  // ---- Language fetch for filter ----

  Future<void> fetchLanguagesForFilter() async {
    try {
      isLoadingLanguages.value = true;
      final response = await _networkManager.get(
        ApiEndpoints.bookLanguages,
        sendToken: false,
      );
      if (response['success']) {
        final List<dynamic> data = response['data'] ?? [];
        languages.assignAll(
          data.map((j) => BookLanguage.fromJson(j as Map<String, dynamic>)).toList(),
        );
      }
    } catch (_) {
      // Silently fail
    } finally {
      isLoadingLanguages.value = false;
    }
  }

  // ---- Genre fetch for filter ----

  Future<void> fetchGenresForFilter() async {
    try {
      isLoadingGenres.value = true;
      final response = await _networkManager.get(
        '${ApiEndpoints.geners}?parent_id=',
        sendToken: true,
      );
      if (response['success']) {
        final List<dynamic> data = response['data'] ?? [];
        allGenres.assignAll(data.map((j) => Genre.fromJson(j)).toList());
      }
    } catch (_) {
      // Silently fail
    } finally {
      isLoadingGenres.value = false;
    }
  }

  /// Toggle genre selection in temp state
  void toggleGenre(int genreId) {
    if (tempGenreIds.contains(genreId)) {
      tempGenreIds.remove(genreId);
    } else {
      tempGenreIds.add(genreId);
    }
  }

  /// Toggle author selection in temp state
  void toggleAuthor(int authorId) {
    if (tempAuthorIds.contains(authorId)) {
      tempAuthorIds.remove(authorId);
    } else {
      // Cache the Author object so we can show the name even after allAuthors is cleared
      final author = allAuthors.firstWhereOrNull((a) => a.id == authorId);
      if (author != null) _authorCache[authorId] = author;
      tempAuthorIds.add(authorId);
    }
  }

  /// Returns the display name for a selected author id, using cache as fallback.
  String authorDisplayName(int id) {
    final author = allAuthors.firstWhereOrNull((a) => a.id == id) ?? _authorCache[id];
    return author?.name ?? 'ID: $id';
  }

  /// Returns the current app locale key (tk / ru / en).
  String get _localeCode {
    final code = Get.locale?.languageCode ?? 'tk';
    // App uses 'tr' internally for Turkmen — map to API key 'tk'
    return code == 'tr' ? 'tk' : code;
  }

  /// Locale-aware display name for a BookLanguage.
  String languageDisplayName(BookLanguage lang) => lang.localizedName(_localeCode);

  /// Get the display name of the currently selected language.
  String? getSelectedLanguageName() {
    if (selectedLanguageId.value == null) return null;
    final lang = languages.firstWhereOrNull((l) => l.id == selectedLanguageId.value);
    return lang != null ? languageDisplayName(lang) : null;
  }
}
