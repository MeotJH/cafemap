import 'package:front/domain/entities/place_search_result.dart';

// ?μ냼 寃???곗씠?곕? ?쒓났?섎뒗 ??μ냼 ?명꽣?섏씠?ㅻ떎.
abstract class PlaceSearchRepository {
  // ?ㅼ썙?쒕줈 ?μ냼瑜?寃?됲븳??
  Future<List<PlaceSearchResult>> searchPlaces(
    String query, {
    int display = 5,
    double? lat,
    double? lng,
    double? radiusKm,
    int? pages,
    double? southLat,
    double? westLng,
    double? northLat,
    double? eastLng,
  });
}
