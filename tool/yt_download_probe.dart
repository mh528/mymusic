// Live probe: tests the real downloadAudio code path end-to-end.
// Usage: dart run tool/yt_download_probe.dart [videoId]
// Exit 0 = pass. Exit 1 = download failed or file missing/empty.
import 'dart:io';
import 'package:mymusic/data/youtube_music_service.dart';

Future<void> main(List<String> args) async {
  final videoId = args.isNotEmpty ? args[0] : 'dQw4w9WgXcQ';
  final destPath = '/tmp/yt_probe_download_${DateTime.now().millisecondsSinceEpoch}.m4a';
  print('--- yt_download_probe: videoId=$videoId ---');
  print('dest=$destPath');

  final svc = YouTubeMusicService();
  bool ok = false;

  try {
    int lastReceived = 0;
    await svc.downloadAudio(
      videoId,
      destPath,
      onProgress: (received, total) {
        if (received - lastReceived > 200000) {
          print('progress: ${received ~/ 1024}KB / ${total ~/ 1024}KB');
          lastReceived = received;
        }
      },
    );

    final file = File(destPath);
    if (!await file.exists()) {
      print('FAIL: file does not exist after download');
    } else {
      final size = await file.length();
      print('FILE_SIZE=${size ~/ 1024}KB');
      if (size < 102400) {
        print('FAIL: file suspiciously small (< 100 KB)');
      } else {
        print('DOWNLOAD_OK');
        ok = true;
      }
    }
  } catch (e, st) {
    print('DOWNLOAD_ERROR: $e\n$st');
  } finally {
    svc.dispose();
    final f = File(destPath);
    if (await f.exists()) {
      await f.delete();
      print('cleanup: deleted $destPath');
    }
  }

  print('--- ${ok ? "PASS" : "FAIL"} ---');
  exit(ok ? 0 : 1);
}
