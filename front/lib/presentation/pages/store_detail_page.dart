import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:front/app/write_cafe_review_button.dart';
import 'package:front/core/constants/app_colors.dart';
import 'package:front/core/constants/rating_dimensions.dart';
import 'package:front/domain/entities/review.dart';
import 'package:front/presentation/providers/store_providers.dart';
import 'package:front/presentation/widgets/review_card.dart';
import 'package:go_router/go_router.dart';

// 지점 상세 화면이다.
class StoreDetailPage extends ConsumerStatefulWidget {
  final String storeId;

  const StoreDetailPage({super.key, required this.storeId});

  @override
  ConsumerState<StoreDetailPage> createState() => _StoreDetailPageState();
}

class _StoreDetailPageState extends ConsumerState<StoreDetailPage> {
  String _selectedCategory = '';

  List<MapEntry<String, double>> _scoreEntries(Map<String, double> scores) {
    final entries = scores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries;
  }

  List<String> _categoriesFromReviews(List<Review> reviews) {
    final seen = <String>{};
    final categories = <String>[];
    for (final review in reviews) {
      final category = normalizeRatingCategory(review.menuCategory);
      if (seen.contains(category)) continue;
      seen.add(category);
      if (!categoryRatingDimensions.containsKey(category)) continue;
      categories.add(category);
    }
    return categories;
  }

  List<MapEntry<String, double>> _filteredEntries(
    Map<String, double> scores,
    String selectedCategory,
  ) {
    final all = _scoreEntries(scores);
    if (selectedCategory.isEmpty) return all;

    final allowed =
        categoryRatingDimensions[selectedCategory] ?? const <String>[];
    final filtered = all.where((entry) => allowed.contains(entry.key)).toList();
    if (filtered.isEmpty) return all;
    return filtered;
  }

  @override
  // 지점 상세 정보와 리뷰를 구성한다.
  Widget build(BuildContext context) {
    final store = ref.watch(storeDetailProvider(widget.storeId));
    final breakdown = ref.watch(storeBreakdownProvider(widget.storeId));
    final reviews = ref.watch(storeReviewsProvider(widget.storeId));

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('지점 상세'),
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
                store.when(
                  data: (data) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data.name,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1F1F1F),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        data.address,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  loading: () => const LinearProgressIndicator(),
                  error: (_, _) => const Text('지점 정보를 불러오지 못했어요.'),
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
                            Builder(
                              builder: (context) {
                                final reviewedCategories =
                                    _categoriesFromReviews(
                                      reviews.asData?.value ?? const [],
                                    );
                                final selected =
                                    reviewedCategories.contains(
                                      _selectedCategory,
                                    )
                                    ? _selectedCategory
                                    : (reviewedCategories.isNotEmpty
                                          ? reviewedCategories.first
                                          : '');
                                final entries = _filteredEntries(
                                  data.scores,
                                  selected,
                                );

                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (reviewedCategories.isNotEmpty) ...[
                                      SizedBox(
                                        height: 36,
                                        child: ListView.separated(
                                          scrollDirection: Axis.horizontal,
                                          itemCount: reviewedCategories.length,
                                          separatorBuilder: (_, _) =>
                                              const SizedBox(width: 8),
                                          itemBuilder: (context, index) {
                                            final category =
                                                reviewedCategories[index];
                                            final isSelected =
                                                selected == category;
                                            return ChoiceChip(
                                              label: Text(category),
                                              selected: isSelected,
                                              onSelected: (_) {
                                                setState(() {
                                                  _selectedCategory = category;
                                                });
                                              },
                                              labelStyle: TextStyle(
                                                color: isSelected
                                                    ? Colors.white
                                                    : AppColors.textSecondary,
                                                fontWeight: FontWeight.w600,
                                              ),
                                              backgroundColor: Colors.white,
                                              selectedColor: AppColors.primary,
                                              side: BorderSide(
                                                color: isSelected
                                                    ? AppColors.primary
                                                    : AppColors.cardBorder,
                                              ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(999),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                    ],
                                    ...entries.expand(
                                      (entry) => [
                                        _ScoreProgressRow(
                                          label: ratingLabel(entry.key),
                                          value: entry.value,
                                        ),
                                        const SizedBox(height: 16),
                                      ],
                                    ),
                                  ],
                                );
                              },
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
                  error: (_, _) => const Text('점수 정보를 불러오지 못했어요.'),
                ),
                const SizedBox(height: 28),
                const Text(
                  '리뷰',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 12),
                reviews.when(
                  data: (items) => Column(
                    children: items
                        .map(
                          (review) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: ReviewCard(review: review),
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
              onPressed: () {
                final data = store.asData?.value;
                final uri = Uri(
                  path: '/review/write',
                  queryParameters: {
                    if (data != null) 'storeName': data.name,
                    if (data != null) 'address': data.address,
                    if (data != null) 'brandName': data.brandName,
                  },
                );
                context.go(uri.toString());
              },
              text: '이 지점에서 마신 메뉴 리뷰 남기기',
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


