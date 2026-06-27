# My Music — YouTube Music & Local Library Plan

## Overview

The app has a complete UI shell and Riverpod state layer but no actual audio playback. This document covers the full plan for wiring real audio: first local files, then local folder library, then YouTube Music streaming.

**Order of implementation:**
1. **Phase 1D** — Wire `just_audio` to asset MP3s, hear sound ✅ DONE
2. **Phase 1E** — Local folder library: user picks a folder, app scans ID3 tags, library populates
3. **Phase 2** — YouTube Music streaming via `youtube_explode_dart` (anonymous, no login)

---

## Key Decisions

- **No login, ever** — anonymous streaming only, no YouTube account sync
- **`youtube_explode_dart` v3.1.0** (actively maintained, May 2026) is the extraction layer for Phase 2 — same library Harmony used, but called directly since Harmony the app is deprecated
- **Local files first** — gives a fully working offline player before introducing network dependencies
- **ID3 tags** are the source of truth for metadata (`metadata_god` package, cross-platform ID3v2.4)
- **No SQLite** — scanned library is cached as a JSON file in app support directory; simple, human-readable, deletable to reset
- **`file_picker`** for folder selection on Android/macOS/desktop

---

## Biggest Challenges

### Local library
- **Permissions** — Android requires `READ_MEDIA_AUDIO` (API 33+). Need `permission_handler` package.
- **Scan time** — large libraries can have thousands of files. Scan must be async with a progress state indicator. Run in an isolate if it blocks the UI.
- **Missing tags** — many MP3s have incomplete ID3 tags. Fallback chain: filename → title, parent folder → album, grandparent folder → artist.
- **Album art** — embedded art (Uint8List from `metadata_god`) must be displayed lazily to avoid loading all art into memory at once.
- **Duplicates** — re-scanning the same folder must not duplicate entries. IDs are MD5 hash of `filePath` — stable across rescans.

### YouTube Music (Phase 2)
- **Breakage risk** — `youtube_explode_dart` calls reverse-engineered YouTube internals. YouTube changes these periodically. Mitigate by keeping the package updated and abstracting stream URL resolution behind `getStreamUrl()`.
- **Throttling** — `n` parameter deobfuscation is handled by the library but has broken before. No mitigation except keeping the package current.
- **No Harmony code to copy** — Harmony is a deprecated app. Use `youtube_explode_dart` directly via its current pub.dev API.

---

## Phase 1D — Wire just_audio to Asset MP3s ✅ DONE

**Goal:** Drop a few MP3s into `assets/audio/`, wire `just_audio`, hear sound.

### New file: `lib/data/audio_service.dart`

```dart
class AudioService {
  final AudioPlayer _player = AudioPlayer();

  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;

  Future<void> play(String url) async {
    await _player.setUrl(url);  // works for asset://, file://, and https://
    await _player.play();
  }

  Future<void> pause() => _player.pause();
  Future<void> resume() => _player.play();
  Future<void> seek(Duration position) => _player.seek(position);
  Future<void> setVolume(double v) => _player.setVolume(v);
  void dispose() => _player.dispose();
}
```

### `Song` model — add `filePath` field

```dart
final String? filePath;  // null = no local file; asset:// or file:// path when available
```

`copyWith` updated to include `filePath`.

### Wire `PlaybackNotifier` to `AudioService`

- `playSong()` → `audioService.play(song.filePath)`
- `playPause()` → `audioService.pause()` / `audioService.resume()`
- `skipNext()` / `skipPrevious()` → `audioService.play()` on the new song
- `audioService.positionStream` → drives `playbackProvider.setPosition()`
- `audioService.durationStream` → drives `playbackProvider` duration state

### `MockMusicRepository.getStreamUrl()`

Return `'asset:///assets/audio/<filename>.mp3'` for songs with a matching asset file. Return null for others — UI should grey out the play button when filePath is null.

### Auto-navigate to Queue on song tap

Controlled by the existing `AppSettings.autoOpenQueue` setting (already in the model and Settings UI). When true, tapping a song in the library calls `context.go('/queue')` after `playSong()`. Default is off so users keep their place. Setting label: "Auto Open Queue — Switch to Queue tab when a song starts".

---

## Phase 1E — Local Folder Library

**Goal:** User adds a folder in Settings → app scans it → library populates with real music organized by Artist/Album from ID3 tags.

### New packages

Add to `pubspec.yaml`:
- `metadata_god: ^1.1.0` — ID3v2.4 tags, cross-platform
- `file_picker: ^11.0.2` — native folder picker dialog
- `permission_handler: ^11.0.0` — Android storage permissions
- `path_provider: ^2.1.0` — `getApplicationSupportDirectory()` for JSON cache

### Settings changes

Add to `AppSettings` (`lib/models/settings.dart`):
```dart
final List<String> localMusicFolders;
```

Add to `SettingsRepository` (`lib/data/settings_repository.dart`): persist `localMusicFolders` as a JSON-encoded list in SharedPreferences.

Add to Settings UI (`lib/pages/settings_page.dart`) — new "Local Library" section:
- **Add Music Folder** button → `FilePicker.platform.getDirectoryPath()` → appends path
- List of configured folders with red × remove button
- **Rescan Library** button → triggers re-scan and cache refresh

### New file: `lib/data/local_music_scanner.dart`

```dart
class LocalMusicScanner {
  static const _audioExtensions = {'.mp3', '.flac', '.m4a', '.aac', '.wav', '.ogg'};

  Future<List<Song>> scan(List<String> folderPaths) async {
    // For each folder: list files recursively
    // Filter by extension
    // For each file: MetadataGod.readMetadata(path)
    // Build Song from tags with fallbacks (see below)
    // Return flat Song list
  }
}
```

