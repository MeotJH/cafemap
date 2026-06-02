import 'package:front/data/remote/review_api.dart';
import 'package:front/domain/entities/auth_context.dart';
import 'package:front/domain/entities/review.dart';

// 리뷰를 가져오는 저장소 객체이다
abstract class ReviewRepository {
  // 내 리뷰를 가져오는 메서드이다
  Future<List<Review>> fetchMyReviews({AuthContext? auth});

  // 리뷰 상세 정보를 가져오는 메서드이다
  Future<Review> fetchReviewDetail(String reviewId);

  // 리뷰를 생성하는 메서드이다
  Future<Review> createReview(ReviewCreateRequest payload, {AuthContext? auth});

  // 리뷰를 업데이트하는 메서드이다
  Future<Review> updateReview(
    String reviewId,
    ReviewCreateRequest payload, {
    AuthContext? auth,
  });
}
