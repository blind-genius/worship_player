import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import '../../data/models/worship_item.dart';

/// هندلر اختصاصی پخش صوت بر پایه audio_service و just_audio
class WorshipAudioHandler extends BaseAudioHandler with SeekHandler {
  final AudioPlayer _player = AudioPlayer();

  List<WorshipItem> _playlist = [];
  int _currentIndex = -1;

  // کال‌بک در زمان اتمام یک قطعه جهت اطلاع به UI یا پلی‌لیست
  void Function(int nextIndex)? onTrackChanged;

  WorshipAudioHandler() {
    _initAudioStreams();
  }

  AudioPlayer get player => _player;
  List<WorshipItem> get playlist => _playlist;
  int get currentIndex => _currentIndex;
  WorshipItem? get currentItem =>
      (_currentIndex >= 0 && _currentIndex < _playlist.length) ? _playlist[_currentIndex] : null;

  void _initAudioStreams() {
    // ۱. پخش استیت پلیر به audio_service جهت نمایش در اعلان اندروید
    _player.playbackEventStream.listen((PlaybackEvent event) {
      final playing = _player.playing;
      playbackState.add(
        playbackState.value.copyWith(
          controls: [
            MediaControl.skipToPrevious,
            if (playing) MediaControl.pause else MediaControl.play,
            MediaControl.skipToNext,
            MediaControl.stop,
          ],
          systemActions: const {
            MediaAction.seek,
            MediaAction.seekForward,
            MediaAction.seekBackward,
            MediaAction.setSpeed,
          },
          androidCompactActionIndices: const [0, 1, 2],
          processingState: const {
            ProcessingState.idle: AudioProcessingState.idle,
            ProcessingState.loading: AudioProcessingState.loading,
            ProcessingState.buffering: AudioProcessingState.buffering,
            ProcessingState.ready: AudioProcessingState.ready,
            ProcessingState.completed: AudioProcessingState.completed,
          }[_player.processingState]!,
          playing: playing,
          updatePosition: _player.position,
          bufferedPosition: _player.bufferedPosition,
          speed: _player.speed,
          queueIndex: _currentIndex,
        ),
      );
    });

    // ۲. اتصال مدت زمان کل به مدیا آیتم
    _player.durationStream.listen((duration) {
      if (mediaItem.value != null && duration != null) {
        mediaItem.add(mediaItem.value!.copyWith(duration: duration));
      }
    });

    // ۳. پخش خودکار قطعه بعدی هنگام اتمام قطعه جاری
    _player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        skipToNext();
      }
    });
  }

  /// تنظیم پلی‌لیست فعال
  void setPlaylist(List<WorshipItem> items) {
    _playlist = List.from(items);
  }

  /// پخش یک آیتم مشخص از لیست
  Future<void> playTrackAtIndex(int index, {double? initialSpeed}) async {
    if (index < 0 || index >= _playlist.length) return;

    final item = _playlist[index];
    if (!item.hasAudio) return;

    _currentIndex = index;

    // به‌روزرسانی اطلاعات نوتیفیکیشن
    mediaItem.add(
      MediaItem(
        id: item.id,
        title: item.title,
        album: 'برنامه عبادی',
        artist: 'پخش از گوگل درایو',
        duration: null,
      ),
    );

    try {
      if (item.isDownloaded) {
        await _player.setFilePath(item.localFilePath!);
      } else {
        await _player.setUrl(item.streamUrl);
      }

      if (initialSpeed != null) {
        await _player.setSpeed(initialSpeed);
      }

      await _player.play();
      onTrackChanged?.call(_currentIndex);
    } catch (e) {
      // در صورت خطای لود صوت
      playbackState.add(
        playbackState.value.copyWith(
          processingState: AudioProcessingState.error,
          errorMessage: 'خطا در بارگذاری صوت: $e',
        ),
      );
    }
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
  Future<void> setSpeed(double speed) async {
    await _player.setSpeed(speed);
    playbackState.add(playbackState.value.copyWith(speed: speed));
  }

  @override
  Future<void> skipToNext() async {
    if (_currentIndex + 1 < _playlist.length) {
      await playTrackAtIndex(_currentIndex + 1);
    }
  }

  @override
  Future<void> skipToPrevious() async {
    if (_currentIndex - 1 >= 0) {
      await playTrackAtIndex(_currentIndex - 1);
    } else {
      await seek(Duration.zero);
    }
  }
}
