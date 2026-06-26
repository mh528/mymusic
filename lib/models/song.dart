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
  });

  Song copyWith({
    bool? isDownloaded,
    bool? isDownloading,
    bool? inLibrary,
    bool? inQueue,
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
