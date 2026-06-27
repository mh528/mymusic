# My Music — YouTube Music & Local Library Plan

## Overview

The app has a complete UI shell and Riverpod state layer. Audio playback is wired for both asset files and local folder libraries.

**Order of implementation:**
1. **Phase 1D** — Wire `just_audio` to asset MP3s, hear sound ✅ DONE
2. **Phase 1E** — Local folder library: user picks a folder, app scans ID3 tags, library populates ✅ DONE (+ bug-fixed 2026-06-27)
3. **Phase 2** — YouTube Music streaming via `youtube_explode_dart` (anonymous, no login)

---

## Key Decisions

- **No login, ever** — anonymous streaming only, no YouTube account sync
- **`youtube_explode_dart` v3.1.0** (actively maintained, May 2026) is the extraction layer for Phase 2
- **Local files first** — gives a fully working offline player before introducing network dependencies
- **ID3 tags via inline Dart parser** — pure-Dart ID3v2 parser inline in `local_music_scanner.dart` (replaced `metadata_god` which required Rust/Swift Package Manager)
- **No SQLite** — scanned library is cached as a JSON file in app support directory
- **`file_picker`** for folder selection on Android/macOS/desktop

---

## Phase 1D — Wire just_audio to Asset MP3s ✅ DONE

Asset MP3 in `assets/audio/`, `just_audio` wired via `AudioService`, playback provider driving live progress bar.

---

## Phase 1E — Local Folder Library ✅ DONE

User picks a folder in Settings → app scans for MP3/FLAC/M4A/AAC/WAV/OGG → reads ID3v2 tags → builds library → JSON cache for cold-launch restore.

### What's actually implemented (differs from original plan)

- `metadata_god` was dropped — replaced with ~100-line pure-Dart ID3v2 parser inline in `local_music_scanner.dart`
- Single folder (not list) — `AppSettings.localMusicFolder` (string, not list)
- `MusicSource` enum (`mock` | `local`) — explicit toggle in Settings rather than auto-detecting from folder presence
- `musicRepositoryProvider` in `library_provider.dart` — uses `ref.watch` so library rebuilds on scan completion
- Cold-launch cache restore via `initFromSettings()` called from `AppShell` in `app.dart`
- Android: `MANAGE_EXTERNAL_STORAGE` permission required for `dart:io` to read arbitrary folder paths

### Bug fixes applied 2026-06-27

| Bug | Fix |
|-----|-----|
| Library never refreshed after scan | `LibraryNotifier.build()` used `ref.read` — changed to `ref.watch` |
| Local files silent / error | Scanner stored `file://$path`; `just_audio` needs raw path via `setFilePath()` |
| Library wiped on every settings save | `localLibraryProvider.build()` watched settings and reset state; replaced with `initFromSettings()` + `_cacheLoaded` flag |
| Cache never loaded on cold launch | `initFromSettings` was Settings-page-only; moved to `AppShell` |
| Wrong Android permission | `Permission.audio` → `Permission.manageExternalStorage` + manifest entry |

### Remaining Phase 1E gaps

- Album art (`albumArtBytes`) read into Song but not displayed — `ArtThumbnail` shows grey placeholder
- `autoOpenQueue` setting wired in model/Settings UI but not implemented in playback
- `defaultLibraryTab` not applied on Library page init

---

## Phase 2 — YouTube Music Streaming

**Prerequisites:** Phase 1E on-device test passes (local files play correctly).

### Goal

Search YouTube Music anonymously, get a CDN audio stream URL, pass it to `just_audio`. No login, no account, no Google Play Services.

### Package

```yaml
youtube_explode_dart: ^3.1.0
```

Handles cipher deobfuscation, `n` parameter throttling, and format selection. Check pub.dev for latest version before adding.

### New files to create

**`lib/data/youtube_music_service.dart`**

Singleton wrapper around `YoutubeExplode`. Manages lifecycle (close on dispose).

```dart
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class YouTubeMusicService {
  final _yt = YoutubeExplode();

  Future<List<Song>> search(String query) async {
    final results = await _yt.search.search(query);
    return results.map(_videoToSong).toList();
  }

  Future<String?> getStreamUrl(String videoId) async {
    final manifest = await _yt.videos.streams.getManifest(videoId);
    final audio = manifest.audioOnly.withHighestBitrate();
    return audio.url.toString();
  }

  Song _videoToSong(Video v) => Song(
    id: v.id.value,
    title: v.title,
    artist: v.author,
    artistId: v.channelId.value,
    album: '',
    albumId: '',
    duration: v.duration ?? const Duration(minutes: 3, seconds: 30),
    filePath: null, // resolved lazily via getStreamUrl()
  );

  void dispose() => _yt.close();
}
```

**`lib/data/youtube_music_repository.dart`**

Implements `MusicRepository`. Stream URLs are resolved on-demand in `getStreamUrl()` — not stored on the Song, since CDN URLs expire.

