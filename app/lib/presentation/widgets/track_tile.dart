import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/utils/accessibility.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/worship_item.dart';
import '../../logic/download/download_provider.dart';
import '../../logic/playlist/playlist_provider.dart';

/// کارت نمایش هر قطعه در لیست با رعایت کامل استانداردهای دسترسی‌پذیری نابینایان (TalkBack)
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

    final String positionFa = AppFormatters.toPersianDigits(item.position.toString());
    final String sizeFa = item.sizeBytes > 0 ? AppFormatters.formatBytes(item.sizeBytes) : '';
    final String statusFa = isDownloaded ? 'آفلاین، ذخیره در حافظه گوشی' : 'آنلاین، استریم از گوگل درایو';
    final String playingFa = isPlaying ? 'در حال پخش است.' : '';

    final String tileSemanticLabel =
        'قطعه $positionFa: ${item.title}. وضعیت: $statusFa. $sizeFa. $playingFa برای پخش دو بار ضربه بزنید.';

    return Card(
      elevation: isPlaying ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isPlaying
            ? const BorderSide(color: Color(0xFF0D9488), width: 1.5)
            : BorderSide.none,
      ),
      child: Semantics(
        label: tileSemanticLabel,
        button: true,
        selected: isPlaying,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: item.hasAudio
              ? () {
                  playlistProvider.playTrack(index);
                  AppAccessibility.announce(context, 'در حال پخش ${item.title}');
                }
              : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                // شماره ردیف (از دید تاک‌بک استثنا می‌شود چون در لیبل کل کارت خوانده شده است)
                ExcludeSemantics(
                  child: Container(
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
                      positionFa,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isPlaying ? Colors.white : theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),

                // متن عنوان و مشخصات
                Expanded(
                  child: ExcludeSemantics(
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
                            Icon(
                              isDownloaded ? Icons.offline_pin_rounded : Icons.cloud_outlined,
                              size: 14,
                              color: isDownloaded ? Colors.green : Colors.grey,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isDownloaded ? 'آفلاین' : 'آنلاین',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDownloaded ? Colors.green : Colors.grey,
                              ),
                            ),
                            const SizedBox(width: 10),
                            if (sizeFa.isNotEmpty)
                              Text(
                                sizeFa,
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // دکمه‌های دانلود و مدیریت فایل با تعاریف دسترسی‌پذیری صوتی
                if (item.hasAudio) ...[
                  if (isDownloading) ...[
                    Semantics(
                      label: 'در حال دانلود ${item.title}، ${AppFormatters.toPersianDigits((progress * 100).toInt().toString())} درصد. دکمه لغو دانلود.',
                      button: true,
                      child: SizedBox(
                        width: 40,
                        height: 40,
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
                              tooltip: 'لغو دانلود',
                              onPressed: () {
                                downloadProvider.cancelDownload(item.driveFileId);
                                AppAccessibility.announce(context, 'دانلود لغو شد');
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ] else if (isDownloaded) ...[
                    Semantics(
                      label: 'فایل ${item.title} قبلاً دانلود شده است. دکمه منوی مدیریت یا حذف فایل.',
                      button: true,
                      child: PopupMenuButton<String>(
                        icon: const Icon(Icons.check_circle_rounded, color: Colors.green),
                        tooltip: 'مدیریت فایل آفلاین',
                        onSelected: (val) {
                          if (val == 'delete') {
                            downloadProvider.deleteDownload(item);
                            playlistProvider.markItemDeleted(item.driveFileId);
                            AppAccessibility.announce(context, 'فایل آفلاین ${item.title} حذف شد');
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
                    ),
                  ] else ...[
                    Semantics(
                      label: 'دکمه دانلود ${item.title} برای استفاده بدون اینترنت. حجم $sizeFa.',
                      button: true,
                      child: IconButton(
                        icon: const Icon(Icons.download_rounded, color: Color(0xFF0D9488)),
                        tooltip: 'دانلود آفلاین',
                        onPressed: () async {
                          AppAccessibility.announce(context, 'دانلود ${item.title} آغاز شد');
                          final path = await downloadProvider.downloadItem(item);
                          if (path != null && context.mounted) {
                            playlistProvider.markItemDownloaded(item.driveFileId, path);
                            AppAccessibility.announce(context, 'دانلود ${item.title} به پایان رسید');
                          }
                        },
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
