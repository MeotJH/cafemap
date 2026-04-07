import 'package:front/domain/entities/brand_menu_ranking.dart';
import 'package:front/domain/entities/rating_breakdown.dart';
import 'package:front/domain/entities/review.dart';

// 랭킹 데이터를 제공하는 저장소 인터페이스다.
abstract class RankingRepository {
  // 랭킹 목록을 조회한다.
  Future<List<BrandMenuRanking>> fetchRankings();

  // 랭킹 상세의 항목별 점수를 조회한다.
  Future<RatingBreakdown> fetchRankingBreakdown(String rankingId);

  // 랭킹 상세의 리뷰 리스트를 조회한다.
  Future<List<Review>> fetchRankingReviews(String rankingId);
}
