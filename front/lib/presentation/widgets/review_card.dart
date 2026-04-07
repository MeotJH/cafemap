import 'package:flutter/material.dart';
import 'package:front/core/constants/app_colors.dart';
import 'package:front/core/utils/formatters.dart';
import 'package:front/domain/entities/review.dart';

class ReviewCard extends StatelessWidget {
  final Review review;

  const ReviewCard({super.key, required this.review});

  @override
  Widget build(BuildContext context) {
    final isCafeMaster = _isCafeMaster(review.userEmail);
    final reviewerName = isCafeMaster
        ? '카페 마스터'
        : _reviewerDisplayName(review.userEmail);

    return Container(
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
                child: Text(
                  '${review.brandName} · ${review.menuName}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (isCafeMaster)
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
                  if (isCafeMaster) const SizedBox(height: 6),
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
        ],
      ),
    );
  }

  bool _isCafeMaster(String email) {
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
}
