import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import '../../core/utils/accessibility.dart';
import '../../core/utils/formatters.dart';
import '../../logic/download/download_provider.dart';
import '../../logic/playlist/playlist_provider.dart';
import '../widgets/speed_dialog.dart';

/// صفحه تمام‌صفحه پخش صوت با دسترس‌پذیری کامل برای کاربران نابینا (TalkBack)
class PlayerScreen extends StatelessWidget {
  const PlayerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final playlist = context.watch<PlaylistProvider>();
    final download = context.watch<DownloadProvider>();
    final track = playlist.currentTrack;

    if (track == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('پخش‌کننده')),
        body: const Center(
          child: Text('هیچ صوتی در حال حاضر انتخاب نشده است.'),
        ),
      );
    }

    final player = playlist.audioHandler.player;
    final theme = Theme.of(context);
    final isDownloaded = track.isDownloaded;
    final isDownloading = download.isDownloading(track.driveFileId);
    final String speedFa = AppFormatters.toPersianDigits(playlist.playbackSpeed.toString());

    return Scaffold(
      appBar: AppBar(
        title: const Text('در حال پخش'),
        actions: [
          Semantics(
            label: 'تغییر سرعت پخش صوت. سرعت فعلی $speedFa برابر است.',
            button: true,
            child: IconButton(
              icon: const Icon(Icons.speed_rounded),
              tooltip: 'سرعت پخش',
              onPressed: () {
                SpeedSelectorDialog.show(
                  context,
                  currentSpeed: playlist.playbackSpeed,
                  onSpeedSelected: (s) {
                    playlist.setPlaybackSpeed(s);
                    AppAccessibility.announce(context, 'سرعت پخش روی $s برابر تنظیم شد');
                  },
                );
              },
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            children: [
              const Spacer(),

              // کاور تزیینی (از دید تاک‌بک استثنا می‌شود تا خواندن اضافی نداشته باشد)
              ExcludeSemantics(
                child: Container(
                  width: 240,
                  height: 240,
                  decoration: BoxDecoration(
                    gradient: const RadialGradient(
                      colors: [Color(0xFF0D9488), Color(0xFF0F172A)],
                      radius: 0.85,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0D9488).withValues(alpha: 0.35),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                    ],
                    border: Border.all(color: const Color(0xFF0D9488), width: 3),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.menu_book_rounded,
                      size: 96,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              const Spacer(),

              // عنوان قطعه برای تاک‌بک
              Semantics(
                header: true,
                label: 'عنوان قطعه در حال پخش: ${track.title}',
                child: Text(
                  track.title,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 8),

              // برچسب وضعیت آنلاین / آفلاین
              Semantics(
                label: isDownloaded
                    ? 'وضعیت: فایل به صورت آفلاین در حافظه گوشی شما وجود دارد.'
                    : 'وضعیت: در حال پخش به صورت آنلاین از گوگل درایو.',
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDownloaded
                        ? Colors.green.withValues(alpha: 0.15)
                        : Colors.blue.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isDownloaded ? Icons.offline_pin_rounded : Icons.cloud_outlined,
                        size: 14,
                        color: isDownloaded ? Colors.green : Colors.blue,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isDownloaded ? 'پخش آفلاین (حافظه دستگاه)' : 'استریم مستقیم از گوگل درایو',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDownloaded ? Colors.green : Colors.blue,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // نوار اسلایدر Seek و مدت زمان با پشتیبانی کامل از کلیدهای تغییر اسلایدر در تاک‌بک
              StreamBuilder<Duration>(
                stream: player.positionStream,
                builder: (context, snapshot) {
                  final position = snapshot.data ?? Duration.zero;
                  final duration = player.duration ?? Duration.zero;
                  final maxMillis = duration.inMilliseconds.toDouble();
                  final currentMillis = position.inMilliseconds.toDouble().clamp(0.0, maxMillis > 0 ? maxMillis : 0.0);

                  final posFa = AppFormatters.formatDuration(position);
                  final durFa = AppFormatters.formatDuration(duration);

                  return Semantics(
                    label: 'اسلایدر زمان صوت',
                    value: '$posFa از $durFa',
                    increasedValue: '۱۰ ثانیه به جلو',
                    decreasedValue: '۱۰ ثانیه به عقب',
                    onIncrease: () {
                      final newPos = position + const Duration(seconds: 10);
                      player.seek(newPos < duration ? newPos : duration);
                    },
                    onDecrease: () {
                      final newPos = position - const Duration(seconds: 10);
                      player.seek(newPos > Duration.zero ? newPos : Duration.zero);
                    },
                    child: Column(
                      children: [
                        Slider(
                          value: (maxMillis > 0) ? currentMillis : 0.0,
                          max: (maxMillis > 0) ? maxMillis : 1.0,
                          onChanged: (val) {
                            player.seek(Duration(milliseconds: val.toInt()));
                          },
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: ExcludeSemantics(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(posFa, style: theme.textTheme.bodySmall),
                                Text(durFa, style: theme.textTheme.bodySmall),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),

              const SizedBox(height: 16),

              // کلیدهای کنترلی صوتی با برچسب‌های دقیق
              StreamBuilder<PlayerState>(
                stream: player.playerStateStream,
                builder: (context, snapshot) {
                  final state = snapshot.data;
                  final playing = state?.playing ?? false;
                  final processingState = state?.processingState ?? ProcessingState.idle;

                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // سرعت
                      Semantics(
                        label: 'سرعت پخش: $speedFa برابر. برای تغییر دو بار ضربه بزنید.',
                        button: true,
                        child: TextButton.icon(
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          ),
                          icon: const Icon(Icons.speed_rounded, size: 18),
                          label: Text(
                            '${speedFa}x',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          onPressed: () {
                            SpeedSelectorDialog.show(
                              context,
                              currentSpeed: playlist.playbackSpeed,
                              onSpeedSelected: (s) {
                                playlist.setPlaybackSpeed(s);
                                AppAccessibility.announce(context, 'سرعت روی $s برابر تنظیم شد');
                              },
                            );
                          },
                        ),
                      ),

                      // قبلی
                      Semantics(
                        label: 'قطعه قبلی',
                        button: true,
                        child: IconButton(
                          iconSize: 42,
                          icon: const Icon(Icons.skip_previous_rounded),
                          tooltip: 'قطعه قبلی',
                          onPressed: () {
                            playlist.audioHandler.skipToPrevious();
                            AppAccessibility.announce(context, 'رفتن به قطعه قبلی');
                          },
                        ),
                      ),

                      // پخش / مکث / لودینگ
                      if (processingState == ProcessingState.loading ||
                          processingState == ProcessingState.buffering) ...[
                        Semantics(
                          label: 'در حال بارگذاری صوت...',
                          child: const SizedBox(
                            width: 64,
                            height: 64,
                            child: CircularProgressIndicator(strokeWidth: 3),
                          ),
                        ),
                      ] else ...[
                        Semantics(
                          label: playing ? 'مکث پخش صوت' : 'پخش صوت',
                          button: true,
                          child: Container(
                            width: 68,
                            height: 68,
                            decoration: const BoxDecoration(
                              color: Color(0xFF0D9488),
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              iconSize: 42,
                              color: Colors.white,
                              icon: Icon(
                                playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                              ),
                              tooltip: playing ? 'مکث' : 'پخش',
                              onPressed: () {
                                if (playing) {
                                  playlist.audioHandler.pause();
                                  AppAccessibility.announce(context, 'صوت متوقف شد');
                                } else {
                                  playlist.audioHandler.play();
                                  AppAccessibility.announce(context, 'پخش آغاز شد');
                                }
                              },
                            ),
                          ),
                        ),
                      ],

                      // بعدی
                      Semantics(
                        label: 'قطعه بعدی',
                        button: true,
                        child: IconButton(
                          iconSize: 42,
                          icon: const Icon(Icons.skip_next_rounded),
                          tooltip: 'قطعه بعدی',
                          onPressed: () {
                            playlist.audioHandler.skipToNext();
                            AppAccessibility.announce(context, 'رفتن به قطعه بعدی');
                          },
                        ),
                      ),

                      // دکمه وضعیت دانلود
                      if (isDownloading) ...[
                        Semantics(
                          label: 'در حال دانلود فایل این قطعه...',
                          child: const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      ] else if (isDownloaded) ...[
                        Semantics(
                          label: 'این قطعه قبلاً به صورت آفلاین دانلود شده است.',
                          button: true,
                          child: IconButton(
                            icon: const Icon(Icons.download_done_rounded, color: Colors.green),
                            tooltip: 'فایل موجود در حافظه',
                            onPressed: () {
                              AppAccessibility.announce(context, 'این قطعه به صورت آفلاین در دستگاه موجود است');
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('این قطعه قبلاً به صورت آفلاین دانلود شده است.')),
                              );
                            },
                          ),
                        ),
                      ] else ...[
                        Semantics(
                          label: 'دکمه دانلود این قطعه برای پخش آفلاین بدون نیاز به اینترنت.',
                          button: true,
                          child: IconButton(
                            icon: const Icon(Icons.download_rounded),
                            tooltip: 'دانلود آفلاین',
                            onPressed: () async {
                              AppAccessibility.announce(context, 'دانلود آغاز شد');
                              final path = await download.downloadItem(track);
                              if (path != null && context.mounted) {
                                playlist.markItemDownloaded(track.driveFileId, path);
                                AppAccessibility.announce(context, 'دانلود با موفقیت انجام شد');
                              }
                            },
                          ),
                        ),
                      ],
                    ],
                  );
                },
              ),

              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
