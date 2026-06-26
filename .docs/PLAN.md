# My Music — Development Plan

**App:** My Music (com.mymusic.app)  
**Stack:** Flutter/Dart, Riverpod, go_router, just_audio  
**Philosophy:** Black/white/grey, minimalist, private, no login, no ads, no tracking

---

## Phase 1 — Local Music Player

### 1A. UI Review & Polish (current)
Get feedback on the running UI before wiring anything.

- [ ] Review Library page — layout, chips, tabs, list rows
- [ ] Review Queue / Now Playing — controls, progress, layout
- [ ] Review Search — field, chips, history, results
- [ ] Review Settings — all toggles and dropdowns
- [ ] Review detail pages — Album, Artist, Playlist
- [ ] Review context menus (long-press / ⋮)
- [ ] Fix any layout, spacing, or design issues

### 1B. Navigation Wiring
Connect all taps to actual routes.

- [ ] Library → Album detail (`context.push('/library/album/:id')`)
- [ ] Library → Artist detail (`context.push('/library/artist/:id')`)
- [ ] Library → Playlist detail (`context.push('/library/playlist/:id')`)
- [ ] Search results → same drill-in routes
- [ ] Context menu "View Album" / "View Artist" → navigate
- [ ] Back buttons on detail pages

### 1C. Action Wiring
Connect context menu callbacks and list row buttons to providers.

- [ ] Download button → `libraryProvider.toggleSongDownload(id)` (1500ms sim already built)
- [ ] Library toggle → `libraryProvider.toggleLibrary(id)`
- [ ] Add to Queue → `playbackProvider.addToQueue(song)`
- [ ] Remove from Queue → `playbackProvider.removeFromQueue(id)`
- [ ] Play song → `playbackProvider.playSong(song)`
- [ ] Create/Edit/Delete playlist → `libraryProvider` methods
- [ ] Add to Playlist → `libraryProvider.addSongToPlaylist(playlistId, songId)`

### 1D. Audio Playback
Wire just_audio for actual sound.

- [ ] Add a few mp3 files to `assets/audio/`
- [ ] Update `MockMusicRepository.getStreamUrl()` to return asset paths
- [ ] Write `lib/data/audio_service.dart` — wraps `just_audio` AudioPlayer
- [ ] Connect `playbackProvider` to `AudioService`:
  - `playSong()` → `audioService.play(url)`
  - `playPause()` → `audioService.pause()` / `audioService.resume()`
  - `skipNext()` / `skipPrevious()` → advance queue + play
  - Position stream → update `playbackProvider.position`
- [ ] Progress bar in Now Playing becomes live
- [ ] Elapsed/remaining time becomes live

### 1E. Settings Polish
- [ ] Apply `defaultOpenPage` on cold launch (set initial GoRouter location)
- [ ] Apply `defaultLibraryTab` on Library page init
- [ ] Apply `defaultSearchSource` on Search page init
- [ ] `autoOpenQueue`: switch to Queue tab when song starts playing

### 1F. Release APK
- [ ] Update `android/app/src/main/AndroidManifest.xml`: label="My Music"
- [ ] Confirm `android/app/build.gradle`: applicationId = "com.mymusic.app"
- [ ] `flutter build apk --release`
- [ ] Push APK to GitHub Releases for sideloading

---

## Phase 2 — YouTube Music Integration

The data layer is designed for this — one swap in `main.dart`.

### 2A. Repository Swap
- [ ] Write `lib/data/innertube_service.dart` — HTTP calls to innertube API via dio
- [ ] Write `lib/data/youtube_music_repository.dart` implementing `MusicRepository`
- [ ] `getStreamUrl(songId)` returns innertube adaptive audio stream URL
- [ ] Change `ProviderScope` override in `main.dart` to use `YouTubeMusicRepository`

### 2B. Search Goes Live
- [ ] `SearchNotifier.search()` already calls `musicRepository.search()` async — no UI changes needed
- [ ] `YouTubeMusicRepository.search()` calls innertube search endpoint
- [ ] Results populate same `SongRow`/`AlbumRow`/`ArtistRow` widgets

### 2C. Library Sync
- [ ] Account login (the Login stub in Library header account icon)
- [ ] Sync liked songs / saved albums from YouTube Music account
- [ ] `inLibrary` state backed by real account data

### 2D. FOSS Integration Options
These are all open-source projects that wrap the innertube API:
- **InnerTube** — direct API (no client lib needed, just dio)
- **Metrolist** — reference for Android innertube patterns
- **Harmony Music** — reference for stream URL extraction

---

## Design Rules (do not change without discussion)

- Colors: black (#000), white (#FFF), greys (#1A1A1A, #222, #333, #404040, #666, #888). Red (#FF3B30) for destructive only.
- No gradients, no accent colors, no animations beyond functional ones
- Bottom nav: Library | Queue | Search | Settings (fixed 4 tabs)
- Content tabs (Songs/Albums/Artists/Playlists): configurable per user in Settings
- Context menus: always bottom sheet, alphabetical items, destructive in red
- No mini-player bar — Queue tab is the Now Playing screen

---

## Commands

```bash
# Run in browser (dev)
cd /Users/michaelhayes/Documents/Code/mymusic/flutter
flutter run -d web-server --web-port=9090
# Open http://localhost:9090

# Hot reload (while running)
# Press 'r' in the terminal

# Analyze for errors
flutter analyze

# Build Android APK
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```
