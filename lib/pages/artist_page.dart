import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/artist.dart';
import '../models/song.dart';
import '../models/album.dart';
import '../models/live_performance.dart';
import '../models/video.dart';
import '../providers/library_provider.dart';
import '../components/art_thumbnail.dart';
import '../components/buttons.dart';
import '../components/tabs/filter_chips_row.dart';
import '../components/tabs/content_tab_bar.dart';
import '../components/list_rows/song_row.dart';
import '../components/list_rows/album_row.dart';
import '../theme.dart';

class ArtistPage extends ConsumerStatefulWidget {
  final String artistId;

  const ArtistPage({super.key, required this.artistId});

  @override
  ConsumerState<ArtistPage> createState() => _ArtistPageState();
}

class _ArtistPageState extends ConsumerState<ArtistPage> {
  bool isSearchActive = false;
  String searchQuery = '';
  String _activeSource = 'All Music';
  int _activeTabIndex = 0; // 0=Songs, 1=Albums, 2=Videos

  Artist? artist;
  List<Song> songs = [];
  List<Album> albums = [];
  List<LivePerformance> livePerformances = [];
  List<Video> videos = [];
  bool isLoading = true;

  final TextEditingController _searchController = TextEditingController();

  static const List<String> _sourceOptions = ['All Music', 'Library', 'Downloads'];
  static const List<String> _contentTabs = ['Songs', 'Albums', 'Videos'];

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
    final results = await Future.wait([
      repo.getArtist(widget.artistId),
      repo.getSongsByArtist(widget.artistId),
      repo.getAlbumsByArtist(widget.artistId),
      repo.getLivePerformancesByArtist(widget.artistId),
      repo.getVideosByArtist(widget.artistId),
    ]);
    if (mounted) {
      setState(() {
        artist = results[0] as Artist?;
        songs = results[1] as List<Song>;
        albums = results[2] as List<Album>;
        livePerformances = results[3] as List<LivePerformance>;
        videos = results[4] as List<Video>;
        isLoading = false;
      });
    }
  }

  List<Song> get _filteredSongs {
    List<Song> list;
    switch (_activeSource) {
      case 'Library':
        list = songs.where((s) => s.inLibrary).toList();
        break;
      case 'Downloads':
        list = songs.where((s) => s.isDownloaded).toList();
        break;
      default:
        list = List<Song>.from(songs);
    }
    if (searchQuery.isNotEmpty) {
      final q = searchQuery.toLowerCase();
      list = list.where((s) => s.title.toLowerCase().contains(q)).toList();
    }
    list.sort((a, b) => a.title.compareTo(b.title));
    return list;
  }

  List<Album> get _filteredAlbums {
    List<Album> list;
    switch (_activeSource) {
      case 'Library':
        list = albums.where((a) => a.inLibrary).toList();
        break;
      case 'Downloads':
        list = albums.where((a) => a.isDownloaded).toList();
        break;
      default:
        list = List<Album>.from(albums);
    }
    if (searchQuery.isNotEmpty) {
      final q = searchQuery.toLowerCase();
      list = list.where((a) => a.title.toLowerCase().contains(q)).toList();
    }
    list.sort((a, b) => a.title.compareTo(b.title));
    return list;
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
                          hintText: 'Search...',
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
            Expanded(
              child: ListView(
                children: [
                  // Artist info card
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          decoration: const BoxDecoration(
                            color: AppColors.bg3,
                            shape: BoxShape.circle,
                          ),
                          child: const ArtThumbnail(size: 120, icon: Icons.person),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(artist?.name ?? '', style: AppTextStyles.pageTitle),
                              const SizedBox(height: 8),
                              AppButtonBar(
                                expanded: false,
                                buttons: [
                                  AppIconButton(
                                    icon: (artist?.inLibrary ?? false)
                                        ? Icons.library_add_check
                                        : Icons.library_add_outlined,
                                    onTap: () {},
                                  ),
                                  AppIconButton(icon: Icons.radio, onTap: () {}),
                                  AppIconButton(icon: Icons.shuffle, onTap: () {}),
                                  AppIconButton(icon: Icons.more_horiz, onTap: () {}),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Source filter chips
                  FilterChipsRow<String>(
                    options: _sourceOptions,
                    selected: _activeSource,
                    label: (s) => s,
                    onSelected: (v) => setState(() => _activeSource = v),
                  ),
                  // Content based on active tab
                  if (isLoading)
                    const Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else
                    _buildTabContent(),
                ],
              ),
            ),
            // Content tab bar — Songs | Albums | Videos
            ContentTabBar(
              tabs: _contentTabs,
              selectedIndex: _activeTabIndex,
              onTabChanged: (i) => setState(() => _activeTabIndex = i),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_activeTabIndex) {
      case 0: // Songs
        final filtered = _filteredSongs;
        if (filtered.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(32),
            child: Center(
              child: Text('No songs found', style: TextStyle(color: AppColors.textMuted)),
            ),
          );
        }
        return Column(
          children: filtered
              .map((s) => SongRow(song: s, onTap: () {}, onDownloadTap: () {}, onMoreTap: () {}))
              .toList(),
        );
      case 1: // Albums
        final filtered = _filteredAlbums;
        if (filtered.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(32),
            child: Center(
              child: Text('No albums found', style: TextStyle(color: AppColors.textMuted)),
            ),
          );
        }
        return Column(
          children: filtered
              .map((a) => AlbumRow(album: a, onTap: () {}, onMoreTap: () {}))
              .toList(),
        );
      case 2: // Videos
        return const Padding(
          padding: EdgeInsets.all(32),
          child: Center(
            child: Text(
              'Videos coming in Phase 2',
              style: TextStyle(color: AppColors.textMuted),
            ),
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }
}

