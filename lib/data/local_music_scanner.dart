import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:metadata_god/metadata_god.dart';
import '../models/song.dart';

class LocalMusicScanner {
  static const _audioExtensions = {'.mp3', '.flac', '.m4a', '.aac', '.wav', '.ogg'};

  /// Scans [folderPaths] recursively and returns a flat list of [Song]s.
  /// Calls onProgress with the running count as each file is processed.
  Future<List<Song>> scan(
    List<String> folderPaths, {
    void Function(int count)? onProgress,
  }) async {
    final songs = <Song>[];
    for (final folderPath in folderPaths) {
      final dir = Directory(folderPath);
      if (!dir.existsSync()) continue;
      await for (final entity in dir.list(recursive: true, followLinks: false)) {
        if (entity is! File) continue;
        final ext = entity.path.toLowerCase();
        if (!_audioExtensions.any((e) => ext.endsWith(e))) continue;
        final song = await _buildSong(entity);
        if (song != null) {
          songs.add(song);
          onProgress?.call(songs.length);
        }
      }
    }
    return songs;
  }

  Future<Song?> _buildSong(File file) async {
    try {
      final path = file.path;
      final segments = path.split(Platform.pathSeparator);
      final filename = segments.last;
      final nameWithoutExt = filename.contains('.')
          ? filename.substring(0, filename.lastIndexOf('.'))
          : filename;
      final parentFolder = segments.length >= 2 ? segments[segments.length - 2] : 'Unknown Album';
      final grandparentFolder = segments.length >= 3 ? segments[segments.length - 3] : 'Unknown Artist';

      Metadata? meta;
      try {
        meta = await MetadataGod.readMetadata(file: path);
      } catch (_) {
        // Unreadable tags — fall back to filename/folder
      }

      final title = _nonEmpty(meta?.title) ?? nameWithoutExt;
      final artist = _nonEmpty(meta?.artist) ?? grandparentFolder;
      final album = _nonEmpty(meta?.album) ?? parentFolder;
      final durationMs = meta?.durationMs?.round();

      // Stable ID: MD5 of the absolute file path
      final id = md5.convert(path.codeUnits).toString();

      // Derive stable IDs for artist/album grouping
      final artistId = md5.convert(artist.toLowerCase().codeUnits).toString();
      final albumId = md5.convert('$artist\x00$album'.toLowerCase().codeUnits).toString();

      return Song(
        id: id,
        title: title,
        artist: artist,
        artistId: artistId,
        album: album,
        albumId: albumId,
        duration: durationMs != null
            ? Duration(milliseconds: durationMs)
            : const Duration(minutes: 3, seconds: 45),
        filePath: 'file://$path',
        albumArtBytes: meta?.picture?.data,
        inLibrary: true,
        isDownloaded: true,
      );
    } catch (_) {
      return null;
    }
  }

  static String? _nonEmpty(String? s) {
    if (s == null || s.trim().isEmpty) return null;
    return s.trim();
  }
}
