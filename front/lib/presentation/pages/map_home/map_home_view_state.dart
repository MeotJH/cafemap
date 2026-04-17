import 'package:front/domain/entities/place_search_result.dart';
import 'package:front/domain/entities/store_summary.dart';
import 'package:front/presentation/providers/app_providers.dart';
import 'package:front/presentation/widgets/naver_map_view.dart';

const _sentinel = Object();

class MapHomeViewState {
  final List<PlaceSearchResult> newPlaces;
  final List<PlaceSearchResult> searchResults;
  final bool isSearching;
  final bool isPlaceSearching;
  final String? searchError;
  final String? placeSearchError;
  final StoreSummary? selectedStore;
  final PlaceSearchResult? selectedPlace;
  final double mapLat;
  final double mapLng;
  final bool isCurrentLocationResolved;
  final MapViewportData? viewport;
  final AppLocationState? lastAppliedLocation;

  const MapHomeViewState({
    required this.newPlaces,
    required this.searchResults,
    required this.isSearching,
    required this.isPlaceSearching,
    required this.searchError,
    required this.placeSearchError,
    required this.selectedStore,
    required this.selectedPlace,
    required this.mapLat,
    required this.mapLng,
    required this.isCurrentLocationResolved,
    required this.viewport,
    required this.lastAppliedLocation,
  });

  factory MapHomeViewState.initial({
    required double defaultLat,
    required double defaultLng,
  }) {
    return MapHomeViewState(
      newPlaces: const [],
      searchResults: const [],
      isSearching: false,
      isPlaceSearching: false,
      searchError: null,
      placeSearchError: null,
      selectedStore: null,
      selectedPlace: null,
      mapLat: defaultLat,
      mapLng: defaultLng,
      isCurrentLocationResolved: false,
      viewport: null,
      lastAppliedLocation: null,
    );
  }

  MapHomeViewState copyWith({
    List<PlaceSearchResult>? newPlaces,
    List<PlaceSearchResult>? searchResults,
    bool? isSearching,
    bool? isPlaceSearching,
    Object? searchError = _sentinel,
    Object? placeSearchError = _sentinel,
    Object? selectedStore = _sentinel,
    Object? selectedPlace = _sentinel,
    double? mapLat,
    double? mapLng,
    bool? isCurrentLocationResolved,
    Object? viewport = _sentinel,
    Object? lastAppliedLocation = _sentinel,
  }) {
    return MapHomeViewState(
      newPlaces: newPlaces ?? this.newPlaces,
      searchResults: searchResults ?? this.searchResults,
      isSearching: isSearching ?? this.isSearching,
      isPlaceSearching: isPlaceSearching ?? this.isPlaceSearching,
      searchError: identical(searchError, _sentinel)
          ? this.searchError
          : searchError as String?,
      placeSearchError: identical(placeSearchError, _sentinel)
          ? this.placeSearchError
          : placeSearchError as String?,
      selectedStore: identical(selectedStore, _sentinel)
          ? this.selectedStore
          : selectedStore as StoreSummary?,
      selectedPlace: identical(selectedPlace, _sentinel)
          ? this.selectedPlace
          : selectedPlace as PlaceSearchResult?,
      mapLat: mapLat ?? this.mapLat,
      mapLng: mapLng ?? this.mapLng,
      isCurrentLocationResolved:
          isCurrentLocationResolved ?? this.isCurrentLocationResolved,
      viewport: identical(viewport, _sentinel)
          ? this.viewport
          : viewport as MapViewportData?,
      lastAppliedLocation: identical(lastAppliedLocation, _sentinel)
          ? this.lastAppliedLocation
          : lastAppliedLocation as AppLocationState?,
    );
  }
}
