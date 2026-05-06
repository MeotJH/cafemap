import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:front/core/constants/app_colors.dart';
import 'package:front/core/constants/app_sizes.dart';
import 'package:front/core/utils/formatters.dart';
import 'package:front/domain/entities/store_ranking.dart';
import 'package:front/presentation/pages/ranking_home/ranking_home_types.dart';

class StoreRankingCard extends StatelessWidget {
  final StoreRanking ranking;
  final int rankIndex;
  final double distanceKm;
  final RankingAudience audience;
  final VoidCallback onTap;

  const StoreRankingCard({
    super.key,
    required this.ranking,
    required this.rankIndex,
    required this.distanceKm,
    required this.audience,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final headlineScore = switch (audience) {
      RankingAudience.couple => ranking.coupleScore,
      RankingAudience.wife => ranking.wifeScore,
      RankingAudience.husband => ranking.husbandScore,
      RankingAudience.user => ranking.userScore,
    };

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
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _StoreBrandLogo(
                              brandName: ranking.brandName,
                              imageUrl: ranking.imageUrl,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              ranking.storeName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
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
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: _StoreTypePill(isLocal: ranking.isLocal),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _MetricChip(
                        icon: Icons.star_rounded,
                        label: RatingFormatter.score(
                          headlineScore > 0
                              ? headlineScore
                              : ranking.displayScore,
                        ),
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
                  Row(
                    children: [
                      Expanded(
                        child: _SplitScore(
                          label: '아내',
                          value: ranking.wifeScore,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _SplitScore(
                          label: '남편',
                          value: ranking.husbandScore,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    ranking.summary.isNotEmpty
                        ? ranking.summary
                        : '${ranking.topLabelA} ${RatingFormatter.score(ranking.topScoreA)}, '
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
                  if (ranking.tags.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: ranking.tags
                          .take(3)
                          .map(
                            (tag) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF6F7F9),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                tag,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SplitScore extends StatelessWidget {
  final String label;
  final double value;

  const _SplitScore({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F4EE),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value > 0 ? value.toStringAsFixed(1) : '-',
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _StoreBrandLogo extends StatelessWidget {
  final String brandName;
  final String imageUrl;

  const _StoreBrandLogo({required this.brandName, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    final url = imageUrl.trim();
    if (url.isEmpty) {
      return _StoreBrandLogoFrame(
        child: Text(
          brandName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
          ),
        ),
      );
    }
    final isSvgImage = url.toLowerCase().endsWith('.svg');
    return _StoreBrandLogoFrame(
      child: isSvgImage
          ? SizedBox.expand(
              child: SvgPicture.network(
                url,
                fit: BoxFit.contain,
                placeholderBuilder: (context) => const Center(
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 1.6),
                  ),
                ),
              ),
            )
          : SizedBox.expand(
              child: Image.network(
                url,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => Text(
                  brandName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
    );
  }
}

class _StoreBrandLogoFrame extends StatelessWidget {
  final Widget child;

  const _StoreBrandLogoFrame({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 112,
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: child,
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
