import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:front/domain/entities/brand_menu_ranking.dart';
import 'package:front/domain/entities/rating_breakdown.dart';
import 'package:front/domain/entities/review.dart';
import 'package:front/domain/entities/store_ranking.dart';
import 'package:front/presentation/pages/ranking_home/ranking_home_types.dart';
import 'package:front/presentation/providers/app_providers.dart';

final rankingListProvider = FutureProvider<List<BrandMenuRanking>>((ref) async {
  final repository = ref.watch(rankingRepositoryProvider);
  return repository.fetchRankings();
});

final storeRankingListProvider =
    FutureProvider.family<List<StoreRanking>, StoreRankingQuery>((
      ref,
      query,
    ) async {
      final repository = ref.watch(rankingRepositoryProvider);
      return repository.fetchStoreRankings(
        query.audience,
        purpose: query.purpose,
      );
    });

final homeSummaryProvider = FutureProvider<HomeSummary>((ref) async {
  final repository = ref.watch(rankingRepositoryProvider);
  return repository.fetchHomeSummary();
});

final rankingBreakdownProvider = FutureProvider.family<RatingBreakdown, String>(
  (ref, rankingId) async {
    final repository = ref.watch(rankingRepositoryProvider);
    return repository.fetchRankingBreakdown(rankingId);
  },
);

final rankingReviewsProvider = FutureProvider.family<List<Review>, String>((
  ref,
  rankingId,
) async {
  final repository = ref.watch(rankingRepositoryProvider);
  return repository.fetchRankingReviews(rankingId);
});
