class Artist {
  final String id;
  final String name;
  final bool inLibrary;

  const Artist({
    required this.id,
    required this.name,
    this.inLibrary = false,
  });

  Artist copyWith({bool? inLibrary}) {
    return Artist(id: id, name: name, inLibrary: inLibrary ?? this.inLibrary);
  }
}
