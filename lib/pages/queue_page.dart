import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/song.dart';
import '../models/settings.dart' as app_settings;
import '../theme.dart';
import '../components/art_thumbnail.dart';
import '../components/buttons.dart';
import '../components/list_rows/queue_item_row.dart';
import '../components/menus/queue_item_context_menu.dart';
import '../components/menus/now_playing_more_menu.dart';
import '../components/drawers/lyrics_drawer.dart';
import '../providers/playback_provider.dart';
import '../providers/settings_provider.dart';

class QueuePage extends ConsumerWidget {
  const QueuePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playback = ref.watch(playbackProvider);
    final queue = playback.queue;
    final currentSong = playback.currentSong;
    final error = playback.lastError;

    return Scaffold(
      backgroundColor: AppColors.black,
      body: SafeArea(
        child: Column(
          children: [
            if (error != null)
              Container(
                width: double.infinity,
                color: Colors.red.shade900,
                padding: const EdgeInsets.all(12),
                child: Text(error, style: const TextStyle(color: Colors.white, fontSize: 12)),
              ),
            _NowPlayingSection(
              currentSong: currentSong,
              ref: ref,
              onLyricsTap: () {
                if (currentSong == null) return;
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => LyricsDrawer(
                      song: currentSong,
                      isPlaying: playback.isPlaying,
                      onPlayPause: () =>
                          ref.read(playbackProvider.notifier).playPause(),
                      onSkipNext: () =>
                          ref.read(playbackProvider.notifier).skipNext(),
                      onSkipPrevious: () =>
                          ref.read(playbackProvider.notifier).skipPrevious(),
                      onClose: () => Navigator.pop(context),
                    ),
                  ),
                );
              },
              onMoreTap: () {
                if (currentSong == null) return;
                showNowPlayingMoreMenu(
                  context,
                  currentSong,
                  volume: playback.volume,
                  onVolumeChanged: (v) =>
                      ref.read(playbackProvider.notifier).setVolume(v),
                  onAddToPlaylist: () {},
                  onDownload: () {},
                  onRemoveDownload: () {},
                  onShare: () {},
                  onStartRadio: () {},
                  onViewAlbum: () {},
                  onViewArtist: () {},
                );
              },
            ),
            if (queue.isNotEmpty)
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Up Next',
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            Expanded(
              child: queue.isEmpty
                  ? _EmptyQueue()
                  : ReorderableListView.builder(
                      itemCount: queue.length,
                      onReorderItem: (oldIndex, newIndex) {
                        ref
                            .read(playbackProvider.notifier)
                            .reorderQueue(oldIndex, newIndex);
                      },
                      itemBuilder: (_, index) {
                        final song = queue[index];
                        return Dismissible(
                          key: ValueKey('dismiss_${song.id}_$index'),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            color: AppColors.red,
                            child: const Icon(Icons.remove_circle_outline, color: AppColors.white, size: AppIconSize.md),
                          ),
                          onDismissed: (_) => ref
                              .read(playbackProvider.notifier)
                              .removeFromQueue(song.id),
                          child: QueueItemRow(
                          key: ValueKey(song.id + index.toString()),
                          song: song,
                          position: index + 1,
                          onRemoveTap: () => ref
                              .read(playbackProvider.notifier)
                              .removeFromQueue(song.id),
                          onMoreTap: () => showQueueItemContextMenu(
                            context,
                            song,
                            onAddToLibrary: () {},
                            onAddToPlaylist: () {},
                            onDownload: () {},
                            onPlayNext: () {},
                            onRemoveFromQueue: () {
                              ref
                                  .read(playbackProvider.notifier)
                                  .removeFromQueue(song.id);
                            },
                            onShare: () {},
                            onStartRadio: () {},
                            onViewAlbum: () {},
                            onViewArtist: () {},
                          ),
                        ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyQueue extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.queue_music, size: 64, color: AppColors.textDim),
          const SizedBox(height: 12),
          const Text(
            'Queue is empty',
            style: TextStyle(color: AppColors.textMuted, fontSize: 16),
          ),
          const SizedBox(height: 8),
          const Text(
            'Play a song to get started',
            style: TextStyle(color: AppColors.textDim, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _NowPlayingSection extends ConsumerWidget {
  final Song? currentSong;
  final WidgetRef ref;
  final VoidCallback onLyricsTap;
  final VoidCallback onMoreTap;

  const _NowPlayingSection({
    required this.currentSong,
    required this.ref,
    required this.onLyricsTap,
    required this.onMoreTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playback = ref.watch(playbackProvider);
    final settingsAsync = ref.watch(settingsProvider);
    final showVolumeSlider = settingsAsync.valueOrNull?.showQueueVolumeSlider ?? true;

    if (currentSong == null) {
      return const SizedBox.shrink();
    }

    final song = currentSong!;
    final position = playback.position;
    final duration = song.duration;
    final progress = duration.inSeconds > 0
        ? position.inSeconds / duration.inSeconds
        : 0.0;
    final remaining = duration - position;

    String fmt(Duration d) {
      final m = d.inMinutes;
      final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
      return '$m:$s';
    }

    return Container(
      color: AppColors.bg1,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Song info row
          Row(
            children: [
              ArtThumbnail(size: 56),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      song.title,
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      song.artist,
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      song.album,
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  song.inLibrary ? Icons.library_add_check : Icons.library_add,
                  color: song.inLibrary ? AppColors.white : AppColors.textMuted,
                ),
                onPressed: () {},
              ),
              IconButton(
                icon: Icon(
                  song.isDownloading
                      ? Icons.downloading
                      : song.isDownloaded
                          ? Icons.download_done
                          : Icons.download_for_offline,
                  color: song.isDownloaded ? AppColors.white : AppColors.textMuted,
                ),
                onPressed: song.isDownloading ? null : () {},
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Seek slider
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 9),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 18),
            ),
            child: Slider(
              value: progress.clamp(0.0, 1.0),
              onChanged: (v) {
                final seek = Duration(seconds: (v * duration.inSeconds).round());
                ref.read(playbackProvider.notifier).setPosition(seek);
              },
            ),
          ),
          // Time row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  fmt(position),
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                ),
                Text(
                  '-${fmt(remaining)}',
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          // Controls row — shuffle left, repeat right, equal widths keep < play > centered
          Row(
            children: [
              SizedBox(
                width: 48,
                child: IconButton(
                  icon: Icon(Icons.shuffle, color: AppColors.textMuted),
                  onPressed: () => ref.read(playbackProvider.notifier).shuffleQueue(),
                  padding: EdgeInsets.zero,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => ref.read(playbackProvider.notifier).skipPrevious(),
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.white, width: 1.5),
                  ),
                  child: const Icon(Icons.skip_previous, color: AppColors.white, size: 28),
                ),
              ),
              const SizedBox(width: 8),
              _PlayPauseButton(
                isPlaying: playback.isPlaying,
                onTap: () => ref.read(playbackProvider.notifier).playPause(),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => ref.read(playbackProvider.notifier).skipNext(),
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.white, width: 1.5),
                  ),
                  child: const Icon(Icons.skip_next, color: AppColors.white, size: 28),
                ),
              ),
              const Spacer(),
              SizedBox(
                width: 48,
                child: _RepeatButton(
                  mode: playback.repeatMode,
                  onTap: () => ref.read(playbackProvider.notifier).cycleRepeat(),
                ),
              ),
            ],
          ),
          // Volume slider (gated by setting) — sits in instrument panel zone with controls
          if (showVolumeSlider) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.volume_down, color: AppColors.textMuted, size: 20),
                Expanded(
                  child: Slider(
                    value: playback.volume.clamp(0.0, 1.0),
                    min: 0,
                    max: 1,
                    onChanged: (v) =>
                        ref.read(playbackProvider.notifier).setVolume(v),
                  ),
                ),
                const Icon(Icons.volume_up, color: AppColors.textMuted, size: 20),
              ],
            ),
          ],
          const SizedBox(height: 4),
          // Action buttons row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              AppGhostButton(
                icon: Icons.playlist_add,
                label: 'Playlist',
                active: true,
                onTap: () {},
              ),
              AppGhostButton(
                icon: Icons.album,
                label: 'Album',
                active: true,
                onTap: () => context.go('/music/album/${song.albumId}'),
              ),
              AppGhostButton(
                icon: Icons.person,
                label: 'Artist',
                active: true,
                onTap: () => context.go('/music/artist/${song.artistId}'),
              ),
              AppGhostButton(
                icon: Icons.more_horiz,
                label: 'More',
                active: true,
                onTap: onMoreTap,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PlayPauseButton extends StatelessWidget {
  final bool isPlaying;
  final VoidCallback onTap;

  const _PlayPauseButton({required this.isPlaying, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: CircleAvatar(
        radius: 32,
        backgroundColor: AppColors.white,
        child: Icon(
          isPlaying ? Icons.pause : Icons.play_arrow,
          color: AppColors.black,
          size: 28,
        ),
      ),
    );
  }
}

class _RepeatButton extends StatelessWidget {
  final app_settings.RepeatMode mode;
  final VoidCallback onTap;

  const _RepeatButton({required this.mode, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final icon = mode == app_settings.RepeatMode.one ? Icons.repeat_one : Icons.repeat;
    final color = mode == app_settings.RepeatMode.off ? AppColors.textDim : AppColors.white;

    return IconButton(
      icon: Icon(icon, color: color),
      onPressed: onTap,
    );
  }
}
