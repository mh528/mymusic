import 'package:flutter/material.dart';
import '../../models/video.dart';
import '../../theme.dart';
import '../art_thumbnail.dart';

class VideoRow extends StatelessWidget {
  final Video video;
  final VoidCallback? onTap;

  const VideoRow({
    super.key,
    required this.video,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppSpacing.rowHeight,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.md),
          child: Row(
            children: [
              const ArtThumbnail(size: 48, icon: Icons.play_circle_outline),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      video.title,
                      style: AppTextStyles.listTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      '${video.artist} · ${video.duration.inMinutes}:${(video.duration.inSeconds % 60).toString().padLeft(2, '0')}',
                      style: AppTextStyles.listSubtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
