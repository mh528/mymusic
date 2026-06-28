import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mymusic/data/youtube_library_cache.dart';
import 'package:mymusic/models/song.dart';

Song _song(String id) => Song(
      id: id,
      title: 'Test Song',
      artist: 'Artist',
      artistId: '',
      album: '',
      albumId: '',
      duration: const Duration(minutes: 3),
      videoId: id,
      inLibrary: false,
    );

void main() {
  late Directory tempDir;
  late YouTubeLibraryCache cache;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('yt_cache_test_');
    cache = YouTubeLibraryCache(directory: tempDir);
  });

  tearDown(() async {
    await tempDir.delete(recursive: true);
  });

  group('YouTubeLibraryCache', () {
    test('load on missing file returns empty list', () async {
      final result = await cache.load();
      expect(result, isEmpty);
    });

    test('add then load persists song', () async {
      final song = _song('yt_abc123');
      await cache.add(song, []);
      final loaded = await cache.load();
      expect(loaded, hasLength(1));
      expect(loaded.first.id, 'yt_abc123');
      expect(loaded.first.inLibrary, isTrue);
    });

    test('add deduplicates by id', () async {
      final song = _song('yt_abc123');
      await cache.add(song, [song.copyWith(inLibrary: true)]);
      final loaded = await cache.load();
      expect(loaded, hasLength(1));
    });

    test('remove deletes song by id', () async {
      final song = _song('yt_abc123');
      final withSong = await cache.add(song, []);
      await cache.remove('yt_abc123', withSong);
      final loaded = await cache.load();
      expect(loaded, isEmpty);
    });

    test('remove leaves other songs untouched', () async {
      final a = _song('yt_aaa');
      final b = _song('yt_bbb');
      final both = await cache.add(a, []);
      final withBoth = await cache.add(b, both);
      await cache.remove('yt_aaa', withBoth);
      final loaded = await cache.load();
      expect(loaded, hasLength(1));
      expect(loaded.first.id, 'yt_bbb');
    });

    test('update replaces song in place', () async {
      final original = _song('yt_abc123');
      final current = await cache.add(original, []);
      final updated = original.copyWith(isDownloaded: true, filePath: '/data/abc.m4a');
      await cache.update(updated, current);
      final loaded = await cache.load();
      expect(loaded.first.isDownloaded, isTrue);
      expect(loaded.first.filePath, '/data/abc.m4a');
    });

    test('load on corrupted JSON returns empty list without throwing', () async {
      final file = File('${tempDir.path}/yt_library.json');
      await file.writeAsString('NOT_VALID_JSON{{{{');
      final result = await cache.load();
      expect(result, isEmpty);
    });

    test('round-trip preserves all fields', () async {
      final song = Song(
        id: 'yt_xyz',
        title: 'Round Trip',
        artist: 'The Artist',
        artistId: 'art1',
        album: 'The Album',
        albumId: 'alb1',
        duration: const Duration(minutes: 4, seconds: 12),
        videoId: 'xyz',
        thumbnailUrl: 'https://example.com/thumb.jpg',
        inLibrary: true,
        isDownloaded: true,
        filePath: '/data/xyz.m4a',
      );
      await cache.add(song, []);
      final loaded = await cache.load();
      final s = loaded.first;
      expect(s.title, 'Round Trip');
      expect(s.artist, 'The Artist');
      expect(s.duration, const Duration(minutes: 4, seconds: 12));
      expect(s.thumbnailUrl, 'https://example.com/thumb.jpg');
      expect(s.isDownloaded, isTrue);
      expect(s.filePath, '/data/xyz.m4a');
    });
  });
}
