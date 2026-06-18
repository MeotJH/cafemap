import 'package:front/domain/entities/review.dart';

/// 리뷰 제출 이후 컨트롤러가 페이지에 돌려주는 결과 객체.
///
/// 페이지 셸은 이 값을 보고
/// - 토스트를 띄울지
/// - 인증 화면으로 보낼지
/// - 상세 화면으로 이동할지
/// 를 결정한다.
class ReviewWriteSubmissionResult {
  final Review? review;
  final String? message;
  final bool needsAuth;

  const ReviewWriteSubmissionResult({
    this.review,
    this.message,
    this.needsAuth = false,
  });

  bool get isSuccess => review != null;
}
