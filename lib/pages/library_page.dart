import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/settings.dart';
import '../models/song.dart';
import '../models/album.dart';
import '../models/artist.dart';
import '../models/playlist.dart';
import '../providers/library_provider.dart';
import '../providers/playback_provider.dart';
import '../providers/search_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/yt_library_provider.dart';
import '../components/tabs/filter_chips_row.dart';
import '../components/tabs/content_tab_bar.dart';
import '../components/list_rows/song_row.dart';
import '../components/list_rows/album_row.dart';
import '../components/list_rows/artist_row.dart';
import '../components/list_rows/playlist_row.dart';
import '../components/menus/song_context_menu.dart';
import '../components/menus/album_context_menu.dart';
import '../components/menus/artist_context_menu.dart';
import '../components/menus/playlist_context_menu.dart';
import '../theme.dart';

class LibraryPage extends ConsumerStatefulWidget {
  const LibraryPage({super.key});

  @override
  ConsumerState<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends ConsumerState<LibraryPage> {
  String _searchQuery = '';
  String _activeSource = 'Library';
  LibraryTab _activeTab = LibraryTab.songs;
  Timer? _searchDebounce;

  final TextEditingController _searchController = TextEditingController();

  static const List<String> _sources = ['Library', 'Downloads', 'All Music'];

  void _triggerYtSearch(String query) {
    _searchDebounce?.cancel();
    if (query.trim().isEmpty) {
      ref.read(searchProvider.notifier).clearQuery();
      return;
    }
    _searchDebounce = Timer(const Duration(milliseconds: 400), () {
      ref.read(searchProvider.notifier).search(query);
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _syncFromSettings(AppSettings settings) {
    final visibleTabs = settings.orderedVisibleTabs;
    if (visibleTabs.isEmpty) return;
    if (!visibleTabs.contains(_activeTab)) {
      setState(() {
        _activeTab = visibleTabs.first;
      });
    }
  }

  String _tabLabel(LibraryTab tab) {
    return switch (tab) {
      LibraryTab.songs => 'Songs',
      LibraryTab.albums => 'Albums',
      LibraryTab.artists => 'Artists',
      LibraryTab.playlists => 'Playlists',
    };
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(settingsProvider);
    final libraryAsync = ref.watch(libraryProvider);
    final allSongs = ref.watch(allSongsProvider);
    final libraryNotifier = ref.read(libraryProvider.notifier);
    final playbackNotifier = ref.read(playbackProvider.notifier);

    settingsAsync.whenData((settings) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _syncFromSettings(settings);
      });
    });

    final settings = settingsAsync.valueOrNull;
    final visibleTabs =
        settings?.orderedVisibleTabs ?? LibraryTab.values.toList();
    final searchState = ref.watch(searchProvider);

    return SafeArea(
      child: Column(
        children: [
          // Search field — always visible
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: AppColors.white),
              decoration: InputDecoration(
                hintText: 'Search music',
                prefixIcon:
                    const Icon(Icons.search, color: AppColors.textMuted),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close,
                            color: AppColors.textMuted),
                        onPressed: () {
                          setState(() {
                            _searchQuery = '';
                            _searchController.clear();
                          });
                          if (_activeSource == 'All Music') {
                            _searchDebounce?.cancel();
                            ref.read(searchProvider.notifier).clearQuery();
                          }
                        },
                      )
                    : null,
              ),
              onChanged: (v) {
                setState(() => _searchQuery = v);
                if (_activeSource == 'All Music') _triggerYtSearch(v);
              },
            ),
          ),

          // Source filter chips
          FilterChipsRow<String>(
            options: _sources,
            selected: _activeSource,
            label: (s) => s,
            onSelected: (src) {
              setState(() => _activeSource = src);
              if (src == 'All Music') {
                _triggerYtSearch(_searchQuery);
              } else {
                _searchDebounce?.cancel();
                ref.read(searchProvider.notifier).clearQuery();
              }
            },
          ),

