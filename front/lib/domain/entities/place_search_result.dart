// Place search result returned from the backend.
class PlaceSearchResult {
  final String name;
  final String address;
  final String roadAddress;
  final String category;
  final String phone;
  final String link;
  final String placeId;
  final int mapx;
  final int mapy;

  const PlaceSearchResult({
    required this.name,
    required this.address,
    required this.roadAddress,
    required this.category,
    required this.phone,
    required this.link,
    required this.placeId,
    required this.mapx,
    required this.mapy,
  });
}
