import '../models/album.dart';
import '../models/artist.dart';
import '../models/live_performance.dart';
import '../models/playlist.dart';
import '../models/song.dart';
import '../models/video.dart';
import 'music_repository.dart';

class LocalMusicRepository implements MusicRepository {
  final List<Song> _songs;

  LocalMusicRepository(this._songs);

  // --- Albums derived from song list ---

  List<Album> _buildAlbums() {
    final map = <String, List<Song>>{};
    for (final s in _songs) {
      map.putIfAbsent(s.albumId, () => []).add(s);
    }
    return map.entries.map((e) {
      final songs = e.value;
      final first = songs.first;
      final year = int.tryParse(
            songs.map((s) => s.album).first, // placeholder — year not on Song
          ) ??
          0;
      return Album(
        id: e.key,
        title: first.album,
        artist: first.artist,
        artistId: first.artistId,
        year: year,
        songCount: songs.length,
        inLibrary: true,
        isDownloaded: true,
      );
    }).toList()
      ..sort((a, b) => a.title.compareTo(b.title));
  }

  // --- Artists derived from song list ---

  List<Artist> _buildArtists() {
    final map = <String, String>{};
    for (final s in _songs) {
      map.putIfAbsent(s.artistId, () => s.artist);
    }
    return map.entries
        .map((e) => Artist(id: e.key, name: e.value, inLibrary: true))
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  // --- MusicRepository ---

  @override
  Future<List<Song>> getAllSongs() async {
    final sorted = [..._songs]..sort((a, b) => a.title.compareTo(b.title));
    return sorted;
  }

  @override
  Future<List<Song>> getLibrarySongs() => getAllSongs();

  @override
  Future<List<Album>> getAllAlbums() async => _buildAlbums();

  @override
  Future<List<Album>> getLibraryAlbums() => getAllAlbums();

  @override
  Future<List<Artist>> getAllArtists() async => _buildArtists();

  @override
  Future<List<Artist>> getLibraryArtists() => getAllArtists();

  @override
  Future<List<Playlist>> getPlaylists() async => [];

  @override
  Future<List<Song>> getSongsByAlbum(String albumId) async =>
      _songs.where((s) => s.albumId == albumId).toList()
        ..sort((a, b) => a.title.compareTo(b.title));

  @override
  Future<List<Song>> getSongsByArtist(String artistId) async =>
      _songs.where((s) => s.artistId == artistId).toList()
        ..sort((a, b) => a.title.compareTo(b.title));

  @override
  Future<List<Album>> getAlbumsByArtist(String artistId) async =>
      _buildAlbums().where((a) => a.artistId == artistId).toList();

  @override
  Future<List<LivePerformance>> getLivePerformancesByArtist(String artistId) async => [];

  @override
  Future<List<Video>> getVideosByArtist(String artistId) async => [];

  @override
  Future<Album?> getAlbum(String id) async {
    try {
      return _buildAlbums().firstWhere((a) => a.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Artist?> getArtist(String id) async {
    try {
      return _buildArtists().firstWhere((a) => a.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Playlist?> getPlaylist(String id) async => null;

  @override
  Future<SearchResults> search(String query) async {
    final q = query.toLowerCase();
    final songs = _songs
        .where((s) =>
            s.title.toLowerCase().contains(q) ||
            s.artist.toLowerCase().contains(q) ||
            s.album.toLowerCase().contains(q))
        .toList();
    final albums = _buildAlbums()
        .where((a) => a.title.toLowerCase().contains(q) || a.artist.toLowerCase().contains(q))
        .toList();
    final artists =
        _buildArtists().where((a) => a.name.toLowerCase().contains(q)).toList();
    return SearchResults(songs: songs, albums: albums, artists: artists);
  }

  @override
  Future<String?> getStreamUrl(String songId) async {
    try {
      return _songs.firstWhere((s) => s.id == songId).filePath;
    } catch (_) {
      return null;
    }
  }
}
