import 'package:flutter/material.dart';
import '../../models/playlist.dart';
import '../../theme.dart';
import '../art_thumbnail.dart';

void showPlaylistContextMenu(
  BuildContext context,
  Playlist playlist, {
  bool inLibrary = false,
  VoidCallback? onAddToLibrary,
  VoidCallback? onAddToQueue,
  VoidCallback? onDeletePlaylist,
  VoidCallback? onDownload,
  VoidCallback? onRemoveDownload,
  VoidCallback? onEditPlaylist,
  VoidCallback? onPlay,
  VoidCallback? onPlayNext,
  VoidCallback? onSharePlaylist,
  VoidCallback? onViewDetails,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => _PlaylistContextMenuContent(
      playlist: playlist,
      inLibrary: inLibrary,
      onAddToLibrary: onAddToLibrary,
      onAddToQueue: onAddToQueue,
      onDeletePlaylist: onDeletePlaylist,
      onDownload: onDownload,
      onRemoveDownload: onRemoveDownload,
      onEditPlaylist: onEditPlaylist,
      onPlay: onPlay,
      onPlayNext: onPlayNext,
      onSharePlaylist: onSharePlaylist,
      onViewDetails: onViewDetails,
    ),
  );
}

class _PlaylistContextMenuContent extends StatefulWidget {
  final Playlist playlist;
  final bool inLibrary;
  final VoidCallback? onAddToLibrary;
  final VoidCallback? onAddToQueue;
  final VoidCallback? onDeletePlaylist;
  final VoidCallback? onDownload;
  final VoidCallback? onRemoveDownload;
  final VoidCallback? onEditPlaylist;
  final VoidCallback? onPlay;
  final VoidCallback? onPlayNext;
  final VoidCallback? onSharePlaylist;
  final VoidCallback? onViewDetails;

  const _PlaylistContextMenuContent({
    required this.playlist,
    this.inLibrary = false,
    this.onAddToLibrary,
    this.onAddToQueue,
    this.onDeletePlaylist,
    this.onDownload,
    this.onRemoveDownload,
    this.onEditPlaylist,
    this.onPlay,
    this.onPlayNext,
    this.onSharePlaylist,
    this.onViewDetails,
  });

  @override
  State<_PlaylistContextMenuContent> createState() => _PlaylistContextMenuContentState();
}

class _PlaylistContextMenuContentState extends State<_PlaylistContextMenuContent> {
  late bool _inLibrary;
  late bool _isDownloaded;
  late bool _isDownloading;

  @override
  void initState() {
    super.initState();
    _inLibrary = widget.inLibrary;
    _isDownloaded = widget.playlist.isDownloaded;
    _isDownloading = widget.playlist.isDownloading;
  }

  void _handleDownloadToggle(BuildContext context) {
    if (_isDownloaded) {
      widget.onRemoveDownload?.call();
      setState(() => _isDownloaded = false);
    } else if (!_isDownloading) {
      widget.onDownload?.call();
      setState(() => _isDownloading = true);
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final songCount = widget.playlist.songCount;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.bg1,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.bottomSheet)),
      ),
      padding: EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.xl, AppSpacing.xl, AppSpacing.xl + bottomPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            children: [
              ArtThumbnail(size: 64),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.playlist.name,
                      style: AppTextStyles.sectionTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '$songCount ${songCount == 1 ? 'song' : 'songs'}',
                      style: AppTextStyles.menuSubtitle,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  _inLibrary ? Icons.library_add_check : Icons.library_add,
                  color: _inLibrary ? AppColors.white : AppColors.textMuted,
                ),
                onPressed: () {
                  widget.onAddToLibrary?.call();
                  setState(() => _inLibrary = !_inLibrary);
                },
              ),
              IconButton(
                icon: Icon(
                  _isDownloading
                      ? Icons.downloading
                      : _isDownloaded
                          ? Icons.download_done
                          : Icons.download_for_offline,
                  color: _isDownloaded ? AppColors.white : AppColors.textMuted,
                ),
                onPressed: _isDownloading ? null : () => _handleDownloadToggle(context),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          const Divider(),
          const SizedBox(height: AppSpacing.sm),
          _MenuItem(
            icon: Icons.library_add,
            label: 'Add to Library',
            onTap: () {
              widget.onAddToLibrary?.call();
              Navigator.pop(context);
            },
          ),
          _MenuItem(
            icon: Icons.queue_music,
            label: 'Add to Queue',
            onTap: () {
              widget.onAddToQueue?.call();
              Navigator.pop(context);
            },
          ),
          _MenuItem(
            icon: Icons.delete_outline,
            label: 'Delete Playlist',
            destructive: true,
            onTap: () {
              widget.onDeletePlaylist?.call();
              Navigator.pop(context);
            },
          ),
          _MenuItem(
            icon: _isDownloading
                ? Icons.downloading
                : _isDownloaded
                    ? Icons.download_done
                    : Icons.download_for_offline,
            label: _isDownloading
                ? 'Downloading…'
                : _isDownloaded
                    ? 'Remove Download'
                    : 'Download',
            enabled: !_isDownloading,
            onTap: () => _handleDownloadToggle(context),
          ),
          _MenuItem(
            icon: Icons.edit,
            label: 'Edit Playlist',
            onTap: () {
              widget.onEditPlaylist?.call();
              Navigator.pop(context);
            },
          ),
          _MenuItem(
            icon: Icons.play_arrow,
            label: 'Play',
            onTap: () {
              widget.onPlay?.call();
              Navigator.pop(context);
            },
          ),
          _MenuItem(
            icon: Icons.queue_play_next,
            label: 'Play Next',
            onTap: () {
              widget.onPlayNext?.call();
              Navigator.pop(context);
            },
          ),
          _MenuItem(
            icon: Icons.share,
            label: 'Share Playlist',
            onTap: () {
              widget.onSharePlaylist?.call();
              Navigator.pop(context);
            },
          ),
          _MenuItem(
            icon: Icons.info_outline,
            label: 'View Details',
            onTap: () {
              widget.onViewDetails?.call();
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
  final bool enabled;

  const _MenuItem({
    required this.icon,
    required this.label,
    this.onTap,
    this.destructive = false,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final color = !enabled ? AppColors.textDim : destructive ? AppColors.red : AppColors.white;

    return SizedBox(
      height: AppSpacing.menuItemHeight,
      child: InkWell(
        onTap: enabled ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          child: Row(
            children: [
              Icon(icon, size: AppIconSize.md, color: color),
              const SizedBox(width: AppSpacing.xl),
              Text(label, style: AppTextStyles.menuItemLabel.copyWith(color: color)),
            ],
          ),
        ),
      ),
    );
  }
}
