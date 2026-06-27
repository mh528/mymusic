# /dev-fresh

Kills any running flutter process, clears the build cache, and restarts the web dev server on port 8080 in Brave.

**Run this in your terminal to start manually:**
```sh
cd /Users/michaelhayes/Documents/Code/mymusic/flutter
pkill -f "flutter run" 2>/dev/null; pkill -f "dart.*flutter" 2>/dev/null; sleep 2
flutter clean
CHROME_EXECUTABLE="/Applications/Brave Browser.app/Contents/MacOS/Brave Browser" flutter run -d web-server --web-port 8080
```
Then open **http://localhost:8080** in Brave.

---

## Instructions for Claude

When this command is invoked:

1. Kill any running flutter processes:
   ```
   pkill -f "flutter run" 2>/dev/null; pkill -f "dart.*flutter" 2>/dev/null; sleep 2
   ```
2. Run `flutter clean` from `/Users/michaelhayes/Documents/Code/mymusic/flutter` to clear build cache (prevents shader compiler crashes).
3. Start the dev server in the background:
   ```
   CHROME_EXECUTABLE="/Applications/Brave Browser.app/Contents/MacOS/Brave Browser" flutter run -d web-server --web-port 8080 2>&1
   ```
   Run with `run_in_background: true`.
4. Wait for "Flutter run key commands" to appear in the output file before reporting ready.
5. Tell the user to open or refresh **http://localhost:8080** in Brave.

Note: Hot reload via `r` keypress is not possible when running headlessly — a full restart (`flutter run`) picks up all changes. If the shader compiler crashes again, `flutter clean` first.
