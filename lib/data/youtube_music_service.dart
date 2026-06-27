import 'dart:io';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import '../models/song.dart';

class YouTubeMusicService {
  final _yt = YoutubeExplode();

  Future<List<Song>> search(String query) async {
    try {
      final results = await _yt.search.search(query);
      return results.map(_videoToSong).toList();
    } catch (_) {
      return [];
    }
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

  Song _videoToSong(Video v) => Song(
    id: 'yt_${v.id.value}',
    title: v.title,
    artist: v.author,
    artistId: v.channelId.value,
    album: '',
    albumId: '',
    duration: v.duration ?? const Duration(minutes: 3, seconds: 30),
    videoId: v.id.value,
    thumbnailUrl: v.thumbnails.highResUrl,
    inLibrary: false,
  );

  void dispose() => _yt.close();
}
