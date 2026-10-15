import 'package:flutter/foundation.dart';
import '../../data/datasources/drive_remote_datasource.dart';
import '../../data/datasources/local_storage_datasource.dart';
import '../../data/models/worship_item.dart';
import '../player/worship_audio_handler.dart';

/// مدیریت وضعیت لیست پخش، همگام‌سازی با درایو و کنترل پخش قطعات
class PlaylistProvider extends ChangeNotifier {
  final DriveRemoteDatasource _remoteDatasource;
  final LocalStorageDatasource _storageDatasource;
  final WorshipAudioHandler _audioHandler;

  List<WorshipItem> _items = [];
  bool _isLoading = false;
  String? _errorMessage;
  int _currentPlayingIndex = -1;
  double _playbackSpeed = 1.0;

  PlaylistProvider({
    required DriveRemoteDatasource driveRemoteDatasource,
    required LocalStorageDatasource localStorageDatasource,
    required WorshipAudioHandler worshipAudioHandler,
  })  : _remoteDatasource = driveRemoteDatasource,
        _storageDatasource = localStorageDatasource,
        _audioHandler = worshipAudioHandler {
    _init();
  }

  List<WorshipItem> get items => _items;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get currentPlayingIndex => _currentPlayingIndex;
  double get playbackSpeed => _playbackSpeed;
  WorshipAudioHandler get audioHandler => _audioHandler;

  WorshipItem? get currentTrack =>
      (_currentPlayingIndex >= 0 && _currentPlayingIndex < _items.length)
          ? _items[_currentPlayingIndex]
          : null;

  void _init() {
    _playbackSpeed = _storageDatasource.getPreferredPlaybackSpeed();

    // اتصال لیسنر تغییر قطعه از پلیر به این ارائه‌دهنده
    _audioHandler.onTrackChanged = (index) {
      _currentPlayingIndex = index;
      notifyListeners();
    };

    // بارگذاری سریع از کش محلی در اولین فریم
    final cached = _storageDatasource.getCachedPlaylist();
    if (cached != null && cached.isNotEmpty) {
      _items = cached;
      _audioHandler.setPlaylist(_items);
    }

    // بارگذاری به‌روز از گوگل درایو
    loadPlaylist();
  }

  /// بارگذاری لیست از گوگل درایو
  Future<void> loadPlaylist() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final remoteItems = await _remoteDatasource.fetchPlaylist();

      // تطبیق با فایل‌های دانلود شده روی گوشی
      final downloadedMap = _storageDatasource.getDownloadedFilesMap();
      final merged = remoteItems.map((item) {
        final localPath = downloadedMap[item.driveFileId];
        return item.copyWith(localFilePath: localPath);
      }).toList();

      // مرتب‌سازی بر اساس موقعیت ارسالی از ربات تلگرام
      merged.sort((a, b) => a.position.compareTo(b.position));

      _items = merged;
      _audioHandler.setPlaylist(_items);

      // ذخیره در کش محلی
      await _storageDatasource.cachePlaylist(_items);
    } catch (e) {
      _errorMessage = 'امکان دریافت لیست جدید وجود ندارد: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// پخش یک قطعه از لیست
  Future<void> playTrack(int index) async {
    if (index < 0 || index >= _items.length) return;
    _currentPlayingIndex = index;
    notifyListeners();
    await _audioHandler.playTrackAtIndex(index, initialSpeed: _playbackSpeed);
  }

  /// تغییر سرعت پخش
  Future<void> setPlaybackSpeed(double speed) async {
    _playbackSpeed = speed;
    await _storageDatasource.savePreferredPlaybackSpeed(speed);
    await _audioHandler.setSpeed(speed);
    notifyListeners();
  }

  /// به‌روزرسانی مسیر محلی بعد از اتمام دانلود
  void markItemDownloaded(String driveFileId, String localPath) {
    final index = _items.indexWhere((e) => e.driveFileId == driveFileId);
    if (index != -1) {
      _items[index] = _items[index].copyWith(localFilePath: localPath);
      _audioHandler.setPlaylist(_items);
      _storageDatasource.cachePlaylist(_items);
      notifyListeners();
    }
  }

  /// به‌روزرسانی پس از حذف فایل دانلود شده
  void markItemDeleted(String driveFileId) {
    final index = _items.indexWhere((e) => e.driveFileId == driveFileId);
    if (index != -1) {
      _items[index] = _items[index].copyWith(localFilePath: null);
      _audioHandler.setPlaylist(_items);
      _storageDatasource.cachePlaylist(_items);
      notifyListeners();
    }
  }
}
