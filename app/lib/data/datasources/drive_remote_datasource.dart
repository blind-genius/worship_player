import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/constants/app_constants.dart';
import '../models/worship_item.dart';

/// فراخوانی اطلاعات لیست پخش از گوگل درایو
class DriveRemoteDatasource {
  final http.Client _client;

  DriveRemoteDatasource({http.Client? client}) : _client = client ?? http.Client();

  /// دریافت لیست پخش از گوگل درایو
  Future<List<WorshipItem>> fetchPlaylist({String? playlistFileId}) async {
    // در صورت وجود شناسه فایل playlist.json در درایو، تلاش برای دانلود آن
    if (playlistFileId != null && playlistFileId.isNotEmpty) {
      try {
        final url = Uri.parse(AppConstants.getDriveDownloadUrl(playlistFileId));
        final response = await _client.get(url).timeout(const Duration(seconds: 12));

        if (response.statusCode == 200) {
          final decoded = json.decode(utf8.decode(response.bodyBytes));
          if (decoded is Map<String, dynamic> && decoded['items'] is List) {
            final itemsList = decoded['items'] as List<dynamic>;
            return itemsList.map((e) => WorshipItem.fromJson(e as Map<String, dynamic>)).toList();
          }
        }
      } catch (e) {
        // در صورت بروز خطا در دانلود فایل اختصاصی درایو، به فال‌بک سوئیچ می‌شود
      }
    }

    // بازگرداندن مقادیر پیش‌فرض استاندارد
    return AppConstants.defaultInitialItems.map((e) => WorshipItem.fromJson(e)).toList();
  }
}
