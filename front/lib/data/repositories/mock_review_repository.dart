import 'package:front/data/mock/mock_data.dart';
import 'package:front/data/remote/review_api.dart';
import 'package:front/domain/entities/auth_context.dart';
import 'package:front/domain/entities/review.dart';
import 'package:front/domain/repositories/review_repository.dart';

// ?? ?? ??? ????.
class MockReviewRepository implements ReviewRepository {
  MockReviewRepository(this._dataSource);

  final MockDataSource _dataSource;

  @override
  // ? ??? ?? ???? ????.
  Future<List<Review>> fetchMyReviews({AuthContext? auth}) async {
    return _dataSource.reviews();
  }

  @override
  Future<Review> fetchReviewDetail(String reviewId) async {
    return _dataSource.reviews().first;
  }

  @override
  Future<Review> createReview(ReviewCreateRequest payload, {AuthContext? auth}) async {
    return _dataSource.reviews().first;
  }
}
