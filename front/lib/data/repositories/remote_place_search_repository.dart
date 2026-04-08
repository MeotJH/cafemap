import 'package:front/data/remote/place_search_api.dart';
import 'package:front/domain/entities/place_search_result.dart';
import 'package:front/domain/repositories/place_search_repository.dart';

// ?먭꺽 API 湲곕컲???μ냼 寃????μ냼 援ы쁽泥대떎.
class RemotePlaceSearchRepository implements PlaceSearchRepository {
  final PlaceSearchApi _api;

  RemotePlaceSearchRepository(this._api);

  @override
  Future<List<PlaceSearchResult>> searchPlaces(
    String query, {
    int display = 5,
    double? lat,
    double? lng,
    double? radiusKm,
    int? pages,
  }) {
    return _api.search(
      query,
      display: display,
      lat: lat,
      lng: lng,
      radiusKm: radiusKm,
      pages: pages,
    );
  }
}
