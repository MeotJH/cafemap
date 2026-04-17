// ignore_for_file: use_null_aware_elements

import 'package:front/domain/entities/place_search_result.dart';
import 'package:front/domain/entities/store_summary.dart';
import 'package:front/presentation/pages/map_home/map_home_place_logic.dart';
import 'package:front/presentation/widgets/naver_map_view.dart';

class MapHomeMarkerBundle {
  final List<MapMarkerData> markers;
  final Map<String, StoreSummary> storeById;
  final Map<String, PlaceSearchResult> placeById;

  const MapHomeMarkerBundle({
    required this.markers,
    required this.storeById,
    required this.placeById,
  });

  factory MapHomeMarkerBundle.fromData({
    required List<StoreSummary> reviewedStores,
    required List<PlaceSearchResult> newPlaces,
    required List<PlaceSearchResult> searchResults,
    required PlaceSearchResult? selectedPlace,
    required String reviewedCafeMarkerIconUrl,
  }) {
    final reviewedMarkers = reviewedStores
        .map(
          (store) => MapMarkerData(
            id: store.id,
            lat: store.lat,
            lng: store.lng,
            caption: store.name,
            description: store.address,
            iconUrl: reviewedCafeMarkerIconUrl,
            badgeText: '☕',
          ),
        )
        .toList();

    final newPlaceMarkers = newPlaces
        .map(_placeMarker)
        .whereType<MapMarkerData>()
        .toList();

    final searchResultMarkers = searchResults
        .where(
          (place) => !newPlaces.any((item) => item.placeId == place.placeId),
        )
        .map(_placeMarker)
        .whereType<MapMarkerData>()
        .toList();

    final selectedPlaceMarker = (() {
      final place = selectedPlace;
      if (place == null) return null;
      if (newPlaces.any((item) => item.placeId == place.placeId) ||
          searchResults.any((item) => item.placeId == place.placeId)) {
        return null;
      }
      return _placeMarker(place);
    })();

    final placeItems = [
      ...newPlaces,
      ...searchResults,
      ...[if (selectedPlace != null) selectedPlace],
    ];

    return MapHomeMarkerBundle(
      markers: [
        ...reviewedMarkers,
        ...newPlaceMarkers,
        ...searchResultMarkers,
        ...[if (selectedPlaceMarker != null) selectedPlaceMarker],
      ],
      storeById: {for (final store in reviewedStores) store.id: store},
      placeById: {
        for (final place in placeItems)
          MapHomePlaceLogic.placeMarkerId(place): place,
      },
    );
  }

  static MapMarkerData? _placeMarker(PlaceSearchResult place) {
    final coords = MapHomePlaceLogic.coordsFromPlace(place);
    if (coords == null) return null;
    return MapMarkerData(
      id: MapHomePlaceLogic.placeMarkerId(place),
      lat: coords.$1,
      lng: coords.$2,
      caption: place.name,
      description: MapHomePlaceLogic.resolveAddress(place),
      useDefaultMarker: true,
    );
  }
}
