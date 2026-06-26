class Album {
  final String id;
  final String title;
  final String artist;
  final String artistId;
  final int year;
  final int songCount;
  final bool isDownloaded;
  final bool isDownloading;
  final bool inLibrary;

  const Album({
    required this.id,
    required this.title,
    required this.artist,
    required this.artistId,
    required this.year,
    this.songCount = 0,
    this.isDownloaded = false,
    this.isDownloading = false,
    this.inLibrary = false,
  });

  Album copyWith({
    bool? isDownloaded,
    bool? isDownloading,
    bool? inLibrary,
  }) {
    return Album(
      id: id,
      title: title,
      artist: artist,
      artistId: artistId,
      year: year,
      songCount: songCount,
      isDownloaded: isDownloaded ?? this.isDownloaded,
      isDownloading: isDownloading ?? this.isDownloading,
      inLibrary: inLibrary ?? this.inLibrary,
    );
  }
}
