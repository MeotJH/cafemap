// 리뷰 한 건을 표현하는 엔티티다.
class Review {
  final String id;
  final String storeName;
  final String brandName;
  final String menuName;
  final String menuCategory;
  final String userEmail;
  final Map<String, double> scores;
  final double overall;
  final String comment;
  final List<String> imageUrls;
  final DateTime createdAt;

  const Review({
    required this.id,
    required this.storeName,
    required this.brandName,
    required this.menuName,
    required this.menuCategory,
    required this.userEmail,
    required this.scores,
    required this.overall,
    required this.comment,
    required this.imageUrls,
    required this.createdAt,
  });
}
