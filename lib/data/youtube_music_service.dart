import 'dart:convert';
import 'dart:io';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import '../models/song.dart';

const _ytMusicBase = 'https://music.youtube.com/youtubei/v1/';
const _ytMusicKey = 'AIzaSyC9XL3ZjWddXya6X74dJoCTL-WEYFDNX30';
const _ytMusicContext = {
  'client': {
    'clientName': 'WEB_REMIX',
    'clientVersion': '1.20260627.01.00',
    'hl': 'en',
  }
};

class YouTubeMusicService {
  final _yt = YoutubeExplode();

  Future<List<Song>> search(String query) async {
    try {
      final uri = Uri.parse(
          '${_ytMusicBase}search?prettyPrint=false&alt=json&key=$_ytMusicKey');
      final client = HttpClient();
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
        final body = await res.transform(utf8.decoder).join();
        final data = jsonDecode(body) as Map<String, dynamic>;
        return _parseSongs(data);
      } finally {
        client.close(force: true);
      }
    } catch (_) {
      return [];
    }
  }

  List<Song> _parseSongs(Map<String, dynamic> data) {
    final songs = <Song>[];
    try {
      final tabs = _nav(data, [
        'contents',
        'tabbedSearchResultsRenderer',
        'tabs',
        0,
        'tabRenderer',
        'content',
        'sectionListRenderer',
        'contents',
      ]) as List?;
      if (tabs == null) return songs;
      for (final section in tabs) {
        final shelf = section['musicShelfRenderer'];
        if (shelf == null) continue;
        final contents = shelf['contents'] as List?;
        if (contents == null) continue;
        for (final item in contents) {
          final renderer = item['musicResponsiveListItemRenderer'];
          if (renderer == null) continue;
          final song = _parseListItem(renderer);
          if (song != null) songs.add(song);
        }
      }
    } catch (_) {}
    return songs;
  }

  Song? _parseListItem(Map<String, dynamic> r) {
    try {
      // videoId
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

      // title
      final title = _nav(r, [
        'flexColumns',
        0,
        'musicResponsiveListItemFlexColumnRenderer',
        'text',
        'runs',
        0,
        'text',
      ]) as String? ?? '';

      // artist — second flex column, first run
      final artist = _nav(r, [
        'flexColumns',
        1,
        'musicResponsiveListItemFlexColumnRenderer',
        'text',
        'runs',
        0,
        'text',
      ]) as String? ?? '';

      // thumbnail
      final thumbs = _nav(r, [
        'thumbnail',
        'musicThumbnailRenderer',
        'thumbnail',
        'thumbnails',
      ]) as List?;
      final thumbnailUrl = thumbs != null && thumbs.isNotEmpty
          ? (thumbs.last['url'] as String?)
          : null;

      // duration from fixedColumns
      final durationText = _nav(r, [
        'fixedColumns',
        0,
        'musicResponsiveListItemFixedColumnRenderer',
        'text',
        'runs',
        0,
        'text',
      ]) as String?;
      final duration = _parseDuration(durationText);

      return Song(
        id: 'yt_$videoId',
        title: title,
        artist: artist,
        artistId: '',
        album: '',
        albumId: '',
        duration: duration,
        videoId: videoId,
        thumbnailUrl: thumbnailUrl,
        inLibrary: false,
      );
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

  Duration _parseDuration(String? text) {
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
  Future<String?> getStreamUrl(String videoId) async {
    try {
      final manifest = await _yt.videos.streams.getManifest(videoId);
      final audio = manifest.audioOnly.withHighestBitrate();
      return audio.url.toString();
    } catch (_) {
      return null;
    }
  }

  /// Downloads audio to [destPath]. Streams bytes to avoid loading into RAM.
  Future<void> downloadAudio(
    String videoId,
    String destPath, {
    void Function(int received, int total)? onProgress,
  }) async {
    final manifest = await _yt.videos.streams.getManifest(videoId);
    final audio = manifest.audioOnly.withHighestBitrate();
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
