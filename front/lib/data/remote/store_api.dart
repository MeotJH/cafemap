import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:front/domain/entities/rating_breakdown.dart';
import 'package:front/domain/entities/review.dart';
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
    address: json['address'] as String? ?? '',
    rating: (json['rating'] as num?)?.toDouble() ?? 0,
    reviewCount: json['reviewCount'] as int? ?? 0,
    distanceKm: (json['distanceKm'] as num?)?.toDouble() ?? 0,
    imageUrl: json['imageUrl'] as String? ?? '',
    lat: (json['lat'] as num?)?.toDouble() ?? 0,
    lng: (json['lng'] as num?)?.toDouble() ?? 0,
  );
}

RatingBreakdown _breakdownFromJson(Map<String, dynamic> json) {
  final scores = _scoresFromJson(json['scores']);
  return RatingBreakdown(
    scores: scores,
    overall: (json['overall'] as num?)?.toDouble() ?? 0,
  );
}

Review _reviewFromJson(Map<String, dynamic> json) {
  final scores = _scoresFromJson(json['scores']);
  return Review(
    id: json['id'] as String? ?? '',
    storeName: json['storeName'] as String? ?? '',
    brandName: json['brandName'] as String? ?? '',
    menuName: json['menuName'] as String? ?? '',
    menuCategory: json['menuCategory'] as String? ?? '',
    userEmail: json['userEmail'] as String? ?? '',
    scores: scores,
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

List<String> _imageUrlsFromJson(dynamic raw) {
  if (raw is! List<dynamic>) return const [];
  return raw
      .whereType<String>()
      .map((url) => url.trim())
      .where((url) => url.isNotEmpty)
      .toList();
}

