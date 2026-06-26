class LivePerformance {
  final String id;
  final String title;
  final String artist;
  final String artistId;
  final String date;

  const LivePerformance({
    required this.id,
    required this.title,
    required this.artist,
    required this.artistId,
    this.date = '',
  });
}
