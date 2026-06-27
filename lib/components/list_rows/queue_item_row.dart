import 'package:flutter/material.dart';
import '../../models/song.dart';
import '../../theme.dart';

class QueueItemRow extends StatelessWidget {
  final Song song;
  final int position;
  final VoidCallback? onMoreTap;
  final VoidCallback? onRemoveTap;

  const QueueItemRow({
    required Key key,
    required this.song,
    required this.position,
    this.onMoreTap,
    this.onRemoveTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppSpacing.rowHeight,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.md),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(
                Icons.remove_circle_outline,
                color: AppColors.textMuted,
                size: AppIconSize.sm,
              ),
              onPressed: onRemoveTap,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    song.title,
                    style: AppTextStyles.listTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '${song.artist} · ${song.duration.mmss}',
                    style: AppTextStyles.listSubtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(
                Icons.more_vert,
                color: AppColors.textMuted,
                size: AppIconSize.sm,
              ),
              onPressed: onMoreTap,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            const SizedBox(width: AppSpacing.lg),
          ],
        ),
      ),
    );
  }
}
