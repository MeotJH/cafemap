import 'package:flutter/material.dart';
import 'package:front/core/constants/app_colors.dart';
import 'package:front/core/utils/formatters.dart';

// 리뷰 작성 화면에서 사용하는 점수 입력 슬라이더다.
class RatingSlider extends StatelessWidget {
  final String label;
  final double value;
  final ValueChanged<double> onChanged;
  final bool isOverall;

  const RatingSlider({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.isOverall = false,
  });

  @override
  // 슬라이더와 라벨을 포함한 입력 UI를 그린다.
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isOverall ? AppColors.primary.withOpacity(0.08) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isOverall ? AppColors.primary.withOpacity(0.3) : AppColors.cardBorder,
          width: isOverall ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontWeight: isOverall ? FontWeight.bold : FontWeight.w600,
                  color: isOverall ? AppColors.primary : AppColors.textPrimary,
                ),
              ),
              Text(
                RatingFormatter.score(value),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isOverall ? AppColors.primary : AppColors.textPrimary,
                ),
              ),
            ],
          ),
          Slider(
            value: value,
            min: 1,
            max: 5,
            divisions: isOverall ? 40 : 8,
            onChanged: isOverall ? null : onChanged,
            activeColor: AppColors.primary,
            inactiveColor: AppColors.primary.withOpacity(0.2),
          ),
        ],
      ),
    );
  }
}
