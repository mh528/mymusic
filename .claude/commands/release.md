Build a release APK and publish it to GitHub releases at https://github.com/mh528/mymusic.

The Flutter binary is at `/Users/michaelhayes/Documents/Code/flutter/bin/flutter` (also on PATH as just `flutter`).
All commands must run from `/Users/michaelhayes/Documents/Code/mymusic/flutter/`.

If $ARGUMENTS is provided, parse it as: first word = version tag (e.g. v1.1.0), rest = release notes.
Example: `/release v1.1.0 Fixed ID3 fallback for FLAC files`

## Steps

1. Ask the user for the version tag and release notes if not provided in $ARGUMENTS.
   Also bump `version:` in `pubspec.yaml` to match (e.g. `1.1.0+2`, incrementing build number) BEFORE building.

2. Kill any running dev server / flutter process:
   ```
   pkill -f "flutter run" || true
   ```

3. Deep clean (avoids stale Gradle cache issues):
   ```
   flutter clean
   rm -rf android/app/build android/.gradle android/app/.cxx
   ```

4. Build the release APK (arm64 only — covers all modern Android devices, halves compile time/memory).
   **Always `cd` first** — shell cwd does not persist between tool calls, and flutter will error "No pubspec.yaml found" if run from the wrong directory:
   ```
   cd /Users/michaelhayes/Documents/Code/mymusic/flutter && flutter build apk --release --target-platform android-arm64 --no-tree-shake-icons
   ```

5. APK is written to: `build/app/outputs/flutter-apk/app-release.apk`
   (Flutter may print a false "couldn't find it" warning — ignore it, the file is there.)

6. Commit the version bump in the flutter submodule:
   ```
   # Use GIT_DIR/GIT_WORK_TREE because git -C hangs on large build/ dirs
   GIT_DIR=/Users/michaelhayes/Documents/Code/mymusic/flutter/.git \
   GIT_WORK_TREE=/Users/michaelhayes/Documents/Code/mymusic/flutter \
   git add pubspec.yaml pubspec.lock
   
   GIT_DIR=/Users/michaelhayes/Documents/Code/mymusic/flutter/.git \
   GIT_WORK_TREE=/Users/michaelhayes/Documents/Code/mymusic/flutter \
   git commit -m "chore: bump version to <tag>"
   
   GIT_DIR=/Users/michaelhayes/Documents/Code/mymusic/flutter/.git git push origin main
   ```
   Then update the submodule pointer in the root repo:
   ```
   git -C /Users/michaelhayes/Documents/Code/mymusic add flutter
   git -C /Users/michaelhayes/Documents/Code/mymusic commit -m "chore: update flutter submodule to <tag>"
   git -C /Users/michaelhayes/Documents/Code/mymusic push origin main
   ```

7. Create the GitHub release:
   ```
   gh release create <tag> build/app/outputs/flutter-apk/app-release.apk \
     --title "My Music <tag>" \
     --notes "<release notes>" \
     --repo mh528/mymusic
   ```

8. Report the release URL to the user.

## Terminal Command
flutter build apk --release --target-platform android-arm64 --no-tree-shake-icons 2>&1

## Known quirks

- **git status / git add hang** when called from inside `flutter/` — the large `android/app/build/` directory (even though gitignored) causes git to scan slowly. Always use the `GIT_DIR` + `GIT_WORK_TREE` pattern with explicit file paths, never `git add -A` or `git status` inside the flutter dir.
- **Gradle version** is pinned to 8.14.5 (`android/gradle/wrapper/gradle-wrapper.properties`) and AGP to 8.11.1 (`android/settings.gradle.kts`). Do not upgrade — Gradle 9+ breaks several plugins.
- **No Rust required** — ID3 parsing is pure Dart (inline in `lib/data/local_music_scanner.dart`). Do not add `metadata_god` or `audiotags` — both require rustup.
- **arm64 only** — `--target-platform android-arm64` avoids OOM on 8GB Mac during AOT compilation. The APK works on all modern Android phones.
- **`--no-tree-shake-icons`** — suppresses a Cupertino font warning that can interfere with the shader compilation step.
