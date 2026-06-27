# My Music — Flutter App Status

**Last Updated:** 2026-06-27  
**Dev Server:** `flutter run -d web-server --web-port=9090` → http://localhost:9090  
**Build APK:** `flutter build apk --release`  
**Release APK:** `flutter build apk --release --target-platform android-arm64`

---

## Current State: Phase 1E Bug-Fixed — Ready for On-Device Test

Phase 1D (asset playback) and Phase 1E (local folder library) are complete. A batch of bugs found during post-release audit have been fixed. The app should now correctly show scanned songs in the library and play them. APK rebuild + on-device test is the next step.

---

## What's Done ✅

### Foundation
- Flutter project scaffolded at `/Users/michaelhayes/Documents/Code/mymusic/flutter/`
- Package: `com.mymusic.app` | App name: My Music
- Theme: black/white/grey only, red for destructive — `lib/theme.dart`
- Dependencies: go_router, flutter_riverpod, just_audio, shared_preferences, file_picker, permission_handler, path_provider, crypto

### Data Layer
- All models: `Song` (with `filePath`, `albumArtBytes`), `Album`, `Artist`, `Playlist`, `LivePerformance`, `Video`, `AppSettings` (with `localMusicFolder`, `musicSource`)
- Mock data: 3 artists, 3 albums, 12 songs, 2 playlists — `lib/data/mock_data.dart`
- Abstract `MusicRepository` interface
- `MockMusicRepository` — returns mock data
- `LocalMusicRepository` — implements `MusicRepository` from scanned song list; derives Albums/Artists at query time
- `SettingsRepository` — reads/writes SharedPreferences

### Audio Playback (Phase 1D ✅)
- `AudioService` at `lib/data/audio_service.dart` — wraps `just_audio`
  - Uses `setFilePath()` for local paths (`/...`), `setUrl()` for remote/asset URLs
- `PlaybackNotifier` wired to `AudioService` — play, pause, skip next/prev, seek, volume
- Position and duration streams drive live progress bar in Queue page

### Local Folder Library (Phase 1E ✅)
- `LocalMusicScanner` — async folder scan, pure-Dart inline ID3v2 parser, fallback chain (filename/folder for missing tags), stable MD5 song IDs
- `LocalMusicRepository` — `MusicRepository` implementation backed by scanned song list
- `localLibraryProvider` — scan state (isScanning, progress count, error), JSON cache at app support directory
- `musicRepositoryProvider` in `library_provider.dart` — uses `ref.watch` (not `ref.read`) so it rebuilds when songs update or source changes
- Cold-launch cache restore wired in `AppShell` (`app.dart`) via `ref.listen(settingsProvider)` → `initFromSettings()`
- Settings → Local Library section: folder picker, scan progress indicator, song count, Rescan button, Music Source dropdown

### Bug Fixes Applied (2026-06-27)
- **Library never refreshed** — `LibraryNotifier.build()` used `ref.read` instead of `ref.watch` for `musicRepositoryProvider`
- **Playback failed on local files** — scanner stored `file://$path`; `just_audio` requires raw path via `setFilePath()`. Fixed in scanner + `AudioService`
- **Library wiped on every settings save** — `localLibraryProvider.build()` watched `settingsProvider` and reset state to empty on every rebuild. Replaced with `initFromSettings()` + `_cacheLoaded` flag
- **Cold-launch cache never loaded** — `initFromSettings` was only called from Settings page. Moved to `AppShell` so it runs on every launch
- **Android permission wrong** — changed `Permission.audio` → `Permission.manageExternalStorage`; added `MANAGE_EXTERNAL_STORAGE` to `AndroidManifest.xml`

### Pages & Navigation
- All 4 pages: Library, Queue, Search, Settings
- Detail pages: Album, Artist, Playlist
- GoRouter with `StatefulShellRoute.indexedStack` — 4 tabs preserve back stack
- Album/Artist/Playlist drill-in from Library wired

### Android
- `READ_MEDIA_AUDIO` + `READ_EXTERNAL_STORAGE` (≤ API 32) + `MANAGE_EXTERNAL_STORAGE` in AndroidManifest.xml

---

## What's Pending 🔴

### On-Device Test (do this first)
- Rebuild APK with bug fixes and install
- Test: Settings → pick a music folder → scan runs → library shows real tracks
- Test: tap a song → plays audio (not silence)
- Test: kill app, reopen → library reloads from cache without rescanning
- Test: Rescan → no duplicates

### UI Polish
- Album art (`albumArtBytes`) embedded in Song but `ArtThumbnail` still shows grey placeholder — wire `Image.memory(albumArtBytes)` when non-null
- `defaultLibraryTab` setting not applied on Library page init
- `autoOpenQueue` setting not implemented — tapping a song doesn't switch to Queue tab

### Navigation Wiring
- Search results → drill-in routes not connected
- Context menu "View Album" / "View Artist" on detail pages → push route
- Back buttons on detail pages (deep-link entry has no back)

### Phase 2 — YouTube Music
- See `ytmusic.md` Phase 2 section

---

## Known Issues 🟡

- `RepeatMode` name conflict with Flutter's internal `RepeatMode` — resolved with import alias in queue_page
- `just_audio` not supported on web — mock data fallback works, local library section hidden on web
- `MANAGE_EXTERNAL_STORAGE` requires user to grant "All files access" in Android settings on API 30+ — the permission dialog may redirect to system settings instead of showing inline

---

## File Structure

```
lib/
├── main.dart                    # Entry point — ProviderScope
├── app.dart                     # GoRouter + AppShell (wires cold-launch cache init)
├── theme.dart                   # AppColors, AppTextStyles, appTheme
├── models/                      # Song, Album, Artist, Playlist, AppSettings, etc.
├── data/
│   ├── music_repository.dart    # Abstract interface
│   ├── mock_music_repository.dart
│   ├── mock_data.dart
│   ├── local_music_scanner.dart  # Inline ID3v2 parser + fallback chain
│   ├── local_music_repository.dart
│   ├── audio_service.dart        # just_audio wrapper (setFilePath for local, setUrl for remote)
│   └── settings_repository.dart
├── providers/
│   ├── library_provider.dart    # musicRepositoryProvider (ref.watch — switches mock ↔ local)
│   ├── local_library_provider.dart # scan state + JSON cache + initFromSettings()
│   ├── playback_provider.dart
│   ├── search_provider.dart
│   └── settings_provider.dart
├── pages/
│   ├── library_page.dart
│   ├── queue_page.dart
│   ├── search_page.dart
│   ├── settings_page.dart
│   ├── album_page.dart
│   ├── artist_page.dart
│   └── playlist_page.dart
└── components/
    ├── buttons.dart
    ├── tabs/
    ├── list_rows/
    ├── menus/
    ├── drawers/
    ├── dialogs/
    ├── art_thumbnail.dart
    └── download_button.dart
assets/
└── audio/                       # Asset MP3s for Phase 1D testing
```
