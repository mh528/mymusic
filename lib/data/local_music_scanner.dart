import 'dart:io';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import '../models/song.dart';

class LocalMusicScanner {
  static const _audioExtensions = {'.mp3', '.flac', '.m4a', '.aac', '.wav', '.ogg'};

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

      _ID3Tags? tags;
      try {
        tags = await _readID3Tags(file);
      } catch (_) {}

      final title = _nonEmpty(tags?.title) ?? nameWithoutExt;
      final artist = _nonEmpty(tags?.artist) ?? grandparentFolder;
      final album = _nonEmpty(tags?.album) ?? parentFolder;

      final id = md5.convert(path.codeUnits).toString();
      final artistId = md5.convert(artist.toLowerCase().codeUnits).toString();
      final albumId = md5.convert('$artist\x00$album'.toLowerCase().codeUnits).toString();

      return Song(
        id: id,
        title: title,
        artist: artist,
        artistId: artistId,
        album: album,
        albumId: albumId,
        duration: tags?.duration ?? const Duration(minutes: 3, seconds: 45),
        filePath: 'file://$path',
        albumArtBytes: tags?.albumArt,
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

class _ID3Tags {
  final String? title;
  final String? artist;
  final String? album;
  final Duration? duration;
  final Uint8List? albumArt;
  const _ID3Tags({this.title, this.artist, this.album, this.duration, this.albumArt});
}

/// Minimal ID3v2 parser — reads TIT2, TPE1, TALB, TLEN, APIC from MP3 files.
/// Falls back gracefully if the file has no ID3 header.
Future<_ID3Tags?> _readID3Tags(File file) async {
  final raf = await file.open();
  try {
    // Read up to 256 KB — enough to cover header + artwork
    final size = await raf.length();
    final readSize = size < 262144 ? size : 262144;
    final bytes = await raf.read(readSize);

    // Check ID3v2 magic
    if (bytes.length < 10) return null;
    if (bytes[0] != 0x49 || bytes[1] != 0x44 || bytes[2] != 0x33) return null; // "ID3"

    final majorVersion = bytes[3];
    if (majorVersion < 3) return null; // Only ID3v2.3 and v2.4

    // Syncsafe integer for tag size
    final tagSize = ((bytes[6] & 0x7F) << 21) |
        ((bytes[7] & 0x7F) << 14) |
        ((bytes[8] & 0x7F) << 7) |
        (bytes[9] & 0x7F);

    final hasExtHeader = (bytes[5] & 0x40) != 0;
    int pos = 10;

    if (hasExtHeader && pos + 4 <= bytes.length) {
      final extSize = _uint32(bytes, pos);
      pos += extSize;
    }

    final end = (10 + tagSize).clamp(0, bytes.length);

    String? title, artist, album;
    Duration? duration;
    Uint8List? albumArt;

    while (pos + 10 <= end) {
      final frameId = String.fromCharCodes(bytes.sublist(pos, pos + 4));
      if (frameId == '\x00\x00\x00\x00') break;

      final frameSize = majorVersion >= 4
          ? ((bytes[pos + 4] & 0x7F) << 21) |
              ((bytes[pos + 5] & 0x7F) << 14) |
              ((bytes[pos + 6] & 0x7F) << 7) |
              (bytes[pos + 7] & 0x7F)
          : _uint32(bytes, pos + 4);

      pos += 10;
      if (frameSize <= 0 || pos + frameSize > bytes.length) break;

      final frameData = bytes.sublist(pos, pos + frameSize);
      pos += frameSize;

      if (frameId == 'TIT2') title = _decodeText(frameData);
      else if (frameId == 'TPE1') artist = _decodeText(frameData);
      else if (frameId == 'TALB') album = _decodeText(frameData);
      else if (frameId == 'TLEN') {
        final ms = int.tryParse(_decodeText(frameData) ?? '');
        if (ms != null && ms > 0) duration = Duration(milliseconds: ms);
      } else if (frameId == 'APIC' && albumArt == null) {
        albumArt = _decodeApic(frameData);
      }
    }

    if (title == null && artist == null && album == null) return null;
    return _ID3Tags(title: title, artist: artist, album: album, duration: duration, albumArt: albumArt);
  } finally {
    await raf.close();
  }
}

int _uint32(Uint8List b, int offset) =>
    (b[offset] << 24) | (b[offset + 1] << 16) | (b[offset + 2] << 8) | b[offset + 3];

String? _decodeText(Uint8List data) {
  if (data.isEmpty) return null;
  final encoding = data[0];
  final content = data.sublist(1);
  try {
    if (encoding == 0x01 || encoding == 0x02) {
      // UTF-16 — strip BOM if present
      var start = 0;
      if (content.length >= 2 &&
          ((content[0] == 0xFF && content[1] == 0xFE) || (content[0] == 0xFE && content[1] == 0xFF))) {
        start = 2;
      }
      final words = <int>[];
      for (var i = start; i + 1 < content.length; i += 2) {
        final c = content[i] | (content[i + 1] << 8);
        if (c == 0) break;
        words.add(c);
      }
      return String.fromCharCodes(words).trim();
    } else {
      // Latin-1 or UTF-8
      final nullIdx = content.indexOf(0);
      final raw = nullIdx >= 0 ? content.sublist(0, nullIdx) : content;
      return String.fromCharCodes(raw).trim();
    }
  } catch (_) {
    return null;
  }
}

Uint8List? _decodeApic(Uint8List data) {
  if (data.length < 4) return null;
  try {
    // encoding(1) + mime(variable, null-terminated) + picture_type(1) + description(variable, null-terminated) + data
    int pos = 1; // skip encoding byte
    // skip mime type (null-terminated)
    while (pos < data.length && data[pos] != 0) pos++;
    pos++; // skip null
    if (pos >= data.length) return null;
    pos++; // skip picture type
    // skip description (null-terminated)
    while (pos < data.length && data[pos] != 0) pos++;
    pos++; // skip null
    if (pos >= data.length) return null;
    return data.sublist(pos);
  } catch (_) {
    return null;
  }
}
