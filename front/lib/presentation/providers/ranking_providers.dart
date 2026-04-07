import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:front/domain/entities/brand_menu_ranking.dart';
import 'package:front/domain/entities/rating_breakdown.dart';
import 'package:front/domain/entities/review.dart';
import 'package:front/presentation/providers/app_providers.dart';

// 랭킹 리스트를 제공하는 FutureProvider다.
final rankingListProvider = FutureProvider<List<BrandMenuRanking>>((ref) async {
  final repository = ref.watch(rankingRepositoryProvider);
  return repository.fetchRankings();
});

// 랭킹 상세 점수 분해 데이터를 제공한다.
final rankingBreakdownProvider = FutureProvider.family<RatingBreakdown, String>((ref, rankingId) async {
  final repository = ref.watch(rankingRepositoryProvider);
  return repository.fetchRankingBreakdown(rankingId);
});

// 랭킹 상세 리뷰 리스트를 제공한다.
final rankingReviewsProvider = FutureProvider.family<List<Review>, String>((ref, rankingId) async {
  final repository = ref.watch(rankingRepositoryProvider);
  return repository.fetchRankingReviews(rankingId);
});
