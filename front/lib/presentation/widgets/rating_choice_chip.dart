import 'package:flutter/material.dart';

import 'package:front/core/constants/app_colors.dart';

class RatingChoiceChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool neutral;

  const RatingChoiceChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.neutral = false,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      labelStyle: TextStyle(
        color: selected && !neutral ? Colors.white : AppColors.textSecondary,
        fontWeight: FontWeight.w600,
      ),
      backgroundColor: Colors.white,
      selectedColor: neutral ? AppColors.backgroundLight : AppColors.primary,
      side: BorderSide(
        color: selected && !neutral ? AppColors.primary : AppColors.cardBorder,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}
