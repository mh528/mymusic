import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../theme.dart';

class ArtThumbnail extends StatelessWidget {
  final double size;
  final IconData icon;
  final String? thumbnailUrl;
  final Uint8List? artBytes;

  const ArtThumbnail({
    super.key,
    required this.size,
    this.icon = Icons.music_note,
    this.thumbnailUrl,
    this.artBytes,
  });

  @override
  Widget build(BuildContext context) {
    final Widget placeholder = Container(
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

    ImageProvider? imageProvider;
    if (artBytes != null) {
      imageProvider = MemoryImage(artBytes!);
    } else if (thumbnailUrl != null) {
      imageProvider = NetworkImage(thumbnailUrl!);
    }

    if (imageProvider == null) return placeholder;

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.thumbnail),
      child: Image(
        image: imageProvider,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => placeholder,
      ),
    );
  }
}
