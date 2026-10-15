import 'package:flutter/material.dart';

/// تم اپلیکیشن با پالت معنوی و مدرن
class AppTheme {
  // رنگ‌های اختصاصی برند
  static const Color primaryEmerald = Color(0xFF0D9488); // زمردی ملایم
  static const Color accentGold = Color(0xFFF59E0B);     // طلایی چشم‌نواز
  static const Color darkBackground = Color(0xFF0F172A); // سورمه‌ای تیره
  static const Color darkSurface = Color(0xFF1E293B);    // کارت‌های پس‌زمینه
  static const Color lightBackground = Color(0xFFF8FAFC);// روشن تمیز
  static const Color lightSurface = Color(0xFFFFFFFF);

  /// تم تیره (Dark Theme) - تم اصلی و استاندارد برای محیط معنوی و شب
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBackground,
      colorScheme: const ColorScheme.dark(
        primary: primaryEmerald,
        secondary: accentGold,
        surface: darkSurface,
        onSurface: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: darkBackground,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 19,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      cardTheme: CardThemeData(
        color: darkSurface,
        elevation: 2,
        shadowColor: Colors.black38,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      ),
      sliderTheme: const SliderThemeData(
        activeTrackColor: primaryEmerald,
        inactiveTrackColor: Colors.white24,
        thumbColor: accentGold,
        thumbShape: RoundSliderThumbShape(enabledThumbRadius: 7),
        trackHeight: 4,
      ),
    );
  }

  /// تم روشن (Light Theme)
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: lightBackground,
      colorScheme: const ColorScheme.light(
        primary: primaryEmerald,
        secondary: accentGold,
        surface: lightSurface,
        onSurface: Color(0xFF1E293B),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: lightBackground,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 19,
          fontWeight: FontWeight.bold,
          color: Color(0xFF0F172A),
        ),
        iconTheme: IconThemeData(color: Color(0xFF0F172A)),
      ),
      cardTheme: CardThemeData(
        color: lightSurface,
        elevation: 1.5,
        shadowColor: Colors.black12,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      ),
      sliderTheme: const SliderThemeData(
        activeTrackColor: primaryEmerald,
        inactiveTrackColor: Colors.black12,
        thumbColor: primaryEmerald,
        thumbShape: RoundSliderThumbShape(enabledThumbRadius: 7),
        trackHeight: 4,
      ),
    );
  }
}
