import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/theme/app_theme.dart';
import 'data/datasources/drive_remote_datasource.dart';
import 'data/datasources/local_storage_datasource.dart';
import 'logic/download/download_provider.dart';
import 'logic/player/worship_audio_handler.dart';
import 'logic/playlist/playlist_provider.dart';
import 'presentation/screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ۱. راه‌اندازی حافظه لوکال
  final prefs = await SharedPreferences.getInstance();
  final storageDatasource = LocalStorageDatasource(prefs);
  final remoteDatasource = DriveRemoteDatasource();

  // ۲. راه‌اندازی AudioService برای پخش در پس‌زمینه و کنترل نوتیفیکیشن
  final audioHandler = await AudioService.init(
    builder: () => WorshipAudioHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.soleiman.worship.channel.audio',
      androidNotificationChannelName: 'پخش صوت عبادی',
      androidNotificationChannelDescription: 'کنترل‌های پخش ادعیه و سوره‌ها',
      androidNotificationOngoing: false,
      androidStopForegroundOnPause: true,
      androidNotificationIcon: 'mipmap/ic_launcher',
    ),
  );

  runApp(
    MultiProvider(
      providers: [
        Provider<LocalStorageDatasource>.value(value: storageDatasource),
        Provider<DriveRemoteDatasource>.value(value: remoteDatasource),
        Provider<WorshipAudioHandler>.value(value: audioHandler),
        ChangeNotifierProvider(
          create: (_) => DownloadProvider(storageDatasource),
        ),
        ChangeNotifierProvider(
          create: (_) => PlaylistProvider(
            driveRemoteDatasource: remoteDatasource,
            localStorageDatasource: storageDatasource,
            worshipAudioHandler: audioHandler,
          ),
        ),
      ],
      child: const WorshipApp(),
    ),
  );
}

class WorshipApp extends StatelessWidget {
  const WorshipApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'پخش عبادی',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark, // به طور پیش‌فرض حالت تیره معنوی فعال است
      home: const HomeScreen(),
    );
  }
}
