import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import '../../core/utils/formatters.dart';
import '../../logic/playlist/playlist_provider.dart';
import '../screens/player_screen.dart';
import 'speed_dialog.dart';

/// مینی‌پلیر شناور در پایین صفحه اصلی
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
                // نوار پیشرفت باریک در بالای مینی‌پلیر
                StreamBuilder<Duration>(
                  stream: player.positionStream,
                  builder: (context, posSnapshot) {
                    final position = posSnapshot.data ?? Duration.zero;
                    final duration = player.duration ?? Duration.zero;
                    final progress = (duration.inMilliseconds > 0)
                        ? position.inMilliseconds / duration.inMilliseconds
                        : 0.0;

                    return LinearProgressIndicator(
                      value: progress.clamp(0.0, 1.0),
                      minHeight: 3,
                      backgroundColor: Colors.transparent,
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF0D9488)),
                    );
                  },
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  child: Row(
                    children: [
                      // آیکون کاور مینیاتوری
                      Container(
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
                      const SizedBox(width: 12),

                      // عنوان قطعه
                      Expanded(
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
                            StreamBuilder<Duration>(
                              stream: player.positionStream,
                              builder: (context, posSnapshot) {
                                final pos = posSnapshot.data ?? Duration.zero;
                                final dur = player.duration ?? Duration.zero;
                                return Text(
                                  '${AppFormatters.formatDuration(pos)} / ${AppFormatters.formatDuration(dur)}',
                                  style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                                );
                              },
                            ),
                          ],
                        ),
                      ),

                      // دکمه انتخاب سرعت
                      InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () {
                          SpeedSelectorDialog.show(
                            context,
                            currentSpeed: playlist.playbackSpeed,
                            onSpeedSelected: playlist.setPlaybackSpeed,
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade600, width: 0.8),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${AppFormatters.toPersianDigits(playlist.playbackSpeed.toString())}x',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),

                      // کلید پخش / توقف
                      if (processingState == ProcessingState.loading ||
                          processingState == ProcessingState.buffering) ...[
                        const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2.5),
                          ),
                        ),
                      ] else ...[
                        IconButton(
                          icon: Icon(
                            playing ? Icons.pause_circle_filled_rounded : Icons.play_circle_fill_rounded,
                            size: 38,
                            color: const Color(0xFF0D9488),
                          ),
                          onPressed: () {
                            if (playing) {
                              playlist.audioHandler.pause();
                            } else {
                              playlist.audioHandler.play();
                            }
                          },
                        ),
                      ],

                      // قطعه بعدی
                      IconButton(
                        icon: const Icon(Icons.skip_next_rounded),
                        onPressed: () => playlist.audioHandler.skipToNext(),
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
  }
}
