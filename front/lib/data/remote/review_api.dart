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
      'Authorization': 'Bearer ${auth.toAuthorizationToken()}'
    };
  }
}

// 리뷰 생성 요청 모델이다.
class ReviewCreateRequest {
  final String storeName;
  final String address;
  final String placeId;
  final String brandId;
  final String menuName;
  final Map<String, double> scores;
  final Map<String, double> storeScores;
  final double overall;
  final String comment;
  final List<String> imageUrls;

  const ReviewCreateRequest({
    required this.storeName,
    required this.address,
    required this.placeId,
    required this.brandId,
    required this.menuName,
    required this.scores,
    required this.storeScores,
    required this.overall,
    required this.comment,
    required this.imageUrls,
  });

  Map<String, dynamic> toJson() => {
        'storeName': storeName,
        'address': address,
        'placeId': placeId,
        'brandId': brandId,
        'menuName': menuName,
        'scores': scores,
        'storeScores': storeScores,
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
