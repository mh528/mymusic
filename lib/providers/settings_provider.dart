import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/settings_repository.dart';
import '../models/settings.dart';

final settingsRepositoryProvider = Provider((ref) => SettingsRepository());

final settingsProvider =
    AsyncNotifierProvider<SettingsNotifier, AppSettings>(SettingsNotifier.new);

class SettingsNotifier extends AsyncNotifier<AppSettings> {
  late final SettingsRepository _repo;

  @override
  Future<AppSettings> build() async {
    _repo = ref.read(settingsRepositoryProvider);
    return _repo.load();
  }

  Future<void> _update(AppSettings Function(AppSettings) updater) async {
    final current = state.valueOrNull;
    if (current == null) return;
    final updated = updater(current);
    state = AsyncData(updated);
    await _repo.save(updated);
  }

  void setAudioQuality(AudioQuality q) =>
      _update((s) => s.copyWith(audioQuality: q));

  void setPersistentQueue(bool v) =>
      _update((s) => s.copyWith(persistentQueue: v));

  void setAutoOpenQueue(bool v) =>
      _update((s) => s.copyWith(autoOpenQueue: v));

  void setStreamOverWifiOnly(bool v) =>
      _update((s) => s.copyWith(streamOverWifiOnly: v));

  void setDefaultLibraryTab(LibraryTab t) =>
      _update((s) => s.copyWith(defaultLibraryTab: t));

  void setDefaultLibrarySource(LibrarySource src) =>
      _update((s) => s.copyWith(defaultLibrarySource: src));

  void setDefaultSearchSource(SearchSource src) =>
      _update((s) => s.copyWith(defaultSearchSource: src));

  void setMusicSource(MusicSource src) =>
      _update((s) => s.copyWith(musicSource: src));

  void setShowQueueVolumeSlider(bool v) =>
      _update((s) => s.copyWith(showQueueVolumeSlider: v));

  void setLocalMusicFolder(String? path) => _update((s) => path != null
      ? s.copyWith(localMusicFolder: path)
      : s.copyWith(clearLocalMusicFolder: true));

  void setTabVisible(LibraryTab tab, bool visible) {
    _update((s) {
      final tabs = Set<LibraryTab>.from(s.visibleTabs);
      if (visible) {
        tabs.add(tab);
      } else {
        // At least one tab must remain visible
        if (tabs.length > 1) tabs.remove(tab);
      }
      // Ensure defaultLibraryTab is still visible
      LibraryTab defaultTab = s.defaultLibraryTab;
      if (!tabs.contains(defaultTab)) {
        defaultTab = LibraryTab.values.firstWhere((t) => tabs.contains(t));
      }
      return s.copyWith(visibleTabs: tabs, defaultLibraryTab: defaultTab);
    });
  }
}
