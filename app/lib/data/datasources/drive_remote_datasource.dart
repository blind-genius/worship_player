import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/constants/app_constants.dart';
import '../models/worship_item.dart';

/// فراخوانی اطلاعات لیست پخش از منبع ابری و گوگل درایو
class DriveRemoteDatasource {
  final http.Client _client;

  DriveRemoteDatasource({http.Client? client}) : _client = client ?? http.Client();

  /// دریافت لیست پخش همگام‌شده
  Future<List<WorshipItem>> fetchPlaylist({String? playlistFileId}) async {
    // ۱. ابتدا تلاش برای دریافت آخرین فایل همگام‌شده از آدرس مستقیم ابری
    try {
      final cacheBusterUrl = Uri.parse(
        '${AppConstants.playlistRemoteUrl}?t=${DateTime.now().millisecondsSinceEpoch}',
      );
      final response = await _client.get(cacheBusterUrl).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final decoded = json.decode(utf8.decode(response.bodyBytes));
        if (decoded is Map<String, dynamic> && decoded['items'] is List) {
          final itemsList = decoded['items'] as List<dynamic>;
          return itemsList.map((e) => WorshipItem.fromJson(e as Map<String, dynamic>)).toList();
        }
      }
    } catch (_) {
      // در صورت عدم دسترسی موقت، مرحله بعدی چک می‌شود
    }

    // ۲. در صورت وجود شناسه فایل در درایو، تلاش برای خواندن از درایو
    if (playlistFileId != null && playlistFileId.isNotEmpty) {
      try {
        final driveUrl = Uri.parse(AppConstants.getDriveDownloadUrl(playlistFileId));
        final response = await _client.get(driveUrl).timeout(const Duration(seconds: 10));

        if (response.statusCode == 200) {
          final decoded = json.decode(utf8.decode(response.bodyBytes));
          if (decoded is Map<String, dynamic> && decoded['items'] is List) {
            final itemsList = decoded['items'] as List<dynamic>;
            return itemsList.map((e) => WorshipItem.fromJson(e as Map<String, dynamic>)).toList();
          }
        }
      } catch (_) {}
    }

    // ۳. بازگرداندن مقادیر پیش‌فرض
    return AppConstants.defaultInitialItems.map((e) => WorshipItem.fromJson(e)).toList();
  }
}
