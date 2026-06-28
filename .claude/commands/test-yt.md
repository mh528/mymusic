# /test-yt

Run all YouTube tests before every release. Live probes require network; unit tests do not.

## Unit tests (no network — run on every code change)

```
flutter test test/youtube/
```

## Live probes (require network — run before every release)

```
dart run tool/yt_probe.dart            # primary ANDROID_VR stream path + range check
dart run tool/yt_search_probe.dart     # search returns results
dart run tool/yt_fallback_probe.dart   # explode fallback works when direct path fails
dart run tool/yt_download_probe.dart   # full download to disk works
```

## Reading probe output

| Output | Meaning |
|--------|---------|
| `RESULT_OK` + `RANGE_OK` + `CLIENT_CHECK=ANDROID_VR_OK` | Primary path working ✓ |
| `RESULT_NULL` | Direct path failed — check if ANDROID_VR client is still anonymous |
| `FALLBACK_OK` | Explode fallback working — primary broke but audio still plays |
| `FALLBACK_NULL` | Both paths dead — audio is broken, **do not release** |
| `SONGS>=1` | Search working ✓ |
| `SONGS=0` | Search broken — check clientVersion format in `_ytMusicContext` |
| `DOWNLOAD_OK` | Download path working ✓ |

## What each probe tests

- **yt_probe**: Calls real `YouTubeMusicService.getStreamUrl`, confirms `c=ANDROID_VR` + `itag=140` in URL, does an HTTP 206 range check to confirm CDN serves bytes
- **yt_search_probe**: Calls real `search('Radiohead')`, asserts songs > 0 with valid videoIds, also tests empty query doesn't throw
- **yt_fallback_probe**: Forces the direct path to return `LOGIN_REQUIRED` via a fake HttpClient, then confirms `youtube_explode_dart` fallback runs and returns a URL
- **yt_download_probe**: Calls real `downloadAudio`, writes to `/tmp/`, asserts file > 100 KB, cleans up

## Known failure modes and fixes

| Symptom | Likely cause | Fix |
|---------|-------------|-----|
| `yt_probe` returns `RESULT_NULL` with `LOGIN_REQUIRED` | ANDROID_VR client blocked | Update `clientVersion` in `_androidVrContext` or switch client |
| `yt_search_probe` returns `SONGS=0` / HTTP 404 | `clientVersion` format wrong | Check `_ytMusicContext` — format must be `1.YYYYMM01.01.00` |
| `yt_fallback_probe` returns `FALLBACK_NULL` | `youtube_explode_dart` broken | Run `flutter pub upgrade youtube_explode_dart` |
| Unit tests fail on `search_parse_test` | YouTube changed response schema | Re-capture fixture: `dart run tool/yt_probe.dart` → inspect output, update `_parseResults` |

## Re-capturing the fixture

If YouTube changes its response schema and `search_parse_test` starts failing:

```
# From repo root — re-captures and slims yt_search_sample.json
dart run /path/to/scratchpad/yt_capture.dart
```

Or just re-run the search probe with logging enabled and capture manually.
