import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:front/domain/entities/rating_breakdown.dart';
import 'package:front/domain/entities/review.dart';
import 'package:front/domain/entities/similar_store.dart';
import 'package:front/domain/entities/store_summary.dart';
import 'package:front/domain/entities/store_visit_media_page.dart';
import 'package:front/data/remote/review_api.dart' show reviewFromJson;

// 지점 API 호출을 담당한다.
class StoreApi {
  StoreApi({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;

  String get _baseUrl => dotenv.env['API_BASE_URL'] ?? 'http://localhost:8080';

  Future<List<StoreSummary>> fetchStores() async {
    final response = await _dio.get('$_baseUrl/api/cafemap/stores');
    final data = response.data as List<dynamic>;
    return data
        .map((item) => _storeFromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<StoreSummary> fetchStoreDetail(String storeId) async {
    final response = await _dio.get('$_baseUrl/api/cafemap/stores/$storeId');
    return _storeFromJson(response.data as Map<String, dynamic>);
  }

  Future<RatingBreakdown> fetchStoreBreakdown(String storeId) async {
    final response = await _dio.get(
      '$_baseUrl/api/cafemap/stores/$storeId/breakdown',
    );
    final json = response.data as Map<String, dynamic>;
    return _breakdownFromJson(json);
  }

  Future<List<SimilarStore>> fetchSimilarStores(String storeId) async {
    final response = await _dio.get(
      '$_baseUrl/api/cafemap/stores/$storeId/similar',
    );
    final data = response.data as List<dynamic>;
    return data
        .map((item) => _similarStoreFromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<Review>> fetchStoreReviews(String storeId) async {
    final response = await _dio.get(
      '$_baseUrl/api/cafemap/stores/$storeId/reviews',
    );
    final data = response.data as List<dynamic>;
    return data
        .map((item) => _reviewFromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<StoreVisitMediaPage> fetchStoreVisitMediaPage(
    String storeId, {
    String? cursor,
    int limit = 10,
  }) async {
    final response = await _dio.get(
      '$_baseUrl/api/cafemap/stores/$storeId/visit-media',
      queryParameters: {
        if (cursor != null && cursor.trim().isNotEmpty) 'cursor': cursor,
        'limit': limit,
      },
    );
    final json = response.data as Map<String, dynamic>;
    return StoreVisitMediaPage(
      items: _storeMediaItemsFromJson(json['items']),
      hasMore: json['hasMore'] as bool? ?? false,
      nextCursor: json['nextCursor'] as String?,
    );
  }
}

StoreSummary _storeFromJson(Map<String, dynamic> json) {
  return StoreSummary(
    id: json['id'] as String? ?? '',
    name: json['name'] as String? ?? '',
    brandName: json['brandName'] as String? ?? '',
    storeType: json['storeType'] as String? ?? 'unknown',
    isLocal: json['isLocal'] as bool? ?? false,
    address: json['address'] as String? ?? '',
    link: json['link'] as String? ?? '',
    rating: (json['rating'] as num?)?.toDouble() ?? 0,
    displayScore: (json['displayScore'] as num?)?.toDouble() ?? 0,
    reviewCount: json['reviewCount'] as int? ?? 0,
    distanceKm: (json['distanceKm'] as num?)?.toDouble() ?? 0,
    imageUrl: json['imageUrl'] as String? ?? '',
    lat: (json['lat'] as num?)?.toDouble() ?? 0,
    lng: (json['lng'] as num?)?.toDouble() ?? 0,
    coffeeQualityScore: (json['coffeeQualityScore'] as num?)?.toDouble() ?? 0,
    workFriendlyScore: (json['workFriendlyScore'] as num?)?.toDouble() ?? 0,
    quietnessScore: (json['quietnessScore'] as num?)?.toDouble() ?? 0,
    dessertScore: (json['dessertScore'] as num?)?.toDouble() ?? 0,
    topLabelA: json['topLabelA'] as String? ?? '',
    topScoreA: (json['topScoreA'] as num?)?.toDouble() ?? 0,
    topLabelB: json['topLabelB'] as String? ?? '',
    topScoreB: (json['topScoreB'] as num?)?.toDouble() ?? 0,
    visitMediaItems: _storeMediaItemsFromJson(json['visitMediaItems']),
    hasVisitMediaMore: json['hasVisitMediaMore'] as bool? ?? false,
    visitMediaNextCursor: json['visitMediaNextCursor'] as String?,
  );
}

RatingBreakdown _breakdownFromJson(Map<String, dynamic> json) {
  final scores = _scoresFromJson(json['scores']);
  return RatingBreakdown(
    scores: scores,
    overall: (json['overall'] as num?)?.toDouble() ?? 0,
    ratingSchemaVersion: (json['ratingSchemaVersion'] as num?)?.toInt() ?? 1,
    reviewCount: json['reviewCount'] as int? ?? 0,
  );
}

SimilarStore _similarStoreFromJson(Map<String, dynamic> json) {
  return SimilarStore(
    storeId: json['storeId'] as String? ?? '',
    name: json['name'] as String? ?? '',
    brandName: json['brandName'] as String? ?? '',
    address: json['address'] as String? ?? '',
    rating: (json['rating'] as num?)?.toDouble() ?? 0,
    reviewCount: json['reviewCount'] as int? ?? 0,
    lat: (json['lat'] as num?)?.toDouble() ?? 0,
    lng: (json['lng'] as num?)?.toDouble() ?? 0,
    similarityScore: (json['similarityScore'] as num?)?.toDouble() ?? 0,
    ratingSchemaVersion: (json['ratingSchemaVersion'] as num?)?.toInt() ?? 1,
    matchedDimensions: _stringListFromJson(json['matchedDimensions']),
  );
}

Review _reviewFromJson(Map<String, dynamic> json) {
  return reviewFromJson(json);
}

Map<String, double> _scoresFromJson(dynamic raw) {
  if (raw is! Map<String, dynamic>) return const {};
  return {
    for (final entry in raw.entries)
      entry.key: (entry.value as num?)?.toDouble() ?? 0,
  };
}

List<String> _stringListFromJson(dynamic raw) {
  if (raw is! List<dynamic>) return const [];
  return raw
      .whereType<String>()
      .map((value) => value.trim())
      .where((value) => value.isNotEmpty)
      .toList();
}


List<ReviewMediaItem> _storeMediaItemsFromJson(dynamic raw) {
  if (raw is! List<dynamic>) return const [];
  return raw
      .whereType<Map<String, dynamic>>()
      .map(
        (item) => ReviewMediaItem(
          type: item['type'] as String? ?? 'image',
          url: item['url'] as String? ?? '',
          thumbnailUrl: item['thumbnailUrl'] as String? ?? '',
          durationMs: (item['durationMs'] as num?)?.toInt(),
        ),
      )
      .where((item) => item.url.trim().isNotEmpty)
      .toList();
}
