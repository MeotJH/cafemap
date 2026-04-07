import 'package:flutter/material.dart';
import 'package:front/core/constants/app_colors.dart';
import 'package:front/core/utils/formatters.dart';

// 별점 배지를 표현하는 공통 위젯이다.
class RatingBadge extends StatelessWidget {
  final double rating;
  final Color? backgroundColor;
  final Color? textColor;

  const RatingBadge({
    super.key,
    required this.rating,
    this.backgroundColor,
    this.textColor,
  });

  @override
  // 별점 배지 UI를 그린다.
  Widget build(BuildContext context) {
    final bg = backgroundColor ?? AppColors.primary;
    final color = textColor ?? Colors.white;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star, size: 14, color: AppColors.ratingStar),
          const SizedBox(width: 4),
          Text(
            RatingFormatter.score(rating),
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
