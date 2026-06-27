enum AudioQuality { auto, high, low }

enum LibrarySource { library, downloads }

enum SearchSource { allMusic, library, downloads }

enum LibraryTab { songs, albums, artists, playlists }

enum RepeatMode { off, all, one }

enum MusicSource { mock, local }

class AppSettings {
  final AudioQuality audioQuality;
  final bool persistentQueue;
  final bool autoOpenQueue;
  final bool streamOverWifiOnly;
  final LibraryTab defaultLibraryTab;
  final LibrarySource defaultLibrarySource;
  final SearchSource defaultSearchSource;
  final Set<LibraryTab> visibleTabs;
  final String? localMusicFolder;
  final MusicSource musicSource;

  const AppSettings({
    this.audioQuality = AudioQuality.auto,
    this.persistentQueue = false,
    this.autoOpenQueue = false,
    this.streamOverWifiOnly = false,
    this.defaultLibraryTab = LibraryTab.songs,
    this.defaultLibrarySource = LibrarySource.library,
    this.defaultSearchSource = SearchSource.allMusic,
    this.visibleTabs = const {
      LibraryTab.songs,
      LibraryTab.albums,
      LibraryTab.artists,
      LibraryTab.playlists,
    },
    this.localMusicFolder,
    this.musicSource = MusicSource.mock,
  });

  AppSettings copyWith({
    AudioQuality? audioQuality,
    bool? persistentQueue,
    bool? autoOpenQueue,
    bool? streamOverWifiOnly,
    LibraryTab? defaultLibraryTab,
    LibrarySource? defaultLibrarySource,
    SearchSource? defaultSearchSource,
    Set<LibraryTab>? visibleTabs,
    String? localMusicFolder,
    bool clearLocalMusicFolder = false,
    MusicSource? musicSource,
  }) {
    return AppSettings(
      audioQuality: audioQuality ?? this.audioQuality,
      persistentQueue: persistentQueue ?? this.persistentQueue,
      autoOpenQueue: autoOpenQueue ?? this.autoOpenQueue,
      streamOverWifiOnly: streamOverWifiOnly ?? this.streamOverWifiOnly,
      defaultLibraryTab: defaultLibraryTab ?? this.defaultLibraryTab,
      defaultLibrarySource: defaultLibrarySource ?? this.defaultLibrarySource,
      defaultSearchSource: defaultSearchSource ?? this.defaultSearchSource,
      visibleTabs: visibleTabs ?? this.visibleTabs,
      localMusicFolder: clearLocalMusicFolder ? null : (localMusicFolder ?? this.localMusicFolder),
      musicSource: musicSource ?? this.musicSource,
    );
  }

  List<LibraryTab> get orderedVisibleTabs {
    return LibraryTab.values.where((t) => visibleTabs.contains(t)).toList();
  }
}
