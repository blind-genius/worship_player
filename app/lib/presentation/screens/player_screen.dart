import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import '../../core/utils/formatters.dart';
import '../../logic/download/download_provider.dart';
import '../../logic/playlist/playlist_provider.dart';
import '../widgets/speed_dialog.dart';

/// صفحه تمام‌صفحه پخش صوت با کنترل کامل سرعت و اسلایدر
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
        body: const Center(child: Text('هیچ صوتی در حال پخش نیست.')),
      );
    }

    final player = playlist.audioHandler.player;
    final theme = Theme.of(context);
    final isDownloaded = track.isDownloaded;
    final isDownloading = download.isDownloading(track.driveFileId);

    return Scaffold(
      appBar: AppBar(
        title: const Text('در حال پخش'),
        actions: [
          IconButton(
            icon: const Icon(Icons.speed_rounded),
            tooltip: 'تغییر سرعت پخش',
            onPressed: () {
              SpeedSelectorDialog.show(
                context,
                currentSpeed: playlist.playbackSpeed,
                onSpeedSelected: playlist.setPlaybackSpeed,
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            children: [
              const Spacer(),

              // کاور معنوی بزرگ با گرادیان زمردی
              Container(
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

              const Spacer(),

              // عنوان قطعه و وضعیت
              Text(
                track.title,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
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
                ],
              ),

              const SizedBox(height: 24),

              // نوار اسلایدر Seek و مدت زمان
              StreamBuilder<Duration>(
                stream: player.positionStream,
                builder: (context, snapshot) {
                  final position = snapshot.data ?? Duration.zero;
                  final duration = player.duration ?? Duration.zero;
                  final maxMillis = duration.inMilliseconds.toDouble();
                  final currentMillis = position.inMilliseconds.toDouble().clamp(0.0, maxMillis > 0 ? maxMillis : 0.0);

                  return Column(
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
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              AppFormatters.formatDuration(position),
                              style: theme.textTheme.bodySmall,
                            ),
                            Text(
                              AppFormatters.formatDuration(duration),
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 16),

              // ردیف کلیدهای اصلی کنترل
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
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        ),
                        icon: const Icon(Icons.speed_rounded, size: 18),
                        label: Text(
                          '${AppFormatters.toPersianDigits(playlist.playbackSpeed.toString())}x',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        onPressed: () {
                          SpeedSelectorDialog.show(
                            context,
                            currentSpeed: playlist.playbackSpeed,
                            onSpeedSelected: playlist.setPlaybackSpeed,
                          );
                        },
                      ),

                      // قبلی
                      IconButton(
                        iconSize: 42,
                        icon: const Icon(Icons.skip_previous_rounded),
                        onPressed: () => playlist.audioHandler.skipToPrevious(),
                      ),

                      // پخش / توقف / لودینگ
                      if (processingState == ProcessingState.loading ||
                          processingState == ProcessingState.buffering) ...[
                        const SizedBox(
                          width: 64,
                          height: 64,
                          child: CircularProgressIndicator(strokeWidth: 3),
                        ),
                      ] else ...[
                        Container(
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
                            onPressed: () {
                              if (playing) {
                                playlist.audioHandler.pause();
                              } else {
                                playlist.audioHandler.play();
                              }
                            },
                          ),
                        ),
                      ],

                      // بعدی
                      IconButton(
                        iconSize: 42,
                        icon: const Icon(Icons.skip_next_rounded),
                        onPressed: () => playlist.audioHandler.skipToNext(),
                      ),

                      // دکمه دانلود / وضعیت لوکال
                      if (isDownloading) ...[
                        const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ] else if (isDownloaded) ...[
                        IconButton(
                          icon: const Icon(Icons.download_done_rounded, color: Colors.green),
                          tooltip: 'فایل در حافظه موجود است',
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('این قطعه قبلاً به صورت آفلاین دانلود شده است.')),
                            );
                          },
                        ),
                      ] else ...[
                        IconButton(
                          icon: const Icon(Icons.download_rounded),
                          tooltip: 'دانلود آفلاین',
                          onPressed: () async {
                            final path = await download.downloadItem(track);
                            if (path != null) {
                              playlist.markItemDownloaded(track.driveFileId, path);
                            }
                          },
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
