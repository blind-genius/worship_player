import 'dart:io';

/// مدل داده هر آیتم صوتی یا عبادی
class WorshipItem {
  final String id;
  final int position;
  final String title;
  final String fileName;
  final String folder;
  final String driveFileId;
  final int sizeBytes;
  final bool hasAudio;
  final String streamUrl;
  final String? localFilePath;

  const WorshipItem({
    required this.id,
    required this.position,
    required this.title,
    required this.fileName,
    required this.folder,
    required this.driveFileId,
    required this.sizeBytes,
    required this.hasAudio,
    required this.streamUrl,
    this.localFilePath,
  });

  /// بررسی اینکه آیا فایل به صورت محلی و سالم در حافظه دستگاه موجود است یا خیر
  bool get isDownloaded {
    if (localFilePath == null || localFilePath!.isEmpty) return false;
    final file = File(localFilePath!);
    return file.existsSync() && file.lengthSync() > 0;
  }

  /// دریافت آدرس قطعی جهت ارسال به پلیر (اگر دانلود شده بود از فایل لوکال، در غیر این صورت استریم آنلاین)
  String get effectivePlaybackUrl {
    if (isDownloaded) {
      return localFilePath!;
    }
    return streamUrl;
  }

  factory WorshipItem.fromJson(Map<String, dynamic> json) {
    return WorshipItem(
      id: json['id']?.toString() ?? '',
      position: json['position'] is int ? json['position'] : int.tryParse(json['position']?.toString() ?? '1') ?? 1,
      title: json['title'] ?? '',
      fileName: json['file_name'] ?? '',
      folder: json['folder'] ?? '',
      driveFileId: json['drive_file_id'] ?? '',
      sizeBytes: json['size_bytes'] is int ? json['size_bytes'] : int.tryParse(json['size_bytes']?.toString() ?? '0') ?? 0,
      hasAudio: json['has_audio'] ?? (json['drive_file_id'] != null && json['drive_file_id'].toString().isNotEmpty),
      streamUrl: json['stream_url'] ?? '',
      localFilePath: json['local_file_path'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'position': position,
      'title': title,
      'file_name': fileName,
      'folder': folder,
      'drive_file_id': driveFileId,
      'size_bytes': sizeBytes,
      'has_audio': hasAudio,
      'stream_url': streamUrl,
      'local_file_path': localFilePath,
    };
  }

  WorshipItem copyWith({
    String? id,
    int? position,
    String? title,
    String? fileName,
    String? folder,
    String? driveFileId,
    int? sizeBytes,
    bool? hasAudio,
    String? streamUrl,
    String? localFilePath,
  }) {
    return WorshipItem(
      id: id ?? this.id,
      position: position ?? this.position,
      title: title ?? this.title,
      fileName: fileName ?? this.fileName,
      folder: folder ?? this.folder,
      driveFileId: driveFileId ?? this.driveFileId,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      hasAudio: hasAudio ?? this.hasAudio,
      streamUrl: streamUrl ?? this.streamUrl,
      localFilePath: localFilePath ?? this.localFilePath,
    );
  }
}
