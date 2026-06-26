import 'package:flutter/material.dart';
import '../../models/album.dart';
import '../../theme.dart';
import '../art_thumbnail.dart';

void showAlbumContextMenu(
  BuildContext context,
  Album album, {
  VoidCallback? onAddToLibrary,
  VoidCallback? onAddToQueue,
  VoidCallback? onDownload,
  VoidCallback? onRemoveDownload,
  VoidCallback? onPlay,
  VoidCallback? onPlayNext,
  VoidCallback? onShareAlbum,
  VoidCallback? onViewDetails,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => _AlbumContextMenuContent(
      album: album,
      onAddToLibrary: onAddToLibrary,
      onAddToQueue: onAddToQueue,
      onDownload: onDownload,
      onRemoveDownload: onRemoveDownload,
      onPlay: onPlay,
      onPlayNext: onPlayNext,
      onShareAlbum: onShareAlbum,
      onViewDetails: onViewDetails,
    ),
  );
}

class _AlbumContextMenuContent extends StatefulWidget {
  final Album album;
  final VoidCallback? onAddToLibrary;
  final VoidCallback? onAddToQueue;
  final VoidCallback? onDownload;
  final VoidCallback? onRemoveDownload;
  final VoidCallback? onPlay;
  final VoidCallback? onPlayNext;
  final VoidCallback? onShareAlbum;
  final VoidCallback? onViewDetails;

  const _AlbumContextMenuContent({
    required this.album,
    this.onAddToLibrary,
    this.onAddToQueue,
    this.onDownload,
    this.onRemoveDownload,
    this.onPlay,
    this.onPlayNext,
    this.onShareAlbum,
    this.onViewDetails,
  });

  @override
  State<_AlbumContextMenuContent> createState() => _AlbumContextMenuContentState();
}

class _AlbumContextMenuContentState extends State<_AlbumContextMenuContent> {
  late bool _inLibrary;
  late bool _isDownloaded;
  late bool _isDownloading;

  @override
  void initState() {
    super.initState();
    _inLibrary = widget.album.inLibrary;
    _isDownloaded = widget.album.isDownloaded;
    _isDownloading = widget.album.isDownloading;
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
              ArtThumbnail(size: 64),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.album.title,
                      style: AppTextStyles.sectionTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      widget.album.artist,
                      style: AppTextStyles.menuSubtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${widget.album.year}',
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
            label: 'Share Album',
            onTap: () {
              widget.onShareAlbum?.call();
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
              Text(label, style: AppTextStyles.menuItemLabel.copyWith(color: color)),
            ],
          ),
        ),
      ),
    );
  }
}
