import 'package:front/data/remote/review_api.dart';
import 'package:front/domain/entities/auth_context.dart';
import 'package:front/domain/entities/review.dart';

// ?? ???? ???? ??? ??????.
abstract class ReviewRepository {
  // ? ?? ??? ????.
  Future<List<Review>> fetchMyReviews({AuthContext? auth});

  // ?? ??? ????.
  Future<Review> fetchReviewDetail(String reviewId);

  // ??? ????.
  Future<Review> createReview(ReviewCreateRequest payload, {AuthContext? auth});

  // ??? ??????.
  Future<Review> updateReview(
    String reviewId,
    ReviewCreateRequest payload, {
    AuthContext? auth,
  });
}
