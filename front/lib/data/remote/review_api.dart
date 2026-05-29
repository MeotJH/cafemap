import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:front/domain/entities/auth_context.dart';
import 'package:front/domain/entities/review.dart';

// 리뷰 API 호출을 담당한다.
class ReviewApi {
  ReviewApi({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                connectTimeout: const Duration(seconds: 8),
                receiveTimeout: const Duration(seconds: 8),
                sendTimeout: const Duration(seconds: 8),
              ),
            );

  final Dio _dio;

  String get _baseUrl => dotenv.env['API_BASE_URL'] ?? 'http://localhost:8080';

  Future<Review> createReview(
    ReviewCreateRequest payload, {
    AuthContext? auth,
  }) async {
    final headers = _authHeaders(auth);
    final response = await _dio.post(
      '$_baseUrl/api/cafemap/reviews',
      data: payload.toJson(),
      options: Options(headers: headers.isEmpty ? null : headers),
    );
    return _reviewFromJson(response.data as Map<String, dynamic>);
  }

  Future<Review> updateReview(
    String reviewId,
    ReviewCreateRequest payload, {
    AuthContext? auth,
  }) async {
    final headers = _authHeaders(auth);
    final response = await _dio.put(
      '$_baseUrl/api/cafemap/reviews/$reviewId',
      data: payload.toJson(),
      options: Options(headers: headers.isEmpty ? null : headers),
    );
    return _reviewFromJson(response.data as Map<String, dynamic>);
  }

  Future<List<Review>> fetchMyReviews({AuthContext? auth}) async {
    final headers = _authHeaders(auth);
    final response = await _dio.get(
      '$_baseUrl/api/cafemap/reviews/me',
      options: Options(headers: headers.isEmpty ? null : headers),
    );
    final data = response.data as List<dynamic>;
    return data
        .map((item) => _reviewFromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<Review> fetchReviewDetail(String reviewId) async {
    final response = await _dio.get('$_baseUrl/api/cafemap/reviews/$reviewId');
    return _reviewFromJson(response.data as Map<String, dynamic>);
  }

  Future<ReviewImagePresignResponse> requestReviewImagePresign(
    ReviewImagePresignRequest payload, {
    AuthContext? auth,
  }) async {
    final headers = _authHeaders(auth);
    final response = await _dio.post(
      '$_baseUrl/api/cafemap/uploads/review-images/presign',
      data: payload.toJson(),
      options: Options(headers: headers.isEmpty ? null : headers),
    );
    final data = response.data as Map<String, dynamic>;
    return ReviewImagePresignResponse(
      uploadUrl: data['uploadUrl'] as String? ?? '',
      fileUrl: data['fileUrl'] as String? ?? '',
    );
  }

  Future<void> uploadToPresignedUrl({
    required String uploadUrl,
    required List<int> bytes,
    required String contentType,
  }) async {
    await _dio.put(
      uploadUrl,
      data: bytes,
      options: Options(headers: <String, String>{'Content-Type': contentType}),
    );
  }

  Map<String, String> _authHeaders(AuthContext? auth) {
    if (auth == null) return const {};
    return <String, String>{
      'Authorization': 'Bearer ${auth.toAuthorizationToken()}',
    };
  }
}

// 리뷰 생성 요청 모델이다.
class ReviewCreateRequest {
  final String storeName;
  final String address;
  final String placeId;
  final String link;
  final String temperatureOption;
  final double? lat;
  final double? lng;
  final String brandId;
  final String menuName;
  final int ratingSchemaVersion;
  final Map<String, double> scores;
  final Map<String, double> storeScores;
  final Map<String, String> attributes;
  final double overall;
  final String comment;
  final List<String> imageUrls;

  const ReviewCreateRequest({
    required this.storeName,
    required this.address,
    required this.placeId,
    required this.link,
    required this.temperatureOption,
    this.lat,
    this.lng,
    required this.brandId,
    required this.menuName,
    this.ratingSchemaVersion = 1,
    required this.scores,
    required this.storeScores,
    this.attributes = const {},
    required this.overall,
    required this.comment,
    required this.imageUrls,
  });

  Map<String, dynamic> toJson() => {
        'storeName': storeName,
        'address': address,
        'placeId': placeId,
        'link': link,
        'temperatureOption': temperatureOption,
        'lat': lat,
        'lng': lng,
        'brandId': brandId,
        'menuName': menuName,
        'ratingSchemaVersion': ratingSchemaVersion,
        'scores': scores,
        'storeScores': storeScores,
        'attributes': attributes,
        'overall': overall,
        'comment': comment,
        'imageUrls': imageUrls,
      };
}

class ReviewImagePresignRequest {
  final String fileName;
  final String contentType;

  const ReviewImagePresignRequest({
    required this.fileName,
    required this.contentType,
  });

  Map<String, dynamic> toJson() => {
        'fileName': fileName,
        'contentType': contentType,
      };
}

class ReviewImagePresignResponse {
  final String uploadUrl;
  final String fileUrl;

  const ReviewImagePresignResponse({
    required this.uploadUrl,
    required this.fileUrl,
  });
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
  if (raw is! List<dynamic>) return const [];
  return raw
      .whereType<String>()
      .map((url) => url.trim())
      .where((url) => url.isNotEmpty)
      .toList();
}
