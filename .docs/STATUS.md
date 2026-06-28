# My Music — Flutter App Status

**Last Updated:** 2026-06-28  
**Current Release:** v1.3.3  
**Build APK:** `flutter build apk --release --target-platform android-arm64 --no-tree-shake-icons --no-shrink`  
Note: after `flutter clean`, add `--no-shrink` to avoid shader compiler OOM on 8GB RAM.

---

## Current State: black screen fixed (v1.3.3); YouTube playback fixed via ANDROID_VR client

Phase 1D (asset playback), Phase 1E (local folder library), and Phase 2 search all work.

**Startup crash (v1.2.7/v1.2.8):** the app crashed before any UI rendered because `main()`
called `JustAudioBackground.init()` without a preceding `WidgetsFlutterBinding.ensureInitialized()`,
which throws `Binding has not yet been initialized`. Fixed in v1.2.9 (commit 979124a) by
restoring the binding init before `JustAudioBackground.init()`.

**Black screen (v1.2.8–v1.3.2):** R8 code shrinking stripped `com.ryanheise.audioservice.AudioService` because it was only referenced from AndroidManifest, not traced from Dart/Java. ProGuard rules added in v1.3.1 to keep `com.ryanheise.audioservice.*`. Additionally, `JustAudioBackground.init()` was awaited in `main()` — if the AudioService binding hung, `runApp()` never fired. Fixed in v1.3.3 by wrapping init in a 5-second timeout so the UI always renders.

**Pending (v1.3.3):** `LateInitializationError: field _audioHandler has not been initialized` — inside `just_audio_background` if the user taps play before the 5s timeout elapses and init hasn't completed yet. Fix planned: await with timeout is already in place; need to guard playback calls until init resolves.

**YouTube playback ("source error 0"):** root cause was the stream-extraction client.
`getStreamUrl` now does a direct InnerTube `youtubei/v1/player` call with the **ANDROID_VR**
client (verified anonymous, returns playabilityStatus OK with unciphered, no-n-param URLs that
serve HTTP 200 / 206-on-range). `youtube_explode_dart` (androidSdkless) is kept only as a fallback.
ANDROID_MUSIC returns LOGIN_REQUIRED and IOS returns 400 anonymously — neither is usable.

---

## What's Done ✅

### Foundation
- Flutter project scaffolded at `/Users/michaelhayes/Documents/Code/mymusic/flutter/`
- Package: `com.mymusic.app` | App name: My Music
- Theme: black/white/grey only, red for destructive — `lib/theme.dart`
- Dependencies: go_router, flutter_riverpod, just_audio, shared_preferences, file_picker, permission_handler, path_provider, crypto, youtube_explode_dart ^3.1.0

### Phase 1D — Asset Playback ✅
- `AudioService` wraps `just_audio` — `setFilePath()` for local, `setUrl()` for remote
- `PlaybackNotifier` wired — play, pause, skip, seek, volume, progress bar

### Phase 1E — Local Folder Library ✅
- Pure-Dart inline ID3v2 parser in `local_music_scanner.dart`
- JSON cache at app support directory, cold-launch restore via `AppShell`
- `MANAGE_EXTERNAL_STORAGE` + `READ_MEDIA_AUDIO` permissions in AndroidManifest
- Bug fixes 2026-06-27: ref.read→ref.watch, file:// prefix, permission, cache restore

### Phase 2 — YouTube Music Search ✅
- `YouTubeMusicService` — raw InnerTube HTTP (no youtube_explode search API)
- Parser handles `musicCardShelfRenderer` + `itemSectionRenderer` (fixed 2026-06-27 — was looking for `musicShelfRenderer` which never appears)
- Artist extraction handles both `[Artist • Duration]` and `[Song • Artist • Album]` run formats
- Search returns `SearchResults` with songs, albums, artists, playlists
- Album/artist taps navigate to `AlbumPage`/`ArtistPage`
- `INTERNET` permission in AndroidManifest

### Error Visibility
- Red banner at top of queue page shows exact error when playback fails
- `PlaybackState.lastError` field surfaces errors from `_resolveUrl` and `_audio.play()`

---

## Playback Debugging Log ✅ RESOLVED

**Resolution (2026-06-28):** switched stream extraction to a direct InnerTube `player` call
with the **ANDROID_VR** client. Diagnostic evidence collected before the fix:
- The androidSdkless URL had **no `n=` param** → n-param deobfuscation theory ruled out.
- itag-140 AAC/mp4 was correctly selected → codec theory ruled out.
- `curl` of the URL from the Mac returned **HTTP 200** and **HTTP 206 on range/seek** requests
  → the CDN and range handling were fine; the URL itself was valid.
