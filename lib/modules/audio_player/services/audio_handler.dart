// ignore_for_file: avoid_print

import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

/// AudioHandler - connects just_audio to iOS Now Playing system
/// This registers our audiobook player with iOS Control Center,
/// Lock Screen, and all system media controls.
class ElkitapAudioHandler extends BaseAudioHandler with QueueHandler, SeekHandler {
  final AudioPlayer _player = AudioPlayer();

  AudioPlayer get player => _player;

  ElkitapAudioHandler() {
    _player.playbackEventStream.map(_transformEvent).pipe(playbackState);

    _player.durationStream.listen((duration) {
      final current = mediaItem.value;
      if (current != null && duration != null) {
        mediaItem.add(current.copyWith(duration: duration));
      }
    });
  }

  PlaybackState _transformEvent(PlaybackEvent event) {
    return PlaybackState(
      controls: [
        MediaControl.skipToPrevious,
        if (_player.playing) MediaControl.pause else MediaControl.play,
        MediaControl.skipToNext,
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
      },
      androidCompactActionIndices: const [0, 1, 2],
      processingState: const {
        ProcessingState.idle: AudioProcessingState.idle,
        ProcessingState.loading: AudioProcessingState.loading,
        ProcessingState.buffering: AudioProcessingState.buffering,
        ProcessingState.ready: AudioProcessingState.ready,
        ProcessingState.completed: AudioProcessingState.completed,
      }[_player.processingState]!,
      playing: _player.playing,
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
      queueIndex: event.currentIndex,
    );
  }

  Future<void> loadUrl(String url, MediaItem item) async {
    mediaItem.add(item);
    await _player.setAudioSource(
      AudioSource.uri(Uri.parse(url), tag: item),
    );
  }

  Future<void> loadAsset(String assetPath, MediaItem item) async {
    mediaItem.add(item);
    await _player.setAudioSource(
      AudioSource.asset(assetPath, tag: item),
    );
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> stop() async {
    await _player.stop();
    await super.stop();
  }

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> skipToNext() async {
    await _player.seek(_player.position + const Duration(seconds: 15));
  }

  @override
  Future<void> skipToPrevious() async {
    final newPos = _player.position - const Duration(seconds: 15);
    await _player.seek(newPos > Duration.zero ? newPos : Duration.zero);
  }

  @override
  Future<void> setSpeed(double speed) async {
    await _player.setSpeed(speed);
    playbackState.add(playbackState.value.copyWith(speed: speed));
  }

  void dispose() {
    _player.dispose();
  }
}
