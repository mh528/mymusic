### Page
Now Playing Section is at the top
Queue item rows are at bottom (below now playing section)

### Now Playing Section
Move towards the top of the screen
Make Song, Artist, and Album text larger
Need to allow for click and drag on the time elapse slider
Add a section to Settings page to show/hide volume slider on queue/now playing song
Add buttons below the pause, forward buttons: should be icon top, label below similar to the nav bar: + and Playlist, album icon and Album - goes to the album, person and Artist - goes to Artist, and More, 

### Queue Items
Move to bottom of screen
On left side of item, replace the numbers with a (-) or circle minus icon to indicate remove from queue, right side stays the same with grip and more menu icons

---

## Implementation Plan

### Context
The Queue page currently has Now Playing at the bottom and queue items at the top. This plan flips that layout, expands the Now Playing section with larger text, an interactive seek slider, navigation shortcuts, and a settings toggle for the volume slider; it also updates queue item rows to show a remove button instead of a position number.

---

### 1. Flip page layout (`queue_page.dart`)
In `QueuePage.build`, swap the order in the `Column`: put `_NowPlayingSection` first (top), then the `Expanded` queue list below it.

```
Column(children: [
  _NowPlayingSection(...),   // ← move to top
  Expanded(child: queue list),
])
```

---

### 2. Larger song/artist/album text (`queue_page.dart` · `_NowPlayingSection`)
Current sizes: title `14`, artist/album `12`.  
Increase to: title `18 w600`, artist `14`, album `13 textMuted`.

---

### 3. Interactive seek slider (`queue_page.dart` · `_NowPlayingSection`)
Replace `LinearProgressIndicator` (line 254) with a Flutter `Slider`:

```dart
Slider(
  value: progress.clamp(0.0, 1.0),
  onChanged: (v) {
    final seek = Duration(seconds: (v * duration.inSeconds).round());
    ref.read(playbackProvider.notifier).setPosition(seek);
  },
)
```

`setPosition` already exists in `PlaybackNotifier` (playback_provider.dart:189) and calls `audioService.seek()`.

---

### 4. Action buttons row (`queue_page.dart` · `_NowPlayingSection`)
Replace the current `TextButton.icon` ghost row (Add to Playlist / More) with four `AppGhostButton`s in a `Row(mainAxisAlignment: spaceEvenly)`:

| Label | Icon | Action |
|---|---|---|
| Playlist | `Icons.playlist_add` | stub `onAddToPlaylist` |
| Album | `Icons.album` | `context.go('/music/album/${song.albumId}')` |
| Artist | `Icons.person` | `context.go('/music/artist/${song.artistId}')` |
| More | `Icons.more_horiz` | `onMoreTap` |

Use existing `AppGhostButton` from `components/buttons.dart`. Wire Album/Artist via GoRouter (`context.go`). The routes `/music/album/:id` and `/music/artist/:id` already exist in `app.dart`.

**Note:** Check that `Song` model has `albumId` and `artistId` fields — if not, use `song.album`/`song.artist` as the route param (consistent with existing stubs).

---

### 5. Settings toggle for volume slider (`settings_page.dart`, `models/settings.dart`, `providers/settings_provider.dart`)
1. Add `bool showQueueVolumeSlider` field to `AppSettings` (default `true`).
2. Add `setShowQueueVolumeSlider(bool)` to the settings notifier.
3. Add a `_ToggleSetting` under the Playback section in `settings_page.dart`:
   - Title: "Volume Slider"
   - Description: "Show volume slider on the Now Playing screen"
4. In `_NowPlayingSection`, read the setting and conditionally show/hide the volume slider (currently the volume slider lives in `NowPlayingMoreMenu` — decide whether to surface it inline in Now Playing or keep it in the More menu; the spec says "on queue/now playing song", so add it inline below the seek slider, gated by the setting).

---

### 6. Queue item row: remove button replaces position number (`queue_item_row.dart`)
Replace the `SizedBox(width: AppSpacing.xxl)` position number on the left with an `IconButton`:

```dart
IconButton(
  icon: const Icon(Icons.remove_circle_outline, color: AppColors.textMuted, size: AppIconSize.sm),
  onPressed: onRemoveTap,
  padding: EdgeInsets.zero,
  constraints: const BoxConstraints(),
)
```

Add `VoidCallback? onRemoveTap` parameter to `QueueItemRow`. In `queue_page.dart`, pass:
```dart
onRemoveTap: () => ref.read(playbackProvider.notifier).removeFromQueue(song.id),
```

The `removeFromQueue` method already exists in `PlaybackNotifier`.

---

### Files to modify
| File | Change |
|---|---|
| `lib/pages/queue_page.dart` | Layout flip, larger text, seek slider, action buttons row |
| `lib/components/list_rows/queue_item_row.dart` | Remove button replaces position number |
| `lib/models/settings.dart` | Add `showQueueVolumeSlider` field |
| `lib/providers/settings_provider.dart` | Add setter for new setting |
| `lib/pages/settings_page.dart` | Add toggle under Playback section |

---

### Verification
1. Run the app (`flutter run`) and navigate to the Queue tab.
2. Confirm Now Playing appears at top, queue list below.
3. Tap and drag the seek slider — playback position should update.
4. Tap Album / Artist buttons — should navigate to correct pages.
5. Tap the `-` icon on a queue item — item should be removed.
6. Go to Settings → Playback → toggle "Volume Slider" off — volume control should disappear from Now Playing.