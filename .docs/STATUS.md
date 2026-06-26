# My Music — Flutter App Status

**Last Updated:** 2026-06-26  
**Dev Server:** `flutter run -d web-server --web-port=9090` → http://localhost:9090  
**Build APK:** `flutter build apk --release`

---

## Current State: UI Shell Complete, Wiring In Progress

The full UI structure is built and running in the browser. All pages and components exist. Context menus are wired. Shared button and typography tokens are in place. Real audio playback and remaining navigation wiring are the next steps.

---

## What's Done ✅

### Foundation
- Flutter project scaffolded at `/Users/michaelhayes/Documents/Code/mymusic/flutter/`
- Package: `com.mymusic.app` | App name: My Music
- Theme: black/white/grey only, red for destructive — `lib/theme.dart`
- All dependencies installed: go_router, flutter_riverpod, just_audio, shared_preferences, dio

### Design Tokens
- `AppColors` — all color tokens in `lib/theme.dart`
- `AppTextStyles` — semantic typography tokens (pageTitle, sectionTitle, listTitle, listSubtitle, body, bodyMuted, caption, settingTitle, settingCaption, tabActive, tabInactive, chipLabel)
- `FilterChipsRow` and `ContentTabBar` both pull from `AppTextStyles` — no more inline font sizes

### Shared Button Components (`lib/components/buttons.dart`)
- `AppIconButton` — square pill with icon + optional label, standard 40dp size
- `AppButtonBar` — evenly-spaced row of `AppIconButton`s, `expanded` flag for full-width vs compact
- `AppGhostButton` — icon stacked above label for low-emphasis actions (Queue page Lyrics/Queue/More row)

### Data Layer
- All models: `Song`, `Album`, `Artist`, `Playlist`, `LivePerformance`, `Video`, `AppSettings`
- Mock data: 3 artists, 3 albums, 12 songs, 2 playlists — `lib/data/mock_data.dart`
- Abstract `MusicRepository` interface — Phase 2 swap point
- `MockMusicRepository` — returns mock data
- `SettingsRepository` — reads/writes SharedPreferences

### State Providers (Riverpod)
- `settingsProvider` — all app settings with live updates
- `libraryProvider` — songs/albums/artists/playlists, download state (1500ms sim)
- `playbackProvider` — current song, queue, isPlaying, repeat mode, volume (state only, no audio yet)
- `searchProvider` — query, results, history (max 10)

### Pages (all exist, partially wired)
- `LibraryPage` — filter chips (Library/Downloads), content tabs (Songs/Albums/Artists/Playlists), search, list rows
- `QueuePage` — Up Next reorderable list, Now Playing section, progress bar, controls, ghost buttons (Lyrics/Queue/More)
- `SearchPage` — search field, filter chips (All Music/Library/Downloads), result tabs, history
- `SettingsPage` — all toggles and dropdowns, tab visibility config, fully wired to settings provider
- `AlbumPage` — album info card, `AppButtonBar` icon row + Play/Shuffle/Queue action bar, song list
- `ArtistPage` — artist info with `AppButtonBar`, filter chips, sort, grouped/flat content, source tabs via shared `ContentTabBar`
- `PlaylistPage` — playlist info, song list

### Components
- `ArtThumbnail` — grey placeholder box (48/56/64/120dp)
- `DownloadButton` — 3-state (not downloaded / downloading / downloaded)
- `FilterChipsRow` — horizontal scrollable chips, uses `AppTextStyles.chipLabel`
- `ContentTabBar` — sticky tab bar, uses `AppTextStyles.tabActive/tabInactive`
- All list rows: `SongRow`, `AlbumRow`, `ArtistRow`, `PlaylistRow`, `QueueItemRow`, `LivePerformanceRow`, `VideoRow`
- All 6 context menus wired: Song, Queue Item, Now Playing More, Album, Artist, Playlist
- Lyrics drawer (full-screen overlay)
- Dialogs: Create Playlist, Edit Playlist, Add to Playlist

### Context Menu Wiring (Library page)
- Song ⋮ → library toggle, add to queue, download, play next, view album, view artist
- Album ⋮ → download toggle
- Artist ⋮ → library toggle
- Playlist ⋮ → delete, rename

### Navigation
- GoRouter with `StatefulShellRoute.indexedStack` — 4 tabs preserve back stack
- Sub-routes: `/library/album/:id`, `/library/artist/:id`, `/library/playlist/:id`
- Album/Artist/Playlist drill-in from Library taps wired

---

## What's Pending 🔴

### Navigation Wiring
- Search results → drill-in routes not yet connected
- Context menu "View Album" / "View Artist" navigation (callbacks exist, routes not pushed)
- Back buttons on detail pages (Navigator.pop works, but deep-link entry has no back)

### Context Menu Wiring (detail pages)
- Album/Artist/Playlist page header ⋮ button callbacks are stubs
- SongRow ⋮ on ArtistPage and AlbumPage not yet wired

### Audio Playback
- `playbackProvider` manages state but no actual audio plays
- `just_audio` is installed but not wired
- Phase 1: wire to local asset files in `assets/audio/`

### Download Simulation
- `libraryProvider.toggleSongDownload()` exists with 1500ms delay
- Download button on detail pages not yet wired

### Settings Polish
- `defaultOpenPage` not yet applied on cold launch
- `defaultLibraryTab` not applied on Library page init
- `autoOpenQueue` not implemented

---

## Known Issues 🟡

- `RepeatMode` name conflict with Flutter's internal `RepeatMode` — resolved with import alias in queue_page
- `destructive` param on some context menu items defined but not passed (warnings only, not errors)
- No local audio files in `assets/audio/` — tapping play does nothing

---

## File Structure

```
lib/
├── main.dart                    # Entry point + ProviderScope
├── app.dart                     # GoRouter + AppShell + NavigationBar
├── theme.dart                   # AppColors, AppTextStyles, appTheme
├── models/                      # Data classes (Song, Album, Artist, etc.)
├── data/                        # Repository layer + mock data + settings persistence
├── providers/                   # Riverpod state (library, playback, search, settings)
├── pages/                       # Full screens (library, queue, search, settings, album, artist, playlist)
└── components/
    ├── buttons.dart             # AppIconButton, AppButtonBar, AppGhostButton
    ├── tabs/                    # FilterChipsRow, ContentTabBar
    ├── list_rows/               # SongRow, AlbumRow, ArtistRow, etc.
    ├── menus/                   # 6 context menu bottom sheets
    ├── drawers/                 # LyricsDrawer
    ├── dialogs/                 # Create/Edit/AddToPlaylist dialogs
    ├── art_thumbnail.dart
    └── download_button.dart
assets/
└── audio/                       # Local mp3s go here for Phase 1 audio testing
```
