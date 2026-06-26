import 'package:flutter/material.dart';
import '../../models/song.dart';
import '../../theme.dart';
import '../art_thumbnail.dart';

void showSongContextMenu(
  BuildContext context,
  Song song, {
  VoidCallback? onAddToLibrary,
  VoidCallback? onRemoveFromLibrary,
  VoidCallback? onAddToQueue,
  VoidCallback? onRemoveFromQueue,
  VoidCallback? onAddToPlaylist,
  VoidCallback? onDownload,
  VoidCallback? onRemoveDownload,
  VoidCallback? onPlayNext,
  VoidCallback? onShare,
  VoidCallback? onStartRadio,
  VoidCallback? onViewAlbum,
  VoidCallback? onViewArtist,
  VoidCallback? onViewDetails,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => SongContextMenu(
      song: song,
      onAddToLibrary: onAddToLibrary,
      onRemoveFromLibrary: onRemoveFromLibrary,
      onAddToQueue: onAddToQueue,
      onRemoveFromQueue: onRemoveFromQueue,
      onAddToPlaylist: onAddToPlaylist,
      onDownload: onDownload,
      onRemoveDownload: onRemoveDownload,
      onPlayNext: onPlayNext,
      onShare: onShare,
      onStartRadio: onStartRadio,
      onViewAlbum: onViewAlbum,
      onViewArtist: onViewArtist,
      onViewDetails: onViewDetails,
    ),
  );
}

class SongContextMenu extends StatefulWidget {
  final Song song;
  final VoidCallback? onAddToLibrary;
  final VoidCallback? onRemoveFromLibrary;
  final VoidCallback? onAddToQueue;
  final VoidCallback? onRemoveFromQueue;
  final VoidCallback? onAddToPlaylist;
  final VoidCallback? onDownload;
  final VoidCallback? onRemoveDownload;
  final VoidCallback? onPlayNext;
  final VoidCallback? onShare;
  final VoidCallback? onStartRadio;
  final VoidCallback? onViewAlbum;
  final VoidCallback? onViewArtist;
  final VoidCallback? onViewDetails;

  const SongContextMenu({
    super.key,
    required this.song,
    this.onAddToLibrary,
    this.onRemoveFromLibrary,
    this.onAddToQueue,
    this.onRemoveFromQueue,
    this.onAddToPlaylist,
    this.onDownload,
    this.onRemoveDownload,
    this.onPlayNext,
    this.onShare,
    this.onStartRadio,
    this.onViewAlbum,
    this.onViewArtist,
    this.onViewDetails,
  });

  @override
  State<SongContextMenu> createState() => _SongContextMenuState();
}

class _SongContextMenuState extends State<SongContextMenu> {
  late bool _inLibrary;
  late bool _inQueue;
  late bool _isDownloaded;
  late bool _isDownloading;

  @override
  void initState() {
    super.initState();
    _inLibrary = widget.song.inLibrary;
    _inQueue = widget.song.inQueue;
    _isDownloaded = widget.song.isDownloaded;
    _isDownloading = widget.song.isDownloading;
  }

  void _handleLibraryToggle(BuildContext context) {
    if (_inLibrary) {
      widget.onRemoveFromLibrary?.call();
    } else {
      widget.onAddToLibrary?.call();
    }
    setState(() => _inLibrary = !_inLibrary);
    Navigator.pop(context);
  }

  void _handleQueueToggle(BuildContext context) {
    if (_inQueue) {
      widget.onRemoveFromQueue?.call();
    } else {
      widget.onAddToQueue?.call();
    }
    setState(() => _inQueue = !_inQueue);
    Navigator.pop(context);
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
              ArtThumbnail(size: 48),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.song.title,
                      style: AppTextStyles.sectionTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      widget.song.artist,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      widget.song.album,
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
              IconButton(
                icon: Icon(
                  _inLibrary ? Icons.library_add_check : Icons.library_add,
                  color: _inLibrary ? AppColors.white : AppColors.textMuted,
                ),
                onPressed: () => _handleLibraryToggle(context),
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
          // Menu items (alphabetical)
          _MenuItem(
            icon: _inLibrary ? Icons.library_add_check : Icons.library_add,
            label: _inLibrary ? 'Remove from Library' : 'Add to Library',
            onTap: () => _handleLibraryToggle(context),
          ),
          _MenuItem(
            icon: Icons.playlist_add,
            label: 'Add to Playlist',
            onTap: () {
              widget.onAddToPlaylist?.call();
              Navigator.pop(context);
            },
          ),
          _MenuItem(
            icon: Icons.queue_music,
            label: _inQueue ? 'Remove from Queue' : 'Add to Queue',
            onTap: () => _handleQueueToggle(context),
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
            icon: Icons.queue_play_next,
            label: 'Play Next',
            onTap: () {
              widget.onPlayNext?.call();
              Navigator.pop(context);
            },
          ),
          _MenuItem(
            icon: Icons.share,
            label: 'Share',
            onTap: () {
              widget.onShare?.call();
              Navigator.pop(context);
            },
          ),
          _MenuItem(
            icon: Icons.radio,
            label: 'Start Radio',
            onTap: () {
              widget.onStartRadio?.call();
              Navigator.pop(context);
            },
          ),
          _MenuItem(
            icon: Icons.album,
            label: 'View Album',
            onTap: () {
              widget.onViewAlbum?.call();
              Navigator.pop(context);
            },
          ),
          _MenuItem(
            icon: Icons.person,
            label: 'View Artist',
            onTap: () {
              widget.onViewArtist?.call();
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
  final bool enabled;

  const _MenuItem({
    required this.icon,
    required this.label,
    this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final color = !enabled
        ? AppColors.textDim
        : AppColors.white;

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
              Text(
                label,
                style: AppTextStyles.menuItemLabel.copyWith(color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
