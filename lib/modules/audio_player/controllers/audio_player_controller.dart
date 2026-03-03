// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:developer';
// ignore: unused_import
import 'dart:io'; // needed for RandomAccessFile header read
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:just_audio/just_audio.dart' show ProcessingState;
import 'package:audio_service/audio_service.dart';

import 'package:elkitap/data/network/api_edpoints.dart';
import 'package:elkitap/data/network/network_manager.dart';
import 'package:elkitap/data/controller/connection_controller.dart';
import 'package:elkitap/modules/audio_player/services/audio_handler.dart';
import 'package:elkitap/modules/library/controllers/downloaded_controller.dart';
import 'package:elkitap/core/config/secure_file_storage_service.dart';
import 'package:elkitap/utils/local_hls_server.dart';
import 'package:elkitap/main.dart' show audioHandler;

class AudioPlayerController extends GetxController {
  // Use the global audioHandler that is registered with iOS Now Playing
  ElkitapAudioHandler get _handler => audioHandler;
  NetworkManager? _networkManager;

  // GetStorage for local persistence
  final _storage = GetStorage();
  static const String _progressKey = 'audio_progress_';

  final Rx<Duration> duration = Duration.zero.obs;
  final Rx<Duration> position = Duration.zero.obs;
  final RxBool isPlaying = false.obs;
  final RxDouble playbackSpeed = 1.0.obs;

  // Sleep timer properties
  final Rxn<Duration> sleepTimerDuration = Rxn<Duration>();
  final Rx<DateTime?> sleepTimerEndTime = Rx<DateTime?>(null);
  final RxString sleepTimerRemaining = ''.obs;
  Timer? _sleepTimer;
  Timer? _countdownTimer;

  final RxBool isDriverMode = false.obs;
  final RxString audioSource = ''.obs;
  final RxBool isAssetAudio = true.obs;
  // true while audio is loading or buffering (hides play button, shows spinner)
  final RxBool isAudioLoading = false.obs;

  // Book data for display
  final RxString currentBookTitle = ''.obs;
  final RxString currentBookAuthor = ''.obs;
  final RxString currentBookCover = ''.obs;
  final RxInt currentBookId = 0.obs;

  /// Local HTTP server for offline HLS playback on iOS.
  /// iOS AVPlayer cannot play file:// HLS manifests — we serve via localhost.
  final LocalHlsServer _hlsServer = LocalHlsServer();

  Timer? _saveProgressTimer;
  bool _isProgressSaving = false;
  bool _hasRestoredProgress = false;

  @override
  void onInit() {
    super.onInit();
    if (Get.isRegistered<NetworkManager>()) {
      _networkManager = Get.find<NetworkManager>();
    }
    _setupListeners();
  }

  void _setupListeners() {
    // Listen to the underlying just_audio player inside our handler
    _handler.player.durationStream.listen((d) {
      if (d != null) {
        duration.value = d;
        if (!_hasRestoredProgress && currentBookId.value != 0) {
          _restoreProgress();
        }
      }
    });

    _handler.player.positionStream.listen((p) {
      position.value = p;
      if (isPlaying.value && duration.value.inSeconds > 0) {
        _debouncedSaveProgress();
      }
    });

    _handler.player.playerStateStream.listen((state) {
      isPlaying.value = state.playing;
      // Show spinner while loading or buffering
      isAudioLoading.value = state.processingState == ProcessingState.loading || state.processingState == ProcessingState.buffering;
    });
  }

  Future<void> loadAudio(String source, bool isAsset, {String? title, String? artist, Uri? artUri}) async {
    try {
      final mediaItem = MediaItem(
        id: source,
        title: title ?? 'Audio',
        artist: artist ?? '',
        artUri: artUri,
        album: 'Elkitap',
      );

      if (isAsset) {
        await _handler.loadAsset(source, mediaItem);
      } else {
        await _handler.loadUrl(source, mediaItem);
      }

      audioSource.value = source;
      isAssetAudio.value = isAsset;

      print('📱 Audio loaded with iOS Now Playing metadata:');
      print('   Title: $title');
      print('   Artist: $artist');
      print('   Art: $artUri');
    } catch (e) {
      print('🔇 Audio load error (ignored): $e');
    }
  }

  void loadFromAsset(String assetPath) {
    loadAudio(assetPath, true);
  }

  void loadFromUrl(String url) {
    loadAudio(url, false);
  }

