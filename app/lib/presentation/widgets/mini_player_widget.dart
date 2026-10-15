import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import '../../core/utils/accessibility.dart';
import '../../core/utils/formatters.dart';
import '../../logic/playlist/playlist_provider.dart';
import '../screens/player_screen.dart';
import 'speed_dialog.dart';

/// مینی‌پلیر شناور با پشتیبانی کامل از صفحه‌خوان تاک‌بک (TalkBack)
class MiniPlayerWidget extends StatelessWidget {
  const MiniPlayerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final playlist = context.watch<PlaylistProvider>();
    final track = playlist.currentTrack;

    if (track == null) return const SizedBox.shrink();

    final player = playlist.audioHandler.player;
    final theme = Theme.of(context);

    return StreamBuilder<PlayerState>(
      stream: player.playerStateStream,
      builder: (context, snapshot) {
        final playerState = snapshot.data;
        final playing = playerState?.playing ?? false;
        final processingState = playerState?.processingState ?? ProcessingState.idle;

        return StreamBuilder<Duration>(
          stream: player.positionStream,
          builder: (context, posSnapshot) {
            final position = posSnapshot.data ?? Duration.zero;
            final duration = player.duration ?? Duration.zero;
            final progress = (duration.inMilliseconds > 0)
                ? position.inMilliseconds / duration.inMilliseconds
                : 0.0;

            final String posFa = AppFormatters.formatDuration(position);
            final String durFa = AppFormatters.formatDuration(duration);
            final String speedFa = AppFormatters.toPersianDigits(playlist.playbackSpeed.toString());

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              elevation: 8,
              shadowColor: Colors.black54,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PlayerScreen()),
                  );
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // نوار پیشرفت بصری
                    ExcludeSemantics(
                      child: LinearProgressIndicator(
                        value: progress.clamp(0.0, 1.0),
                        minHeight: 3,
                        backgroundColor: Colors.transparent,
                        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF0D9488)),
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      child: Row(
                        children: [
                          // آیکون تزیینی کاور
                          ExcludeSemantics(
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF0D9488), Color(0xFF1E293B)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.music_note_rounded, color: Colors.white, size: 24),
                            ),
                          ),
                          const SizedBox(width: 12),

                          // اطلاعات قطعه برای تاک‌بک
                          Expanded(
                            child: Semantics(
                              label: 'پخش‌کننده: ${track.title}. ${playing ? "در حال پخش" : "متوقف شده"}. زمان: $posFa از $durFa. برای باز کردن کنترل کامل دو بار ضربه بزنید.',
                              button: true,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    track.title,
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '$posFa / $durFa',
                                    style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // دکمه انتخاب سرعت با برچسب تاک‌بک
                          Semantics(
                            label: 'سرعت پخش: $speedFa برابر. برای تغییر سرعت دو بار ضربه بزنید.',
                            button: true,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(8),
                              onTap: () {
                                SpeedSelectorDialog.show(
                                  context,
                                  currentSpeed: playlist.playbackSpeed,
                                  onSpeedSelected: (s) {
                                    playlist.setPlaybackSpeed(s);
                                    AppAccessibility.announce(context, 'سرعت روی $s برابر تنظیم شد');
                                  },
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey.shade600, width: 0.8),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${speedFa}x',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),

                          // دکمه پخش / مکث با برچسب صوتی دقیق
                          if (processingState == ProcessingState.loading ||
                              processingState == ProcessingState.buffering) ...[
                            Semantics(
                              label: 'در حال بارگذاری صوت...',
                              child: const Padding(
                                padding: EdgeInsets.all(12),
                                child: SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(strokeWidth: 2.5),
                                ),
                              ),
                            ),
                          ] else ...[
                            Semantics(
                              label: playing ? 'مکث' : 'پخش',
                              button: true,
                              child: IconButton(
                                icon: Icon(
                                  playing ? Icons.pause_circle_filled_rounded : Icons.play_circle_fill_rounded,
                                  size: 38,
                                  color: const Color(0xFF0D9488),
                                ),
                                tooltip: playing ? 'مکث' : 'پخش',
                                onPressed: () {
                                  if (playing) {
                                    playlist.audioHandler.pause();
                                    AppAccessibility.announce(context, 'صوت متوقف شد');
                                  } else {
                                    playlist.audioHandler.play();
                                    AppAccessibility.announce(context, 'پخش ادامه یافت');
                                  }
                                },
                              ),
                            ),
                          ],

                          // دکمه قطعه بعدی
                          Semantics(
                            label: 'قطعه بعدی',
                            button: true,
                            child: IconButton(
                              icon: const Icon(Icons.skip_next_rounded),
                              tooltip: 'قطعه بعدی',
                              onPressed: () {
                                playlist.audioHandler.skipToNext();
                                AppAccessibility.announce(context, 'رفتن به قطعه بعدی');
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
