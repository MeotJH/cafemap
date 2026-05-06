import 'package:front/data/mock/mock_data.dart';
import 'package:front/domain/entities/brand_menu_ranking.dart';
import 'package:front/domain/entities/rating_breakdown.dart';
import 'package:front/domain/entities/review.dart';
import 'package:front/domain/entities/store_ranking.dart';
import 'package:front/domain/repositories/ranking_repository.dart';
import 'package:front/presentation/pages/ranking_home/ranking_home_types.dart';

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
  Future<List<StoreRanking>> fetchStoreRankings(
    RankingAudience audience,
  ) async {
    return _dataSource.storeRankings();
  }

  @override
  Future<HomeSummary> fetchHomeSummary() async {
    final rankings = _dataSource.storeRankings();
    return HomeSummary(
      featuredCafe: rankings.isNotEmpty ? rankings.first : null,
      wifeTop: rankings,
      husbandTop: rankings,
      recentCafes: rankings,
      recommendedMenus: const [
        HomeRecommendedMenu(
          menuName: '아메리카노',
          storeName: '홍대 로컬 카페',
          score: 4.6,
        ),
      ],
    );
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