  Future<void> _loadAudioSource(String hlsUrl, int bookId, {bool forceOffline = false}) async {
    // Decide strategy:
    // - forceOffline=true  → always play local file (opened from DownloadedListScreen)
    // - hasConnection=false → no internet, must play local file
    // - otherwise          → stream HLS online
    final hasInternet = Get.isRegistered<ConnectionController>() ? Get.find<ConnectionController>().hasConnection.value : true;

    final useOffline = forceOffline || !hasInternet;

    if (useOffline) {
      // Try local file first
      try {
        if (Get.isRegistered<DownloadController>()) {
          final downloadCtrl = Get.find<DownloadController>();
          final downloadedBook = downloadCtrl.downloadedBooks.firstWhereOrNull(
            (book) => book.id == bookId.toString() && book.isAudio,
          );

          if (downloadedBook != null) {
            // Prefer encryptedPath directly (new format: path to index.m3u8 inside a dir).
            // Fall back to getRawAudioFile for backward-compat with old single-file downloads.
            File? localFile;
            if (downloadedBook.encryptedPath.isNotEmpty) {
              final candidate = File(downloadedBook.encryptedPath);
              if (await candidate.exists()) localFile = candidate;
            }
            if (localFile == null) {
              // backward-compat fallback for old .aac single-file downloads
              final storageService = Get.find<SecureFileStorageService>();
              localFile = await storageService.getRawAudioFile(downloadedBook.fileName);
            }

            if (localFile != null && await localFile.exists()) {
              log('🎵 Local file: ${localFile.path}');
              log('🎵 Is local HLS: ${localFile.path.endsWith('.m3u8')}');

              String playUrl = localFile.path;
              // iOS AVPlayer cannot open HLS from file:// — serve via localhost
              if (localFile.path.endsWith('.m3u8')) {
                final dir = localFile.parent.path;
                final baseUrl = await _hlsServer.start(dir);
                playUrl = '$baseUrl/index.m3u8';
                log('🎵 Serving local HLS via: $playUrl');
              } else {
                // Stop server if it was running for a previous book
                await _hlsServer.stop();
              }

              await loadAudio(
                playUrl,
                false,
                title: currentBookTitle.value,
                artist: currentBookAuthor.value,
                artUri: currentBookCover.value.isNotEmpty ? Uri.parse(currentBookCover.value) : null,
              );
              return;
            }
          }
        }
      } catch (e) {
        log('⚠️ Error loading local audio: $e');
      }

      // If forceOffline but no local file found, show error
      if (forceOffline) {
        log('❌ forceOffline=true but no local file found for bookId=$bookId');
        return;
      }
    }

    // Online: stream HLS — stop local server if it was running
    await _hlsServer.stop();
    log('🎵 Playing from HLS URL (online streaming): $hlsUrl');
    await loadAudio(
      hlsUrl,
      false,
      title: currentBookTitle.value,
      artist: currentBookAuthor.value,
      artUri: currentBookCover.value.isNotEmpty ? Uri.parse(currentBookCover.value) : null,
    );
  }

  // Load audio with book information
  Future<void> loadBookAudio({
    required String hlsUrl,
    required String bookTitle,
    required String bookAuthor,
    required String bookCover,
    required int bookId,
    double? initialProgress,
    bool forceOffline = false,
  }) async {
    // Skip reload only when same book AND same playback mode.
    // Note: local HLS is served via http://localhost, so we check for that too.
    final src = audioSource.value;
    final isCurrentlyLocal = src.isNotEmpty && (!src.startsWith('http') || src.startsWith('http://localhost'));
    final alreadyLoaded = currentBookId.value == bookId && src.isNotEmpty && forceOffline == isCurrentlyLocal;
    if (alreadyLoaded) {
      log('⏭️ Skipping reload — same book, same mode (forceOffline=$forceOffline, local=$isCurrentlyLocal)');
      return;
    }

    _hasRestoredProgress = false;

    currentBookTitle.value = bookTitle;
    currentBookAuthor.value = bookAuthor;
    currentBookCover.value = bookCover;
    currentBookId.value = bookId;

    await _loadAudioSource(hlsUrl, bookId, forceOffline: forceOffline);

    final savedProgress = _getLocalProgress(bookId);

    if (savedProgress != null && savedProgress > 0) {
      await Future.delayed(const Duration(milliseconds: 500));

      if (duration.value.inSeconds > 0) {
        final seekSeconds = (duration.value.inSeconds * savedProgress).floor();
        seek(Duration(seconds: seekSeconds));
        _hasRestoredProgress = true;
      }
    } else if (initialProgress != null && initialProgress > 0) {
      await Future.delayed(const Duration(milliseconds: 500));
      if (duration.value.inSeconds > 0) {
        final seekSeconds = (duration.value.inSeconds * initialProgress).floor();
        seek(Duration(seconds: seekSeconds));
        _hasRestoredProgress = true;
      }
    }
  }

