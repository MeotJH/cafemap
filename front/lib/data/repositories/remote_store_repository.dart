import 'package:front/data/remote/store_api.dart';
import 'package:front/domain/entities/rating_breakdown.dart';
import 'package:front/domain/entities/review.dart';
import 'package:front/domain/entities/similar_store.dart';
import 'package:front/domain/entities/store_summary.dart';
import 'package:front/domain/entities/store_visit_media_page.dart';
import 'package:front/domain/repositories/store_repository.dart';

// ?? API ??? ?? ??? ????.
class RemoteStoreRepository implements StoreRepository {
  final StoreApi _api;

  RemoteStoreRepository(this._api);

  @override
  Future<List<StoreSummary>> fetchNearbyStores() {
    return _api.fetchStores();
  }

  @override
  Future<StoreSummary> fetchStoreDetail(String storeId) {
    return _api.fetchStoreDetail(storeId);
  }

  @override
  Future<RatingBreakdown> fetchStoreBreakdown(String storeId) {
    return _api.fetchStoreBreakdown(storeId);
  }

  @override
  Future<List<SimilarStore>> fetchSimilarStores(String storeId) {
    return _api.fetchSimilarStores(storeId);
  }

  @override
  Future<List<Review>> fetchStoreReviews(String storeId) {
    return _api.fetchStoreReviews(storeId);
  }

  @override
  Future<StoreVisitMediaPage> fetchStoreVisitMediaPage(
    String storeId, {
    String? cursor,
    int limit = 10,
  }) {
    return _api.fetchStoreVisitMediaPage(
      storeId,
      cursor: cursor,
      limit: limit,
    );
  }
}
