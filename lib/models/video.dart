class Video {
  final String id;
  final String title;
  final String artist;
  final String artistId;
  final Duration duration;

  const Video({
    required this.id,
    required this.title,
    required this.artist,
    required this.artistId,
    this.duration = const Duration(minutes: 3, seconds: 45),
  });
}
