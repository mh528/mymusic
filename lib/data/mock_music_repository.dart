import 'mock_data.dart';
import 'music_repository.dart';
import '../models/song.dart';
import '../models/album.dart';
import '../models/artist.dart';
import '../models/playlist.dart';
import '../models/live_performance.dart';
import '../models/video.dart';

class MockMusicRepository implements MusicRepository {
  @override
  Future<List<Song>> getAllSongs() async => kSongs.toList();

  @override
  Future<List<Song>> getLibrarySongs() async =>
      kSongs.where((s) => s.inLibrary).toList();

  @override
  Future<List<Album>> getAllAlbums() async => kAlbums.toList();

  @override
  Future<List<Album>> getLibraryAlbums() async => kAlbums.toList();

  @override
  Future<List<Artist>> getAllArtists() async => kArtists.toList();

  @override
  Future<List<Artist>> getLibraryArtists() async => kArtists.toList();

  @override
  Future<List<Playlist>> getPlaylists() async => kPlaylists.toList();

  @override
  Future<List<Song>> getSongsByAlbum(String albumId) async =>
      kSongs.where((s) => s.albumId == albumId).toList();

  @override
  Future<List<Song>> getSongsByArtist(String artistId) async =>
      kSongs.where((s) => s.artistId == artistId).toList();

  @override
  Future<List<Album>> getAlbumsByArtist(String artistId) async =>
      kAlbums.where((a) => a.artistId == artistId).toList();

  @override
  Future<List<LivePerformance>> getLivePerformancesByArtist(
      String artistId) async =>
      kLivePerformances.where((l) => l.artistId == artistId).toList();

  @override
  Future<List<Video>> getVideosByArtist(String artistId) async =>
      kVideos.where((v) => v.artistId == artistId).toList();

  @override
  Future<Album?> getAlbum(String id) async {
    try {
      return kAlbums.firstWhere((a) => a.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Artist?> getArtist(String id) async {
    try {
      return kArtists.firstWhere((a) => a.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Playlist?> getPlaylist(String id) async {
    try {
      return kPlaylists.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<SearchResults> search(String query) async {
    if (query.trim().isEmpty) return const SearchResults();
    final q = query.toLowerCase();
    return SearchResults(
      songs: kSongs
          .where((s) =>
              s.title.toLowerCase().contains(q) ||
              s.artist.toLowerCase().contains(q) ||
              s.album.toLowerCase().contains(q))
          .toList(),
      albums: kAlbums
          .where((a) =>
              a.title.toLowerCase().contains(q) ||
              a.artist.toLowerCase().contains(q))
          .toList(),
      artists:
          kArtists.where((a) => a.name.toLowerCase().contains(q)).toList(),
      playlists:
          kPlaylists.where((p) => p.name.toLowerCase().contains(q)).toList(),
      livePerformances: kLivePerformances
          .where((l) =>
              l.title.toLowerCase().contains(q) ||
              l.artist.toLowerCase().contains(q))
          .toList(),
      videos: kVideos
          .where((v) =>
              v.title.toLowerCase().contains(q) ||
              v.artist.toLowerCase().contains(q))
          .toList(),
    );
  }

  @override
  Future<String?> getStreamUrl(String songId) async {
    // Phase 1: no local audio files wired up yet
    return null;
  }
}
