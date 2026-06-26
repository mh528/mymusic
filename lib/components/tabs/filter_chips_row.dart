import 'package:flutter/material.dart';
import '../../theme.dart';

class FilterChipsRow<T> extends StatelessWidget {
  final List<T> options;
  final T selected;
  final String Function(T) label;
  final ValueChanged<T> onSelected;

  const FilterChipsRow({
    super.key,
    required this.options,
    required this.selected,
    required this.label,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          for (int i = 0; i < options.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            ChoiceChip(
              label: Text(label(options[i])),
              selected: options[i] == selected,
              onSelected: (_) => onSelected(options[i]),
              selectedColor: AppColors.white,
              backgroundColor: Colors.transparent,
              labelStyle: AppTextStyles.chipLabel.copyWith(
                color: options[i] == selected ? AppColors.black : AppColors.textMuted,
              ),
              side: BorderSide(
                color: options[i] == selected ? AppColors.white : AppColors.divider,
              ),
              showCheckmark: false,
            ),
          ],
        ],
      ),
    );
  }
}
