import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/song.dart';

class YouTubeLibraryCache {
  static const _fileName = 'yt_library.json';

  Future<File> _cacheFile() async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/$_fileName');
  }

  Future<List<Song>> load() async {
    try {
      final file = await _cacheFile();
      if (!await file.exists()) return [];
      final raw = await file.readAsString();
      final list = jsonDecode(raw) as List<dynamic>;
      return list.map((e) => Song.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _save(List<Song> songs) async {
    final file = await _cacheFile();
    await file.writeAsString(jsonEncode(songs.map((s) => s.toJson()).toList()));
  }

  Future<List<Song>> add(Song song, List<Song> current) async {
    final updated = [
      ...current.where((s) => s.id != song.id),
      song.copyWith(inLibrary: true),
    ];
    await _save(updated);
    return updated;
  }

  Future<List<Song>> remove(String songId, List<Song> current) async {
    final updated = current.where((s) => s.id != songId).toList();
    await _save(updated);
    return updated;
  }

  Future<List<Song>> update(Song song, List<Song> current) async {
    final updated = current.map((s) => s.id == song.id ? song : s).toList();
    await _save(updated);
    return updated;
  }
}
