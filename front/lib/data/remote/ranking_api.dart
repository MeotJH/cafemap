import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:front/domain/entities/brand_menu_ranking.dart';
import 'package:front/domain/entities/rating_breakdown.dart';
import 'package:front/domain/entities/review.dart';
import 'package:front/domain/entities/store_ranking.dart';
import 'package:front/presentation/pages/ranking_home/ranking_home_types.dart';

class RankingApi {
  RankingApi({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;

  String get _baseUrl => dotenv.env['API_BASE_URL'] ?? 'http://localhost:8080';

  Future<List<BrandMenuRanking>> fetchRankings() async {
    final response = await _dio.get('$_baseUrl/api/cafemap/rankings');
    final data = response.data as List<dynamic>;
    return data
        .map((item) => _rankingFromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<StoreRanking>> fetchStoreRankings(
    RankingAudience audience, {
    RankingPurpose? purpose,
  }) async {
    final response = await _dio.get(
      '$_baseUrl/api/cafemap/store-rankings',
      queryParameters: {
        'type': audience.name,
        if (purpose != null) 'purpose': purpose.queryValue,
      },
    );
    final data = response.data as List<dynamic>;
    return data
        .map((item) => _storeRankingFromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<HomeSummary> fetchHomeSummary() async {
    final response = await _dio.get('$_baseUrl/api/cafemap/home');
    final json = response.data as Map<String, dynamic>;
    return HomeSummary(
      featuredCafe: _nullableStoreRankingFromJson(json['featuredCafe']),
      wifeTop: _storeRankingListFromJson(json['wifeTop']),
      husbandTop: _storeRankingListFromJson(json['husbandTop']),
      recentCafes: _storeRankingListFromJson(json['recentCafes']),
      recommendedMenus: _recommendedMenusFromJson(json['recommendedMenus']),
    );
  }

  Future<RatingBreakdown> fetchRankingBreakdown(String rankingId) async {
    final response = await _dio.get(
      '$_baseUrl/api/cafemap/rankings/$rankingId/breakdown',
    );
    final json = response.data as Map<String, dynamic>;
    return _breakdownFromJson(json);
  }

  Future<List<Review>> fetchRankingReviews(String rankingId) async {
    final response = await _dio.get(
      '$_baseUrl/api/cafemap/rankings/$rankingId/reviews',
    );
    final data = response.data as List<dynamic>;
    return data
        .map((item) => _reviewFromJson(item as Map<String, dynamic>))
        .toList();
  }
}

List<StoreRanking> _storeRankingListFromJson(dynamic raw) {
  if (raw is! List<dynamic>) return const [];
  return raw
      .map((item) => _storeRankingFromJson(item as Map<String, dynamic>))
      .toList();
}

StoreRanking? _nullableStoreRankingFromJson(dynamic raw) {
  if (raw is! Map<String, dynamic>) return null;
  return _storeRankingFromJson(raw);
}

List<HomeRecommendedMenu> _recommendedMenusFromJson(dynamic raw) {
  if (raw is! List<dynamic>) return const [];
  return raw
      .map(
        (item) => HomeRecommendedMenu(
          menuName: (item as Map<String, dynamic>)['menuName'] as String? ?? '',
          storeName: item['storeName'] as String? ?? '',
          score: (item['score'] as num?)?.toDouble() ?? 0,
        ),
      )
      .toList();
}

StoreRanking _storeRankingFromJson(Map<String, dynamic> json) {
  return StoreRanking(
    id: json['id'] as String? ?? '',
    storeId: json['storeId'] as String? ?? '',
    storeName: json['storeName'] as String? ?? '',
    brandName: json['brandName'] as String? ?? '',
    district: json['district'] as String? ?? '',
    storeType: json['storeType'] as String? ?? 'unknown',
    isLocal: json['isLocal'] as bool? ?? false,
    link: json['link'] as String? ?? '',
    rating: (json['rating'] as num?)?.toDouble() ?? 0,
    displayScore: (json['displayScore'] as num?)?.toDouble() ?? 0,
    reviewCount: json['reviewCount'] as int? ?? 0,
    distanceKm: (json['distanceKm'] as num?)?.toDouble() ?? 0,
    imageUrl: json['imageUrl'] as String? ?? '',
    thumbnailImageUrl: json['thumbnailImageUrl'] as String? ?? '',
    imageUrls: _imageUrlsFromJson(json['imageUrls']),
    thumbnailImageUrls: _imageUrlsFromJson(json['thumbnailImageUrls']),
    lat: (json['lat'] as num?)?.toDouble() ?? 0,
    lng: (json['lng'] as num?)?.toDouble() ?? 0,
    coffeeQualityScore: (json['coffeeQualityScore'] as num?)?.toDouble() ?? 0,
    topLabelA: json['topLabelA'] as String? ?? '',
    topScoreA: (json['topScoreA'] as num?)?.toDouble() ?? 0,
    topLabelB: json['topLabelB'] as String? ?? '',
    topScoreB: (json['topScoreB'] as num?)?.toDouble() ?? 0,
    workFriendlyScore: (json['workFriendlyScore'] as num?)?.toDouble() ?? 0,
    quietnessScore: (json['quietnessScore'] as num?)?.toDouble() ?? 0,
    dessertScore: (json['dessertScore'] as num?)?.toDouble() ?? 0,
    coupleScore: (json['coupleScore'] as num?)?.toDouble() ?? 0,
    wifeScore: (json['wifeScore'] as num?)?.toDouble() ?? 0,
    husbandScore: (json['husbandScore'] as num?)?.toDouble() ?? 0,
    userScore: (json['userScore'] as num?)?.toDouble() ?? 0,
    revisitScore: (json['revisitScore'] as num?)?.toDouble() ?? 0,
    summary: json['summary'] as String? ?? '',
    tags: (json['tags'] as List<dynamic>? ?? const [])
        .whereType<String>()
        .toList(),
    latestVisitedAt: _parseDateTime(json['latestVisitedAt']),
  );
}

BrandMenuRanking _rankingFromJson(Map<String, dynamic> json) {
  return BrandMenuRanking(
    id: json['id'] as String? ?? '',
    brandId: json['brandId'] as String? ?? '',
    menuId: json['menuId'] as String? ?? '',
    brandName: json['brandName'] as String? ?? '',
    menuName: json['menuName'] as String? ?? '',
    category: json['category'] as String? ?? '',
    rating: (json['rating'] as num?)?.toDouble() ?? 0,
    reviewCount: json['reviewCount'] as int? ?? 0,
    highlightScoreA: (json['highlightScoreA'] as num?)?.toDouble() ?? 0,
    highlightLabelA: json['highlightLabelA'] as String? ?? '',
    highlightScoreB: (json['highlightScoreB'] as num?)?.toDouble() ?? 0,
    highlightLabelB: json['highlightLabelB'] as String? ?? '',
    imageUrl: json['imageUrl'] as String? ?? '',
    brandLogoUrl: json['brandLogoUrl'] as String? ?? '',
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

DateTime? _parseDateTime(dynamic raw) {
  if (raw is! String || raw.isEmpty) return null;
  return DateTime.tryParse(raw);
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
  if (raw is! List<dynamic>) return const [];
  return raw
      .whereType<String>()
      .map((url) => url.trim())
      .where((url) => url.isNotEmpty)
      .toList();
}
