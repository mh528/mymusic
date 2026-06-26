import 'package:flutter/material.dart';
import '../../theme.dart';

class ContentTabBar extends StatelessWidget {
  final List<String> tabs;
  final int selectedIndex;
  final ValueChanged<int> onTabChanged;

  const ContentTabBar({
    super.key,
    required this.tabs,
    required this.selectedIndex,
    required this.onTabChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 56,
          child: ColoredBox(
            color: AppColors.black,
            child: Row(
              children: [
                for (int i = 0; i < tabs.length; i++)
                  Expanded(
                    child: _TabItem(
                      label: tabs[i],
                      isSelected: i == selectedIndex,
                      onTap: () => onTabChanged(i),
                    ),
                  ),
              ],
            ),
          ),
        ),
        Divider(height: 1, thickness: 1, color: AppColors.divider),
      ],
    );
  }
}

class _TabItem extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TabItem({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.topCenter,
      children: [
        TextButton(
          onPressed: onTap,
          style: TextButton.styleFrom(
            foregroundColor: isSelected ? AppColors.white : AppColors.textMuted,
            padding: EdgeInsets.zero,
            minimumSize: const Size.fromHeight(56),
            shape: const RoundedRectangleBorder(),
          ),
          child: Text(
            label,
            style: isSelected ? AppTextStyles.tabActive : AppTextStyles.tabInactive,
          ),
        ),
        if (isSelected)
          Container(
            height: 2,
            color: AppColors.white,
          ),
      ],
    );
  }
}
