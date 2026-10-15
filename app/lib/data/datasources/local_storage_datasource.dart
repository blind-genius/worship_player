import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_constants.dart';
import '../models/worship_item.dart';

/// مدیریت حافظه لوکال، کش پلی‌لیست و فایل‌های دانلود شده
class LocalStorageDatasource {
  final SharedPreferences _prefs;

  LocalStorageDatasource(this._prefs);

  /// مسیر پوشه ذخیره‌سازی فایل‌های صوتی دانلود شده در گوشی
  Future<Directory> getAudioStorageDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final worshipDir = Directory('${appDir.path}/worship_audios');
    if (!worshipDir.existsSync()) {
      await worshipDir.create(recursive: true);
    }
    return worshipDir;
  }

  /// دریافت نقشه فایل‌های دانلود شده {driveFileId: localFilePath}
  Map<String, String> getDownloadedFilesMap() {
    final raw = _prefs.getString(AppConstants.prefDownloadedFilesKey);
    if (raw == null || raw.isEmpty) return {};
    try {
      final decoded = json.decode(raw) as Map<String, dynamic>;
      return decoded.map((key, value) => MapEntry(key, value.toString()));
    } catch (_) {
      return {};
    }
  }

  /// ذخیره رکورد فایل دانلود شده جدید
  Future<void> saveDownloadedFile(String driveFileId, String localPath) async {
    final map = getDownloadedFilesMap();
    map[driveFileId] = localPath;
    await _prefs.setString(AppConstants.prefDownloadedFilesKey, json.encode(map));
  }

  /// حذف فایل دانلود شده از دیسک و از رجیستری
  Future<void> deleteDownloadedFile(String driveFileId) async {
    final map = getDownloadedFilesMap();
    final localPath = map[driveFileId];
    if (localPath != null) {
      final file = File(localPath);
      if (file.existsSync()) {
        try {
          await file.delete();
        } catch (_) {}
      }
      map.remove(driveFileId);
      await _prefs.setString(AppConstants.prefDownloadedFilesKey, json.encode(map));
    }
  }

  /// کش کردن آخرین لیست دریافت شده برای دسترسی آفلاین
  Future<void> cachePlaylist(List<WorshipItem> items) async {
    final jsonList = items.map((e) => e.toJson()).toList();
    await _prefs.setString(AppConstants.prefCachedPlaylistKey, json.encode(jsonList));
  }

  /// بازیابی آخرین لیست کش شده
  List<WorshipItem>? getCachedPlaylist() {
    final raw = _prefs.getString(AppConstants.prefCachedPlaylistKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = json.decode(raw) as List<dynamic>;
      final downloadedMap = getDownloadedFilesMap();
      return decoded.map((e) {
        final item = WorshipItem.fromJson(e as Map<String, dynamic>);
        final localPath = downloadedMap[item.driveFileId];
        return item.copyWith(localFilePath: localPath);
      }).toList();
    } catch (_) {
      return null;
    }
  }

  /// ذخیره و بازیابی آخرین سرعت پخش انتخاب شده
  double getPreferredPlaybackSpeed() {
    return _prefs.getDouble(AppConstants.prefPlaybackSpeedKey) ?? 1.0;
  }

  Future<void> savePreferredPlaybackSpeed(double speed) async {
    await _prefs.setDouble(AppConstants.prefPlaybackSpeedKey, speed);
  }
}
