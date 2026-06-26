import '../models/song.dart';
import '../models/album.dart';
import '../models/artist.dart';
import '../models/playlist.dart';
import '../models/live_performance.dart';
import '../models/video.dart';

class SearchResults {
  final List<Song> songs;
  final List<Album> albums;
  final List<Artist> artists;
  final List<Playlist> playlists;
  final List<LivePerformance> livePerformances;
  final List<Video> videos;

  const SearchResults({
    this.songs = const [],
    this.albums = const [],
    this.artists = const [],
    this.playlists = const [],
    this.livePerformances = const [],
    this.videos = const [],
  });

  bool get isEmpty =>
      songs.isEmpty &&
      albums.isEmpty &&
      artists.isEmpty &&
      playlists.isEmpty &&
      livePerformances.isEmpty &&
      videos.isEmpty;
}

abstract class MusicRepository {
  Future<List<Song>> getAllSongs();
  Future<List<Song>> getLibrarySongs();
  Future<List<Album>> getAllAlbums();
  Future<List<Album>> getLibraryAlbums();
  Future<List<Artist>> getAllArtists();
  Future<List<Artist>> getLibraryArtists();
  Future<List<Playlist>> getPlaylists();
  Future<List<Song>> getSongsByAlbum(String albumId);
  Future<List<Song>> getSongsByArtist(String artistId);
  Future<List<Album>> getAlbumsByArtist(String artistId);
  Future<List<LivePerformance>> getLivePerformancesByArtist(String artistId);
  Future<List<Video>> getVideosByArtist(String artistId);
  Future<Album?> getAlbum(String id);
  Future<Artist?> getArtist(String id);
  Future<Playlist?> getPlaylist(String id);
  Future<SearchResults> search(String query);
  // Phase 2: returns a stream URL; Phase 1: returns local asset path or null
  Future<String?> getStreamUrl(String songId);
}
