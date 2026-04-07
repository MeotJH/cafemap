import 'package:front/domain/entities/rating_breakdown.dart';
import 'package:front/domain/entities/review.dart';
import 'package:front/domain/entities/store_summary.dart';

// 지점 데이터를 제공하는 저장소 인터페이스다.
abstract class StoreRepository {
  // 주변 지점 목록을 조회한다.
  Future<List<StoreSummary>> fetchNearbyStores();

  // 지점 상세 정보를 조회한다.
  Future<StoreSummary> fetchStoreDetail(String storeId);

  // 지점 상세의 항목별 점수를 조회한다.
  Future<RatingBreakdown> fetchStoreBreakdown(String storeId);

  // 지점 상세의 리뷰 리스트를 조회한다.
  Future<List<Review>> fetchStoreReviews(String storeId);
}