  void playPause() {
    if (isPlaying.value) {
      _handler.pause();
    } else {
      _handler.play();
    }
  }

  void seekForward() {
    _handler.skipToNext(); // mapped to +15s in handler
  }

  void seekBackward() {
    _handler.skipToPrevious(); // mapped to -15s in handler
  }

  void seek(Duration position) {
    _handler.seek(position);
  }

  void changeSpeed() {
    if (playbackSpeed.value == 1.0) {
      playbackSpeed.value = 1.5;
    } else if (playbackSpeed.value == 1.5) {
      playbackSpeed.value = 2.0;
    } else {
      playbackSpeed.value = 1.0;
    }
    _handler.setSpeed(playbackSpeed.value);
  }

  String formatDuration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    final seconds = d.inSeconds.remainder(60);

    if (hours == 0) {
      final m = minutes.toString().padLeft(2, '0');
      final s = seconds.toString().padLeft(2, '0');
      return '$m:$s';
    } else {
      final h = hours.toString();
      final m = minutes.toString().padLeft(2, '0');
      final s = seconds.toString().padLeft(2, '0');
      return '$h:$m:$s';
    }
  }

  String formatFullDuration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);

    if (hours == 0) {
      return '$minutes ${'minute_full'.tr}';
    } else {
      if (minutes > 0) {
        return '$hours ${'hour_full'.tr}  $minutes ${'minute_full'.tr}';
      } else {
        return '$hours ${'hour_full'.tr}';
      }
    }
  }

  String formatRemainingTime(Duration d) {
    if (d.isNegative) return '00:00';
    return '-${formatDuration(d)}';
  }

  void setSpeed(double speed) {
    playbackSpeed.value = speed;
    _handler.setSpeed(speed);
  }

  void _debouncedSaveProgress() {
    _saveProgressTimer?.cancel();
    _saveProgressTimer = Timer(const Duration(seconds: 5), () {
      _saveProgress();
    });
  }

  void _saveLocalProgress(int bookId, double progress) {
    try {
      final key = '$_progressKey$bookId';
      _storage.write(key, progress);

      // Also save with generic key for CurrentBookSection
      final progressPercentage = (progress * 100).toStringAsFixed(1);
      _storage.write('book_${bookId}_progress', progressPercentage);

      print('💾 Audio progress saved locally:');
      print('   Book ID: $bookId');
      print('   Key: $key');
      print('   Progress: ${progressPercentage}%');
    } catch (e) {
      print('⚠️ Error saving local audio progress: $e');
    }
  }

  double? _getLocalProgress(int bookId) {
    try {
      final key = '$_progressKey$bookId';
      final progress = _storage.read<double>(key);
      return progress;
    } catch (e) {
      return null;
    }
  }

  void _restoreProgress() {
    if (_hasRestoredProgress || currentBookId.value == 0) return;

    final savedProgress = _getLocalProgress(currentBookId.value);

    if (savedProgress != null && savedProgress > 0 && duration.value.inSeconds > 0) {
      final seekSeconds = (duration.value.inSeconds * savedProgress).floor();

      // Only seek if we're not already at that position
      if ((position.value.inSeconds - seekSeconds).abs() > 5) {
        seek(Duration(seconds: seekSeconds));
      }

      _hasRestoredProgress = true;
    }
  }

  Future<void> _saveProgress() async {
    if (currentBookId.value == 0 || duration.value.inSeconds == 0) {
      return;
    }

    if (_isProgressSaving) return;

    try {
      _isProgressSaving = true;
      final progress = position.value.inMilliseconds / duration.value.inMilliseconds;
      final formattedProgress = double.parse(progress.toStringAsFixed(3));

      print('🎵 Saving audio progress:');
      print('   Book ID: ${currentBookId.value}');
      print('   Position: ${position.value.inMinutes}:${position.value.inSeconds.remainder(60).toString().padLeft(2, '0')}');
      print('   Duration: ${duration.value.inMinutes}:${duration.value.inSeconds.remainder(60).toString().padLeft(2, '0')}');
      print('   Progress: ${(formattedProgress * 100).toStringAsFixed(1)}%');

      _saveLocalProgress(currentBookId.value, formattedProgress);

      if (_networkManager != null) {
        log("✅ Cosmos save backend success %% $formattedProgress");
        final response = await _networkManager!.post(
          ApiEndpoints.bookProgress(currentBookId.value),
          body: {
            'progress': formattedProgress,
          },
          sendToken: true,
        );

        if (response['success'] == true) {
          print('✅ Progress saved to API successfully');

          // Save progress to local storage for CurrentBookSection
          final progressPercentage = (formattedProgress * 100).toStringAsFixed(1);
          _storage.write('book_${currentBookId.value}_progress', progressPercentage);
          print('💾 Saved progress to local storage: $progressPercentage%');
        } else {
          print('⚠️ Failed to save progress to API: ${response['error']}');
        }
      }
    } catch (e) {
      print('⚠️ Error saving audio progress: $e');
    } finally {
      _isProgressSaving = false;
    }
  }

  void clearProgress(int bookId) {
    try {
      final key = '$_progressKey$bookId';
      _storage.remove(key);
    } catch (e) {}
  }

  // Sleep timer methods
  void setSleepTimer(Duration? duration) {
    cancelSleepTimer();

    if (duration == null) {
      sleepTimerDuration.value = null;
      sleepTimerEndTime.value = null;
      sleepTimerRemaining.value = '';
      return;
    }

    sleepTimerDuration.value = duration;
    sleepTimerEndTime.value = DateTime.now().add(duration);
    sleepTimerRemaining.value = getRemainingTime();

    _sleepTimer = Timer(duration, () {
      _handler.pause();
      sleepTimerDuration.value = null;
      sleepTimerEndTime.value = null;
      sleepTimerRemaining.value = '';
      _countdownTimer?.cancel();
    });

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (sleepTimerEndTime.value == null) {
        timer.cancel();
        return;
      }
      sleepTimerRemaining.value = getRemainingTime();
    });
  }

  void cancelSleepTimer() {
    _sleepTimer?.cancel();
    _countdownTimer?.cancel();
    sleepTimerDuration.value = null;
    sleepTimerEndTime.value = null;
    sleepTimerRemaining.value = '';
  }

  String getRemainingTime() {
    if (sleepTimerEndTime.value == null) return '';

    final remaining = sleepTimerEndTime.value!.difference(DateTime.now());
    if (remaining.isNegative) return '0:00';

    final minutes = remaining.inMinutes;
    final seconds = remaining.inSeconds.remainder(60);
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  void toggleDriverMode() {
    isDriverMode.value = !isDriverMode.value;
  }

  void enableDriverMode() {
    isDriverMode.value = true;
  }

  void disableDriverMode() {
    isDriverMode.value = false;
  }

  Future<void> stopAudio() async {
    try {
      await _handler.pause();
      isPlaying.value = false;

      // Safely hide mini player
      try {
        if (Get.isRegistered<GlobalMiniPlayerController>()) {
          Get.find<GlobalMiniPlayerController>().hide();
        }
      } catch (_) {
        // Controller might be disposed
      }
    } catch (e) {
      log('Error stopping audio: $e');
    }
  }

  /// Completely clears the audio from iOS Now Playing / lock screen.
  /// Use this when navigating away from audio (e.g. switching to text reader).
  Future<void> clearAudio() async {
    try {
      // stop() calls super.stop() which removes the iOS Now Playing entry
      await _handler.stop();
      isPlaying.value = false;

      // Clear mediaItem so iOS lock screen / control center disappear
      _handler.mediaItem.add(null);

      // Reset book info so the mini player has nothing to show
      audioSource.value = '';
      currentBookId.value = 0;
      currentBookTitle.value = '';
      currentBookAuthor.value = '';
      currentBookCover.value = '';
      _hasRestoredProgress = false;

      // Stop local HLS server if running
      await _hlsServer.stop();

      // Hide mini player
      try {
        if (Get.isRegistered<GlobalMiniPlayerController>()) {
          Get.find<GlobalMiniPlayerController>().hide();
        }
      } catch (_) {}
    } catch (e) {
      log('Error clearing audio: $e');
    }
  }

  @override
  void onClose() {
    try {
      // Do NOT dispose the handler here — it lives for the app lifetime
      cancelSleepTimer();
      _saveProgressTimer?.cancel();
      _saveProgress();
      _hlsServer.stop();
    } catch (e) {
      log('Error in onClose: $e');
    }
    super.onClose();
  }
}

class GlobalMiniPlayerController extends GetxController {
  final RxBool isVisible = false.obs;
  final RxDouble top = 0.0.obs;
  final RxDouble left = 0.0.obs;

  void show() => isVisible.value = true;
  void hide() => isVisible.value = false;
  void toggle() => isVisible.value = !isVisible.value;

  void setPosition(double newTop, double newLeft) {
    top.value = newTop;
    left.value = newLeft;
  }
}
