import 'package:flutter/material.dart';
import 'package:front/core/constants/app_colors.dart';

// 怨듯넻 ?꾪꽣 移?UI瑜??쒗쁽?쒕떎.
class AppFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final ValueChanged<String> onSelected;
  final double? width;
  final EdgeInsetsGeometry margin;

  const AppFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onSelected,
    this.width,
    this.margin = const EdgeInsets.only(right: 3),
  });

  @override
  Widget build(BuildContext context) {
    final labelWidget = width == null
        ? Text(
            label,
            textAlign: TextAlign.center,
          )
        : SizedBox(
            width: width,
            height: 24,
            child: Center(
              child: Text(
                label,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                softWrap: false,
              ),
            ),
          );

    return Container(
      margin: margin,
      child: FilterChip(
        selected: selected,
        onSelected: (_) => onSelected(label),
        showCheckmark: false,
        checkmarkColor: Colors.transparent,
        backgroundColor: Colors.white,
        selectedColor: AppColors.primary,
        side: BorderSide(
          color: selected ? AppColors.primary : AppColors.cardBorder,
        ),
        labelStyle: TextStyle(
          color: selected ? Colors.white : AppColors.textPrimary,
        ),
        label: labelWidget,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        labelPadding: const EdgeInsets.symmetric(horizontal: 2),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}
