import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/playlist.dart';
import '../models/song.dart';
import '../providers/library_provider.dart';
import '../components/art_thumbnail.dart';
import '../components/buttons.dart';
import '../components/list_rows/song_row.dart';
import '../theme.dart';

class PlaylistPage extends ConsumerStatefulWidget {
  final String playlistId;

  const PlaylistPage({super.key, required this.playlistId});

  @override
  ConsumerState<PlaylistPage> createState() => _PlaylistPageState();
}

class _PlaylistPageState extends ConsumerState<PlaylistPage> {
  Playlist? playlist;
  List<Song> songs = [];
  bool isLoading = true;
  bool _isEditing = false;
  String? _confirmingRemoveId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final repo = ref.read(musicRepositoryProvider);
    final fetchedPlaylist = await repo.getPlaylist(widget.playlistId);
    List<Song> fetchedSongs = [];
    if (fetchedPlaylist != null) {
      final allSongs = await repo.getAllSongs();
      final ids = fetchedPlaylist.songIds.toSet();
      fetchedSongs = allSongs.where((s) => ids.contains(s.id)).toList();
    }
    if (mounted) {
      setState(() {
        playlist = fetchedPlaylist;
        songs = fetchedSongs;
        isLoading = false;
      });
    }
  }

  void _removeSong(String songId) {
    setState(() {
      songs = songs.where((s) => s.id != songId).toList();
      _confirmingRemoveId = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Header row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: AppColors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  Expanded(
                    child: Text(
                      playlist?.name ?? '',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.sectionTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            if (isLoading)
              const Expanded(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (songs.isEmpty && !_isEditing)
              const Expanded(
                child: Center(
                  child: Text(
                    'This playlist is empty',
                    style: AppTextStyles.bodyMuted,
                  ),
                ),
              )
            else
              Expanded(
                child: Column(
                  children: [
                    // Playlist info card
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ArtThumbnail(size: 120, icon: Icons.queue_music),
                          const SizedBox(width: AppSpacing.xl),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  playlist!.name,
                                  style: AppTextStyles.pageTitle,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                Text(
                                  '${playlist!.songCount} songs',
                                  style: AppTextStyles.bodyMuted,
                                ),
                                const SizedBox(height: AppSpacing.lg),
                                AppButtonBar(
                                  expanded: false,
                                  buttons: [
                                    AppIconButton(
                                      icon: Icons.edit,
                                      iconColor: _isEditing ? AppColors.white : AppColors.textMuted,
                                      onTap: () => setState(() {
                                        _isEditing = !_isEditing;
                                        _confirmingRemoveId = null;
                                      }),
                                    ),
                                    AppIconButton(
                                      icon: Icons.download_for_offline,
                                      onTap: () {},
                                    ),
                                    AppIconButton(
                                      icon: Icons.delete_outline,
                                      iconColor: AppColors.red,
                                      onTap: () {},
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Action row
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.sm),
                      child: Row(
                        children: [
                          Expanded(child: _ActionBtn(icon: Icons.play_arrow, label: 'Play', onTap: () {})),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(child: _ActionBtn(icon: Icons.shuffle, label: 'Shuffle', onTap: () {})),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(child: _ActionBtn(icon: Icons.queue_music, label: 'Queue', onTap: () {})),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    // Songs list
                    Expanded(
                      child: _isEditing
                          ? ReorderableListView(
                              onReorderItem: (oldIndex, newIndex) {
                                setState(() {
                                  final item = songs.removeAt(oldIndex);
                                  songs.insert(newIndex, item);
                                });
                              },
                              children: songs
                                  .map((song) => _PlaylistSongRow(
                                        key: ValueKey(song.id),
                                        song: song,
                                        isEditing: true,
                                        isConfirmingRemove: song.id == _confirmingRemoveId,
                                        onDeleteTap: () =>
                                            setState(() => _confirmingRemoveId = song.id),
                                        onConfirmRemove: () => _removeSong(song.id),
                                        onCancelConfirm: () =>
                                            setState(() => _confirmingRemoveId = null),
                                      ))
                                  .toList(),
                            )
                          : ListView(
                              children: songs
                                  .map((song) => _PlaylistSongRow(
                                        key: ValueKey(song.id),
                                        song: song,
                                        isEditing: false,
                                        isConfirmingRemove: false,
                                        onDeleteTap: () {},
                                        onConfirmRemove: () {},
                                        onCancelConfirm: () {},
                                      ))
                                  .toList(),
                            ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionBtn({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: TextButton.icon(
        onPressed: onTap,
        icon: Icon(icon, color: AppColors.white, size: AppIconSize.sm),
        label: Text(label, style: AppTextStyles.body),
        style: TextButton.styleFrom(
          backgroundColor: AppColors.bg3,
          foregroundColor: AppColors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.card)),
          padding: EdgeInsets.zero,
        ),
      ),
    );
  }
}

class _PlaylistSongRow extends StatelessWidget {
  final Song song;
  final bool isEditing;
  final bool isConfirmingRemove;
  final VoidCallback onDeleteTap;
  final VoidCallback onConfirmRemove;
  final VoidCallback onCancelConfirm;

  const _PlaylistSongRow({
    super.key,
    required this.song,
    required this.isEditing,
    required this.isConfirmingRemove,
    required this.onDeleteTap,
    required this.onConfirmRemove,
    required this.onCancelConfirm,
  });

  @override
  Widget build(BuildContext context) {
    if (!isEditing) {
      return SongRow(
        song: song,
        onTap: () {},
        onDownloadTap: () {},
        onMoreTap: () {},
      );
    }

    return GestureDetector(
      onTap: isConfirmingRemove ? onCancelConfirm : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.md),
        child: Row(
          children: [
            const Icon(Icons.drag_handle, color: AppColors.textMuted, size: AppIconSize.sm),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    song.title,
                    style: AppTextStyles.listTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    song.artist,
                    style: AppTextStyles.menuSubtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (isConfirmingRemove)
              TextButton(
                onPressed: onConfirmRemove,
                child: Text('Confirm Remove',
                    style: AppTextStyles.menuSubtitle.copyWith(color: AppColors.red)),
              )
            else
              IconButton(
                icon: const Icon(Icons.delete_outline, color: AppColors.red),
                onPressed: onDeleteTap,
              ),
          ],
        ),
      ),
    );
  }
}
