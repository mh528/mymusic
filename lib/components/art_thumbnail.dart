import 'package:flutter/material.dart';
import '../theme.dart';

class ArtThumbnail extends StatelessWidget {
  final double size;
  final IconData icon;

  const ArtThumbnail({
    super.key,
    required this.size,
    this.icon = Icons.music_note,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.bg3,
        borderRadius: BorderRadius.circular(AppRadius.thumbnail),
      ),
      child: Icon(
        icon,
        color: AppColors.textDim,
        size: size * 0.45,
      ),
    );
  }
}
