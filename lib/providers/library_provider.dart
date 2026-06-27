import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/local_music_repository.dart';
import '../data/mock_music_repository.dart';
import '../data/music_repository.dart';
import '../models/settings.dart';
import '../models/song.dart';
import '../models/album.dart';
import '../models/artist.dart';
import '../models/playlist.dart';
import 'local_library_provider.dart';
import 'settings_provider.dart';

final musicRepositoryProvider = Provider<MusicRepository>((ref) {
  final settings = ref.watch(settingsProvider).valueOrNull;
  if (settings?.musicSource == MusicSource.local &&
      settings?.localMusicFolder != null) {
    final songs = ref.watch(localLibraryProvider).songs;
    return LocalMusicRepository(songs);
  }
  return MockMusicRepository();
});

class LibraryState {
  final List<Song> songs;
  final List<Album> albums;
  final List<Artist> artists;
  final List<Playlist> playlists;

  const LibraryState({
    this.songs = const [],
    this.albums = const [],
    this.artists = const [],
    this.playlists = const [],
  });

  LibraryState copyWith({
    List<Song>? songs,
    List<Album>? albums,
    List<Artist>? artists,
    List<Playlist>? playlists,
  }) {
    return LibraryState(
      songs: songs ?? this.songs,
      albums: albums ?? this.albums,
      artists: artists ?? this.artists,
      playlists: playlists ?? this.playlists,
    );
  }
}

final libraryProvider =
    AsyncNotifierProvider<LibraryNotifier, LibraryState>(LibraryNotifier.new);

class LibraryNotifier extends AsyncNotifier<LibraryState> {
  @override
  Future<LibraryState> build() async {
    final repo = ref.watch(musicRepositoryProvider);
    final results = await Future.wait([
      repo.getAllSongs(),
      repo.getAllAlbums(),
      repo.getAllArtists(),
      repo.getPlaylists(),
    ]);
    return LibraryState(
      songs: results[0] as List<Song>,
      albums: results[1] as List<Album>,
      artists: results[2] as List<Artist>,
      playlists: results[3] as List<Playlist>,
    );
  }

  LibraryState get _state => state.requireValue;

  void _setState(LibraryState next) {
    state = AsyncData(next);
  }

  void toggleLibrary(String songId) {
    final songs = _state.songs.map((s) {
      if (s.id == songId) return s.copyWith(inLibrary: !s.inLibrary);
      return s;
    }).toList();
    _setState(_state.copyWith(songs: songs));
  }

  Future<void> toggleSongDownload(String songId) async {
    final song = _state.songs.firstWhere((s) => s.id == songId);
    if (song.isDownloaded) {
      final songs = _state.songs.map((s) {
        if (s.id == songId) return s.copyWith(isDownloaded: false);
        return s;
      }).toList();
      _setState(_state.copyWith(songs: songs));
    } else {
      final songs = _state.songs.map((s) {
        if (s.id == songId) return s.copyWith(isDownloading: true);
        return s;
      }).toList();
      _setState(_state.copyWith(songs: songs));

      await Future.delayed(const Duration(milliseconds: 1500));

      final updated = _state.songs.map((s) {
        if (s.id == songId) {
          return s.copyWith(isDownloaded: true, isDownloading: false);
        }
        return s;
      }).toList();
      _setState(_state.copyWith(songs: updated));
    }
  }

  Future<void> toggleAlbumDownload(String albumId) async {
    final album = _state.albums.firstWhere((a) => a.id == albumId);
    if (album.isDownloaded) {
      final albums = _state.albums.map((a) {
        if (a.id == albumId) return a.copyWith(isDownloaded: false);
        return a;
      }).toList();
      _setState(_state.copyWith(albums: albums));
    } else {
      final albums = _state.albums.map((a) {
        if (a.id == albumId) return a.copyWith(isDownloading: true);
        return a;
      }).toList();
      _setState(_state.copyWith(albums: albums));

      await Future.delayed(const Duration(milliseconds: 1500));

      final updated = _state.albums.map((a) {
        if (a.id == albumId) {
          return a.copyWith(isDownloaded: true, isDownloading: false);
        }
        return a;
      }).toList();
      _setState(_state.copyWith(albums: updated));
    }
  }

  void addSongToQueue(String songId) {
    final songs = _state.songs.map((s) {
      if (s.id == songId) return s.copyWith(inQueue: true);
      return s;
    }).toList();
    _setState(_state.copyWith(songs: songs));
  }

  void removeSongFromQueue(String songId) {
    final songs = _state.songs.map((s) {
      if (s.id == songId) return s.copyWith(inQueue: false);
      return s;
    }).toList();
    _setState(_state.copyWith(songs: songs));
  }

  void createPlaylist(String name) {
    final id = 'playlist_${DateTime.now().millisecondsSinceEpoch}';
    final playlist = Playlist(id: id, name: name);
    _setState(_state.copyWith(playlists: [..._state.playlists, playlist]));
  }

  void deletePlaylist(String id) {
    final playlists = _state.playlists.where((p) => p.id != id).toList();
    _setState(_state.copyWith(playlists: playlists));
  }

  void renamePlaylist(String id, String name) {
    final playlists = _state.playlists.map((p) {
      if (p.id == id) return p.copyWith(name: name);
      return p;
    }).toList();
    _setState(_state.copyWith(playlists: playlists));
  }

  void addSongToPlaylist(String playlistId, String songId) {
    final playlists = _state.playlists.map((p) {
      if (p.id == playlistId && !p.songIds.contains(songId)) {
        return p.copyWith(songIds: [...p.songIds, songId]);
      }
      return p;
    }).toList();
    _setState(_state.copyWith(playlists: playlists));
  }
}
