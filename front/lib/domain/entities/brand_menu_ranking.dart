// 브랜드-메뉴 랭킹 정보를 표현하는 엔티티다.
class BrandMenuRanking {
  final String id;
  final String brandId;
  final String menuId;
  final String brandName;
  final String menuName;
  final String category;
  final double rating;
  final int reviewCount;
  final double highlightScoreA;
  final String highlightLabelA;
  final double highlightScoreB;
  final String highlightLabelB;
  final String imageUrl;
  final String brandLogoUrl;

  const BrandMenuRanking({
    required this.id,
    required this.brandId,
    required this.menuId,
    required this.brandName,
    required this.menuName,
    required this.category,
    required this.rating,
    required this.reviewCount,
    required this.highlightScoreA,
    required this.highlightLabelA,
    required this.highlightScoreB,
    required this.highlightLabelB,
    required this.imageUrl,
    required this.brandLogoUrl,
  });
}
