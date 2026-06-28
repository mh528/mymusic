import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
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

  /// Downloads a YouTube song to local storage as AAC/mp4 and persists the file path.
  Future<void> downloadSong(
    Song song,
    YouTubeMusicService ytSvc, {
    void Function(int received, int total)? onProgress,
  }) async {
    if (song.videoId == null) return;
    final dir = await getApplicationSupportDirectory();
    final destPath = '${dir.path}/downloads/${song.videoId}.m4a';

    state = state.copyWith(
      songs: state.songs
          .map((s) => s.id == song.id ? s.copyWith(isDownloading: true) : s)
          .toList(),
    );

    try {
      await ytSvc.downloadAudio(song.videoId!, destPath, onProgress: onProgress);
      final updated =
          song.copyWith(isDownloaded: true, isDownloading: false, filePath: destPath);
      await _cache.update(updated, state.songs);
      state = state.copyWith(
        songs: state.songs.map((s) => s.id == song.id ? updated : s).toList(),
      );
    } catch (e) {
      state = state.copyWith(
        songs: state.songs
            .map((s) => s.id == song.id ? s.copyWith(isDownloading: false) : s)
            .toList(),
      );
      rethrow;
    }
  }

  /// Deletes the downloaded file and clears filePath/isDownloaded.
  Future<void> removeDownload(Song song) async {
    if (song.filePath != null) {
      final file = File(song.filePath!);
      if (file.existsSync()) {
        try {
          file.deleteSync();
        } catch (_) {}
      }
    }
    final updated = song.copyWith(isDownloaded: false, clearFilePath: true);
    await _cache.update(updated, state.songs);
    state = state.copyWith(
      songs: state.songs.map((s) => s.id == song.id ? updated : s).toList(),
    );
  }
}
