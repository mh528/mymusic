# My Music — Flutter App Status

**Last Updated:** 2026-06-27  
**Dev Server:** `flutter run -d web-server --web-port=9090` → http://localhost:9090  
**Build APK:** `flutter build apk --release`

---

## Current State: Phase 1E Complete — Local Library Wired, Ready for APK Test

Phase 1D (asset audio playback) and Phase 1E (local folder library) are both complete. The app now scans a real music folder, reads ID3 tags, builds a live library, and plays back local files. Mock data is still the default. An APK build + on-device test is the appropriate next step before continuing.

---

## What's Done ✅

### Foundation
- Flutter project scaffolded at `/Users/michaelhayes/Documents/Code/mymusic/flutter/`
- Package: `com.mymusic.app` | App name: My Music
- Theme: black/white/grey only, red for destructive — `lib/theme.dart`
- Dependencies: go_router, flutter_riverpod, just_audio, shared_preferences, dio, metadata_god, file_picker, permission_handler, path_provider, crypto

### Design Tokens
- `AppColors` — all color tokens in `lib/theme.dart`
- `AppTextStyles` — semantic typography tokens
- `FilterChipsRow` and `ContentTabBar` both pull from `AppTextStyles`

### Shared Button Components (`lib/components/buttons.dart`)
- `AppIconButton`, `AppButtonBar`, `AppGhostButton`

### Data Layer
- All models: `Song` (with `filePath`, `albumArtBytes`), `Album`, `Artist`, `Playlist`, `LivePerformance`, `Video`, `AppSettings` (with `localMusicFolder`, `musicSource`)
- Mock data: 3 artists, 3 albums, 12 songs, 2 playlists — `lib/data/mock_data.dart`
- Abstract `MusicRepository` interface — Phase 2 swap point
- `MockMusicRepository` — returns mock data
- `LocalMusicRepository` — implements `MusicRepository` from scanned song list; derives Albums/Artists at query time
- `SettingsRepository` — reads/writes SharedPreferences (incl. `localMusicFolder`, `musicSource`)

### Audio Playback (Phase 1D ✅)
- `AudioService` — wraps `just_audio`, handles asset://, file://, and https:// URLs
- `PlaybackNotifier` wired to `AudioService` — play, pause, skip next/prev, seek, volume
- Position and duration streams drive live progress bar in Queue page
- One MP3 asset in `assets/audio/` for testing

### Local Folder Library (Phase 1E ✅)
- `LocalMusicScanner` — async folder scan, ID3 tag reading via `metadata_god`, fallback chain (filename/folder for missing tags), stable MD5 song IDs
- `LocalMusicRepository` — `MusicRepository` implementation backed by scanned song list
- `localLibraryProvider` — scan state (isScanning, progress count, error), JSON cache at app support directory
- `musicRepositoryProvider` in `library_provider.dart` — switches to `LocalMusicRepository` when `musicSource == MusicSource.local` and a folder is configured; otherwise falls back to mock
- Settings → Local Library section: folder picker, scan progress indicator, song count, Rescan button, Music Source dropdown

### State Providers (Riverpod)
- `settingsProvider` — all app settings with live updates (incl. `setMusicSource`, `setLocalMusicFolder`)
- `libraryProvider` — songs/albums/artists/playlists, download state (1500ms sim)
- `playbackProvider` — current song, queue, isPlaying, repeat mode, volume, live position/duration
- `searchProvider` — query, results, history (max 10)
- `localLibraryProvider` — scan state + JSON cache

### Pages (all exist, partially wired)
- `LibraryPage` — filter chips, content tabs, search, list rows
- `QueuePage` — Up Next reorderable list, Now Playing, live progress bar, controls
- `SearchPage` — search field, filter chips, result tabs, history
- `SettingsPage` — all toggles/dropdowns + Local Library section
- `AlbumPage`, `ArtistPage`, `PlaylistPage` — detail pages

### Components
- `ArtThumbnail`, `DownloadButton`, `FilterChipsRow`, `ContentTabBar`
- All list rows: `SongRow`, `AlbumRow`, `ArtistRow`, `PlaylistRow`, `QueueItemRow`, `LivePerformanceRow`, `VideoRow`
- All 6 context menus wired
- Lyrics drawer, Create/Edit/AddToPlaylist dialogs

### Navigation
- GoRouter with `StatefulShellRoute.indexedStack` — 4 tabs preserve back stack
- Sub-routes: `/library/album/:id`, `/library/artist/:id`, `/library/playlist/:id`
- Album/Artist/Playlist drill-in from Library taps wired

### Android
- `READ_MEDIA_AUDIO` + `READ_EXTERNAL_STORAGE` (≤ API 32) permissions in AndroidManifest.xml

---

## What's Pending 🔴

### On-Device Testing (do this before continuing)
- Build APK and install on Android device
- Test: mock data plays (asset MP3)
- Test: Settings → pick a music folder → scan runs → library shows real tracks → tap a song → plays
- Test: Rescan doesn't duplicate entries
- Test: folder picker permission request on Android 13+

### Navigation Wiring
- Search results → drill-in routes not connected
- Context menu "View Album" / "View Artist" → push route
- Back buttons on detail pages (deep-link entry has no back)

### Context Menu Wiring (detail pages)
- Album/Artist/Playlist page header ⋮ callbacks are stubs
- SongRow ⋮ on ArtistPage and AlbumPage not wired

### Local Library — On-Device Gaps
- `localLibraryProvider` loads cache on scan but doesn't auto-load cache on cold launch (needs to be triggered from app init when a folder is configured)
- Album art (`albumArtBytes`) stored in Song but not yet displayed in `ArtThumbnail` — grey placeholder still used

### Settings Polish
- `defaultOpenPage` not applied on cold launch
- `defaultLibraryTab` not applied on Library page init
- `autoOpenQueue` not implemented

### Phase 2
- YouTube Music streaming via `youtube_explode_dart`

---

## Known Issues 🟡

- `RepeatMode` name conflict with Flutter's internal `RepeatMode` — resolved with import alias in queue_page
- `metadata_god` does not support Swift Package Manager (uses CocoaPods) — warning at build time, non-fatal
- `just_audio` not supported on web (audio plays on Android/iOS/macOS only)
- Local library folder picker and scan not available on web — mock data remains active

---

## File Structure

```
lib/
├── main.dart                    # Entry point — MetadataGod.initialize() + ProviderScope
├── app.dart                     # GoRouter + AppShell + NavigationBar
├── theme.dart                   # AppColors, AppTextStyles, appTheme
├── models/                      # Song, Album, Artist, Playlist, AppSettings, etc.
├── data/
│   ├── music_repository.dart    # Abstract interface
│   ├── mock_music_repository.dart
│   ├── mock_data.dart
│   ├── local_music_scanner.dart  # ID3 scan + fallback chain
│   ├── local_music_repository.dart # MusicRepository from scanned songs
│   ├── audio_service.dart        # just_audio wrapper
│   └── settings_repository.dart
├── providers/
│   ├── library_provider.dart    # musicRepositoryProvider (switches mock ↔ local)
│   ├── local_library_provider.dart # scan state + JSON cache
│   ├── playback_provider.dart
│   ├── search_provider.dart
│   └── settings_provider.dart
├── pages/
│   ├── library_page.dart
│   ├── queue_page.dart
│   ├── search_page.dart
│   ├── settings_page.dart       # Includes Local Library section
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
