import 'dart:developer';
import 'package:get_storage/get_storage.dart';

/// Mixin for handling audio/text book progress synchronization
/// Manages caching and syncing progress between audio and text versions of books
mixin ProgressSyncMixin {
  final _storage = GetStorage();
  static const String _audioProgressKey = 'audio_progress_';
  static const String _totalPagesKey = 'total_pages_';

  /// Get unique book ID (must be implemented by the class using this mixin)
  String get uniqueBookId;

  /// Get audio progress for the current book
  double? getAudioProgress() {
    try {
      final key = '$_audioProgressKey$uniqueBookId';
      log('🔍 Looking for audio progress with key: $key');

      final progress = _storage.read<double>(key);
      log('📻 Raw storage value: $progress (type: ${progress.runtimeType})');

      if (progress != null && progress > 0) {
        log('✅ Audio progress found: ${(progress * 100).toStringAsFixed(1)}%');
        return progress;
      } else {
        log('❌ No valid audio progress found (value: $progress)');
      }
      return null;
    } catch (e) {
      log('⚠️ Error reading audio progress: $e');
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
      log('💾 Cached total pages: $totalPages');
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
        log('💾 Saved progress to audio storage:');
        log('   Key: $key');
        log('   Page: $currentPage / $totalPages');
        log('   Progress: ${(textProgress * 100).toStringAsFixed(1)}%');
      }
    } catch (e) {
      log('⚠️ Error saving text progress to audio: $e');
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
}
