/// ابزارهای قالب‌بندی متون، زمان و حجم فایل
class AppFormatters {
  /// تبدیل ارقام انگلیسی به فارسی
  static String toPersianDigits(String input) {
    const english = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    const persian = ['۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹'];

    for (int i = 0; i < english.length; i++) {
      input = input.replaceAll(english[i], persian[i]);
    }
    return input;
  }

  /// قالب‌بندی مدت زمان صوت (مثال: 04:35)
  static String formatDuration(Duration? duration, {bool toPersian = true}) {
    if (duration == null || duration == Duration.zero) {
      return toPersian ? '۰۰:۰۰' : '00:00';
    }

    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    final minStr = minutes.toString().padLeft(2, '0');
    final secStr = seconds.toString().padLeft(2, '0');

    String result;
    if (hours > 0) {
      result = '$hours:$minStr:$secStr';
    } else {
      result = '$minStr:$secStr';
    }

    return toPersian ? toPersianDigits(result) : result;
  }

  /// قالب‌بندی حجم فایل به مگابایت یا کیلوبایت
  static String formatBytes(int bytes, {bool toPersian = true}) {
    if (bytes <= 0) return toPersian ? '۰ مگابایت' : '0 MB';

    double sizeInMb = bytes / (1024 * 1024);
    if (sizeInMb >= 1.0) {
      final formatted = sizeInMb.toStringAsFixed(1);
      return toPersian ? '${toPersianDigits(formatted)} مگابایت' : '$formatted MB';
    } else {
      double sizeInKb = bytes / 1024;
      final formatted = sizeInKb.toStringAsFixed(0);
      return toPersian ? '${toPersianDigits(formatted)} کیلوبایت' : '$formatted KB';
    }
  }
}
