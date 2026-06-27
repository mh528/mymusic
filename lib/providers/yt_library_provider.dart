import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/youtube_library_cache.dart';
import '../data/youtube_music_service.dart';
import '../models/song.dart';

// Singleton service provider — disposed when app exits
final youtubeMusicServiceProvider = Provider<YouTubeMusicService>((ref) {
  final svc = YouTubeMusicService();
  ref.onDispose(svc.dispose);
  return svc;
});

class YtLibraryState {
  final List<Song> songs;
  final bool isLoaded;

  const YtLibraryState({this.songs = const [], this.isLoaded = false});

  YtLibraryState copyWith({List<Song>? songs, bool? isLoaded}) =>
      YtLibraryState(
        songs: songs ?? this.songs,
        isLoaded: isLoaded ?? this.isLoaded,
      );
}

final ytLibraryProvider =
    NotifierProvider<YtLibraryNotifier, YtLibraryState>(YtLibraryNotifier.new);

class YtLibraryNotifier extends Notifier<YtLibraryState> {
  final _cache = YouTubeLibraryCache();

  @override
  YtLibraryState build() {
    // Load cache asynchronously on first build
    Future.microtask(_loadCache);
    return const YtLibraryState();
  }

  Future<void> _loadCache() async {
    final songs = await _cache.load();
    state = state.copyWith(songs: songs, isLoaded: true);
  }

  Future<void> addToLibrary(Song song) async {
    final updated = await _cache.add(song, state.songs);
    state = state.copyWith(songs: updated);
  }

  Future<void> removeFromLibrary(String songId) async {
    final updated = await _cache.remove(songId, state.songs);
    state = state.copyWith(songs: updated);
  }

  Future<void> updateSong(Song song) async {
    final updated = await _cache.update(song, state.songs);
    state = state.copyWith(songs: updated);
  }

  bool isInLibrary(String songId) => state.songs.any((s) => s.id == songId);
}
