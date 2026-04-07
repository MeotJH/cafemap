import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:front/domain/entities/rating_breakdown.dart';
import 'package:front/domain/entities/review.dart';
import 'package:front/domain/entities/store_summary.dart';
import 'package:front/presentation/providers/app_providers.dart';

// 주변 지점 리스트를 제공하는 FutureProvider다.
final nearbyStoresProvider = FutureProvider<List<StoreSummary>>((ref) async {
  final repository = ref.watch(storeRepositoryProvider);
  return repository.fetchNearbyStores();
});

// 지점 상세 정보를 제공한다.
final storeDetailProvider = FutureProvider.family<StoreSummary, String>((ref, storeId) async {
  final repository = ref.watch(storeRepositoryProvider);
  return repository.fetchStoreDetail(storeId);
});

// 지점 상세 점수 분해 데이터를 제공한다.
final storeBreakdownProvider = FutureProvider.family<RatingBreakdown, String>((ref, storeId) async {
  final repository = ref.watch(storeRepositoryProvider);
  return repository.fetchStoreBreakdown(storeId);
});

// 지점 리뷰 리스트를 제공한다.
final storeReviewsProvider = FutureProvider.family<List<Review>, String>((ref, storeId) async {
  final repository = ref.watch(storeRepositoryProvider);
  return repository.fetchStoreReviews(storeId);
});
