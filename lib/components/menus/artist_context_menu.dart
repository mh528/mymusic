import 'package:flutter/material.dart';
import '../../models/artist.dart';
import '../../theme.dart';
import '../art_thumbnail.dart';

void showArtistContextMenu(
  BuildContext context,
  Artist artist, {
  VoidCallback? onAddToLibrary,
  VoidCallback? onPlayRadio,
  VoidCallback? onShareArtist,
  VoidCallback? onShuffleArtist,
  VoidCallback? onViewArtist,
  VoidCallback? onViewDetails,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => _ArtistContextMenuContent(
      artist: artist,
      onAddToLibrary: onAddToLibrary,
      onPlayRadio: onPlayRadio,
      onShareArtist: onShareArtist,
      onShuffleArtist: onShuffleArtist,
      onViewArtist: onViewArtist,
      onViewDetails: onViewDetails,
    ),
  );
}

class _ArtistContextMenuContent extends StatefulWidget {
  final Artist artist;
  final VoidCallback? onAddToLibrary;
  final VoidCallback? onPlayRadio;
  final VoidCallback? onShareArtist;
  final VoidCallback? onShuffleArtist;
  final VoidCallback? onViewArtist;
  final VoidCallback? onViewDetails;

  const _ArtistContextMenuContent({
    required this.artist,
    this.onAddToLibrary,
    this.onPlayRadio,
    this.onShareArtist,
    this.onShuffleArtist,
    this.onViewArtist,
    this.onViewDetails,
  });

  @override
  State<_ArtistContextMenuContent> createState() => _ArtistContextMenuContentState();
}

class _ArtistContextMenuContentState extends State<_ArtistContextMenuContent> {
  late bool _inLibrary;

  @override
  void initState() {
    super.initState();
    _inLibrary = widget.artist.inLibrary;
  }

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
              ArtThumbnail(size: 64),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.artist.name,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
            ],
          ),
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 4),
          _MenuItem(
            icon: Icons.library_add,
            label: 'Add to Library',
            onTap: () {
              widget.onAddToLibrary?.call();
              Navigator.pop(context);
            },
          ),
          _MenuItem(
            icon: Icons.radio,
            label: 'Play Radio',
            onTap: () {
              widget.onPlayRadio?.call();
              Navigator.pop(context);
            },
          ),
          _MenuItem(
            icon: Icons.share,
            label: 'Share Artist',
            onTap: () {
              widget.onShareArtist?.call();
              Navigator.pop(context);
            },
          ),
          _MenuItem(
            icon: Icons.shuffle,
            label: 'Shuffle Artist',
            onTap: () {
              widget.onShuffleArtist?.call();
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
