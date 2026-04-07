import 'package:front/data/remote/review_api.dart';
import 'package:front/domain/entities/auth_context.dart';
import 'package:front/domain/entities/review.dart';
import 'package:front/domain/repositories/review_repository.dart';

// ?? API ??? ?? ??? ????.
class RemoteReviewRepository implements ReviewRepository {
  final ReviewApi _api;

  RemoteReviewRepository(this._api);

  @override
  Future<List<Review>> fetchMyReviews({AuthContext? auth}) {
    return _api.fetchMyReviews(auth: auth);
  }

  @override
  Future<Review> fetchReviewDetail(String reviewId) {
    return _api.fetchReviewDetail(reviewId);
  }

  @override
  Future<Review> createReview(ReviewCreateRequest payload, {AuthContext? auth}) {
    return _api.createReview(payload, auth: auth);
  }
}
