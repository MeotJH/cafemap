// 리뷰 한 건을 표현하는 엔티티다.
class Review {
  final String id;
  final String storeName;
  final String address;
  final String placeId;
  final String link;
  final double? lat;
  final double? lng;
  final String brandId;
  final String temperatureOption;
  final String brandName;
  final String menuName;
  final String menuCategory;
  final String userEmail;
  final String reviewerType;
  final Map<String, double> scores;
  final double overall;
  final String comment;
  final List<String> imageUrls;
  final DateTime createdAt;

  const Review({
    required this.id,
    required this.storeName,
    required this.address,
    required this.placeId,
    required this.link,
    this.lat,
    this.lng,
    required this.brandId,
    required this.temperatureOption,
    required this.brandName,
    required this.menuName,
    required this.menuCategory,
    required this.userEmail,
    required this.reviewerType,
    required this.scores,
    required this.overall,
    required this.comment,
    required this.imageUrls,
    required this.createdAt,
  });
}
