import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/utils/formatters.dart';
import '../../logic/playlist/playlist_provider.dart';
import '../widgets/mini_player_widget.dart';
import '../widgets/track_tile.dart';

/// صفحه اصلی برنامه نمایش‌دهنده لیست ادعیه و سوره‌ها
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final playlist = context.watch<PlaylistProvider>();
    final theme = Theme.of(context);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('برنامه عبادی'),
          actions: [
            IconButton(
              icon: playlist.isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.sync_rounded),
              tooltip: 'همگام‌سازی با گوگل درایو',
              onPressed: playlist.isLoading ? null : () => playlist.loadPlaylist(),
            ),
            IconButton(
              icon: const Icon(Icons.info_outline_rounded),
              tooltip: 'درباره برنامه',
              onPressed: () => _showAboutDialog(context),
            ),
          ],
        ),
        body: Column(
          children: [
            // پیام خطا در صورت عدم برقراری ارتباط
            if (playlist.errorMessage != null)
              Container(
                margin: const EdgeInsets.all(12),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        playlist.errorMessage!,
                        style: const TextStyle(fontSize: 12, color: Colors.red),
                      ),
                    ),
                    TextButton(
                      onPressed: () => playlist.loadPlaylist(),
                      child: const Text('تلاش مجدد'),
                    ),
                  ],
                ),
              ),

            // نوار خلاصه وضعیت
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'لیست پخش جاری (${AppFormatters.toPersianDigits(playlist.items.length.toString())} مورد)',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade400,
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFF0D9488),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'همگام با تلگرام',
                        style: TextStyle(fontSize: 12, color: Color(0xFF0D9488)),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // لیست قطعات با قابلیت Pull-to-refresh
            Expanded(
              child: RefreshIndicator(
                color: const Color(0xFF0D9488),
                onRefresh: () => playlist.loadPlaylist(),
                child: playlist.items.isEmpty
                    ? ListView(
                        children: const [
                          SizedBox(height: 120),
                          Center(
                            child: Column(
                              children: [
                                Icon(Icons.playlist_remove_rounded, size: 64, color: Colors.grey),
                                SizedBox(height: 12),
                                Text(
                                  'هنوز هیچ سوره‌ای از ربات ارسال نشده است.',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                        ],
                      )
                    : ListView.builder(
                        itemCount: playlist.items.length,
                        padding: const EdgeInsets.only(bottom: 90, top: 4),
                        itemBuilder: (context, index) {
                          final item = playlist.items[index];
                          final isPlaying = playlist.currentPlayingIndex == index;

                          return TrackTile(
                            item: item,
                            index: index,
                            isPlaying: isPlaying,
                          );
                        },
                      ),
              ),
            ),
          ],
        ),

        // مینی‌پلیر در پایین صفحه
        bottomSheet: const MiniPlayerWidget(),
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.auto_stories_rounded, color: Color(0xFF0D9488)),
              SizedBox(width: 8),
              Text('راهنمای پخش عبادی'),
            ],
          ),
          content: const Text(
            'این اپلیکیشن مستقیماً به پوشه اختصاصی شما در گوگل درایو متصل است.\n\n'
            'هنگامی که در ربات تلگرام نام سوره‌ها یا ادعیه را بفرستید، ربات فایل‌ها را طبق ایندکس پیدا کرده '
            'و این برنامه لیست را به‌روزرسانی می‌کند.\n\n'
            'امکانات برنامه:\n'
            '• پخش آنلاین فایل‌های صوتی از گوگل درایو\n'
            '• دانلود فایل برای پخش آفلاین (بدون اینترنت)\n'
            '• تنظیم سرعت پخش (۰.۵x تا ۲.۰x)\n'
            '• ادامه پخش در پس‌زمینه و حالت قفل صفحه',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('متوجه شدم'),
            ),
          ],
        ),
      ),
    );
  }
}
