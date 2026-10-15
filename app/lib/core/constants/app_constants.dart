/// ثابت‌های سراسری اپلیکیشن
class AppConstants {
  static const String appName = 'پخش عبادی';
  
  // شناسه پوشه اصلی worship در گوگل درایو
  static const String googleDriveFolderId = '1wPcJ84M0WiRIn85mbYaaVsu11rdMALA9';

  // آدرس ابری مستقیم فایل playlist.json همگام‌شده با ربات تلگرام
  static const String playlistRemoteUrl =
      'https://raw.githubusercontent.com/blind-genius/worship_player/main/playlist.json';

  // ساخت لینک مستقیم استریم یا دانلود بر اساس شناسه فایل در گوگل درایو
  static String getDriveDownloadUrl(String fileId) {
    return 'https://drive.google.com/uc?export=download&id=$fileId';
  }

  // سرعت‌های مجاز جهت پخش صوت
  static const List<double> playbackSpeeds = [
    0.5,
    0.75,
    1.0,
    1.25,
    1.5,
    1.75,
    2.0,
  ];

  // کلیدهای ذخیره‌سازی لوکال در SharedPreferences
  static const String prefDownloadedFilesKey = 'downloaded_worship_files';
  static const String prefCachedPlaylistKey = 'cached_worship_playlist';
  static const String prefPlaybackSpeedKey = 'preferred_playback_speed';
  static const String prefDrivePlaylistFileIdKey = 'drive_playlist_file_id';

  // مقادیر پیش‌فرض در صورت عدم اتصال در اولین اجرا
  static const List<Map<String, dynamic>> defaultInitialItems = [
    {
      'id': '1',
      'position': 1,
      'title': 'سوره یاسین',
      'file_name': '036.mp3',
      'folder': 'quran',
      'drive_file_id': '19Q_oK7V6yg_-SYwTyJiun4rMA3rAFf6H',
      'size_bytes': 5602543,
      'has_audio': true,
      'stream_url': 'https://drive.google.com/uc?export=download&id=19Q_oK7V6yg_-SYwTyJiun4rMA3rAFf6H',
    },
    {
      'id': '2',
      'position': 2,
      'title': 'سوره لقمان',
      'file_name': '031.mp3',
      'folder': 'quran',
      'drive_file_id': '1MCKgXLgQk2J-fd7JgbwZ_rDdPtiiJfDt',
      'size_bytes': 4226412,
      'has_audio': true,
      'stream_url': 'https://drive.google.com/uc?export=download&id=1MCKgXLgQk2J-fd7JgbwZ_rDdPtiiJfDt',
    },
    {
      'id': '3',
      'position': 3,
      'title': 'سوره جن',
      'file_name': '072.mp3',
      'folder': 'quran',
      'drive_file_id': '1_P3IrUtQuO63vFEEdCwvk8vYzWB2RhVG',
      'size_bytes': 2282486,
      'has_audio': true,
      'stream_url': 'https://drive.google.com/uc?export=download&id=1_P3IrUtQuO63vFEEdCwvk8vYzWB2RhVG',
    },
  ];
}
