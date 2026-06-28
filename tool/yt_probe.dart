// Live probe: tests the real app code path for stream URL resolution.
// Usage: dart run tool/yt_probe.dart [videoId]
// Exit 0 = all checks passed. Exit 1 = something is broken.
import 'dart:io';
import 'package:mymusic/data/youtube_music_service.dart';
import 'package:mymusic/models/settings.dart';

Future<void> main(List<String> args) async {
  final videoId = args.isNotEmpty ? args[0] : 'dQw4w9WgXcQ';
  print('--- yt_probe: videoId=$videoId ---');

  final svc = YouTubeMusicService();
  bool ok = true;

  try {
    final url = await svc.getStreamUrl(videoId, quality: AudioQuality.auto);
    if (url == null) {
      print('RESULT_NULL — getStreamUrl returned null');
      ok = false;
    } else {
      final hasVr = url.contains('c=ANDROID_VR');
      final hasItag = url.contains('itag=140');
      print('RESULT_OK len=${url.length}');
      print('CLIENT_CHECK=${hasVr ? "ANDROID_VR_OK" : "ANDROID_VR_MISSING"}');
      print('ITAG_CHECK=${hasItag ? "ITAG140_OK" : "ITAG140_MISSING"}');
      if (!hasVr || !hasItag) ok = false;

      // Range request to confirm the CDN URL actually serves bytes.
      print('--- Range check ---');
      final client = HttpClient();
      try {
        final req = await client.getUrl(Uri.parse(url));
        req.headers.set('range', 'bytes=0-1023');
        final res = await req.close();
        await res.drain<void>();
        final rangeOk = res.statusCode == 206;
        print('HTTP=${res.statusCode} RANGE_CHECK=${rangeOk ? "RANGE_OK" : "RANGE_FAIL"}');
        if (!rangeOk) ok = false;
      } finally {
        client.close(force: true);
      }
    }
  } catch (e, st) {
    print('RESULT_ERROR: $e\n$st');
    ok = false;
  } finally {
    svc.dispose();
  }

  print('--- ${ok ? "PASS" : "FAIL"} ---');
  exit(ok ? 0 : 1);
}
