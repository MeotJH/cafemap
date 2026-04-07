import 'package:flutter/material.dart';
import 'package:front/core/constants/app_colors.dart';
import 'package:front/core/utils/formatters.dart';

// 점수 항목을 한 줄로 보여주는 위젯이다.
class ScoreRow extends StatelessWidget {
  final String label;
  final double value;

  const ScoreRow({
    super.key,
    required this.label,
    required this.value,
  });

  @override
  // 항목명과 점수를 가로로 배치한다.
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textSecondary)),
        Text(
          RatingFormatter.score(value),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
