import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/settings.dart';
import '../providers/local_library_provider.dart';
import '../providers/settings_provider.dart';
import '../theme.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsProvider);

    return Scaffold(
      body: SafeArea(
        child: settingsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (s) => _SettingsBody(settings: s),
        ),
      ),
    );
  }
}

class _SettingsBody extends ConsumerWidget {
  final AppSettings settings;
  const _SettingsBody({required this.settings});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(settingsProvider.notifier);

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        const SizedBox(height: 16),
        Text('Settings', style: Theme.of(context).textTheme.headlineLarge),
        const SizedBox(height: 24),

        // ── Playback ──────────────────────────────────────
        _SectionHeader('Playback'),
        _DropdownSetting<AudioQuality>(
          title: 'Audio Quality',
          description: 'Streaming audio quality',
          value: settings.audioQuality,
          items: AudioQuality.values,
          label: (q) => q.name[0].toUpperCase() + q.name.substring(1),
          onChanged: notifier.setAudioQuality,
        ),
        _ToggleSetting(
          title: 'Persistent Queue',
          description: 'Keep queue between sessions',
          value: settings.persistentQueue,
          onChanged: notifier.setPersistentQueue,
        ),
        _ToggleSetting(
          title: 'Auto Open Queue',
          description: 'Switch to Queue tab when a song starts',
          value: settings.autoOpenQueue,
          onChanged: notifier.setAutoOpenQueue,
        ),

        // ── Navigation / Tabs ─────────────────────────────
        _SectionHeader('Navigation & Tabs'),
        _DropdownSetting<LibrarySource>(
          title: 'Default Library Source',
          description: 'Which chip is selected by default in Library',
          value: settings.defaultLibrarySource,
          items: LibrarySource.values,
          label: (s) => s == LibrarySource.library ? 'Library' : 'Downloads',
          onChanged: notifier.setDefaultLibrarySource,
        ),
        _DropdownSetting<SearchSource>(
          title: 'Default Search Source',
          description: 'Which chip is selected by default in Search',
          value: settings.defaultSearchSource,
          items: SearchSource.values,
          label: (s) {
            switch (s) {
              case SearchSource.allMusic: return 'All Music';
              case SearchSource.library: return 'Library';
              case SearchSource.downloads: return 'Downloads';
            }
          },
          onChanged: notifier.setDefaultSearchSource,
        ),
        _DropdownSetting<LibraryTab>(
          title: 'Default Tab',
          description: 'Which tab is selected by default',
          value: settings.visibleTabs.contains(settings.defaultLibraryTab)
              ? settings.defaultLibraryTab
              : settings.orderedVisibleTabs.first,
          items: settings.orderedVisibleTabs,
          label: (t) => _tabLabel(t),
          onChanged: notifier.setDefaultLibraryTab,
        ),
        const SizedBox(height: 8),
        Text('Visible Tabs', style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: AppColors.textMuted,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        )),
        const SizedBox(height: 4),
        ...LibraryTab.values.map((tab) => _ToggleSetting(
          title: _tabLabel(tab),
          description: 'Show ${_tabLabel(tab)} tab in Library & Search',
          value: settings.visibleTabs.contains(tab),
          onChanged: (v) => notifier.setTabVisible(tab, v),
        )),

        // ── Local Library ─────────────────────────────────
        _SectionHeader('Local Library'),
        _LocalLibrarySection(settings: settings),

        // ── Data ──────────────────────────────────────────
        _SectionHeader('Data'),
        _ToggleSetting(
          title: 'Stream Over WiFi Only',
          description: 'Prevent streaming on mobile data',
          value: settings.streamOverWifiOnly,
          onChanged: notifier.setStreamOverWifiOnly,
        ),
        _InfoSetting(title: 'App Size', value: '12.4 MB'),
        _InfoSetting(title: 'Downloads', value: '0 MB'),
        _RemoveDownloadsButton(),

        // ── App ───────────────────────────────────────────
        _SectionHeader('App'),
        _InfoSetting(title: 'Version', value: '1.0.0'),
        const SizedBox(height: 32),
      ],
    );
  }

  String _tabLabel(LibraryTab t) {
    switch (t) {
      case LibraryTab.songs: return 'Songs';
      case LibraryTab.albums: return 'Albums';
      case LibraryTab.artists: return 'Artists';
      case LibraryTab.playlists: return 'Playlists';
    }
  }
}

