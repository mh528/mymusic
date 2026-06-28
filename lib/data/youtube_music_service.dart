import 'dart:convert';
import 'dart:developer' as dev;
import 'dart:io';
import 'package:youtube_explode_dart/youtube_explode_dart.dart' hide Playlist;
import '../models/song.dart';
import '../models/album.dart';
import '../models/artist.dart';
import '../models/playlist.dart';
import 'music_repository.dart';
import '../models/settings.dart';

const _ytMusicBase = 'https://music.youtube.com/youtubei/v1/';
const _ytMusicKey = 'AIzaSyC9XL3ZjWddXya6X74dJoCTL-WEYFDNX30';

void _log(String msg) => dev.log(msg, name: 'YT');

Map<String, dynamic> get _ytMusicContext {
  // YouTube Music clientVersion format: 1.YYYYMM01.01.00 — must be the 1st of the month.
  // Using the actual day (e.g. YYYYMMDD) causes 404s.
  final now = DateTime.now().toUtc();
  final version = '1.${now.year}${now.month.toString().padLeft(2, '0')}01.01.00';
  return {
    'client': {
      'clientName': 'WEB_REMIX',
      'clientVersion': version,
      'hl': 'en',
    }
  };
}

// ANDROID_VR client — verified anonymous: its /player response returns
// playabilityStatus OK with adaptiveFormats carrying direct, unciphered `url`
// fields (no signatureCipher, no n-param). ANDROID_MUSIC and IOS both fail
// anonymously now (LOGIN_REQUIRED / 400), so VR is the working client.
const _ytPlayerEndpoint =
    'https://www.youtube.com/youtubei/v1/player?prettyPrint=false&alt=json';
Map<String, dynamic> get _androidVrContext => {
      'client': {
        'clientName': 'ANDROID_VR',
        'clientVersion': '1.60.19',
        'androidSdkVersion': 32,
        'deviceMake': 'Oculus',
        'deviceModel': 'Quest 3',
        'osName': 'Android',
        'osVersion': '12L',
        'hl': 'en',
      }
    };

class YouTubeMusicService {
  final _yt = YoutubeExplode();
  final HttpClient Function() _createClient;

  YouTubeMusicService({HttpClient Function()? createClient})
      : _createClient = createClient ?? HttpClient.new;

