import 'package:flutter/material.dart';
import '../../models/song.dart';
import '../../theme.dart';
import '../art_thumbnail.dart';

void showQueueItemContextMenu(
  BuildContext context,
  Song song, {
  VoidCallback? onAddToLibrary,
  VoidCallback? onAddToPlaylist,
  VoidCallback? onDownload,
  VoidCallback? onPlayNext,
  VoidCallback? onRemoveFromQueue,
  VoidCallback? onShare,
  VoidCallback? onStartRadio,
  VoidCallback? onViewAlbum,
  VoidCallback? onViewArtist,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => QueueItemContextMenu(
      song: song,
      onAddToLibrary: onAddToLibrary,
      onAddToPlaylist: onAddToPlaylist,
      onDownload: onDownload,
      onPlayNext: onPlayNext,
      onRemoveFromQueue: onRemoveFromQueue,
      onShare: onShare,
      onStartRadio: onStartRadio,
      onViewAlbum: onViewAlbum,
      onViewArtist: onViewArtist,
    ),
  );
}

class QueueItemContextMenu extends StatelessWidget {
  final Song song;
  final VoidCallback? onAddToLibrary;
  final VoidCallback? onAddToPlaylist;
  final VoidCallback? onDownload;
  final VoidCallback? onPlayNext;
  final VoidCallback? onRemoveFromQueue;
  final VoidCallback? onShare;
  final VoidCallback? onStartRadio;
  final VoidCallback? onViewAlbum;
  final VoidCallback? onViewArtist;

  const QueueItemContextMenu({
    super.key,
    required this.song,
    this.onAddToLibrary,
    this.onAddToPlaylist,
    this.onDownload,
    this.onPlayNext,
    this.onRemoveFromQueue,
    this.onShare,
    this.onStartRadio,
    this.onViewAlbum,
    this.onViewArtist,
  });

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.bg1,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            children: [
              ArtThumbnail(size: 48),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      song.title,
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      song.artist,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 4),
          _MenuItem(
            icon: Icons.library_add,
            label: 'Add to Library',
            onTap: () {
              onAddToLibrary?.call();
              Navigator.pop(context);
            },
          ),
          _MenuItem(
            icon: Icons.playlist_add,
            label: 'Add to Playlist',
            onTap: () {
              onAddToPlaylist?.call();
              Navigator.pop(context);
            },
          ),
          _MenuItem(
            icon: Icons.download_for_offline,
            label: 'Download',
            onTap: () {
              onDownload?.call();
              Navigator.pop(context);
            },
          ),
          _MenuItem(
            icon: Icons.queue_play_next,
            label: 'Play Next',
            onTap: () {
              onPlayNext?.call();
              Navigator.pop(context);
            },
          ),
          _MenuItem(
            icon: Icons.remove_circle_outline,
            label: 'Remove from Queue',
            destructive: true,
            onTap: () {
              onRemoveFromQueue?.call();
              Navigator.pop(context);
            },
          ),
          _MenuItem(
            icon: Icons.share,
            label: 'Share',
            onTap: () {
              onShare?.call();
              Navigator.pop(context);
            },
          ),
          _MenuItem(
            icon: Icons.radio,
            label: 'Start Radio',
            onTap: () {
              onStartRadio?.call();
              Navigator.pop(context);
            },
          ),
          _MenuItem(
            icon: Icons.album,
            label: 'View Album',
            onTap: () {
              onViewAlbum?.call();
              Navigator.pop(context);
            },
          ),
          _MenuItem(
            icon: Icons.person,
            label: 'View Artist',
            onTap: () {
              onViewArtist?.call();
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool destructive;

  const _MenuItem({
    required this.icon,
    required this.label,
    this.onTap,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = destructive ? AppColors.red : AppColors.white;

    return SizedBox(
      height: 56,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Icon(icon, size: 24, color: color),
              const SizedBox(width: 16),
              Text(label, style: TextStyle(fontSize: 16, color: color)),
            ],
          ),
        ),
      ),
    );
  }
}
