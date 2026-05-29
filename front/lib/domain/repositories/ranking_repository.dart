import 'package:front/domain/entities/brand_menu_ranking.dart';
import 'package:front/domain/entities/rating_breakdown.dart';
import 'package:front/domain/entities/review.dart';
import 'package:front/domain/entities/store_ranking.dart';
import 'package:front/presentation/pages/ranking_home/ranking_home_types.dart';

// 랭킹 데이터를 제공하는 저장소 인터페이스다.
abstract class RankingRepository {
  Future<List<BrandMenuRanking>> fetchRankings();

  Future<List<StoreRanking>> fetchStoreRankings(
    RankingAudience audience, {
    RankingPurpose? purpose,
  });

  Future<HomeSummary> fetchHomeSummary();

  Future<RatingBreakdown> fetchRankingBreakdown(String rankingId);

  Future<List<Review>> fetchRankingReviews(String rankingId);
}
