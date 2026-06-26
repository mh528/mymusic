import 'package:flutter/material.dart';
import '../../models/album.dart';
import '../../theme.dart';
import '../art_thumbnail.dart';
import '../download_button.dart';

class AlbumRow extends StatelessWidget {
  final Album album;
  final VoidCallback? onTap;
  final VoidCallback? onMoreTap;
  final VoidCallback? onDownloadTap;

  const AlbumRow({
    super.key,
    required this.album,
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
              const ArtThumbnail(size: 48),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      album.title,
                      style: AppTextStyles.listTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      '${album.artist} · ${album.year}',
                      style: AppTextStyles.listSubtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (onDownloadTap != null)
                DownloadButton(
                  isDownloaded: album.isDownloaded,
                  isDownloading: album.isDownloading,
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