- ANDROID_VR `/player` (anonymous): playabilityStatus **OK**, 26 formats, itag-140 carries a
  direct `url`, and that URL serves 200/206 — verified end-to-end through the real
  `YouTubeMusicService.getStreamUrl` code.

### Historical log (pre-resolution)

YouTube stream URL was fetched successfully (`getStreamUrl` returned a URL), but `just_audio` failed to play it.

| Version | Change | Result |
|---------|--------|--------|
| v1.2.1 | Fix parser (musicCardShelfRenderer) | Search works, playback frozen at 0:00, no error |
| v1.2.2 | Explicit `androidSdkless` client in getManifest | Same — already default in v3.1.0 |
| v1.2.4 | Add `lastError` to PlaybackState, snackbar on error | No snackbar appeared |
| v1.2.5 | Red error banner on queue page | Banner shows: "Playback error: 0 source error" |
| v1.2.6 | Pass YouTube user-agent header to `just_audio setUrl()` | Same error |
| v1.2.7 | Prefer AAC/mp4 (itag 140) over opus/webm (itag 251) | Same error |

**Key facts:**
- "Playback error: 0 source error" = `just_audio` got the URL but failed to open the stream
- Error only appears when user drags seek bar — not immediately on tap
- Stream URL is definitely being returned (error path says "Playback error", not "getStreamUrl returned null")
- AAC/mp4 itag 140 is now selected — opus/webm ruled out as cause
- YouTube user-agent header is sent — 403 from missing UA ruled out

**Next suspects:**
- The `n` parameter in the CDN URL may need deobfuscation that `youtube_explode_dart` isn't doing correctly for the `androidSdkless` client
- The CDN URL may be IP-locked to the server that fetched it (Mac) and not usable from the Android device
- `just_audio` Android may need `okhttp` or a specific media3 version for YouTube CDN

---

## What's Pending 🔴

### YouTube Playback (blocker)
- Source error 0 in just_audio when playing YouTube CDN URL
- Next approach to try: fetch stream URL on device using a different method

### UI Polish
- Album art: `albumArtBytes` on Song not displayed — `ArtThumbnail` shows grey placeholder
- YouTube thumbnails (`thumbnailUrl` on Song) not displayed
- `defaultLibraryTab` setting not applied on Library page init
- `autoOpenQueue` setting not implemented

### Navigation
- Context menu "View Album" / "View Artist" not wired on detail pages

---

## Known Build Quirks

- `flutter clean` → rebuild requires `--no-shrink` flag or shader compiler OOM-kills on 8GB RAM
- `git add/status` inside `flutter/` hangs — always use `GIT_DIR`+`GIT_WORK_TREE` pattern
- Gradle pinned to 8.14.5, AGP to 8.11.1 — do not upgrade
- arm64 only (`--target-platform android-arm64`) to avoid OOM during AOT compile

---

## File Structure

```
lib/
├── main.dart
├── app.dart                         # GoRouter + AppShell (cold-launch cache init)
├── theme.dart
├── models/                          # Song, Album, Artist, Playlist, AppSettings, etc.
├── data/
│   ├── music_repository.dart        # Abstract interface + SearchResults
│   ├── mock_music_repository.dart
│   ├── mock_data.dart
│   ├── local_music_scanner.dart     # Inline ID3v2 parser
│   ├── local_music_repository.dart
│   ├── audio_service.dart           # just_audio wrapper
│   ├── youtube_music_service.dart   # InnerTube search + stream URL fetch
│   ├── youtube_library_cache.dart   # JSON cache for saved YT songs
│   └── settings_repository.dart
├── providers/
│   ├── library_provider.dart        # musicRepositoryProvider
│   ├── local_library_provider.dart  # scan state + JSON cache
│   ├── yt_library_provider.dart     # YT service singleton + saved library
│   ├── playback_provider.dart       # PlaybackNotifier + lastError
│   ├── search_provider.dart         # SearchNotifier → YouTubeMusicService
│   └── settings_provider.dart
├── pages/
│   ├── library_page.dart
│   ├── queue_page.dart              # Shows red error banner on lastError
│   ├── search_page.dart
│   ├── settings_page.dart
│   ├── album_page.dart
│   ├── artist_page.dart
│   └── playlist_page.dart
└── components/
```
