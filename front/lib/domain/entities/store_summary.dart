// 지점 요약 정보를 표현하는 엔티티다.
class StoreSummary {
  final String id;
  final String name;
  final String brandName;
  final String address;
  final double rating;
  final int reviewCount;
  final double distanceKm;
  final String imageUrl;
  final double lat;
  final double lng;

  const StoreSummary({
    required this.id,
    required this.name,
    required this.brandName,
    required this.address,
    required this.rating,
    required this.reviewCount,
    required this.distanceKm,
    required this.imageUrl,
    required this.lat,
    required this.lng,
  });
}
