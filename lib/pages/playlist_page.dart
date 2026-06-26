import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/playlist.dart';
import '../models/song.dart';
import '../providers/library_provider.dart';
import '../components/art_thumbnail.dart';
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
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
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
                    style: TextStyle(color: AppColors.textMuted, fontSize: 14),
                  ),
                ),
              )
            else
              Expanded(
                child: Column(
                  children: [
                    // Playlist info card
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              color: AppColors.bg3,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const ArtThumbnail(size: 120, icon: Icons.queue_music),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  playlist!.name,
                                  style: const TextStyle(
                                    color: AppColors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${playlist!.songCount} songs',
                                  style: const TextStyle(
                                    color: AppColors.textMuted,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                // Icon buttons row
                                Row(
                                  children: [
                                    _IconBtn(
                                      icon: Icons.edit,
                                      color: _isEditing ? AppColors.white : AppColors.textMuted,
                                      onTap: () => setState(() {
                                        _isEditing = !_isEditing;
                                        _confirmingRemoveId = null;
                                      }),
                                    ),
                                    const SizedBox(width: 8),
                                    _IconBtn(
                                      icon: Icons.download_for_offline,
                                      onTap: () {},
                                    ),
                                    const SizedBox(width: 8),
                                    _IconBtn(
                                      icon: Icons.delete_outline,
                                      color: AppColors.red,
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
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: Row(
                        children: [
                          Expanded(
                            child: _ActionBtn(
                              icon: Icons.play_arrow,
                              label: 'Play',
                              onTap: () {},
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _ActionBtn(
                              icon: Icons.shuffle,
                              label: 'Shuffle',
                              onTap: () {},
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _ActionBtn(
                              icon: Icons.queue_music,
                              label: 'Queue',
                              onTap: () {},
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(),
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

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _IconBtn({
    required this.icon,
    this.color = AppColors.textMuted,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.bg3,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, color: color, size: 18),
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionBtn({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(
          backgroundColor: AppColors.bg2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: EdgeInsets.zero,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.white, size: 18),
            const SizedBox(width: 4),
            Text(label, style: const TextStyle(color: AppColors.white, fontSize: 13)),
          ],
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            const Icon(Icons.drag_handle, color: AppColors.textMuted),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    song.title,
                    style: const TextStyle(color: AppColors.white, fontSize: 15),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    song.artist,
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (isConfirmingRemove)
              TextButton(
                onPressed: onConfirmRemove,
                child: const Text('Confirm Remove',
                    style: TextStyle(color: AppColors.red, fontSize: 13)),
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
