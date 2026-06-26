import 'package:flutter/material.dart';
import '../../models/song.dart';
import '../../theme.dart';

class LyricsDrawer extends StatelessWidget {
  final Song song;
  final bool isPlaying;
  final VoidCallback onPlayPause;
  final VoidCallback onSkipNext;
  final VoidCallback onSkipPrevious;
  final VoidCallback onClose;

  const LyricsDrawer({
    super.key,
    required this.song,
    required this.isPlaying,
    required this.onPlayPause,
    required this.onSkipNext,
    required this.onSkipPrevious,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: AppBar(
        backgroundColor: AppColors.black,
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.white),
          onPressed: onClose,
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              song.title,
              style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const Text(
              'Now Playing',
              style: AppTextStyles.caption,
            ),
          ],
        ),
      ),
      body: const Center(
        child: Text(
          '♪ Lyrics coming soon',
          style: TextStyle(
            color: Color(0xCCFFFFFF),
            fontSize: 24, // intentionally large — decorative lyric placeholder
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.skip_previous, color: AppColors.white, size: 36),
                onPressed: onSkipPrevious,
              ),
              const SizedBox(width: AppSpacing.xl),
              CircleAvatar(
                radius: 28,
                backgroundColor: AppColors.white,
                child: IconButton(
                  icon: Icon(
                    isPlaying ? Icons.pause : Icons.play_arrow,
                    color: AppColors.black,
                    size: 28,
                  ),
                  onPressed: onPlayPause,
                ),
              ),
              const SizedBox(width: AppSpacing.xl),
              IconButton(
                icon: const Icon(Icons.skip_next, color: AppColors.white, size: 36),
                onPressed: onSkipNext,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
