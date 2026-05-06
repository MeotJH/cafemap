import 'package:front/data/remote/ranking_api.dart';
import 'package:front/domain/entities/brand_menu_ranking.dart';
import 'package:front/domain/entities/rating_breakdown.dart';
import 'package:front/domain/entities/review.dart';
import 'package:front/domain/entities/store_ranking.dart';
import 'package:front/domain/repositories/ranking_repository.dart';
import 'package:front/presentation/pages/ranking_home/ranking_home_types.dart';

class RemoteRankingRepository implements RankingRepository {
  RemoteRankingRepository(this._api);

  final RankingApi _api;

  @override
  Future<List<BrandMenuRanking>> fetchRankings() async {
    return _api.fetchRankings();
  }

  @override
  Future<List<StoreRanking>> fetchStoreRankings(
    RankingAudience audience,
  ) async {
    return _api.fetchStoreRankings(audience);
  }

  @override
  Future<HomeSummary> fetchHomeSummary() async {
    return _api.fetchHomeSummary();
  }

  @override
  Future<RatingBreakdown> fetchRankingBreakdown(String rankingId) async {
    return _api.fetchRankingBreakdown(rankingId);
  }

  @override
  Future<List<Review>> fetchRankingReviews(String rankingId) async {
    return _api.fetchRankingReviews(rankingId);
  }
}
