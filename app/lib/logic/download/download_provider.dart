import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../data/datasources/local_storage_datasource.dart';
import '../../data/models/worship_item.dart';

/// مدیریت دانلود فایل‌ها و رصد درصد پیشرفت دانلود
class DownloadProvider extends ChangeNotifier {
  final LocalStorageDatasource _storageDatasource;
  final Dio _dio = Dio();

  // نگهداری درصد پیشرفت هر دانلود: {driveFileId: progress (0.0 to 1.0)}
  final Map<String, double> _downloadProgress = {};

  // نگهداری توکن‌های لغو دانلود
  final Map<String, CancelToken> _cancelTokens = {};

  DownloadProvider(this._storageDatasource);

  Map<String, double> get downloadProgress => _downloadProgress;

  bool isDownloading(String driveFileId) => _downloadProgress.containsKey(driveFileId);

  double getProgress(String driveFileId) => _downloadProgress[driveFileId] ?? 0.0;

  /// شروع دانلود یک صوت
  Future<String?> downloadItem(WorshipItem item) async {
    if (!item.hasAudio || item.driveFileId.isEmpty) return null;
    if (isDownloading(item.driveFileId)) return null;

    final storageDir = await _storageDatasource.getAudioStorageDirectory();
    final targetPath = '${storageDir.path}/${item.folder}_${item.fileName}';

    final cancelToken = CancelToken();
    _cancelTokens[item.driveFileId] = cancelToken;
    _downloadProgress[item.driveFileId] = 0.01;
    notifyListeners();

    try {
      await _dio.download(
        item.streamUrl,
        targetPath,
        cancelToken: cancelToken,
        onReceiveProgress: (received, total) {
          if (total > 0) {
            _downloadProgress[item.driveFileId] = received / total;
            notifyListeners();
          }
        },
      );

      // ذخیره رکورد در رجیستری محلی
      await _storageDatasource.saveDownloadedFile(item.driveFileId, targetPath);

      _downloadProgress.remove(item.driveFileId);
      _cancelTokens.remove(item.driveFileId);
      notifyListeners();

      return targetPath;
    } catch (e) {
      _downloadProgress.remove(item.driveFileId);
      _cancelTokens.remove(item.driveFileId);

      // پاک کردن فایل ناقص در صورت بروز خطا
      final incompleteFile = File(targetPath);
      if (incompleteFile.existsSync()) {
        try {
          incompleteFile.deleteSync();
        } catch (_) {}
      }

      notifyListeners();
      return null;
    }
  }

  /// لغو دانلود در حال انجام
  void cancelDownload(String driveFileId) {
    if (_cancelTokens.containsKey(driveFileId)) {
      _cancelTokens[driveFileId]?.cancel();
      _cancelTokens.remove(driveFileId);
      _downloadProgress.remove(driveFileId);
      notifyListeners();
    }
  }

  /// حذف فایل دانلود شده
  Future<void> deleteDownload(WorshipItem item) async {
    await _storageDatasource.deleteDownloadedFile(item.driveFileId);
    notifyListeners();
  }
}