  Future<SearchResults> search(String query) async {
    try {
      final uri = Uri.parse(
          '${_ytMusicBase}search?prettyPrint=false&alt=json&key=$_ytMusicKey');
      final client = _createClient();
      try {
        final req = await client.postUrl(uri);
        req.headers
          ..set('content-type', 'application/json')
          ..set('accept-encoding', 'identity') // prevent gzip — HttpClient won't auto-decompress
          ..set('user-agent',
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/114.0.0.0 Safari/537.36')
          ..set('origin', 'https://music.youtube.com')
          ..set('cookie', 'CONSENT=YES+1');
        req.write(jsonEncode({'context': _ytMusicContext, 'query': query}));
        final res = await req.close();
        _log('HTTP ${res.statusCode} for query: $query');
        final body = await res.transform(utf8.decoder).join();
        _log('body length: ${body.length}');
        if (body.length < 500) _log('body: $body');
        final data = jsonDecode(body) as Map<String, dynamic>;
        return _parseResults(data);
      } finally {
        client.close(force: true);
      }
    } catch (e, st) {
      _log('search error: $e\n$st');
      return const SearchResults();
    }
  }

  SearchResults _parseResults(Map<String, dynamic> data) {
    final songs = <Song>[];
    final albums = <Album>[];
    final artists = <Artist>[];
    final playlists = <Playlist>[];
    try {
      final sections = _nav(data, [
        'contents',
        'tabbedSearchResultsRenderer',
        'tabs',
        0,
        'tabRenderer',
        'content',
        'sectionListRenderer',
        'contents',
      ]) as List?;
      if (sections == null) return const SearchResults();
      for (final section in sections) {
        // YouTube returns musicCardShelfRenderer (top result) and
        // itemSectionRenderer (remaining rows) — never musicShelfRenderer.
        List? items;
        if (section['musicCardShelfRenderer'] != null) {
          items = section['musicCardShelfRenderer']['contents'] as List?;
        } else if (section['itemSectionRenderer'] != null) {
          items = section['itemSectionRenderer']['contents'] as List?;
        }
        if (items == null) continue;
        for (final item in items) {
          final r = item['musicResponsiveListItemRenderer'];
          if (r == null) continue;
          final typeLabel = _col1FirstRun(r);
          if (typeLabel == 'Album' || typeLabel == 'Single' || typeLabel == 'EP') {
            final album = _parseAlbum(r);
            if (album != null) albums.add(album);
          } else if (typeLabel == 'Artist') {
            final artist = _parseArtist(r);
            if (artist != null) artists.add(artist);
          } else if (typeLabel == 'Playlist') {
            final playlist = _parsePlaylist(r);
            if (playlist != null) playlists.add(playlist);
          } else {
            // Song, Video, Episode, or card shelf items with direct videoId
            final song = _parseSong(r);
            if (song != null) songs.add(song);
          }
        }
      }
    } catch (e) {
      _log('parse error: $e');
    }
    _log('parsed songs=${songs.length} albums=${albums.length} artists=${artists.length} playlists=${playlists.length}');
    return SearchResults(songs: songs, albums: albums, artists: artists, playlists: playlists);
  }

  String _col1FirstRun(Map<String, dynamic> r) {
    try {
      return r['flexColumns'][1]['musicResponsiveListItemFlexColumnRenderer']['text']['runs'][0]['text'] as String? ?? '';
    } catch (_) {
      return '';
    }
  }

  Song? _parseSong(Map<String, dynamic> r) {
    try {
      final videoId = _nav(r, [
        'overlay',
        'musicItemThumbnailOverlayRenderer',
        'content',
        'musicPlayButtonRenderer',
        'playNavigationEndpoint',
        'watchEndpoint',
        'videoId',
      ]) as String?;
      if (videoId == null) return null;

      final title = _nav(r, [
        'flexColumns', 0,
        'musicResponsiveListItemFlexColumnRenderer',
        'text', 'runs', 0, 'text',
      ]) as String? ?? '';

      // col1 format: [Artist, •, Duration] or [Song/Video/Episode, •, Artist, ...]
      final col1Runs = _nav(r, [
        'flexColumns', 1,
        'musicResponsiveListItemFlexColumnRenderer',
        'text', 'runs',
      ]) as List?;
      final typeLabels = {'Song', 'Video', 'Album', 'Single', 'EP', 'Playlist', 'Episode'};
      String artist = '';
      if (col1Runs != null && col1Runs.isNotEmpty) {
        final first = col1Runs[0]['text'] as String? ?? '';
        if (typeLabels.contains(first) && col1Runs.length >= 3) {
          artist = col1Runs[2]['text'] as String? ?? '';
        } else {
          artist = first;
        }
      }

      final thumbs = _nav(r, [
        'thumbnail', 'musicThumbnailRenderer', 'thumbnail', 'thumbnails',
      ]) as List?;
      final thumbnailUrl = thumbs != null && thumbs.isNotEmpty
          ? (thumbs.last['url'] as String?)
          : null;

      final durationText = _nav(r, [
        'fixedColumns', 0,
        'musicResponsiveListItemFixedColumnRenderer',
        'text', 'runs', 0, 'text',
      ]) as String?;

      return Song(
        id: 'yt_$videoId',
        title: title,
        artist: artist,
        artistId: '',
        album: '',
        albumId: '',
        duration: parseDuration(durationText),
        videoId: videoId,
        thumbnailUrl: thumbnailUrl,
        inLibrary: false,
      );
    } catch (_) {
      return null;
    }
  }

  Album? _parseAlbum(Map<String, dynamic> r) {
    try {
      final browseId = _nav(r, ['navigationEndpoint', 'browseEndpoint', 'browseId']) as String?;
      if (browseId == null) return null;
      final title = _nav(r, [
        'flexColumns', 0,
        'musicResponsiveListItemFlexColumnRenderer',
        'text', 'runs', 0, 'text',
      ]) as String? ?? '';
      final col1Runs = _nav(r, [
        'flexColumns', 1,
        'musicResponsiveListItemFlexColumnRenderer',
        'text', 'runs',
      ]) as List? ?? [];
      // format: [Album/Single/EP, •, Artist, •, Year]
      final artist = col1Runs.length >= 3 ? (col1Runs[2]['text'] as String? ?? '') : '';
      final yearStr = col1Runs.length >= 5 ? (col1Runs[4]['text'] as String? ?? '0') : '0';
      return Album(
        id: browseId,
        title: title,
        artist: artist,
        artistId: '',
        year: int.tryParse(yearStr) ?? 0,
      );
    } catch (_) {
      return null;
    }
  }

  Artist? _parseArtist(Map<String, dynamic> r) {
    try {
      final browseId = _nav(r, ['navigationEndpoint', 'browseEndpoint', 'browseId']) as String?;
      if (browseId == null) return null;
      final name = _nav(r, [
        'flexColumns', 0,
        'musicResponsiveListItemFlexColumnRenderer',
        'text', 'runs', 0, 'text',
      ]) as String? ?? '';
      return Artist(id: browseId, name: name);
    } catch (_) {
      return null;
    }
  }

  Playlist? _parsePlaylist(Map<String, dynamic> r) {
    try {
      final browseId = _nav(r, ['navigationEndpoint', 'browseEndpoint', 'browseId']) as String?;
      if (browseId == null) return null;
      final name = _nav(r, [
        'flexColumns', 0,
        'musicResponsiveListItemFlexColumnRenderer',
        'text', 'runs', 0, 'text',
      ]) as String? ?? '';
      return Playlist(id: browseId, name: name);
    } catch (_) {
      return null;
    }
  }

  dynamic _nav(dynamic obj, List<dynamic> keys) {
    dynamic cur = obj;
    for (final key in keys) {
      if (cur == null) return null;
      if (key is int && cur is List) {
        if (key >= cur.length) return null;
        cur = cur[key];
      } else if (key is String && cur is Map) {
        cur = cur[key];
      } else {
        return null;
      }
    }
    return cur;
  }

  Duration parseDuration(String? text) {
    if (text == null) return const Duration(minutes: 3, seconds: 30);
    final parts = text.split(':').map(int.tryParse).toList();
    if (parts.length == 2 && parts[0] != null && parts[1] != null) {
      return Duration(minutes: parts[0]!, seconds: parts[1]!);
    }
    if (parts.length == 3 && parts[0] != null && parts[1] != null && parts[2] != null) {
      return Duration(hours: parts[0]!, minutes: parts[1]!, seconds: parts[2]!);
    }
    return const Duration(minutes: 3, seconds: 30);
  }

  /// Fetches a live CDN stream URL. Never cache — expires in ~6 hours.
  ///
  /// Primary path: a direct InnerTube `/player` call with the ANDROID_MUSIC
  /// client, whose adaptiveFormats carry ready-to-play `url` fields (no cipher,
  /// no n-param). Falls back to youtube_explode_dart if that returns nothing,
  /// so we are never worse off than the previous implementation.
  Future<String?> getStreamUrl(String videoId,
      {AudioQuality quality = AudioQuality.auto}) async {
    _log('getStreamUrl: $videoId quality=$quality');
    final direct = await getStreamUrlDirect(videoId, quality);
    if (direct != null) return direct;
    _log('direct player call yielded no url — falling back to youtube_explode');
    return _getStreamUrlViaExplode(videoId, quality);
  }

  /// Direct InnerTube `youtubei/v1/player` request (ANDROID_MUSIC client).
  /// Returns the itag-140 AAC url (itag 139 for low quality), or null on any
  /// failure / playability error so the caller can fall back.
  Future<String?> getStreamUrlDirect(
      String videoId, AudioQuality quality) async {
    final uri = Uri.parse('$_ytPlayerEndpoint&key=$_ytMusicKey');
    final client = _createClient();
    try {
      final req = await client.postUrl(uri);
      req.headers
        ..set('content-type', 'application/json')
        ..set('accept-encoding', 'identity')
        ..set('user-agent',
            'com.google.android.apps.youtube.vr.oculus/1.60.19 (Linux; U; Android 12L) gzip');
      req.write(jsonEncode({
        'context': _androidVrContext,
        'videoId': videoId,
        'contentCheckOk': true,
        'racyCheckOk': true,
      }));
      final res = await req.close();
      final body = await res.transform(utf8.decoder).join();
      final data = jsonDecode(body) as Map<String, dynamic>;

      final status = _nav(data, ['playabilityStatus', 'status']) as String?;
      if (status != null && status != 'OK') {
        final reason = _nav(data, ['playabilityStatus', 'reason']) as String?;
        _log('player status=$status reason=$reason for $videoId');
        return null;
      }

      final formats =
          _nav(data, ['streamingData', 'adaptiveFormats']) as List?;
      if (formats == null || formats.isEmpty) {
        _log('no adaptiveFormats for $videoId');
        return null;
      }
      // AAC/mp4 only — itag 140 (~128 kbps) preferred, 139 (~48 kbps) for low.
      final wantedItag = quality == AudioQuality.low ? 139 : 140;
      Map? chosen;
      Map? anyAac;
      for (final f in formats.cast<Map>()) {
        final mime = (f['mimeType'] as String?) ?? '';
        if (!mime.startsWith('audio/mp4')) continue;
        anyAac ??= f;
        if (f['itag'] == wantedItag) {
          chosen = f;
          break;
        }
      }
      chosen ??= anyAac;
      if (chosen == null) {
        _log('no AAC/mp4 adaptiveFormat for $videoId');
        return null;
      }
      // ANDROID_MUSIC returns a plain `url`; if a signatureCipher shows up
      // instead, this client can't deobfuscate it — bail to the fallback.
      final url = chosen['url'] as String?;
      if (url == null) {
        _log('AAC format has no direct url (signatureCipher) for $videoId');
        return null;
      }
      _log('direct stream itag=${chosen['itag']} mime=${chosen['mimeType']}');
      return url;
    } catch (e) {
      _log('direct player error: $e');
      return null;
    } finally {
      client.close(force: true);
    }
  }

  /// Fallback stream extraction via youtube_explode_dart.
  Future<String?> _getStreamUrlViaExplode(
      String videoId, AudioQuality quality) async {
    try {
      final manifest = await _yt.videos.streams.getManifest(
        videoId,
        ytClients: [YoutubeApiClient.androidSdkless],
      );
      // Only use AAC/mp4 — opus/webm causes source error 0 on Android just_audio.
      final mp4Streams = manifest.audioOnly
          .where((s) => s.codec.mimeType == 'audio/mp4')
          .toList()
        ..sort((a, b) => b.bitrate.bitsPerSecond.compareTo(a.bitrate.bitsPerSecond));
      if (mp4Streams.isEmpty) {
        _log('WARNING: no mp4 audio stream for $videoId — refusing fallback to incompatible codec');
        return null;
      }
      // low quality → lowest bitrate (itag 139, ~50 kbps); auto/high → highest.
      final audio = quality == AudioQuality.low ? mp4Streams.last : mp4Streams.first;
      final url = audio.url.toString();
      _log('explode stream: mime=${audio.codec.mimeType} bitrate=${audio.bitrate.bitsPerSecond}');
      return url;
    } catch (e, st) {
      _log('getStreamUrl (explode) error: $e\n$st');
      return null;
    }
  }

  /// Downloads audio to [destPath] as AAC/mp4. Streams bytes to avoid loading into RAM.
  Future<void> downloadAudio(
    String videoId,
    String destPath, {
    void Function(int received, int total)? onProgress,
  }) async {
    final manifest = await _yt.videos.streams.getManifest(
      videoId,
      ytClients: [YoutubeApiClient.androidSdkless],
    );
    final mp4Streams = manifest.audioOnly
        .where((s) => s.codec.mimeType == 'audio/mp4')
        .toList()
      ..sort((a, b) => b.bitrate.bitsPerSecond.compareTo(a.bitrate.bitsPerSecond));
    if (mp4Streams.isEmpty) throw Exception('No AAC/mp4 stream available for $videoId');
    final audio = mp4Streams.first;
    final stream = _yt.videos.streams.get(audio);
    final file = File(destPath);
    await file.parent.create(recursive: true);
    final sink = file.openWrite();
    final total = audio.size.totalBytes;
    int received = 0;
    await for (final chunk in stream) {
      sink.add(chunk);
      received += chunk.length;
      onProgress?.call(received, total);
    }
    await sink.flush();
    await sink.close();
  }

  void dispose() => _yt.close();
}