```dart
class YouTubeMusicRepository implements MusicRepository {
  final YouTubeMusicService _svc;
  YouTubeMusicRepository(this._svc);

  @override
  Future<String?> getStreamUrl(String songId) => _svc.getStreamUrl(songId);

  @override
  Future<SearchResults> search(String query) async {
    final songs = await _svc.search(query);
    return SearchResults(songs: songs, albums: [], artists: []);
  }

  // getAllSongs / getAllAlbums etc. return [] — YT library is search-driven, not browsable
  @override Future<List<Song>> getAllSongs() async => [];
  @override Future<List<Album>> getAllAlbums() async => [];
  @override Future<List<Artist>> getAllArtists() async => [];
  // ... other stubs
}
```

### Settings change

`MusicSource` enum already has `mock` and `local`. Add `youtube`:

```dart
// lib/models/settings.dart
enum MusicSource { mock, local, youtube }
```

Update `SettingsRepository` (the int index serialization handles new values automatically via `.clamp()`).

Update Settings UI dropdown label:

```dart
label: (s) => switch (s) {
  MusicSource.mock => 'Mock Data',
  MusicSource.local => 'Local Files',
  MusicSource.youtube => 'YouTube Music',
}
```

### Repository switcher update

In `lib/providers/library_provider.dart`, extend `musicRepositoryProvider`:

```dart
final musicRepositoryProvider = Provider<MusicRepository>((ref) {
  final settings = ref.watch(settingsProvider).valueOrNull;
  switch (settings?.musicSource) {
    case MusicSource.local:
      if (settings?.localMusicFolder != null) {
        final songs = ref.watch(localLibraryProvider).songs;
        return LocalMusicRepository(songs);
      }
    case MusicSource.youtube:
      final svc = ref.watch(youtubeMusicServiceProvider);
      return YouTubeMusicRepository(svc);
    default:
      break;
  }
  return MockMusicRepository();
});

final youtubeMusicServiceProvider = Provider((ref) {
  final svc = YouTubeMusicService();
  ref.onDispose(svc.dispose);
  return svc;
});
```

### Playback change for YouTube songs

`PlaybackNotifier.playSong()` currently calls `audioService.play(song.filePath)`. For YouTube songs, `filePath` is null — stream URL must be fetched first:

```dart
Future<void> playSong(Song song) async {
  String? url = song.filePath;
  if (url == null) {
    url = await ref.read(musicRepositoryProvider).getStreamUrl(song.id);
  }
  if (url == null) return; // unplayable
  await _audioService.play(url);
  // update state...
}
```

`AudioService.play()` already handles `https://` URLs via `setUrl()` — no changes needed there.

### Search wiring

`SearchNotifier` currently calls `repo.search(query)`. This already works — `YouTubeMusicRepository.search()` returns real results. The Search page UI is already built.

### Implementation order for Phase 2

1. Add `youtube_explode_dart` to `pubspec.yaml`, run `flutter pub get`
2. Create `youtube_music_service.dart`
3. Create `youtube_music_repository.dart` 
4. Add `MusicSource.youtube` to enum + update Settings label
5. Add `youtubeMusicServiceProvider` + extend `musicRepositoryProvider` switch
6. Update `PlaybackNotifier.playSong()` to fetch stream URL when `filePath == null`
7. Test: Settings → Music Source → YouTube Music → Search → tap result → plays

---

## Biggest Challenges

### Phase 2 risks

- **Breakage** — `youtube_explode_dart` calls reverse-engineered YouTube internals. Keep the package updated. Breakage is detected quickly (search stops returning results or streams 403).
- **CDN URL expiry** — stream URLs expire in ~6 hours. Never cache them; always call `getStreamUrl()` at play time.
- **Throttling** — `n` parameter deobfuscation is handled by the library. No mitigation except keeping the package current.
- **Rate limits** — anonymous requests are throttled more aggressively than logged-in ones. No mitigation; just keep searches reasonable.

---

## How YouTube streaming avoids ads

These apps don't block ads — they never request the ad system at all.

**Official YouTube flow:**
YouTube App → Google APIs → Player API → Ad decision service → CDN stream

**This app's flow:**
`youtube_explode_dart` → `youtubei/v1/player` endpoint → extract `adaptiveFormats` audio URL → `just_audio` → Google CDN bytes

The app requests the media stream directly, bypassing the player and ad system entirely.

---

## Verification checklist

### Phase 1E (local files)
1. Settings → Choose folder → pick a folder with MP3s → scan shows count
2. Library tab → shows scanned songs (not mock data)
3. Tap a song → plays audio
4. Kill + reopen app → library reloads from cache (no rescan)
5. Rescan → no duplicates

### Phase 2 (YouTube Music)
1. Settings → Music Source → YouTube Music
2. Search tab → type an artist name → results appear
3. Tap a result → audio starts playing within ~2s (stream URL fetch)
4. Progress bar advances, skip works
5. Switch back to Local Files → local library reappears
