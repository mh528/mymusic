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
      height: 64,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              const ArtThumbnail(size: 48, icon: Icons.queue_music),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      playlist.name,
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 15,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${playlist.songCount} songs',
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
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
                  size: 20,
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
