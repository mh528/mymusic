import 'package:flutter/material.dart';
import '../../models/song.dart';
import '../../theme.dart';
import '../art_thumbnail.dart';

void showNowPlayingMoreMenu(
  BuildContext context,
  Song song, {
  required double volume,
  required ValueChanged<double> onVolumeChanged,
  VoidCallback? onAddToPlaylist,
  VoidCallback? onDownload,
  VoidCallback? onRemoveDownload,
  VoidCallback? onShare,
  VoidCallback? onStartRadio,
  VoidCallback? onViewAlbum,
  VoidCallback? onViewArtist,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => NowPlayingMoreMenu(
      song: song,
      volume: volume,
      onVolumeChanged: onVolumeChanged,
      onAddToPlaylist: onAddToPlaylist,
      onDownload: onDownload,
      onRemoveDownload: onRemoveDownload,
      onShare: onShare,
      onStartRadio: onStartRadio,
      onViewAlbum: onViewAlbum,
      onViewArtist: onViewArtist,
    ),
  );
}

class NowPlayingMoreMenu extends StatefulWidget {
  final Song song;
  final double volume;
  final ValueChanged<double> onVolumeChanged;
  final VoidCallback? onAddToPlaylist;
  final VoidCallback? onDownload;
  final VoidCallback? onRemoveDownload;
  final VoidCallback? onShare;
  final VoidCallback? onStartRadio;
  final VoidCallback? onViewAlbum;
  final VoidCallback? onViewArtist;

  const NowPlayingMoreMenu({
    super.key,
    required this.song,
    required this.volume,
    required this.onVolumeChanged,
    this.onAddToPlaylist,
    this.onDownload,
    this.onRemoveDownload,
    this.onShare,
    this.onStartRadio,
    this.onViewAlbum,
    this.onViewArtist,
  });

  @override
  State<NowPlayingMoreMenu> createState() => _NowPlayingMoreMenuState();
}

class _NowPlayingMoreMenuState extends State<NowPlayingMoreMenu> {
  late double _volume;
  late bool _isDownloaded;
  late bool _isDownloading;

  @override
  void initState() {
    super.initState();
    _volume = widget.volume;
    _isDownloaded = widget.song.isDownloaded;
    _isDownloading = widget.song.isDownloading;
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
              ArtThumbnail(size: 56),
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
                      style: AppTextStyles.menuSubtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      widget.song.album,
                      style: AppTextStyles.menuSubtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          // Volume slider
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              children: [
                const Icon(Icons.volume_down, color: AppColors.textMuted, size: 20),
                Expanded(
                  child: Slider(
                    value: _volume,
                    min: 0,
                    max: 1,
                    onChanged: (v) {
                      setState(() => _volume = v);
                      widget.onVolumeChanged(v);
                    },
                  ),
                ),
                const Icon(Icons.volume_up, color: AppColors.textMuted, size: 20),
              ],
            ),
          ),
          const Divider(),
          const SizedBox(height: AppSpacing.sm),
          // Menu items
          _MenuItem(
            icon: Icons.playlist_add,
            label: 'Add to Playlist',
            onTap: () {
              widget.onAddToPlaylist?.call();
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
    final color = enabled ? AppColors.white : AppColors.textDim;

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
