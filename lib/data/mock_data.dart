import '../models/song.dart';
import '../models/album.dart';
import '../models/artist.dart';
import '../models/playlist.dart';
import '../models/live_performance.dart';
import '../models/video.dart';

const kArtists = [
  Artist(id: 'artist_1', name: 'Paolo Nutini'),
  Artist(id: 'artist_2', name: 'Frank Sinatra'),
  Artist(id: 'artist_3', name: 'Bob Dylan'),
];

const kAlbums = [
  Album(
    id: 'album_1',
    title: 'Sunny Side Up',
    artist: 'Paolo Nutini',
    artistId: 'artist_1',
    year: 2009,
    songCount: 12,
  ),
  Album(
    id: 'album_2',
    title: 'In the Wee Small Hours',
    artist: 'Frank Sinatra',
    artistId: 'artist_2',
    year: 1955,
    songCount: 16,
  ),
  Album(
    id: 'album_3',
    title: 'The Freewheelin\'',
    artist: 'Bob Dylan',
    artistId: 'artist_3',
    year: 1963,
    songCount: 13,
  ),
];

const kSongs = [
  Song(
    id: 'song_1',
    title: 'Last Request',
    artist: 'Paolo Nutini',
    artistId: 'artist_1',
    album: 'Sunny Side Up',
    albumId: 'album_1',
    duration: Duration(minutes: 3, seconds: 44),
    inLibrary: true,
  ),
  Song(
    id: 'song_2',
    title: 'Candy',
    artist: 'Paolo Nutini',
    artistId: 'artist_1',
    album: 'Sunny Side Up',
    albumId: 'album_1',
    duration: Duration(minutes: 3, seconds: 20),
    inLibrary: true,
  ),
  Song(
    id: 'song_3',
    title: 'Jenny Don\'t Be Hasty',
    artist: 'Paolo Nutini',
    artistId: 'artist_1',
    album: 'Sunny Side Up',
    albumId: 'album_1',
    duration: Duration(minutes: 4, seconds: 2),
    inLibrary: true,
  ),
  Song(
    id: 'song_4',
    title: 'In the Wee Small Hours of the Morning',
    artist: 'Frank Sinatra',
    artistId: 'artist_2',
    album: 'In the Wee Small Hours',
    albumId: 'album_2',
    duration: Duration(minutes: 2, seconds: 58),
    inLibrary: true,
  ),
  Song(
    id: 'song_5',
    title: 'Mood Indigo',
    artist: 'Frank Sinatra',
    artistId: 'artist_2',
    album: 'In the Wee Small Hours',
    albumId: 'album_2',
    duration: Duration(minutes: 3, seconds: 12),
    inLibrary: true,
  ),
  Song(
    id: 'song_6',
    title: 'Blowin\' in the Wind',
    artist: 'Bob Dylan',
    artistId: 'artist_3',
    album: 'The Freewheelin\'',
    albumId: 'album_3',
    duration: Duration(minutes: 2, seconds: 48),
    inLibrary: true,
  ),
  Song(
    id: 'song_7',
    title: 'New Shoes',
    artist: 'Paolo Nutini',
    artistId: 'artist_1',
    album: 'Sunny Side Up',
    albumId: 'album_1',
    duration: Duration(minutes: 3, seconds: 33),
    inLibrary: false,
  ),
  Song(
    id: 'song_8',
    title: 'These Boots',
    artist: 'Paolo Nutini',
    artistId: 'artist_1',
    album: 'Sunny Side Up',
    albumId: 'album_1',
    duration: Duration(minutes: 4, seconds: 10),
    inLibrary: false,
  ),
  Song(
    id: 'song_9',
    title: 'Autumn Leaves',
    artist: 'Frank Sinatra',
    artistId: 'artist_2',
    album: 'In the Wee Small Hours',
    albumId: 'album_2',
    duration: Duration(minutes: 3, seconds: 5),
    inLibrary: false,
  ),
  Song(
    id: 'song_10',
    title: 'I See Your Face Before Me',
    artist: 'Frank Sinatra',
    artistId: 'artist_2',
    album: 'In the Wee Small Hours',
    albumId: 'album_2',
    duration: Duration(minutes: 3, seconds: 22),
    inLibrary: false,
  ),
  Song(
    id: 'song_11',
    title: 'Girl from the North Country',
    artist: 'Bob Dylan',
    artistId: 'artist_3',
    album: 'The Freewheelin\'',
    albumId: 'album_3',
    duration: Duration(minutes: 3, seconds: 42),
    inLibrary: false,
  ),
  Song(
    id: 'song_12',
    title: 'Don\'t Think Twice, It\'s All Right',
    artist: 'Bob Dylan',
    artistId: 'artist_3',
    album: 'The Freewheelin\'',
    albumId: 'album_3',
    duration: Duration(minutes: 3, seconds: 38),
    inLibrary: false,
  ),
];

const kPlaylists = [
  Playlist(
    id: 'playlist_1',
    name: 'Favourites',
    songIds: ['song_1', 'song_4', 'song_6'],
  ),
  Playlist(
    id: 'playlist_2',
    name: 'Late Night',
    songIds: ['song_4', 'song_5', 'song_9', 'song_10'],
  ),
];

const kLivePerformances = [
  LivePerformance(
    id: 'live_1',
    title: 'Last Request (Live at Glastonbury)',
    artist: 'Paolo Nutini',
    artistId: 'artist_1',
    date: '2009-06-28',
  ),
  LivePerformance(
    id: 'live_2',
    title: 'Blowin\' in the Wind (Live 1964)',
    artist: 'Bob Dylan',
    artistId: 'artist_3',
    date: '1964-10-31',
  ),
];

const kVideos = [
  Video(
    id: 'video_1',
    title: 'Candy (Official Video)',
    artist: 'Paolo Nutini',
    artistId: 'artist_1',
    duration: Duration(minutes: 3, seconds: 52),
  ),
  Video(
    id: 'video_2',
    title: 'New Shoes (Official Video)',
    artist: 'Paolo Nutini',
    artistId: 'artist_1',
    duration: Duration(minutes: 3, seconds: 41),
  ),
  Video(
    id: 'video_3',
    title: 'Blowin\' in the Wind (Live)',
    artist: 'Bob Dylan',
    artistId: 'artist_3',
    duration: Duration(minutes: 3, seconds: 15),
  ),
];