          // Main content
          Expanded(
            child: libraryAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(
                child: Text(
                  'Error loading library',
                  style: TextStyle(color: AppColors.textMuted),
                ),
              ),
              data: (library) {
                // All Music + query → show live YT results
                if (_activeSource == 'All Music' && _searchQuery.trim().isNotEmpty) {
                  if (searchState.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final ytSongs = searchState.results.songs;
                  if (ytSongs.isEmpty) {
                    return Center(
                      child: Text(
                        "No results for '$_searchQuery'",
                        style: const TextStyle(color: AppColors.textMuted, fontSize: 16),
                      ),
                    );
                  }
                  return _buildSongsList(
                    context,
                    songs: ytSongs,
                    libraryNotifier: libraryNotifier,
                    playbackNotifier: playbackNotifier,
                    settings: settings,
                    isYtResult: true,
                  );
                }
                // All Music + no query → prompt to search
                if (_activeSource == 'All Music' && _searchQuery.trim().isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.search, size: 56, color: AppColors.textMuted),
                        SizedBox(height: 16),
                        Text(
                          'Search to discover music',
                          style: TextStyle(color: AppColors.textMuted, fontSize: 16),
                        ),
                      ],
                    ),
                  );
                }
                return _buildContent(
                  context,
                  library: library,
                  allSongs: allSongs,
                  visibleTabs: visibleTabs,
                  libraryNotifier: libraryNotifier,
                  playbackNotifier: playbackNotifier,
                  settings: settings,
                );
              },
            ),
          ),

          // Bottom tab bar
          if (visibleTabs.length > 1)
            ContentTabBar(
              tabs: visibleTabs.map(_tabLabel).toList(),
              selectedIndex: visibleTabs.contains(_activeTab)
                  ? visibleTabs.indexOf(_activeTab)
                  : 0,
              onTabChanged: (i) =>
                  setState(() => _activeTab = visibleTabs[i]),
            ),
        ],
      ),
    );
  }

  Widget _buildContent(
    BuildContext context, {
    required LibraryState library,
    required List<Song> allSongs,
    required List<LibraryTab> visibleTabs,
    required LibraryNotifier libraryNotifier,
    required PlaybackNotifier playbackNotifier,
    AppSettings? settings,
  }) {
    final effectiveTab =
        visibleTabs.contains(_activeTab) ? _activeTab : visibleTabs.first;

    return switch (effectiveTab) {
      LibraryTab.songs => _buildSongsList(
          context,
          songs: _filterSongs(library.songs, allSongs),
          libraryNotifier: libraryNotifier,
          playbackNotifier: playbackNotifier,
          settings: settings,
        ),
      LibraryTab.albums => _buildAlbumsList(
          context,
          albums: _filterAlbums(library.albums),
          libraryNotifier: libraryNotifier,
        ),
      LibraryTab.artists => _buildArtistsList(
          context,
          artists: _filterArtists(library.artists),
          libraryNotifier: libraryNotifier,
        ),
      LibraryTab.playlists => _buildPlaylistsList(
          context,
          playlists: _filterPlaylists(library.playlists),
          libraryNotifier: libraryNotifier,
        ),
    };
  }

  List<Song> _filterSongs(List<Song> songs, List<Song> allSongs) {
    var filtered = switch (_activeSource) {
      'Library' => songs.where((s) => s.inLibrary).toList(),
      'Downloads' => songs.where((s) => s.isDownloaded).toList(),
      _ => allSongs, // All Music — local + YT library songs
    };
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      filtered = filtered
          .where((s) =>
              s.title.toLowerCase().contains(q) ||
              s.artist.toLowerCase().contains(q))
          .toList();
    }
    return filtered;
  }

  List<Album> _filterAlbums(List<Album> albums) {
    var filtered = switch (_activeSource) {
      'Downloads' => albums.where((a) => a.isDownloaded).toList(),
      _ => albums,
    };
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      filtered = filtered
          .where((a) =>
              a.title.toLowerCase().contains(q) ||
              a.artist.toLowerCase().contains(q))
          .toList();
    }
    return filtered;
  }

  List<Artist> _filterArtists(List<Artist> artists) {
    var filtered = artists;
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      filtered =
          filtered.where((a) => a.name.toLowerCase().contains(q)).toList();
    }
    return filtered;
  }

  List<Playlist> _filterPlaylists(List<Playlist> playlists) {
    var filtered = switch (_activeSource) {
      'Downloads' => playlists.where((p) => p.isDownloaded).toList(),
      _ => playlists,
    };
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      filtered =
          filtered.where((p) => p.name.toLowerCase().contains(q)).toList();
    }
    return filtered;
  }

  Widget _buildSongsList(
    BuildContext context, {
    required List<Song> songs,
    required LibraryNotifier libraryNotifier,
    required PlaybackNotifier playbackNotifier,
    AppSettings? settings,
    bool isYtResult = false,
  }) {
    if (_activeSource == 'Downloads' && songs.isEmpty) {
      return _buildEmptyDownloads();
    }
    if (songs.isEmpty && _searchQuery.isNotEmpty) {
      return _buildEmptySearch();
    }
    final ytNotifier = ref.read(ytLibraryProvider.notifier);
    return Column(
      children: [
        // Play All header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${songs.length} song${songs.length == 1 ? '' : 's'}',
                style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
              ),
              TextButton.icon(
                onPressed: songs.isEmpty
                    ? null
                    : () {
                        playbackNotifier.playSong(songs.first, queue: songs);
                        if (settings?.autoOpenQueue == true) context.go('/queue');
                      },
                icon: const Icon(Icons.play_arrow, size: 18),
                label: const Text('Play All'),
                style: TextButton.styleFrom(foregroundColor: AppColors.white),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: songs.length,
            itemBuilder: (context, i) {
              // For YT results, reflect actual library membership so the context
              // menu shows the correct Add/Remove label and icon state.
              final rawSong = songs[i];
              final song = isYtResult
                  ? rawSong.copyWith(inLibrary: ytNotifier.isInLibrary(rawSong.id))
                  : rawSong;
              return SongRow(
                song: song,
                onTap: () {
                  // Tap plays only this song — use "Play All" to play the full list.
                  playbackNotifier.playSong(song, queue: [song]);
                  if (settings?.autoOpenQueue == true) context.go('/queue');
                },
                onDownloadTap: isYtResult
                    ? (song.isDownloading
                        ? null
                        : () {
                            if (song.isDownloaded) {
                              ytNotifier.removeDownload(song);
                            } else {
                              ytNotifier.downloadSong(
                                  song, ref.read(youtubeMusicServiceProvider));
                            }
                          })
                    : () => libraryNotifier.toggleSongDownload(song.id),
                onMoreTap: () => showSongContextMenu(
                  context,
                  song,
                  onAddToLibrary: isYtResult
                      ? () => ytNotifier.addToLibrary(song)
                      : () => libraryNotifier.toggleLibrary(song.id),
                  onRemoveFromLibrary: isYtResult
                      ? () => ytNotifier.removeFromLibrary(song.id)
                      : () => libraryNotifier.toggleLibrary(song.id),
                  onAddToQueue: () => playbackNotifier.addToQueue(song),
                  onDownload: isYtResult
                      ? () => ytNotifier.downloadSong(
                          song, ref.read(youtubeMusicServiceProvider))
                      : () => libraryNotifier.toggleSongDownload(song.id),
                  onRemoveDownload: isYtResult
                      ? () => ytNotifier.removeDownload(song)
                      : () => libraryNotifier.toggleSongDownload(song.id),
                  onPlayNext: () => playbackNotifier.playNext(song),
                  onViewAlbum: () => context.push('/library/album/${song.albumId}'),
                  onViewArtist: () => context.push('/library/artist/${song.artistId}'),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAlbumsList(
    BuildContext context, {
    required List<Album> albums,
    required LibraryNotifier libraryNotifier,
  }) {
    if (_activeSource == 'Downloads' && albums.isEmpty) {
      return _buildEmptyDownloads();
    }
    if (albums.isEmpty && _searchQuery.isNotEmpty) {
      return _buildEmptySearch();
    }
    return ListView.builder(
      itemCount: albums.length,
      itemBuilder: (context, i) {
        final album = albums[i];
        return AlbumRow(
          album: album,
          onTap: () => context.push('/library/album/${album.id}'),
          onDownloadTap: () => libraryNotifier.toggleAlbumDownload(album.id),
          onMoreTap: () => showAlbumContextMenu(
            context,
            album,
            onDownload: () => libraryNotifier.toggleAlbumDownload(album.id),
            onRemoveDownload: () =>
                libraryNotifier.toggleAlbumDownload(album.id),
          ),
        );
      },
    );
  }

  Widget _buildArtistsList(
    BuildContext context, {
    required List<Artist> artists,
    required LibraryNotifier libraryNotifier,
  }) {
    if (_activeSource == 'Downloads' && artists.isEmpty) {
      return _buildEmptyDownloads();
    }
    if (artists.isEmpty && _searchQuery.isNotEmpty) {
      return _buildEmptySearch();
    }
    return ListView.builder(
      itemCount: artists.length,
      itemBuilder: (context, i) {
        final artist = artists[i];
        return ArtistRow(
          artist: artist,
          onTap: () => context.push('/library/artist/${artist.id}'),
          onMoreTap: () => showArtistContextMenu(
            context,
            artist,
            onAddToLibrary: () => libraryNotifier.toggleLibrary(artist.id),
          ),
        );
      },
    );
  }

  Widget _buildPlaylistsList(
    BuildContext context, {
    required List<Playlist> playlists,
    required LibraryNotifier libraryNotifier,
  }) {
    if (_activeSource == 'Downloads' && playlists.isEmpty) {
      return _buildEmptyDownloads();
    }
    if (playlists.isEmpty && _searchQuery.isNotEmpty) {
      return _buildEmptySearch();
    }
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Text(
                'Playlists',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.add, color: AppColors.white),
                onPressed: () {
                  // TODO: showDialog with CreatePlaylistDialog
                },
                tooltip: 'New Playlist',
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: playlists.length,
            itemBuilder: (context, i) {
              final playlist = playlists[i];
              return PlaylistRow(
                playlist: playlist,
                onTap: () =>
                    context.push('/library/playlist/${playlist.id}'),
                onMoreTap: () => showPlaylistContextMenu(
                  context,
                  playlist,
                  onDeletePlaylist: () =>
                      libraryNotifier.deletePlaylist(playlist.id),
                  onEditPlaylist: () => libraryNotifier.renamePlaylist(
                      playlist.id, playlist.name),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyDownloads() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.download_outlined, size: 56, color: AppColors.textMuted),
          SizedBox(height: 16),
          Text(
            'No downloads yet',
            style: TextStyle(color: AppColors.textMuted, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptySearch() {
    return Center(
      child: Text(
        "No results for '$_searchQuery'",
        style: const TextStyle(color: AppColors.textMuted, fontSize: 16),
      ),
    );
  }
}
