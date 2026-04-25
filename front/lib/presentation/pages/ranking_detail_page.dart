import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:front/app/write_cafe_review_button.dart';
import 'package:front/core/constants/app_colors.dart';
import 'package:front/core/constants/rating_dimensions.dart';
import 'package:front/presentation/providers/ranking_providers.dart';
import 'package:front/presentation/utils/auth_navigation.dart';
import 'package:front/presentation/widgets/review_card.dart';
import 'package:front/domain/entities/brand_menu_ranking.dart';
import 'package:go_router/go_router.dart';

// 랭킹 상세 화면이다.
class RankingDetailPage extends ConsumerWidget {
  final String rankingId;
  final BrandMenuRanking? ranking;

  const RankingDetailPage({super.key, required this.rankingId, this.ranking});

  List<MapEntry<String, double>> _scoreEntries(Map<String, double> scores) {
    final allowed = ranking == null
        ? null
        : dimensionsForCategory(ranking!.category).toSet();
    final source = allowed == null
        ? scores.entries
        : scores.entries.where((entry) => allowed.contains(entry.key));
    final entries = source.toList()..sort((a, b) => b.value.compareTo(a.value));
    if (entries.isNotEmpty || allowed == null) {
      return entries;
    }
    return scores.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
  }

  @override
  // 랭킹 상세 점수와 리뷰를 구성한다.
  Widget build(BuildContext context, WidgetRef ref) {
    final breakdown = ref.watch(rankingBreakdownProvider(rankingId));
    final reviews = ref.watch(rankingReviewsProvider(rankingId));

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('랭킹 상세'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
              children: [
                Text(
                  ranking == null
                      ? '랭킹 상세'
                      : '${ranking!.brandName} ${ranking!.menuName}',
                  style: const TextStyle(
                    fontSize: 48 / 2,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1F1F1F),
                  ),
                ),
                const SizedBox(height: 18),
                breakdown.when(
                  data: (data) => Column(
                    children: [
                      Container(
                        color: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 28),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.star,
                                  size: 52,
                                  color: AppColors.ratingStar,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  data.overall.toStringAsFixed(1),
                                  style: const TextStyle(
                                    fontSize: 58,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF0F172A),
                                    height: 1,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              '평균 별점',
                              style: TextStyle(
                                color: Color(0xFF94A3B8),
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(
                        height: 1,
                        thickness: 1,
                        color: Color(0xFFE8EDF3),
                      ),
                      Container(
                        color: Colors.white,
                        padding: const EdgeInsets.fromLTRB(16, 18, 16, 22),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(
                                  Icons.analytics_rounded,
                                  color: AppColors.primary,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  '상세 항목 평가',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            ..._scoreEntries(data.scores).expand(
                              (entry) => [
                                _ScoreProgressRow(
                                  label: ratingLabel(entry.key),
                                  value: entry.value,
                                ),
                                const SizedBox(height: 16),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  loading: () => const SizedBox(
                    height: 240,
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (_, _) => const Text('상세 점수를 불러오지 못했어요.'),
                ),
                const SizedBox(height: 28),
                const SizedBox(height: 12),
                reviews.when(
                  data: (items) => Column(
                    children: items
                        .map(
                          (review) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: ReviewCard(
                              review: review,
                              onTap: () => context.push(
                                '/review/${review.id}',
                                extra: review,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (_, _) => const Text('리뷰를 불러오지 못했어요.'),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: WriteCafeReviewButton(
              onPressed: ranking == null
                  ? null
                  : () async {
                      final isSignedIn = await ensureSignedInForReview(
                        context,
                        ref,
                      );
                      if (!isSignedIn || !context.mounted) return;
                      final uri = Uri(
                        path: '/review/select-store',
                        queryParameters: {
                          'brandId': ranking!.brandId,
                          'brandName': ranking!.brandName,
                          'menuName': ranking!.menuName,
                        },
                      );
                      context.push(uri.toString());
                    },
              text: '이 메뉴를 파는 카페를 선택하고 리뷰 남기기',
            ),
          ),
        ],
      ),
    );
  }
}

class _ScoreProgressRow extends StatelessWidget {
  final String label;
  final double value;

  const _ScoreProgressRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final safeValue = value.clamp(0.0, 5.0);

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF334155),
                fontSize: 17,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '${safeValue.toStringAsFixed(1)} / 5.0',
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 9),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            minHeight: 12,
            value: safeValue / 5.0,
            backgroundColor: const Color(0xFFE7ECF2),
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
      ],
    );
  }
}
