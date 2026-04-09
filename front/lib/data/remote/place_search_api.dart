import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:front/domain/entities/place_search_result.dart';

// 네이버 지역 검색 API 호출을 담당한다.
class PlaceSearchApi {
  PlaceSearchApi({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;

  String get _baseUrl => dotenv.env['API_BASE_URL'] ?? 'http://localhost:8080';

  Future<List<PlaceSearchResult>> search(
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
  }) async {
    final queryParameters = <String, Object>{
      'query': query,
      'display': display,
    };
    if (lat != null) queryParameters['lat'] = lat;
    if (lng != null) queryParameters['lng'] = lng;
    if (radiusKm != null) queryParameters['radiusKm'] = radiusKm;
    if (pages != null) queryParameters['pages'] = pages;
    if (southLat != null) queryParameters['southLat'] = southLat;
    if (westLng != null) queryParameters['westLng'] = westLng;
    if (northLat != null) queryParameters['northLat'] = northLat;
    if (eastLng != null) queryParameters['eastLng'] = eastLng;

    final response = await _dio.get(
      '$_baseUrl/api/cafemap/places/search',
      queryParameters: queryParameters,
    );
    final data = response.data as List<dynamic>;
    return data
        .map((item) => _placeFromJson(item as Map<String, dynamic>))
        .toList();
  }
}

PlaceSearchResult _placeFromJson(Map<String, dynamic> json) {
  return PlaceSearchResult(
    name: json['name'] as String? ?? '',
    address: json['address'] as String? ?? '',
    roadAddress: json['roadAddress'] as String? ?? '',
    category: json['category'] as String? ?? '',
    phone: json['phone'] as String? ?? '',
    link: json['link'] as String? ?? '',
    placeId: json['placeId'] as String? ?? '',
    mapx: json['mapx'] as int? ?? 0,
    mapy: json['mapy'] as int? ?? 0,
    lat: (json['lat'] as num?)?.toDouble(),
    lng: (json['lng'] as num?)?.toDouble(),
    distanceKm: (json['distanceKm'] as num?)?.toDouble(),
  );
}
