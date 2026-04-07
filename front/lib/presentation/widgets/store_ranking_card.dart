import 'package:flutter/material.dart';
import 'package:front/core/constants/app_colors.dart';
import 'package:front/core/constants/app_sizes.dart';
import 'package:front/core/utils/formatters.dart';
import 'package:front/domain/entities/store_ranking.dart';

const _storeRankingDefaultImageAsset = 'assets/cafe_store_default.png';

class StoreRankingCard extends StatelessWidget {
  final StoreRanking ranking;
  final int rankIndex;
  final double distanceKm;
  final VoidCallback onTap;

  const StoreRankingCard({
    super.key,
    required this.ranking,
    required this.rankIndex,
    required this.distanceKm,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppSizes.cardRadius + 6),
          border: Border.all(color: AppColors.cardBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _StoreRankBadge(rankIndex: rankIndex),
            const SizedBox(width: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: _StoreImageWithFallback(imageUrl: ranking.imageUrl),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          ranking.storeName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _StoreTypePill(isLocal: ranking.isLocal),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    ranking.brandName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _MetricChip(
                        icon: Icons.star_rounded,
                        label: RatingFormatter.score(ranking.rating),
                      ),
                      _MetricChip(
                        icon: Icons.rate_review_rounded,
                        label: '${ranking.reviewCount} 리뷰',
                      ),
                      _MetricChip(
                        icon: Icons.place_rounded,
                        label: '${distanceKm.toStringAsFixed(1)}km',
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '${ranking.topLabelA} ${RatingFormatter.score(ranking.topScoreA)}, '
                    '${ranking.topLabelB} ${RatingFormatter.score(ranking.topScoreB)}로 '
                    '좋은 평가를 받은 카페예요.',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.35,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StoreRankBadge extends StatelessWidget {
  final int rankIndex;

  const _StoreRankBadge({required this.rankIndex});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: AppColors.primary,
        shape: BoxShape.circle,
      ),
      child: Text(
        '${rankIndex + 1}',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _StoreTypePill extends StatelessWidget {
  final bool isLocal;

  const _StoreTypePill({required this.isLocal});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isLocal ? const Color(0xFFFFF3E8) : const Color(0xFFEFF2F7),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        isLocal ? '로컬' : '프랜차이즈',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: isLocal ? AppColors.primary : AppColors.textSecondary,
        ),
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetricChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F7F9),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.primary),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _StoreImageWithFallback extends StatelessWidget {
  final String imageUrl;

  const _StoreImageWithFallback({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    final url = imageUrl.trim();
    if (url.isEmpty) {
      return _buildFrame(Image.asset(_storeRankingDefaultImageAsset));
    }
    return _buildFrame(
      Image.network(
        url,
        fit: BoxFit.contain,
        webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
        errorBuilder: (context, error, stackTrace) =>
            Image.asset(_storeRankingDefaultImageAsset),
      ),
    );
  }

  Widget _buildFrame(Widget image) {
    return Container(
      width: 84,
      height: 84,
      color: const Color(0xFFF8F8F8),
      padding: const EdgeInsets.all(8),
      child: image,
    );
  }
}
