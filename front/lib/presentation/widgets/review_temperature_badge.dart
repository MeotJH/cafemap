import 'package:flutter/material.dart';

import 'package:front/core/constants/app_colors.dart';

class ReviewTemperatureBadge extends StatelessWidget {
  final String temperatureOption;

  const ReviewTemperatureBadge({super.key, required this.temperatureOption});

  @override
  Widget build(BuildContext context) {
    final label = _labelFor(temperatureOption);
    if (label.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FA),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: Color(0xFF475569),
        ),
      ),
    );
  }

  static String _labelFor(String value) {
    switch (value.trim().toLowerCase()) {
      case 'hot':
        return 'HOT';
      case 'ice':
        return 'ICE';
      default:
        return '';
    }
  }
}
