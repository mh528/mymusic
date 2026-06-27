import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/settings.dart';
import '../models/song.dart';
import '../data/music_repository.dart';
import '../theme.dart';
import '../components/tabs/filter_chips_row.dart';
import '../components/tabs/content_tab_bar.dart';
import '../components/list_rows/song_row.dart';
import '../components/list_rows/album_row.dart';
import '../components/list_rows/artist_row.dart';
import '../components/list_rows/playlist_row.dart';
import '../providers/playback_provider.dart';
import '../providers/search_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/yt_library_provider.dart';

class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  final _controller = TextEditingController();
  LibraryTab _activeTab = LibraryTab.songs;
  SearchSource _activeSource = SearchSource.allMusic;
  bool _initialized = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _initFromSettings(AppSettings settings) {
    if (_initialized) return;
    _initialized = true;
    _activeSource = settings.defaultSearchSource;
    final visible = settings.orderedVisibleTabs;
    _activeTab = visible.contains(settings.defaultLibraryTab)
        ? settings.defaultLibraryTab
        : (visible.isNotEmpty ? visible.first : LibraryTab.songs);
  }

  void _search(String query) {
    ref.read(searchProvider.notifier).search(query);
  }

  void _clearSearch() {
    _controller.clear();
    ref.read(searchProvider.notifier).clearQuery();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(searchProvider);
    final settingsAsync = ref.watch(settingsProvider);
    final query = _controller.text;

    return settingsAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
      data: (settings) {
        _initFromSettings(settings);
        final visibleTabs = settings.orderedVisibleTabs;

        // Auto-correct activeTab if hidden in settings
        if (!visibleTabs.contains(_activeTab) && visibleTabs.isNotEmpty) {
          _activeTab = visibleTabs.first;
        }

        return Scaffold(
          backgroundColor: AppColors.black,
          body: SafeArea(
            child: Column(
              children: [
                // Search field
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: TextField(
                    controller: _controller,
                    textInputAction: TextInputAction.search,
                    onSubmitted: _search,
                    onChanged: (_) => setState(() {}),
                    style: const TextStyle(color: AppColors.white),
                    decoration: InputDecoration(
                      hintText: 'Search for music',
                      prefixIcon: const Icon(Icons.search, color: AppColors.textMuted),
                      suffixIcon: query.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close, color: AppColors.textMuted),
                              onPressed: _clearSearch,
                            )
                          : null,
                    ),
                  ),
                ),
                // Filter chips
                FilterChipsRow<SearchSource>(
                  options: SearchSource.values,
                  selected: _activeSource,
                  label: (s) {
                    switch (s) {
                      case SearchSource.allMusic: return 'All Music';
                      case SearchSource.library: return 'Library';
                      case SearchSource.downloads: return 'Downloads';
                    }
                  },
                  onSelected: (source) => setState(() => _activeSource = source),
                ),
                // Content area
                Expanded(
                  child: _buildContent(searchState, query),
                ),
                // Tab bar
                ContentTabBar(
                  tabs: visibleTabs.map(_tabLabel).toList(),
                  selectedIndex: visibleTabs.indexOf(_activeTab).clamp(0, visibleTabs.length - 1),
                  onTabChanged: (i) => setState(() => _activeTab = visibleTabs[i]),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _tabLabel(LibraryTab t) {
    switch (t) {
      case LibraryTab.songs: return 'Songs';
      case LibraryTab.albums: return 'Albums';
      case LibraryTab.artists: return 'Artists';
      case LibraryTab.playlists: return 'Playlists';
    }
  }

  Widget _buildContent(SearchState searchState, String query) {
    final hasQuery = query.trim().isNotEmpty;
    final history = searchState.history;

    if (!hasQuery) {
      if (history.isEmpty) {
        return const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.search, size: 64, color: AppColors.textDim),
              SizedBox(height: 12),
              Text('Search for music', style: TextStyle(color: AppColors.textMuted, fontSize: 16)),
            ],
          ),
        );
      }
      return ListView(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Recent Searches', style: TextStyle(color: AppColors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                TextButton(
                  onPressed: () => ref.read(searchProvider.notifier).clearHistory(),
                  child: const Text('Clear', style: TextStyle(color: AppColors.textMuted)),
                ),
              ],
            ),
          ),
          ...history.map((item) => ListTile(
            leading: const Icon(Icons.history, color: AppColors.textMuted),
            title: Text(item, style: const TextStyle(color: AppColors.white)),
            onTap: () {
              _controller.text = item;
              _search(item);
              setState(() {});
            },
          )),
        ],
      );
    }

    if (searchState.isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.white));
    }

    final results = searchState.results;
    if (results.isEmpty) {
      return Center(
        child: Text("No results for '$query'", style: const TextStyle(color: AppColors.textMuted, fontSize: 15)),
      );
    }

    return _buildResults(results);
  }


  Widget _buildResults(SearchResults results) {
    final playback = ref.read(playbackProvider.notifier);
    final ytLibrary = ref.read(ytLibraryProvider.notifier);
    switch (_activeTab) {
      case LibraryTab.songs:
        final songs = _filterSongs(results.songs);
        return ListView.builder(
          itemCount: songs.length,
          itemBuilder: (_, i) {
            final song = songs[i];
            final inLib = ref.watch(ytLibraryProvider).songs.any((s) => s.id == song.id);
            return SongRow(
              song: song.copyWith(inLibrary: inLib),
              onTap: () => playback.playSong(song, queue: songs.cast()),
              onMoreTap: () => _showYtSongMenu(song, inLib, ytLibrary),
            );
          },
        );
      case LibraryTab.albums:
        final albums = _filterAlbums(results.albums);
        return ListView.builder(
          itemCount: albums.length,
          itemBuilder: (_, i) => AlbumRow(album: albums[i]),
        );
      case LibraryTab.artists:
        final artists = _filterArtists(results.artists);
        return ListView.builder(
          itemCount: artists.length,
          itemBuilder: (_, i) => ArtistRow(artist: artists[i]),
        );
      case LibraryTab.playlists:
        final playlists = _filterPlaylists(results.playlists);
        return ListView.builder(
          itemCount: playlists.length,
          itemBuilder: (_, i) => PlaylistRow(playlist: playlists[i]),
        );
    }
  }

  void _showYtSongMenu(Song song, bool inLibrary, YtLibraryNotifier ytLibrary) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(
                inLibrary ? Icons.favorite : Icons.favorite_border,
                color: Colors.white,
              ),
              title: Text(
                inLibrary ? 'Remove from Library' : 'Add to Library',
                style: const TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                if (inLibrary) {
                  ytLibrary.removeFromLibrary(song.id);
                } else {
                  ytLibrary.addToLibrary(song);
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.add, color: Colors.white),
              title: const Text('Add to Queue', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                ref.read(playbackProvider.notifier).addToQueue(song);
              },
            ),
          ],
        ),
      ),
    );
  }

  List _filterSongs(List songs) {
    switch (_activeSource) {
      case SearchSource.allMusic: return songs;
      case SearchSource.library: return songs.where((s) => s.inLibrary == true).toList();
      case SearchSource.downloads: return songs.where((s) => s.isDownloaded == true).toList();
    }
  }

  List _filterAlbums(List albums) {
    switch (_activeSource) {
      case SearchSource.allMusic: return albums;
      case SearchSource.library: return albums.where((a) => a.inLibrary == true).toList();
      case SearchSource.downloads: return albums.where((a) => a.isDownloaded == true).toList();
    }
  }

  List _filterArtists(List artists) {
    switch (_activeSource) {
      case SearchSource.allMusic: return artists;
      case SearchSource.library: return artists.where((a) => a.inLibrary == true).toList();
      case SearchSource.downloads: return artists.toList();
    }
  }

  List _filterPlaylists(List playlists) {
    switch (_activeSource) {
      case SearchSource.allMusic: return playlists;
      case SearchSource.library: return playlists.toList();
      case SearchSource.downloads: return playlists.where((p) => p.isDownloaded == true).toList();
    }
  }
}
