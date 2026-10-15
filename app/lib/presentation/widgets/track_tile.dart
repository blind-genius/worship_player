import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/worship_item.dart';
import '../../logic/download/download_provider.dart';
import '../../logic/playlist/playlist_provider.dart';

/// کارت نمایش هر قطعه در لیست با امکان پخش و دانلود
class TrackTile extends StatelessWidget {
  final WorshipItem item;
  final int index;
  final bool isPlaying;

  const TrackTile({
    super.key,
    required this.item,
    required this.index,
    required this.isPlaying,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final downloadProvider = context.watch<DownloadProvider>();
    final playlistProvider = context.read<PlaylistProvider>();

    final isDownloading = downloadProvider.isDownloading(item.driveFileId);
    final progress = downloadProvider.getProgress(item.driveFileId);
    final isDownloaded = item.isDownloaded;

    return Card(
      elevation: isPlaying ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isPlaying
            ? const BorderSide(color: Color(0xFF0D9488), width: 1.5)
            : BorderSide.none,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: item.hasAudio ? () => playlistProvider.playTrack(index) : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              // شماره ردیف بر اساس ترتیب تلگرام
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: isPlaying
                      ? const Color(0xFF0D9488)
                      : theme.colorScheme.surfaceContainerHighest,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  AppFormatters.toPersianDigits(item.position.toString()),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isPlaying ? Colors.white : theme.colorScheme.onSurface,
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // عنوان و وضعیت دانلود
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: isPlaying ? FontWeight.bold : FontWeight.w600,
                        color: isPlaying ? const Color(0xFF0D9488) : null,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (isDownloaded) ...[
                          const Icon(Icons.offline_pin_rounded, size: 14, color: Colors.green),
                          const SizedBox(width: 4),
                          const Text(
                            'آفلاین',
                            style: TextStyle(fontSize: 12, color: Colors.green),
                          ),
                        ] else ...[
                          const Icon(Icons.cloud_outlined, size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          const Text(
                            'آنلاین',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                        const SizedBox(width: 10),
                        if (item.sizeBytes > 0)
                          Text(
                            AppFormatters.formatBytes(item.sizeBytes),
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              // بخش دانلود / پخش
              if (item.hasAudio) ...[
                if (isDownloading) ...[
                  SizedBox(
                    width: 36,
                    height: 36,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircularProgressIndicator(
                          value: progress > 0 ? progress : null,
                          strokeWidth: 3,
                          color: const Color(0xFF0D9488),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 16),
                          onPressed: () => downloadProvider.cancelDownload(item.driveFileId),
                        ),
                      ],
                    ),
                  ),
                ] else if (isDownloaded) ...[
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.check_circle_rounded, color: Colors.green),
                    onSelected: (val) {
                      if (val == 'delete') {
                        downloadProvider.deleteDownload(item);
                        playlistProvider.markItemDeleted(item.driveFileId);
                      }
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline, color: Colors.red, size: 20),
                            SizedBox(width: 8),
                            Text('حذف فایل آفلاین'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  IconButton(
                    icon: const Icon(Icons.download_rounded, color: Color(0xFF0D9488)),
                    tooltip: 'دانلود جهت پخش آفلاین',
                    onPressed: () async {
                      final path = await downloadProvider.downloadItem(item);
                      if (path != null) {
                        playlistProvider.markItemDownloaded(item.driveFileId, path);
                      }
                    },
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}
