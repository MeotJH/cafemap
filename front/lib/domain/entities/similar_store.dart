class SimilarStore {
  final String storeId;
  final String name;
  final String brandName;
  final String address;
  final double rating;
  final int reviewCount;
  final double lat;
  final double lng;
  final double similarityScore;
  final List<String> matchedDimensions;

  const SimilarStore({
    required this.storeId,
    required this.name,
    required this.brandName,
    required this.address,
    required this.rating,
    required this.reviewCount,
    required this.lat,
    required this.lng,
    required this.similarityScore,
    required this.matchedDimensions,
  });
}
