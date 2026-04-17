import 'package:geolocator/geolocator.dart';

import 'package:front/domain/entities/place_search_result.dart';
import 'package:front/domain/entities/store_summary.dart';

class MapHomePlaceLogic {
  static const int newCafeDisplayCount = 45;

  static String buildReviewedCafeMarkerIconUrl() {
    return _buildMarkerIconUrl(
      label: '☕',
      backgroundColor: '#ECD7A9',
      borderColor: '#FFFFFF',
      textColor: '#FFFFFF',
    );
  }

  static String placeMarkerId(PlaceSearchResult place) {
    return 'place-${place.placeId}';
  }

  static String resolveAddress(PlaceSearchResult place) {
    return place.roadAddress.isNotEmpty ? place.roadAddress : place.address;
  }

  static bool hasPlaceCoords(PlaceSearchResult item) {
    return item.lat != null && item.lng != null;
  }

  static (double lat, double lng)? coordsFromPlace(PlaceSearchResult item) {
    final lat = item.lat;
    final lng = item.lng;
    if (lat == null || lng == null) return null;
    if (lat.abs() > 90 || lng.abs() > 180) return null;
    return (lat, lng);
  }

  static List<PlaceSearchResult> filterNearbyPlaces(
    List<PlaceSearchResult> items,
    List<StoreSummary> reviewedStores,
  ) {
    final nearby = items
        .where(hasPlaceCoords)
        .where((item) => !looksLikeReviewedStore(item, reviewedStores))
        .toList();
    nearby.sort((a, b) {
      final aDistance = a.distanceKm ?? double.infinity;
      final bDistance = b.distanceKm ?? double.infinity;
      return aDistance.compareTo(bDistance);
    });
    return nearby.take(newCafeDisplayCount).toList();
  }

  static bool looksLikeReviewedStore(
    PlaceSearchResult place,
    List<StoreSummary> reviewedStores,
  ) {
    final placeCoords = coordsFromPlace(place);
    if (placeCoords == null) return false;

    final placeName = _normalizeMatchText(place.name);
    for (final store in reviewedStores) {
      final storeName = _normalizeMatchText(store.name);
      final distance =
          Geolocator.distanceBetween(
            placeCoords.$1,
            placeCoords.$2,
            store.lat,
            store.lng,
          ) /
          1000;
      final sameName =
          placeName.isNotEmpty &&
          storeName.isNotEmpty &&
          (placeName.contains(storeName) || storeName.contains(placeName));
      if (sameName && distance <= 0.12) {
        return true;
      }
    }
    return false;
  }

  static String _normalizeMatchText(String value) {
    return value.replaceAll(RegExp(r'[^0-9a-zA-Z가-힣]'), '').toLowerCase();
  }

  static String _buildMarkerIconUrl({
    required String label,
    required String backgroundColor,
    required String borderColor,
    required String textColor,
  }) {
    final svg = '''
<svg xmlns="http://www.w3.org/2000/svg" width="34" height="34" viewBox="0 0 34 34">
  <circle cx="17" cy="17" r="15" fill="$backgroundColor" stroke="$borderColor" stroke-width="2"/>
  <text x="50%" y="50%" text-anchor="middle" dominant-baseline="central" font-size="16" font-weight="700" fill="$textColor">$label</text>
</svg>
''';
    return 'data:image/svg+xml;utf8,${Uri.encodeComponent(svg)}';
  }
}
