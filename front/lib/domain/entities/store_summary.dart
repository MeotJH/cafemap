// 지점 요약 정보를 표현하는 엔티티다.
class StoreSummary {
  final String id;
  final String name;
  final String brandName;
  final String storeType;
  final bool isLocal;
  final String address;
  final String link;
  final double rating;
  final double displayScore;
  final int reviewCount;
  final double distanceKm;
  final String imageUrl;
  final double lat;
  final double lng;
  final double coffeeQualityScore;
  final double workFriendlyScore;
  final double quietnessScore;
  final double dessertScore;
  final String topLabelA;
  final double topScoreA;
  final String topLabelB;
  final double topScoreB;

  const StoreSummary({
    required this.id,
    required this.name,
    required this.brandName,
    required this.storeType,
    required this.isLocal,
    required this.address,
    required this.link,
    required this.rating,
    required this.displayScore,
    required this.reviewCount,
    required this.distanceKm,
    required this.imageUrl,
    required this.lat,
    required this.lng,
    required this.coffeeQualityScore,
    required this.workFriendlyScore,
    required this.quietnessScore,
    required this.dessertScore,
    required this.topLabelA,
    required this.topScoreA,
    required this.topLabelB,
    required this.topScoreB,
  });
}