**Folder structure:** Accept any layout — flat or nested Artist/Album/Track. ID3 tags always win. Fallback chain for missing/empty tags:
1. `title` → filename without extension
2. `artist` → grandparent folder name (or "Unknown Artist")
3. `album` → parent folder name (or "Unknown Album")
4. `year` → null (omit from display)
5. `albumArt` → null (grey `ArtThumbnail` placeholder — already handled by the existing widget)

### Library cache — JSON file (no SQLite)

After scanning, serialize the song list to a JSON file:
- **Path:** `getApplicationSupportDirectory()/local_library_cache.json`
- **On launch:** read cache → populate library instantly, no scan delay
- **Cache invalidation:** user taps "Rescan Library", or app detects folder mtime changed
- **First launch / cache miss:** run scan, write cache, populate library

Human-readable, no schema, deletable to reset state.

### New provider: `lib/providers/local_library_provider.dart`

```dart
// State: { isScanning: bool, songs: List<Song>, error: String? }
// On init: read JSON cache; if no cache and localMusicFolders non-empty, run scan
// Exposes: allSongs, songsByAlbum(albumId), songsByArtist(artistId)
```

Song IDs: MD5 hash of `filePath` — stable across rescans, no collisions.

### How albums and artists are organized

Derived at query time from the flat song list — no separate tables needed:

```dart
// Albums: group songs by (artistName + albumName), use first song's metadata
// Artists: group songs by artistName
```

### New file: `lib/data/local_music_repository.dart`

Implements `MusicRepository`. Backed by `localLibraryProvider` song list.
- `getAllSongs()` → all scanned songs, sorted by title
- `getAllAlbums()` → derived album list
- `getAllArtists()` → derived artist list
- `getStreamUrl(songId)` → `'file://${song.filePath}'`
- `search(query)` → substring match across title/artist/album

### Repository switching in `main.dart`

```dart
final repositoryProvider = Provider<MusicRepository>((ref) {
  final settings = ref.watch(settingsProvider);
  if (settings.localMusicFolders.isNotEmpty) {
    return LocalMusicRepository(ref.watch(localLibraryProvider));
  }
  return MockMusicRepository();
});
```

Mock data remains the default until the user adds a folder.

---

## Phase 2 — YouTube Music Streaming

**After Phase 1 is fully working.**

### New packages

```yaml
youtube_explode_dart: ^3.1.0
```

Handles cipher deobfuscation, `n` parameter throttling, and format selection automatically.

### New files

- `lib/data/youtube_explode_service.dart` — singleton `YoutubeExplode()` instance, lifecycle management
- `lib/data/youtube_music_repository.dart` — implements `MusicRepository`

### Key API usage

```dart
// Search
final yt = YoutubeExplode();
final results = await yt.search.search(query);
// For YouTube Music specifically:
// final results = await yt.music.search(query);

// Stream URL — pass directly to just_audio
final manifest = await yt.videos.streams.getManifest(videoId);
final audio = manifest.audioOnly.withHighestBitrate();
return audio.url.toString();  // Google CDN URL — no ads, no YouTube player
```

The CDN URL goes straight into `audioService.play()` — `just_audio` streams it directly. No YouTube player, no ad system, no Google Play Services required.

### Source toggle in Settings

Add to `AppSettings`:
```dart
enum MusicSource { local, youtubeMusic }
final MusicSource musicSource;
```

`repositoryProvider` selects implementation based on this setting. Settings UI gets a "Music Source" toggle.

**No login. No account sync. No cookies. Anonymous streaming only.**

---

## How YouTube streaming avoids ads

These apps don't block ads — they never request the ad system at all.

**Official YouTube flow:**
YouTube App → Google APIs → Player API → Ad decision service → CDN stream

**This app's flow:**
`youtube_explode_dart` → `youtubei/v1/player` endpoint → extract `adaptiveFormats` audio URL → `just_audio` → Google CDN bytes

The app requests the media stream directly, bypassing the player and ad system entirely.

---

## Files to create / modify

| File | Change |
|------|--------|
| `pubspec.yaml` | Add `metadata_god`, `file_picker`, `permission_handler`, `path_provider` |
| `lib/models/song.dart` | Add `filePath` field |
| `lib/models/settings.dart` | Add `localMusicFolders`, `MusicSource` enum |
| `lib/data/audio_service.dart` | New — wraps `just_audio` |
| `lib/data/local_music_scanner.dart` | New — folder scan + ID3 extraction |
| `lib/data/local_music_repository.dart` | New — implements `MusicRepository` |
| `lib/providers/playback_provider.dart` | Wire to `AudioService` |
| `lib/providers/local_library_provider.dart` | New — scan state + JSON cache |
| `lib/data/settings_repository.dart` | Persist `localMusicFolders` |
| `lib/pages/settings_page.dart` | Add Local Library section + Music Source toggle |
| `lib/main.dart` | Add `repositoryProvider` switcher |
| `assets/audio/` | Drop 2-3 MP3s for Phase 1D testing |
| `android/app/src/main/AndroidManifest.xml` | Add `READ_MEDIA_AUDIO` permission |

---

## Verification

1. **Asset playback:** Drop an MP3 in `assets/audio/`, tap a mock song → audio plays, progress bar moves live
2. **Local folder (Android/macOS):** Settings → Add Music Folder → pick folder with MP3s → Library shows real tracks → tap one → plays
3. **ID3 fallback:** MP3 with no tags → appears with filename as title, folder as album
4. **Re-scan:** Tap Rescan → library refreshes without duplicates
5. **Web mode:** `flutter run -d web-server` → mock library still works; Local Library section in Settings shows "not supported on web"
6. **`flutter analyze`** — zero errors before any push
