import 'dart:typed_data';

class Song {
  final String id;
  final String title;
  final String artist;
  final String artistId;
  final String album;
  final String albumId;
  final Duration duration;
  final bool isDownloaded;
  final bool isDownloading;
  final bool inLibrary;
  final bool inQueue;
  // asset:///, file://, or https:// URL; null = not playable yet
  final String? filePath;
  // Embedded album art from ID3 tags; null = use grey placeholder
  final Uint8List? albumArtBytes;
  // YouTube video ID — null for local songs
  final String? videoId;
  // YouTube thumbnail URL — null for local songs
  final String? thumbnailUrl;

  const Song({
    required this.id,
    required this.title,
    required this.artist,
    required this.artistId,
    required this.album,
    required this.albumId,
    this.duration = const Duration(minutes: 3, seconds: 45),
    this.isDownloaded = false,
    this.isDownloading = false,
    this.inLibrary = false,
    this.inQueue = false,
    this.filePath,
    this.albumArtBytes,
    this.videoId,
    this.thumbnailUrl,
  });

  Song copyWith({
    bool? isDownloaded,
    bool? isDownloading,
    bool? inLibrary,
    bool? inQueue,
    String? filePath,
    bool clearFilePath = false,
    Uint8List? albumArtBytes,
    String? videoId,
    String? thumbnailUrl,
  }) {
    return Song(
      id: id,
      title: title,
      artist: artist,
      artistId: artistId,
      album: album,
      albumId: albumId,
      duration: duration,
      isDownloaded: isDownloaded ?? this.isDownloaded,
      isDownloading: isDownloading ?? this.isDownloading,
      inLibrary: inLibrary ?? this.inLibrary,
      inQueue: inQueue ?? this.inQueue,
      filePath: clearFilePath ? null : (filePath ?? this.filePath),
      albumArtBytes: albumArtBytes ?? this.albumArtBytes,
      videoId: videoId ?? this.videoId,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'artist': artist,
    'artistId': artistId,
    'album': album,
    'albumId': albumId,
    'durationMs': duration.inMilliseconds,
    'isDownloaded': isDownloaded,
    'inLibrary': inLibrary,
    'filePath': filePath,
    'videoId': videoId,
    'thumbnailUrl': thumbnailUrl,
  };

  factory Song.fromJson(Map<String, dynamic> j) => Song(
    id: j['id'] as String,
    title: j['title'] as String,
    artist: j['artist'] as String,
    artistId: j['artistId'] as String? ?? '',
    album: j['album'] as String? ?? '',
    albumId: j['albumId'] as String? ?? '',
    duration: Duration(milliseconds: (j['durationMs'] as int?) ?? 0),
    isDownloaded: j['isDownloaded'] as bool? ?? false,
    inLibrary: j['inLibrary'] as bool? ?? true,
    filePath: j['filePath'] as String?,
    videoId: j['videoId'] as String?,
    thumbnailUrl: j['thumbnailUrl'] as String?,
  );
}

extension DurationFormat on Duration {
  String get mmss {
    final m = inMinutes;
    final s = inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}
