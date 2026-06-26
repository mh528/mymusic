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
      height: 64,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              const ArtThumbnail(size: 48, icon: Icons.mic),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lp.title,
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 15,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${lp.artist} · ${lp.date}',
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
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
