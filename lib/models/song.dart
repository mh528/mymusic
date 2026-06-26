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
  });

  Song copyWith({
    bool? isDownloaded,
    bool? isDownloading,
    bool? inLibrary,
    bool? inQueue,
    String? filePath,
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
      filePath: filePath ?? this.filePath,
    );
  }
}

extension DurationFormat on Duration {
  String get mmss {
    final m = inMinutes;
    final s = inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}
