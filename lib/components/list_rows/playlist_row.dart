import 'package:flutter/material.dart';
import '../../models/playlist.dart';
import '../../theme.dart';
import '../art_thumbnail.dart';
import '../download_button.dart';

class PlaylistRow extends StatelessWidget {
  final Playlist playlist;
  final VoidCallback? onTap;
  final VoidCallback? onMoreTap;
  final VoidCallback? onDownloadTap;

  const PlaylistRow({
    super.key,
    required this.playlist,
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
              const ArtThumbnail(size: 48, icon: Icons.queue_music),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      playlist.name,
                      style: AppTextStyles.listTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      '${playlist.songCount} songs',
                      style: AppTextStyles.listSubtitle,
                    ),
                  ],
                ),
              ),
              if (onDownloadTap != null)
                DownloadButton(
                  isDownloaded: playlist.isDownloaded,
                  isDownloading: playlist.isDownloading,
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
