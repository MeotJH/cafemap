import 'package:front/data/mock/mock_data.dart';
import 'package:front/domain/entities/rating_breakdown.dart';
import 'package:front/domain/entities/review.dart';
import 'package:front/domain/entities/store_summary.dart';
import 'package:front/domain/repositories/store_repository.dart';

// 목업 지점 저장소 구현체다.
class MockStoreRepository implements StoreRepository {
  MockStoreRepository(this._dataSource);

  final MockDataSource _dataSource;

  @override
  // 주변 지점을 목업 데이터로 반환한다.
  Future<List<StoreSummary>> fetchNearbyStores() async {
    return _dataSource.stores();
  }

  @override
  // 지점 상세를 목업 데이터로 반환한다.
  Future<StoreSummary> fetchStoreDetail(String storeId) async {
    return _dataSource.stores().first;
  }

  @override
  // 지점 상세 점수 분해를 목업 데이터로 반환한다.
  Future<RatingBreakdown> fetchStoreBreakdown(String storeId) async {
    return _dataSource.storeBreakdown();
  }

  @override
  // 지점 리뷰 목록을 목업 데이터로 반환한다.
  Future<List<Review>> fetchStoreReviews(String storeId) async {
    return _dataSource.reviews();
  }
}
