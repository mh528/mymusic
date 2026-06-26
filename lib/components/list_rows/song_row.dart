import 'package:flutter/material.dart';
import '../../models/song.dart';
import '../../theme.dart';
import '../art_thumbnail.dart';
import '../download_button.dart';

class SongRow extends StatelessWidget {
  final Song song;
  final VoidCallback? onTap;
  final VoidCallback? onMoreTap;
  final VoidCallback? onDownloadTap;

  const SongRow({
    super.key,
    required this.song,
    this.onTap,
    this.onMoreTap,
    this.onDownloadTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppSpacing.rowHeight,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.md),
          child: Row(
            children: [
              ArtThumbnail(size: 48),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      song.title,
                      style: AppTextStyles.listTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      '${song.artist} · ${song.duration.mmss}',
                      style: AppTextStyles.listSubtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (onDownloadTap != null)
                DownloadButton(
                  isDownloaded: song.isDownloaded,
                  isDownloading: song.isDownloading,
                  onTap: onDownloadTap!,
                ),
              IconButton(
                icon: const Icon(
                  Icons.more_vert,
                  color: AppColors.textMuted,
                  size: AppIconSize.sm,
                ),
                onPressed: onMoreTap,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
