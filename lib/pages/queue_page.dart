import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/song.dart';
import '../models/settings.dart' as app_settings;
import '../theme.dart';
import '../components/art_thumbnail.dart';
import '../components/list_rows/queue_item_row.dart';
import '../components/menus/queue_item_context_menu.dart';
import '../components/menus/now_playing_more_menu.dart';
import '../components/drawers/lyrics_drawer.dart';
import '../providers/playback_provider.dart';

class QueuePage extends ConsumerWidget {
  const QueuePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playback = ref.watch(playbackProvider);
    final queue = playback.queue;
    final currentSong = playback.currentSong;

    return Scaffold(
      backgroundColor: AppColors.black,
      body: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
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
                        return QueueItemRow(
                          key: ValueKey(song.id + index.toString()),
                          song: song,
                          position: index + 1,
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
                        );
                      },
                    ),
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

    if (currentSong == null) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(
          child: Text(
            'Nothing playing',
            style: TextStyle(color: AppColors.textMuted, fontSize: 14),
          ),
        ),
      );
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
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
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
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      song.artist,
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      song.album,
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
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
                          : Icons.download_outlined,
                  color: song.isDownloaded ? AppColors.white : AppColors.textMuted,
                ),
                onPressed: song.isDownloading ? null : () {},
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Progress bar
          LinearProgressIndicator(value: progress.clamp(0.0, 1.0)),
          const SizedBox(height: 4),
          // Time row
          Row(
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
          const SizedBox(height: 4),
          // Controls row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
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
              const SizedBox(width: 16),
              _RepeatButton(
                mode: playback.repeatMode,
                onTap: () => ref.read(playbackProvider.notifier).cycleRepeat(),
              ),
            ],
          ),
          // Ghost buttons row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              TextButton.icon(
                icon: const Icon(Icons.playlist_add),
                label: const Text('Add to Playlist'),
                onPressed: () {},
                style: TextButton.styleFrom(foregroundColor: AppColors.textMuted),
              ),
              TextButton.icon(
                icon: const Icon(Icons.more_horiz),
                label: const Text('More'),
                onPressed: onMoreTap,
                style: TextButton.styleFrom(foregroundColor: AppColors.textMuted),
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
