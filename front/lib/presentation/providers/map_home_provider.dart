import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:front/domain/entities/place_search_result.dart';
import 'package:front/domain/entities/store_summary.dart';
import 'package:front/presentation/pages/map_home/map_home_place_logic.dart';
import 'package:front/presentation/pages/map_home/map_home_view_state.dart';
import 'package:front/presentation/providers/app_providers.dart';
import 'package:front/presentation/widgets/naver_map_view.dart';

class MapHomeController extends Notifier<MapHomeViewState> {
  static const int _newCafePageCount = 3;

  @override
  MapHomeViewState build() {
    return MapHomeViewState.initial(
      defaultLat: AppLocationController.defaultLat,
      defaultLng: AppLocationController.defaultLng,
    );
  }

  bool applyCurrentLocation(AppLocationState location) {
    final lastAppliedLocation = state.lastAppliedLocation;
    final changed =
        lastAppliedLocation == null ||
        (lastAppliedLocation.latitude - location.latitude).abs() > 0.000001 ||
        (lastAppliedLocation.longitude - location.longitude).abs() > 0.000001 ||
        lastAppliedLocation.fromDevice != location.fromDevice;
    if (!changed) return false;

    state = state.copyWith(
      mapLat: location.latitude,
      mapLng: location.longitude,
      isCurrentLocationResolved: location.fromDevice,
      lastAppliedLocation: location,
    );
    if (kDebugMode) {
      debugPrint('[MapHome] currentLocation=${state.mapLat},${state.mapLng}');
    }
    return true;
  }

  bool updateViewport(MapViewportData viewport) {
    final currentViewport = state.viewport;
    final hasMeaningfulChange =
        currentViewport == null ||
        (currentViewport.lat - viewport.lat).abs() > 0.000001 ||
        (currentViewport.lng - viewport.lng).abs() > 0.000001 ||
        (currentViewport.zoom - viewport.zoom).abs() > 0.001 ||
        currentViewport.southLat != viewport.southLat ||
        currentViewport.westLng != viewport.westLng ||
        currentViewport.northLat != viewport.northLat ||
        currentViewport.eastLng != viewport.eastLng;
    if (!hasMeaningfulChange) return false;

    state = state.copyWith(
      viewport: viewport,
      mapLat: viewport.lat,
      mapLng: viewport.lng,
    );
    return true;
  }

  Future<void> searchNearbyNewPlaces(List<StoreSummary> reviewedStores) async {
    final viewport = state.viewport ??
        MapViewportData(lat: state.mapLat, lng: state.mapLng, zoom: 14);

    state = state.copyWith(
      isSearching: true,
      searchError: null,
      selectedStore: null,
      selectedPlace: null,
    );

    try {
      final repository = ref.read(placeSearchRepositoryProvider);
      final results = await repository.searchPlaces(
        '카페',
        display: MapHomePlaceLogic.newCafeDisplayCount,
        lat: viewport.lat,
        lng: viewport.lng,
        pages: _newCafePageCount,
        southLat: viewport.southLat,
        westLng: viewport.westLng,
        northLat: viewport.northLat,
        eastLng: viewport.eastLng,
      );
      final filtered = MapHomePlaceLogic.filterNearbyPlaces(
        results,
        reviewedStores,
      );

      state = state.copyWith(
        newPlaces: filtered,
        searchError: filtered.isEmpty
            ? '현재 지도 영역에서 새 카페 결과가 없어요. 지도를 이동한 뒤 다시 시도해 주세요.'
            : null,
      );
    } catch (_) {
      state = state.copyWith(
        searchError: '새 카페를 찾지 못했어요. 다시 시도해 주세요.',
      );
    } finally {
      state = state.copyWith(isSearching: false);
    }
  }

  Future<void> searchPlaces(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      state = state.copyWith(
        selectedStore: null,
        selectedPlace: null,
        searchResults: const [],
        placeSearchError: null,
      );
      return;
    }

    state = state.copyWith(
      isPlaceSearching: true,
      selectedStore: null,
      selectedPlace: null,
      searchResults: const [],
      placeSearchError: null,
    );

    try {
      final repository = ref.read(placeSearchRepositoryProvider);
      final results = await repository.searchPlaces(trimmed, display: 8);
      state = state.copyWith(
        searchResults: results,
        placeSearchError: results.isEmpty ? '검색 결과가 없어요.' : null,
      );
    } catch (_) {
      state = state.copyWith(
        placeSearchError: '검색에 실패했어요. 다시 시도해 주세요.',
      );
    } finally {
      state = state.copyWith(isPlaceSearching: false);
    }
  }

  void clearSearch() {
    state = state.copyWith(
      searchResults: const [],
      placeSearchError: null,
    );
  }

  void clearNewPlaces() {
    state = state.copyWith(
      newPlaces: const [],
      searchError: null,
      selectedStore: null,
      selectedPlace: null,
      searchResults: const [],
      placeSearchError: null,
    );
  }

  void selectSearchResult(PlaceSearchResult item) {
    state = state.copyWith(
      selectedStore: null,
      selectedPlace: item,
      searchError: null,
      placeSearchError: null,
      searchResults: const [],
    );
  }

  void selectStore(StoreSummary store) {
    state = state.copyWith(
      selectedStore: store,
      selectedPlace: null,
    );
  }
}

final mapHomeControllerProvider =
    NotifierProvider<MapHomeController, MapHomeViewState>(
  MapHomeController.new,
);
