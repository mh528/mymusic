import 'package:flutter/material.dart';
import '../theme.dart';

class DownloadButton extends StatelessWidget {
  final bool isDownloaded;
  final bool isDownloading;
  final VoidCallback onTap;

  const DownloadButton({
    super.key,
    required this.isDownloaded,
    required this.isDownloading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (child, animation) =>
            ScaleTransition(scale: animation, child: child),
        child: Icon(
          key: ValueKey(isDownloading ? 'loading' : isDownloaded ? 'done' : 'none'),
          isDownloading
              ? Icons.downloading
              : isDownloaded
                  ? Icons.download_done
                  : Icons.download_for_offline,
          color: isDownloaded ? AppColors.white : AppColors.textMuted,
          size: 20,
        ),
      ),
      onPressed: isDownloading ? null : onTap,
      splashRadius: 0.01,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
    );
  }
}
