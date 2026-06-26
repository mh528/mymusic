class Playlist {
  final String id;
  final String name;
  final List<String> songIds;
  final bool isDownloaded;
  final bool isDownloading;

  const Playlist({
    required this.id,
    required this.name,
    this.songIds = const [],
    this.isDownloaded = false,
    this.isDownloading = false,
  });

  int get songCount => songIds.length;

  Playlist copyWith({
    String? name,
    List<String>? songIds,
    bool? isDownloaded,
    bool? isDownloading,
  }) {
    return Playlist(
      id: id,
      name: name ?? this.name,
      songIds: songIds ?? this.songIds,
      isDownloaded: isDownloaded ?? this.isDownloaded,
      isDownloading: isDownloading ?? this.isDownloading,
    );
  }
}
