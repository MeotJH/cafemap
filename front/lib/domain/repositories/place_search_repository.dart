import 'package:front/domain/entities/place_search_result.dart';

// 장소 검색 저장소 객체이다.
abstract class PlaceSearchRepository {
  // 주어진 쿼리로 장소를 검색한다.
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
