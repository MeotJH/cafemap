import 'package:front/data/remote/store_api.dart';
import 'package:front/domain/entities/rating_breakdown.dart';
import 'package:front/domain/entities/review.dart';
import 'package:front/domain/entities/store_summary.dart';
import 'package:front/domain/repositories/store_repository.dart';

// ?? API ??? ?? ??? ????.
class RemoteStoreRepository implements StoreRepository {
  final StoreApi _api;

  RemoteStoreRepository(this._api);

  @override
  Future<List<StoreSummary>> fetchNearbyStores({
    List<String> preferenceIds = const [],
    String mapMode = 'all',
  }) {
    return _api.fetchStores(
      preferenceIds: preferenceIds,
      mapMode: mapMode,
    );
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
  Future<List<Review>> fetchStoreReviews(String storeId) {
    return _api.fetchStoreReviews(storeId);
  }
}
