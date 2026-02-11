import 'dart:async';
import 'dart:developer';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:just_audio/just_audio.dart';

import 'package:elkitap/data/network/api_edpoints.dart';
import 'package:elkitap/data/network/network_manager.dart';

class AudioPlayerController extends GetxController {
  final AudioPlayer _audioPlayer = AudioPlayer();
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

  // Book data for display
  final RxString currentBookTitle = ''.obs;
  final RxString currentBookAuthor = ''.obs;
  final RxString currentBookCover = ''.obs;
  final RxInt currentBookId = 0.obs;

  Timer? _saveProgressTimer;
  bool _isProgressSaving = false;
  bool _hasRestoredProgress = false;

  @override
  void onInit() {
    super.onInit();
    if (Get.isRegistered<NetworkManager>()) {
      _networkManager = Get.find<NetworkManager>();
    }
    _initAudio();
  }

  Future<void> _initAudio() async {
    try {
      // Don't load any audio at initialization to avoid ExoPlayer errors
      // Audio will be loaded when user plays something

      // Setup stream listeners without loading audio
      _audioPlayer.durationStream.listen((d) {
        if (d != null) {
          duration.value = d;
          if (!_hasRestoredProgress && currentBookId.value != 0) {
            _restoreProgress();
          }
        }
      });

      _audioPlayer.positionStream.listen((p) {
        position.value = p;
        if (isPlaying.value && duration.value.inSeconds > 0) {
          _debouncedSaveProgress();
        }
      });

      _audioPlayer.playerStateStream.listen((state) {
        isPlaying.value = state.playing;
      });
    } catch (e) {
      // Silently handle any initialization errors
      print('🔇 AudioPlayer initialization error (ignored): $e');
    }
  }

  Future<void> loadAudio(String source, bool isAsset) async {
    try {
      if (isAsset) {
        await _audioPlayer.setAsset(source);
      } else {
        await _audioPlayer.setUrl(source);
      }
      audioSource.value = source;
      isAssetAudio.value = isAsset;
    } catch (e) {
      // Silently handle audio loading errors (e.g., invalid format, missing file)
      print('🔇 Audio load error (ignored): $e');
    }
  }

  void loadFromAsset(String assetPath) {
    loadAudio(assetPath, true);
  }

  void loadFromUrl(String url) {
    loadAudio(url, false);
  }

  // Load audio with book information
  Future<void> loadBookAudio({
    required String hlsUrl,
    required String bookTitle,
    required String bookAuthor,
    required String bookCover,
    required int bookId,
    double? initialProgress,
  }) async {
    if (currentBookId.value == bookId && audioSource.value == hlsUrl) {
      return;
    }

    _hasRestoredProgress = false;

    currentBookTitle.value = bookTitle;
    currentBookAuthor.value = bookAuthor;
    currentBookCover.value = bookCover;
    currentBookId.value = bookId;

    await loadAudio(hlsUrl, false);

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
      _audioPlayer.pause();
    } else {
      _audioPlayer.play();
    }
  }

  void seekForward() {
    final newPosition = position.value + const Duration(seconds: 15);
    _audioPlayer.seek(newPosition);
  }

  void seekBackward() {
    final newPosition = position.value - const Duration(seconds: 15);
    _audioPlayer.seek(newPosition > Duration.zero ? newPosition : Duration.zero);
  }

  void seek(Duration position) {
    _audioPlayer.seek(position);
  }

  void changeSpeed() {
    if (playbackSpeed.value == 1.0) {
      playbackSpeed.value = 1.5;
    } else if (playbackSpeed.value == 1.5) {
      playbackSpeed.value = 2.0;
    } else {
      playbackSpeed.value = 1.0;
    }
    _audioPlayer.setSpeed(playbackSpeed.value);
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
      return '$minutes ' + 'minute'.tr + (minutes > 1 ? 's' : '');
    } else {
      if (minutes > 0) {
        return '$hours ' + 'hour_t'.tr + (hours > 1 ? 's' : '') + ', $minutes ' + 'minute'.tr + (minutes > 1 ? 's' : '');
      } else {
        return '$hours ' + 'hour_t'.tr + (hours > 1 ? 's' : '');
      }
    }
  }

  String formatRemainingTime(Duration d) {
    if (d.isNegative) return '00:00';
    return '-${formatDuration(d)}';
  }

  void setSpeed(double speed) {
    playbackSpeed.value = speed;
    _audioPlayer.setSpeed(speed);
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
            'progress': (formattedProgress * 100).toInt(),
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
      _audioPlayer.pause();
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
      await _audioPlayer.pause();
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

  @override
  void onClose() {
    try {
      _audioPlayer.dispose();
      cancelSleepTimer();
      _saveProgressTimer?.cancel();
      _saveProgress();
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
