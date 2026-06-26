import 'package:flutter/material.dart';
import '../../models/live_performance.dart';
import '../../theme.dart';
import '../art_thumbnail.dart';

class LivePerformanceRow extends StatelessWidget {
  final LivePerformance lp;
  final VoidCallback? onTap;

  const LivePerformanceRow({
    super.key,
    required this.lp,
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
              const ArtThumbnail(size: 48, icon: Icons.mic),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lp.title,
                      style: AppTextStyles.listTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      '${lp.artist} · ${lp.date}',
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
