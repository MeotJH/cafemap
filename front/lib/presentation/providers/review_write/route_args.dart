import 'package:front/domain/entities/review.dart';

/// 리뷰 작성 플로우의 라우트 입력값 묶음.
///
/// 페이지가 네비게이션으로부터 받을 수 있는 값을 한 객체로 모아두고,
/// Riverpod 컨트롤러가 위젯 필드를 직접 읽지 않고도 생성/수정 모드를
/// 초기화할 수 있게 한다.
class ReviewWriteRouteArgs {
  final String? storeName;
  final String? address;
  final String? placeId;
  final String? link;
  final double? lat;
  final double? lng;
  final String? menuName;
  final String? brandId;
  final String? brandName;
  final String? reviewId;
  final Review? initialReview;

  const ReviewWriteRouteArgs({
    this.storeName,
    this.address,
    this.placeId,
    this.link,
    this.lat,
    this.lng,
    this.menuName,
    this.brandId,
    this.brandName,
    this.reviewId,
    this.initialReview,
  });

  @override
  bool operator ==(Object other) {
    return other is ReviewWriteRouteArgs &&
        other.storeName == storeName &&
        other.address == address &&
        other.placeId == placeId &&
        other.link == link &&
        other.lat == lat &&
        other.lng == lng &&
        other.menuName == menuName &&
        other.brandId == brandId &&
        other.brandName == brandName &&
        other.reviewId == reviewId &&
        other.initialReview?.id == initialReview?.id;
  }

  @override
  int get hashCode => Object.hash(
    storeName,
    address,
    placeId,
    link,
    lat,
    lng,
    menuName,
    brandId,
    brandName,
    reviewId,
    initialReview?.id,
  );
}
