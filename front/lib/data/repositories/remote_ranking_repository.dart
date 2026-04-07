import 'package:front/data/remote/ranking_api.dart';
import 'package:front/domain/entities/brand_menu_ranking.dart';
import 'package:front/domain/entities/rating_breakdown.dart';
import 'package:front/domain/entities/review.dart';
import 'package:front/domain/repositories/ranking_repository.dart';

// ?? API ??? ?? ??? ????.
class RemoteRankingRepository implements RankingRepository {
  RemoteRankingRepository(this._api);

  final RankingApi _api;

  @override
  // ?? ??? ?? API? ????.
  Future<List<BrandMenuRanking>> fetchRankings() async {
    return _api.fetchRankings();
  }

  @override
  // ?? ?? ?? ??? ?? API? ????.
  Future<RatingBreakdown> fetchRankingBreakdown(String rankingId) async {
    return _api.fetchRankingBreakdown(rankingId);
  }

  @override
  // ?? ?? ??? ?? API? ????.
  Future<List<Review>> fetchRankingReviews(String rankingId) async {
    return _api.fetchRankingReviews(rankingId);
  }
}
