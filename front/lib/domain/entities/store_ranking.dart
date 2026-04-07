class StoreRanking {
  final String id;
  final String storeId;
  final String storeName;
  final String brandName;
  final bool isLocal;
  final double rating;
  final double displayScore;
  final int reviewCount;
  final double distanceKm;
  final String imageUrl;
  final double lat;
  final double lng;
  final String topLabelA;
  final double topScoreA;
  final String topLabelB;
  final double topScoreB;

  const StoreRanking({
    required this.id,
    required this.storeId,
    required this.storeName,
    required this.brandName,
    required this.isLocal,
    required this.rating,
    required this.displayScore,
    required this.reviewCount,
    required this.distanceKm,
    required this.imageUrl,
    required this.lat,
    required this.lng,
    required this.topLabelA,
    required this.topScoreA,
    required this.topLabelB,
    required this.topScoreB,
  });
}
