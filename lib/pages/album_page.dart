import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/song.dart';
import '../models/album.dart';
import '../providers/library_provider.dart';
import '../components/art_thumbnail.dart';
import '../components/buttons.dart';
import '../theme.dart';

class AlbumPage extends ConsumerStatefulWidget {
  final String albumId;

  const AlbumPage({super.key, required this.albumId});

  @override
  ConsumerState<AlbumPage> createState() => _AlbumPageState();
}

class _AlbumPageState extends ConsumerState<AlbumPage> {
  bool isSearchActive = false;
  String searchQuery = '';
  bool isInLibrary = false;
  bool isDownloaded = false;
  bool isDownloading = false;

  Album? album;
  List<Song> songs = [];
  bool isLoading = true;

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final repo = ref.read(musicRepositoryProvider);
    final fetchedAlbum = await repo.getAlbum(widget.albumId);
    final fetchedSongs = await repo.getSongsByAlbum(widget.albumId);
    if (mounted) {
      setState(() {
        album = fetchedAlbum;
        songs = fetchedSongs;
        isInLibrary = fetchedAlbum?.inLibrary ?? false;
        isDownloaded = fetchedAlbum?.isDownloaded ?? false;
        isDownloading = fetchedAlbum?.isDownloading ?? false;
        isLoading = false;
      });
    }
  }

  List<Song> get _filteredSongs {
    if (searchQuery.isEmpty) return songs;
    final q = searchQuery.toLowerCase();
    return songs.where((s) => s.title.toLowerCase().contains(q)).toList();
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
                  if (isSearchActive)
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        autofocus: true,
                        style: const TextStyle(color: AppColors.white),
                        decoration: const InputDecoration(
                          hintText: 'Search songs...',
                          border: InputBorder.none,
                          hintStyle: TextStyle(color: AppColors.textMuted),
                          contentPadding: EdgeInsets.symmetric(horizontal: 8),
                        ),
                        onChanged: (v) => setState(() => searchQuery = v),
                      ),
                    )
                  else
                    const Spacer(),
                  IconButton(
                    icon: Icon(
                      isSearchActive ? Icons.close : Icons.search,
                      color: AppColors.white,
                    ),
                    onPressed: () {
                      setState(() {
                        isSearchActive = !isSearchActive;
                        if (!isSearchActive) {
                          searchQuery = '';
                          _searchController.clear();
                        }
                      });
                    },
                  ),
                ],
              ),
            ),
            if (isLoading)
              const Expanded(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (album != null)
              Expanded(
                child: ListView(
                  children: [
                    // Album info card
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ArtThumbnail(size: 120),
                          const SizedBox(width: AppSpacing.xl),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  album!.title,
                                  style: AppTextStyles.pageTitle,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                Text(album!.artist, style: AppTextStyles.bodyMuted),
                                const SizedBox(height: AppSpacing.xs),
                                Text(
                                  '${album!.year} · ${album!.songCount} songs',
                                  style: AppTextStyles.caption,
                                ),
                                const SizedBox(height: AppSpacing.lg),
                                AppButtonBar(
                                  expanded: false,
                                  buttons: [
                                    AppIconButton(
                                      icon: isInLibrary
                                          ? Icons.library_add_check
                                          : Icons.library_add_outlined,
                                      onTap: () => setState(() => isInLibrary = !isInLibrary),
                                    ),
                                    AppIconButton(
                                      icon: isDownloaded
                                          ? Icons.download_done
                                          : isDownloading
                                              ? Icons.downloading
                                              : Icons.download_for_offline,
                                      onTap: () {
                                        if (!isDownloaded && !isDownloading) {
                                          setState(() => isDownloading = true);
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Action row — Play | Shuffle | Queue
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
                    ..._filteredSongs.asMap().entries.map((entry) {
                      final index = entry.key;
                      final song = entry.value;
                      return _AlbumSongRow(
                        trackNumber: index + 1,
                        song: song,
                        onTap: () {},
                        onMoreTap: () {},
                        onDownloadTap: () {},
                      );
                    }),
                  ],
                ),
              )
            else
              const Expanded(
                child: Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }
}

class _AlbumSongRow extends StatelessWidget {
  final int trackNumber;
  final Song song;
  final VoidCallback onTap;
  final VoidCallback onMoreTap;
  final VoidCallback onDownloadTap;

  const _AlbumSongRow({
    required this.trackNumber,
    required this.song,
    required this.onTap,
    required this.onMoreTap,
    required this.onDownloadTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            SizedBox(
              width: 24,
              child: Text(
                '$trackNumber',
                style: AppTextStyles.caption,
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(width: 12),
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
                  Text(song.duration.mmss, style: AppTextStyles.caption),
                ],
              ),
            ),
            IconButton(
              icon: Icon(
                song.isDownloaded
                    ? Icons.download_done
                    : song.isDownloading
                        ? Icons.downloading
                        : Icons.download_for_offline,
                color: AppColors.textMuted,
                size: 20,
              ),
              onPressed: onDownloadTap,
            ),
            IconButton(
              icon: const Icon(Icons.more_vert, color: AppColors.textMuted, size: 20),
              onPressed: onMoreTap,
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
