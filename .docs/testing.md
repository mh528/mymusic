# Testing

## Philosophy

YouTube's API breaks silently. The ANDROID_VR client that powers playback was discovered only through manual probing after ANDROID_MUSIC started returning LOGIN_REQUIRED with no warning. Search broke when YouTube stopped accepting `clientVersion` with the actual day of the month — it now requires the 1st. Neither failure threw an exception; both produced silent empty results or null URLs.

The test suite exists so these failures surface in CI or pre-release, not from a user report.

Two-layer approach:
- **Unit tests** — no network, run fast, catch logic/parsing regressions
- **Live probes** — hit real YouTube endpoints, run before every release, catch API-level breakage

---

## Unit Tests

**Location:** `test/youtube/`  
**Run:** `flutter test test/youtube/`  
**Speed:** ~4 seconds, no network required

### Files

| File | What it tests |
|------|--------------|
| `test/youtube/stream_url_test.dart` | `getStreamUrlDirect` — all playability status codes, itag selection, signatureCipher fallback, malformed JSON, fallback chain handoff |
| `test/youtube/search_parse_test.dart` | `_parseResults` — songs/albums/artists from real fixture, missing fields, HTML error body, empty response |
| `test/youtube/cache_test.dart` | `YouTubeLibraryCache` — add/remove/update/load round-trip, deduplication, corrupted JSON recovery |
| `test/youtube/duration_parse_test.dart` | `parseDuration` — MM:SS, HH:MM:SS, null, empty string, invalid input |

**Total: 34 tests.**

### Test infrastructure

Unit tests inject a fake `HttpClient` via the `createClient` constructor seam added to `YouTubeMusicService`:

```dart
YouTubeMusicService(createClient: () => _FakeClient(responseJson))
```

`YouTubeLibraryCache` accepts an optional `directory` param so tests use a temp dir instead of the real app support directory:

```dart
YouTubeLibraryCache(directory: tempDir)
```

### Fixture file

`test/fixtures/yt_search_sample.json` — a slimmed real YouTube Music API response captured from a live `search('Radiohead')` call. Contains one `musicCardShelfRenderer` section (top result), one Album, one Song, and two Artist sections. Used by `search_parse_test.dart` to guard against schema regressions.

**If YouTube changes its response schema** and `search_parse_test` starts failing on the fixture test, re-capture it:

```bash
# From repo root — makes a live search call and saves to test/fixtures/
dart run tool/yt_search_probe.dart   # confirms search is working first
# Then manually update the fixture by running the capture script
```

---

## Live Probes

**Location:** `tool/`  
**Run:** `dart run tool/<probe>.dart`  
**Requires:** network, YouTube access

See `.claude/commands/test-yt.md` for the full pre-release checklist and output interpretation guide. Summary:

### `tool/yt_probe.dart`

Tests the primary stream URL path end-to-end:

1. Calls real `YouTubeMusicService.getStreamUrl('dQw4w9WgXcQ')`
2. Asserts URL is non-null, contains `c=ANDROID_VR`, contains `itag=140`
3. Makes a `Range: bytes=0-1023` HEAD request to the CDN URL — asserts HTTP 206 + `Accept-Ranges: bytes`

This probe would have caught the ANDROID_MUSIC → LOGIN_REQUIRED regression before it hit production.

```
dart run tool/yt_probe.dart [videoId]
```

### `tool/yt_search_probe.dart`

Tests the full search path:

1. Calls `search('Radiohead')` — asserts `songs >= 1`, all songs have non-empty `videoId`
2. Calls `search('')` — asserts no throw, empty graceful result

This probe caught the `clientVersion` format regression (`1.YYYYMMDD.01.00` → `1.YYYYMM01.01.00`).

```
dart run tool/yt_search_probe.dart [query]
```

### `tool/yt_fallback_probe.dart`

Tests the `youtube_explode_dart` fallback independently of the primary path:

1. Injects a fake `HttpClient` that always returns `LOGIN_REQUIRED`
2. Calls `getStreamUrl()` — confirms the explode fallback is invoked and returns a URL

This verifies the fallback chain is intact even when the direct ANDROID_VR path is working and you can't naturally trigger a fallback.

```
dart run tool/yt_fallback_probe.dart [videoId]
```

### `tool/yt_download_probe.dart`

Tests the download path (`downloadAudio`), which has no fallback and no test coverage in the unit suite:

1. Calls `downloadAudio('dQw4w9WgXcQ', '/tmp/...')`
2. Asserts file exists and is > 100 KB
3. Cleans up the temp file

```
dart run tool/yt_download_probe.dart [videoId]
```

---

## Seam Design

Two minimal changes were made to production code to enable testing without changing behavior:

**`YouTubeMusicService`** — `createClient` injection:
```dart
YouTubeMusicService({HttpClient Function()? createClient})
    : _createClient = createClient ?? HttpClient.new;
```
All internal `HttpClient()` calls replaced with `_createClient()`. Default behavior unchanged.

**`YouTubeLibraryCache`** — `directory` injection:
```dart
YouTubeLibraryCache({Directory? directory}) : _testDirectory = directory;
```
If null, falls back to `getApplicationSupportDirectory()` as before.

**`getStreamUrlDirect` and `parseDuration`** — renamed from private (`_`) to public so unit tests can call them directly without going through the full network stack.

---

## What the Tests Catch

| Past or potential failure | Caught by |
|---|---|
| ANDROID_MUSIC → LOGIN_REQUIRED (the trigger for all this) | `yt_probe` + `stream_url_test` #2 |
| ANDROID_VR client invalidated by YouTube | `yt_probe` CLIENT_CHECK assertion |
| clientVersion format rejected (YYYYMMDD vs YYYYMM01) | `yt_search_probe` SONGS=0 |
| YouTube response schema change breaking search parser | `search_parse_test` fixture regression |
| Fallback never triggered when direct path fails | `stream_url_test` fallback group + `yt_fallback_probe` |
| `downloadAudio` silent failure (no fallback) | `yt_download_probe` |
| Library cache corrupted by bad JSON | `cache_test` corrupted file case |
| YouTube returning HTML error page instead of JSON | `stream_url_test` + `search_parse_test` HTML cases |
| Wrong itag selected for quality setting | `stream_url_test` itag selection cases |
