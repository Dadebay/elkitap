import 'dart:convert';
import 'dart:developer';
import 'package:get_storage/get_storage.dart';

/// Mixin for handling audio/text book progress synchronization
/// Manages caching and syncing progress between audio and text versions of books
mixin ProgressSyncMixin {
  final _storage = GetStorage();
  static const String _audioProgressKey = 'audio_progress_';
  static const String _totalPagesKey = 'total_pages_';
  static const String _chapterMappingKey = 'chapter_mapping_';
  static const String _locationsDataKey = 'epub_locations_';
  static const String _chaptersDataKey = 'chapters_data_';

  /// Get unique book ID (must be implemented by the class using this mixin)
  String get uniqueBookId;

  /// Get audio progress for the current book
  double? getAudioProgress() {
    try {
      final key = '$_audioProgressKey$uniqueBookId';
      log('🔍 Looking for audio progress with key: $key');
      log('   uniqueBookId: $uniqueBookId');

      final progress = _storage.read<double>(key);
      log('📻 Raw storage value: $progress (type: ${progress.runtimeType})');

      if (progress != null && progress > 0) {
        log('✅ Audio progress found: ${(progress * 100).toStringAsFixed(1)}%');
        log('   Raw value: $progress');
        return progress;
      } else {
        log('❌ No valid audio progress found (value: $progress)');
      }
      return null;
    } catch (e, st) {
      log('⚠️ Error reading audio progress: $e');
      log('Stack trace: $st');
      return null;
    }
  }

  /// Get cached total pages from storage
  int? getCachedTotalPages() {
    try {
      final key = '$_totalPagesKey$uniqueBookId';
      return _storage.read<int>(key);
    } catch (e) {
      return null;
    }
  }

  /// Cache total pages for future sync
  void cacheTotalPages(int totalPages) {
    try {
      final key = '$_totalPagesKey$uniqueBookId';
      _storage.write(key, totalPages);
      log('┌─────────────────────────────────────────────────────────┐');
      log('│ 💾 CACHED TOTAL PAGES                                   │');
      log('├─────────────────────────────────────────────────────────┤');
      log('│ Total Pages: $totalPages                                │');
      log('│ Book ID:     $uniqueBookId                              │');
      log('└─────────────────────────────────────────────────────────┘');
    } catch (e) {
      log('⚠️ Error caching total pages: $e');
    }
  }

  /// Save text book progress back to audio progress for bidirectional sync
  void saveTextProgressToAudio(int currentPage, int totalPages) {
    try {
      if (totalPages > 0) {
        final textProgress = currentPage / totalPages;
        final key = '$_audioProgressKey$uniqueBookId';
        _storage.write(key, textProgress);
        log('┌─────────────────────────────────────────────────────────┐');
        log('│ 💾 SAVED PROGRESS TO STORAGE                            │');
        log('├─────────────────────────────────────────────────────────┤');
        log('│ Current Page:  $currentPage / $totalPages               │');
        log('│ Progress:      ${(textProgress * 100).toStringAsFixed(1)}%                               │');
        log('│ Book ID:       $uniqueBookId                            │');
        log('│ Raw Value:     $textProgress                            │');
        log('└─────────────────────────────────────────────────────────┘');
      }
    } catch (e, st) {
      log('⚠️ Error saving text progress to audio: $e');
      log('Stack trace: $st');
    }
  }

  /// Calculate target page from audio progress
  int? calculateTargetPageFromAudioProgress(int totalPages) {
    final audioProgress = getAudioProgress();
    if (audioProgress == null || audioProgress <= 0) {
      return null;
    }

    final targetPage = (audioProgress * totalPages).round();
    log('🎯 Calculated target page: $targetPage (${(audioProgress * 100).toStringAsFixed(1)}%)');
    return targetPage;
  }

  /// Check if audio progress should be applied
  bool shouldApplyAudioProgress({
    required int currentPage,
    required int targetPage,
    required int totalPages,
  }) {
    if (totalPages <= 0) return false;
    if (targetPage <= currentPage) return false;

    final currentProgress = currentPage / totalPages;
    final targetProgress = targetPage / totalPages;
    final progressDiff = (targetProgress - currentProgress).abs();

    log('📊 Progress comparison:');
    log('   Current: $currentPage / $totalPages (${(currentProgress * 100).toStringAsFixed(1)}%)');
    log('   Target: $targetPage / $totalPages (${(targetProgress * 100).toStringAsFixed(1)}%)');
    log('   Diff: ${(progressDiff * 100).toStringAsFixed(1)}%');

    // Apply if difference is significant (>5%) or if current page is still at beginning
    return (progressDiff > 0.05 || currentPage < 5);
  }

  /// Cache chapter-to-page mapping
  void cacheChapterMapping(Map<String, int> chapterPages) {
    try {
      final key = '$_chapterMappingKey$uniqueBookId';
      final jsonData = jsonEncode(chapterPages);
      _storage.write(key, jsonData);
      log('💾 Cached chapter mapping: ${chapterPages.length} chapters');
    } catch (e) {
      log('⚠️ Error caching chapter mapping: $e');
    }
  }

  /// Get cached chapter-to-page mapping
  Map<String, int>? getCachedChapterMapping() {
    try {
      final key = '$_chapterMappingKey$uniqueBookId';
      final jsonData = _storage.read<String>(key);
      if (jsonData == null) return null;

      final Map<String, dynamic> decoded = jsonDecode(jsonData);
      final Map<String, int> result = decoded.map(
        (key, value) => MapEntry(key, value as int),
      );

      log('✅ Loaded cached chapter mapping: ${result.length} chapters');
      return result;
    } catch (e) {
      log('⚠️ Error reading cached chapter mapping: $e');
      return null;
    }
  }

  /// Cache chapters metadata (titles and hrefs)
  void cacheChaptersData(List<Map<String, String>> chaptersData) {
    try {
      final key = '$_chaptersDataKey$uniqueBookId';
      final jsonData = jsonEncode(chaptersData);
      _storage.write(key, jsonData);
      log('💾 Cached chapters data: ${chaptersData.length} chapters');
    } catch (e) {
      log('⚠️ Error caching chapters data: $e');
    }
  }

  /// Get cached chapters metadata
  List<Map<String, String>>? getCachedChaptersData() {
    try {
      final key = '$_chaptersDataKey$uniqueBookId';
      final jsonData = _storage.read<String>(key);
      if (jsonData == null) return null;

      final List<dynamic> decoded = jsonDecode(jsonData);
      final List<Map<String, String>> result = decoded.map((item) {
        return (item as Map<String, dynamic>).map(
          (key, value) => MapEntry(key, value.toString()),
        );
      }).toList();

      log('✅ Loaded cached chapters data: ${result.length} chapters');
      return result;
    } catch (e) {
      log('⚠️ Error reading cached chapters data: $e');
      return null;
    }
  }

  /// Cache epub.js locations JSON for fast reopening (font-size-specific)
  void cacheLocationsData(String locationsJson, {int? fontSize}) {
    try {
      // Include font size in cache key since locations are font-size-dependent
      final sizeKey = fontSize != null ? '_fs$fontSize' : '';
      final key = '$_locationsDataKey$uniqueBookId$sizeKey';
      _storage.write(key, locationsJson);
      log('💾 Cached locations data: ${locationsJson.length} chars (fontSize: ${fontSize ?? "unknown"})');
    } catch (e) {
      log('⚠️ Error caching locations data: $e');
    }
  }

  /// Get cached epub.js locations JSON (font-size-specific)
  String? getCachedLocationsData({int? fontSize}) {
    try {
      // Include font size in cache key to ensure we load locations for current font size
      final sizeKey = fontSize != null ? '_fs$fontSize' : '';
      final key = '$_locationsDataKey$uniqueBookId$sizeKey';
      final data = _storage.read<String>(key);
      if (data != null) {
        log('✅ Loaded cached locations data: ${data.length} chars (fontSize: ${fontSize ?? "unknown"})');
      }
      return data;
    } catch (e) {
      log('⚠️ Error reading cached locations data: $e');
      return null;
    }
  }

  /// Clear all cache for this book
  void clearBookCache() {
    try {
      _storage.remove('$_audioProgressKey$uniqueBookId');
      _storage.remove('$_totalPagesKey$uniqueBookId');
      _storage.remove('$_chapterMappingKey$uniqueBookId');
      _storage.remove('$_chaptersDataKey$uniqueBookId');
      _storage.remove('$_locationsDataKey$uniqueBookId');
      log('🗑️ Cleared all cache for book: $uniqueBookId');
    } catch (e) {
      log('⚠️ Error clearing book cache: $e');
    }
  }
}
