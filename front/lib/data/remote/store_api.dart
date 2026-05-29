import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:front/domain/entities/rating_breakdown.dart';
import 'package:front/domain/entities/review.dart';
import 'package:front/domain/entities/similar_store.dart';
import 'package:front/domain/entities/store_summary.dart';

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
  final scores = _scoresFromJson(json['scores']);
  return Review(
    id: json['id'] as String? ?? '',
    storeName: json['storeName'] as String? ?? '',
    address: json['address'] as String? ?? '',
    placeId: json['placeId'] as String? ?? '',
    link: json['link'] as String? ?? '',
    lat: (json['lat'] as num?)?.toDouble(),
    lng: (json['lng'] as num?)?.toDouble(),
    brandId: json['brandId'] as String? ?? '',
    temperatureOption: json['temperatureOption'] as String? ?? '',
    brandName: json['brandName'] as String? ?? '',
    menuName: json['menuName'] as String? ?? '',
    menuCategory: json['menuCategory'] as String? ?? '',
    userEmail: json['userEmail'] as String? ?? '',
    reviewerType: json['reviewerType'] as String? ?? 'USER',
    ratingSchemaVersion: (json['ratingSchemaVersion'] as num?)?.toInt() ?? 1,
    scores: scores,
    attributes: _attributesFromJson(json['attributes']),
    overall: (json['overall'] as num?)?.toDouble() ?? 0,
    comment: json['comment'] as String? ?? '',
    imageUrls: _imageUrlsFromJson(json['imageUrls']),
    createdAt: DateTime.parse(
      json['createdAt'] as String? ?? DateTime.now().toIso8601String(),
    ),
  );
}

Map<String, double> _scoresFromJson(dynamic raw) {
  if (raw is! Map<String, dynamic>) return const {};
  return {
    for (final entry in raw.entries)
      entry.key: (entry.value as num?)?.toDouble() ?? 0,
  };
}

Map<String, String> _attributesFromJson(dynamic raw) {
  if (raw is! Map<String, dynamic>) return const {};
  return {
    for (final entry in raw.entries)
      if (entry.value != null) entry.key: entry.value.toString(),
  };
}

List<String> _imageUrlsFromJson(dynamic raw) {
  return _stringListFromJson(raw);
}

List<String> _stringListFromJson(dynamic raw) {
  if (raw is! List<dynamic>) return const [];
  return raw
      .whereType<String>()
      .map((value) => value.trim())
      .where((value) => value.isNotEmpty)
      .toList();
}
