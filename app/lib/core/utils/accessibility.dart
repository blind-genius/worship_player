import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// ابزار کمکی اعلان‌های صوتی برای صفحه‌خوان تاک‌بک (TalkBack)
class AppAccessibility {
  /// ارسال پیام صوتی مستقیم به TalkBack جهت خوانش فوری
  static void announce(BuildContext context, String message) {
    try {
      final view = View.of(context);
      SemanticsService.sendAnnouncement(view, message, TextDirection.rtl);
    } catch (_) {}
  }
}
