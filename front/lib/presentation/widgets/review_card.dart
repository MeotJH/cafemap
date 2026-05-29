import 'package:flutter/material.dart';
import 'package:front/core/constants/app_colors.dart';
import 'package:front/core/constants/rating_dimensions.dart';
import 'package:front/core/utils/formatters.dart';
import 'package:front/domain/entities/review.dart';
import 'package:front/presentation/widgets/review_temperature_badge.dart';

class ReviewCard extends StatelessWidget {
  final Review review;
  final VoidCallback? onTap;

  const ReviewCard({super.key, required this.review, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isWife = _isWife(review.userEmail);
    final isHusband = _isHusband(review.userEmail);
    String badgeName = '';
    if (isWife) badgeName = '아내픽';
    if (isHusband) badgeName = '남편픽';

    final reviewerName = isWife || isHusband
        ? badgeName
        : _reviewerDisplayName(review.userEmail);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          '${review.brandName} · ${review.menuName}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        if (review.temperatureOption.isNotEmpty)
                          ReviewTemperatureBadge(
                            temperatureOption: review.temperatureOption,
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (isHusband || isWife)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF2E5D8),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            'Master',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      if (isWife || isHusband) const SizedBox(height: 6),
                      Text(
                        reviewerName,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                review.storeName,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.star, size: 16, color: AppColors.ratingStar),
                  const SizedBox(width: 4),
                  Text(
                    RatingFormatter.score(review.overall),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${review.createdAt.year}.${review.createdAt.month}.${review.createdAt.day}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              if (review.comment.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(review.comment, style: const TextStyle(fontSize: 13)),
              ],
              if (_visibleAttributeLabels(review).isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final label in _visibleAttributeLabels(review).take(3))
                      _ReviewAttributeChip(label: label),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  bool _isWife(String email) {
    final normalized = email.trim().toLowerCase();
    return normalized == 'sumdubu1234@gmail.com' ||
        normalized == 'sumin940104@gmail.com';
  }

  bool _isHusband(String email) {
    final normalized = email.trim().toLowerCase();
    return normalized == 'marionette934@gmail.com' ||
        normalized == 'businesskim93@gmail.com';
  }

  String _reviewerDisplayName(String email) {
    final normalized = email.trim().toLowerCase();
    if (normalized.isEmpty) return 'unknown';
    final at = normalized.indexOf('@');
    if (at <= 0) return normalized;
    return normalized.substring(0, at);
  }

  List<String> _visibleAttributeLabels(Review review) {
    return review.attributes.entries
        .where((entry) => entry.key != 'temperature_option')
        .map((entry) => attributeValueLabel(entry.key, entry.value))
        .where((label) => label != '잘 모르겠음' && label != '미선택')
        .toList();
  }
}

class _ReviewAttributeChip extends StatelessWidget {
  final String label;

  const _ReviewAttributeChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
