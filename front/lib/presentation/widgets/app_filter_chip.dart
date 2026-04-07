import 'dart:math' as math;

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
    final labelStyle = TextStyle(
      color: selected ? Colors.white : AppColors.textPrimary,
    );
    final labelWidth = width ?? _measureLabelWidth(context, label, labelStyle);
    final text = Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.clip,
      softWrap: false,
      textAlign: TextAlign.center,
      style: labelStyle,
    );
    final labelWidget = SizedBox(
      width: labelWidth,
      height: 24,
      child: Center(child: text),
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
        labelStyle: labelStyle,
        label: labelWidget,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        labelPadding: const EdgeInsets.symmetric(horizontal: 2),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }

  double _measureLabelWidth(
    BuildContext context,
    String text,
    TextStyle style,
  ) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      maxLines: 1,
      textDirection: Directionality.maybeOf(context) ?? TextDirection.ltr,
      textScaler: MediaQuery.textScalerOf(context),
    )..layout();
    return math.max(1, painter.width.ceilToDouble());
  }
}
