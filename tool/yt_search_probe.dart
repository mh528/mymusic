// Live probe: tests the real YouTube Music search code path.
// Usage: dart run tool/yt_search_probe.dart [query]
// Exit 0 = pass. Exit 1 = something is broken.
import 'dart:io';
import 'package:mymusic/data/youtube_music_service.dart';

Future<void> main(List<String> args) async {
  final svc = YouTubeMusicService();
  bool ok = true;

  try {
    // Test 1: real query should return results.
    final query = args.isNotEmpty ? args[0] : 'Radiohead';
    print('--- yt_search_probe: query="$query" ---');
    final results = await svc.search(query);
    print('SONGS=${results.songs.length} ALBUMS=${results.albums.length} '
        'ARTISTS=${results.artists.length} PLAYLISTS=${results.playlists.length}');

    if (results.songs.isEmpty) {
      print('FAIL: expected songs > 0 for query "$query"');
      ok = false;
    } else {
      for (final song in results.songs) {
        if (song.videoId == null || song.videoId!.isEmpty) {
          print('FAIL: song "${song.title}" has empty videoId');
          ok = false;
          break;
        }
        if (song.title.isEmpty) {
          print('WARN: song with videoId=${song.videoId} has empty title');
        }
      }
    }

    // Test 2: empty query must not throw, must return gracefully.
    print('--- empty query test ---');
    final empty = await svc.search('');
    print('EMPTY_QUERY: songs=${empty.songs.length} (expect 0, no throw)');
  } catch (e, st) {
    print('EXCEPTION: $e\n$st');
    ok = false;
  } finally {
    svc.dispose();
  }

  print('--- ${ok ? "PASS" : "FAIL"} ---');
  exit(ok ? 0 : 1);
}
