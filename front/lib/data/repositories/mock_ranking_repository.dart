import 'package:front/data/mock/mock_data.dart';
import 'package:front/domain/entities/brand_menu_ranking.dart';
import 'package:front/domain/entities/rating_breakdown.dart';
import 'package:front/domain/entities/review.dart';
import 'package:front/domain/repositories/ranking_repository.dart';

// 목업 랭킹 저장소 구현체다.
class MockRankingRepository implements RankingRepository {
  MockRankingRepository(this._dataSource);

  final MockDataSource _dataSource;

  @override
  // 랭킹 리스트를 목업 데이터로 반환한다.
  Future<List<BrandMenuRanking>> fetchRankings() async {
    return _dataSource.rankings();
  }

  @override
  // 랭킹 상세 분해 점수를 목업 데이터로 반환한다.
  Future<RatingBreakdown> fetchRankingBreakdown(String rankingId) async {
    return _dataSource.rankingBreakdown();
  }

  @override
  // 랭킹 리뷰 목록을 목업 데이터로 반환한다.
  Future<List<Review>> fetchRankingReviews(String rankingId) async {
    return _dataSource.reviews();
  }
}
