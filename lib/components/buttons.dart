import 'package:flutter/material.dart';
import '../theme.dart';

/// Square pill button with an icon and optional label below.
/// Used in header icon rows on Album, Artist, Playlist pages.
class AppIconButton extends StatelessWidget {
  final IconData icon;
  final String? label;
  final VoidCallback? onTap;
  final Color color;
  final Color iconColor;
  final double size;

  const AppIconButton({
    super.key,
    required this.icon,
    this.label,
    this.onTap,
    this.color = AppColors.bg3,
    this.iconColor = AppColors.white,
    this.size = 40,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(AppRadius.card),
            ),
            child: Icon(icon, color: iconColor, size: size * 0.48),
          ),
          if (label != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(label!, style: AppTextStyles.caption),
          ],
        ],
      ),
    );
  }
}

/// Evenly-spaced horizontal row of [AppIconButton]s.
/// Pass [expanded] true to stretch buttons to fill full width.
class AppButtonBar extends StatelessWidget {
  final List<AppIconButton> buttons;
  final bool expanded;

  const AppButtonBar({
    super.key,
    required this.buttons,
    this.expanded = true,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (int i = 0; i < buttons.length; i++) ...[
          if (i > 0) const SizedBox(width: AppSpacing.md),
          if (expanded) Expanded(child: _centered(buttons[i]))
          else _centered(buttons[i]),
        ],
      ],
    );
  }

  Widget _centered(Widget child) => Center(child: child);
}

/// Ghost text+icon button — used in Queue page (Lyrics / Queue / More row)
/// and anywhere a low-emphasis labelled action is needed.
class AppGhostButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool active;

  const AppGhostButton({
    super.key,
    required this.icon,
    required this.label,
    this.onTap,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.white : AppColors.textMuted;
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        foregroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: AppIconSize.sm, color: color),
          const SizedBox(height: AppSpacing.sm),
          Text(label, style: AppTextStyles.caption.copyWith(color: color)),
        ],
      ),
    );
  }
}
