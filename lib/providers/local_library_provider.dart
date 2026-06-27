import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import '../data/local_music_scanner.dart';
import '../models/settings.dart';
import '../models/song.dart';

class LocalLibraryState {
  final bool isScanning;
  final List<Song> songs;
  final int scanProgress; // number of songs found so far during scan
  final String? error;

  const LocalLibraryState({
    this.isScanning = false,
    this.songs = const [],
    this.scanProgress = 0,
    this.error,
  });

  LocalLibraryState copyWith({
    bool? isScanning,
    List<Song>? songs,
    int? scanProgress,
    String? error,
  }) {
    return LocalLibraryState(
      isScanning: isScanning ?? this.isScanning,
      songs: songs ?? this.songs,
      scanProgress: scanProgress ?? this.scanProgress,
      error: error,
    );
  }
}

final localLibraryProvider =
    NotifierProvider<LocalLibraryNotifier, LocalLibraryState>(
        LocalLibraryNotifier.new);

class LocalLibraryNotifier extends Notifier<LocalLibraryState> {
  static const _cacheFileName = 'local_library_cache.json';
  bool _cacheLoaded = false;

  @override
  LocalLibraryState build() {
    return const LocalLibraryState();
  }

  /// Call once after settings load to restore cache from a previous session.
  Future<void> initFromSettings(AppSettings settings) async {
    if (_cacheLoaded) return;
    if (settings.musicSource == MusicSource.local &&
        settings.localMusicFolder != null) {
      _cacheLoaded = true;
      await loadCache();
    }
  }

  /// Load from JSON cache. Call this on app start if a music folder is configured.
  Future<void> loadCache() async {
    try {
      final file = await _cacheFile();
      if (!await file.exists()) return;
      final json = jsonDecode(await file.readAsString()) as List<dynamic>;
      final songs = json.map((e) => _songFromJson(e as Map<String, dynamic>)).toList();
      state = state.copyWith(songs: songs);
    } catch (_) {
      // Cache unreadable — will re-scan on next call to scan()
    }
  }

  /// Scan [folderPaths] and replace the library with the result.
  Future<void> scan(List<String> folderPaths) async {
    if (folderPaths.isEmpty) return;
    state = state.copyWith(isScanning: true, scanProgress: 0, error: null);
    try {
      final scanner = LocalMusicScanner();
      final songs = await scanner.scan(
        folderPaths,
        onProgress: (count) {
          state = state.copyWith(scanProgress: count);
        },
      );
      state = state.copyWith(isScanning: false, songs: songs, scanProgress: songs.length);
      await _writeCache(songs);
    } catch (e) {
      state = state.copyWith(isScanning: false, error: e.toString());
    }
  }

  Future<File> _cacheFile() async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/$_cacheFileName');
  }

  Future<void> _writeCache(List<Song> songs) async {
    try {
      final file = await _cacheFile();
      await file.writeAsString(jsonEncode(songs.map(_songToJson).toList()));
    } catch (_) {
      // Cache write failure is non-fatal
    }
  }

  Map<String, dynamic> _songToJson(Song s) => {
        'id': s.id,
        'title': s.title,
        'artist': s.artist,
        'artistId': s.artistId,
        'album': s.album,
        'albumId': s.albumId,
        'durationMs': s.duration.inMilliseconds,
        'filePath': s.filePath,
        // albumArtBytes not cached — re-read from file on rescan
      };

  Song _songFromJson(Map<String, dynamic> m) => Song(
        id: m['id'] as String,
        title: m['title'] as String,
        artist: m['artist'] as String,
        artistId: m['artistId'] as String,
        album: m['album'] as String,
        albumId: m['albumId'] as String,
        duration: Duration(milliseconds: (m['durationMs'] as int? ?? 0)),
        filePath: m['filePath'] as String?,
        inLibrary: true,
        isDownloaded: true,
      );
}
