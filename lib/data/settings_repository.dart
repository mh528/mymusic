import 'package:shared_preferences/shared_preferences.dart';
import '../models/settings.dart';

class SettingsRepository {
  static const _audioQuality = 'audioQuality';
  static const _persistentQueue = 'persistentQueue';
  static const _autoOpenQueue = 'autoOpenQueue';
  static const _streamOverWifi = 'streamOverWifi';
  static const _defaultLibraryTab = 'defaultLibraryTab';
  static const _defaultLibrarySource = 'defaultLibrarySource';
  static const _defaultSearchSource = 'defaultSearchSource';
  static const _visibleTabs = 'visibleTabs';
  static const _localMusicFolder = 'localMusicFolder';
  static const _musicSource = 'musicSource';

  Future<AppSettings> load() async {
    final prefs = await SharedPreferences.getInstance();

    final qualityIndex = prefs.getInt(_audioQuality) ?? 0;
    final libTabIndex = prefs.getInt(_defaultLibraryTab) ?? 0;
    final libSourceIndex = prefs.getInt(_defaultLibrarySource) ?? 0;
    final searchSourceIndex = prefs.getInt(_defaultSearchSource) ?? 0;
    final visibleTabInts = prefs.getStringList(_visibleTabs);

    Set<LibraryTab> visibleTabs;
    if (visibleTabInts != null) {
      visibleTabs = visibleTabInts
          .map((s) => int.tryParse(s))
          .whereType<int>()
          .where((i) => i < LibraryTab.values.length)
          .map((i) => LibraryTab.values[i])
          .toSet();
      if (visibleTabs.isEmpty) visibleTabs = {LibraryTab.songs};
    } else {
      visibleTabs = {
        LibraryTab.songs,
        LibraryTab.albums,
        LibraryTab.artists,
        LibraryTab.playlists,
      };
    }

    return AppSettings(
      audioQuality: AudioQuality.values[qualityIndex.clamp(0, AudioQuality.values.length - 1)],
      persistentQueue: prefs.getBool(_persistentQueue) ?? false,
      autoOpenQueue: prefs.getBool(_autoOpenQueue) ?? false,
      streamOverWifiOnly: prefs.getBool(_streamOverWifi) ?? false,
      defaultLibraryTab: LibraryTab.values[libTabIndex.clamp(0, LibraryTab.values.length - 1)],
      defaultLibrarySource: LibrarySource.values[libSourceIndex.clamp(0, LibrarySource.values.length - 1)],
      defaultSearchSource: SearchSource.values[searchSourceIndex.clamp(0, SearchSource.values.length - 1)],
      visibleTabs: visibleTabs,
      localMusicFolder: prefs.getString(_localMusicFolder),
      musicSource: MusicSource.values[(prefs.getInt(_musicSource) ?? 0).clamp(0, MusicSource.values.length - 1)],
    );
  }

  Future<void> save(AppSettings s) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_audioQuality, s.audioQuality.index);
    await prefs.setBool(_persistentQueue, s.persistentQueue);
    await prefs.setBool(_autoOpenQueue, s.autoOpenQueue);
    await prefs.setBool(_streamOverWifi, s.streamOverWifiOnly);
    await prefs.setInt(_defaultLibraryTab, s.defaultLibraryTab.index);
    await prefs.setInt(_defaultLibrarySource, s.defaultLibrarySource.index);
    await prefs.setInt(_defaultSearchSource, s.defaultSearchSource.index);
    await prefs.setStringList(
      _visibleTabs,
      s.visibleTabs.map((t) => t.index.toString()).toList(),
    );
    if (s.localMusicFolder != null) {
      await prefs.setString(_localMusicFolder, s.localMusicFolder!);
    } else {
      await prefs.remove(_localMusicFolder);
    }
    await prefs.setInt(_musicSource, s.musicSource.index);
  }
}