class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 8),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          color: AppColors.textMuted,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _ToggleSetting extends StatelessWidget {
  final String title;
  final String description;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleSetting({
    required this.title,
    required this.description,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: AppColors.white, fontSize: 15, fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(description, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _DropdownSetting<T> extends StatelessWidget {
  final String title;
  final String description;
  final T value;
  final List<T> items;
  final String Function(T) label;
  final ValueChanged<T> onChanged;

  const _DropdownSetting({
    required this.title,
    required this.description,
    required this.value,
    required this.items,
    required this.label,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: AppColors.white, fontSize: 15, fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(description, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          DropdownButton<T>(
            value: value,
            dropdownColor: AppColors.bg2,
            underline: const SizedBox(),
            style: const TextStyle(color: AppColors.white, fontSize: 14),
            icon: const Icon(Icons.chevron_right, color: AppColors.textMuted, size: 18),
            items: items
                .map((item) => DropdownMenuItem(
                      value: item,
                      child: Text(label(item)),
                    ))
                .toList(),
            onChanged: (v) { if (v != null) onChanged(v); },
          ),
        ],
      ),
    );
  }
}

class _InfoSetting extends StatelessWidget {
  final String title;
  final String value;
  const _InfoSetting({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Text(title, style: const TextStyle(color: AppColors.white, fontSize: 15, fontWeight: FontWeight.w500)),
          const Spacer(),
          Text(value, style: const TextStyle(color: AppColors.textMuted, fontSize: 14)),
        ],
      ),
    );
  }
}

class _LocalLibrarySection extends ConsumerWidget {
  final AppSettings settings;
  const _LocalLibrarySection({required this.settings});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localLibrary = ref.watch(localLibraryProvider);
    final settingsNotifier = ref.read(settingsProvider.notifier);
    final localLibraryNotifier = ref.read(localLibraryProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _DropdownSetting<MusicSource>(
          title: 'Music Source',
          description: 'Use local files or mock data',
          value: settings.musicSource,
          items: MusicSource.values,
          label: (s) => s == MusicSource.local ? 'Local Files' : 'Mock Data',
          onChanged: (v) => settingsNotifier.setMusicSource(v),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Music Folder', style: TextStyle(color: AppColors.white, fontSize: 15, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 2),
                    Text(
                      settings.localMusicFolder ?? 'Not configured',
                      style: TextStyle(
                        color: settings.localMusicFolder != null ? AppColors.textMuted : AppColors.textMuted,
                        fontSize: 12,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: () => _pickFolder(context, ref, settingsNotifier, localLibraryNotifier),
                child: Text(
                  settings.localMusicFolder != null ? 'Change' : 'Choose',
                  style: const TextStyle(color: AppColors.white, fontSize: 14),
                ),
              ),
              if (settings.localMusicFolder != null)
                TextButton(
                  onPressed: () => settingsNotifier.setLocalMusicFolder(null),
                  child: const Text('Remove', style: TextStyle(color: AppColors.red, fontSize: 14)),
                ),
            ],
          ),
        ),
        if (localLibrary.isScanning)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white),
                ),
                const SizedBox(width: 12),
                Text(
                  'Scanning… ${localLibrary.scanProgress} songs found',
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                ),
              ],
            ),
          )
        else if (settings.localMusicFolder != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Text(
                  '${localLibrary.songs.length} songs in library',
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => localLibraryNotifier.scan(
                    [settings.localMusicFolder!],
                  ),
                  child: const Text('Rescan', style: TextStyle(color: AppColors.white, fontSize: 14)),
                ),
              ],
            ),
          ),
        if (localLibrary.error != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(
              'Error: ${localLibrary.error}',
              style: const TextStyle(color: AppColors.red, fontSize: 12),
            ),
          ),
      ],
    );
  }

  Future<void> _pickFolder(
    BuildContext context,
    WidgetRef ref,
    SettingsNotifier settingsNotifier,
    LocalLibraryNotifier localLibraryNotifier,
  ) async {
    // Request Android storage permission
    final status = await Permission.audio.request();
    if (status.isDenied || status.isPermanentlyDenied) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Storage permission required to access music files')),
        );
      }
      return;
    }

    final path = await FilePicker.getDirectoryPath();
    if (path == null) return;

    settingsNotifier.setLocalMusicFolder(path);
    settingsNotifier.setMusicSource(MusicSource.local);
    await localLibraryNotifier.scan([path]);
  }
}

class _RemoveDownloadsButton extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextButton(
        onPressed: () => _confirm(context),
        child: const Text('Remove All Downloads', style: TextStyle(color: AppColors.red, fontSize: 15, fontWeight: FontWeight.w500)),
      ),
    );
  }

  void _confirm(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remove All Downloads'),
        content: const Text('This will delete all downloaded music. This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Remove', style: TextStyle(color: AppColors.red)),
          ),
        ],
      ),
    );
  }
}
