// ignore_for_file: use_null_aware_elements

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:front/domain/entities/place_search_result.dart';
import 'package:front/domain/entities/store_summary.dart';
import 'package:front/presentation/pages/map_home/map_home_marker_bundle.dart';
import 'package:front/presentation/pages/map_home/map_home_place_logic.dart';
import 'package:front/presentation/pages/map_home/map_home_view_state.dart';
import 'package:front/presentation/pages/map_home/map_home_widgets.dart';
import 'package:front/presentation/providers/app_providers.dart';
import 'package:front/presentation/providers/store_providers.dart';
import 'package:front/presentation/utils/auth_navigation.dart';
import 'package:front/presentation/utils/external_link.dart';
import 'package:front/presentation/widgets/naver_map_view.dart';

class MapHomePage extends ConsumerStatefulWidget {
  const MapHomePage({super.key});

  @override
  ConsumerState<MapHomePage> createState() => _MapHomePageState();
}

class _MapHomePageState extends ConsumerState<MapHomePage> {
  static const int _newCafePageCount = 3;
  static const double _markerFocusOffsetMeters = 140;

  final _searchController = TextEditingController();
  final _reviewedCafeMarkerIconUrl =
      MapHomePlaceLogic.buildReviewedCafeMarkerIconUrl();

  late MapHomeViewState _viewState;
  NaverMapController? _mapController;
  bool _cameraIdleUpdateQueued = false;

  @override
  void initState() {
    super.initState();
    _viewState = MapHomeViewState.initial(
      defaultLat: AppLocationController.defaultLat,
      defaultLng: AppLocationController.defaultLng,
    );
    final location = ref.read(currentLocationProvider);
    _applyCurrentLocation(location, focusMap: false);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _handleMapReady(dynamic controller) {
    if (controller is NaverMapController) {
      _mapController = controller;
      if (_viewState.isCurrentLocationResolved) {
        _focusMapTo(_viewState.mapLat, _viewState.mapLng, zoom: 15);
      }
    }

    final selectedStore = _viewState.selectedStore;
    if (selectedStore != null) {
      _focusStoreOnMap(selectedStore);
    }
  }

  Future<void> _focusStoreOnMap(StoreSummary store) async {
    await _focusMarkerOnMap(store.lat, store.lng, zoom: 16);
  }

  Future<void> _focusMapTo(
    double lat,
    double lng, {
    required double zoom,
  }) async {
    final controller = _mapController;
    if (controller == null) return;

    final update = NCameraUpdate.scrollAndZoomTo(
      target: NLatLng(lat, lng),
      zoom: zoom,
    );
    update.setAnimation(duration: const Duration(milliseconds: 450));
    await controller.updateCamera(update);
  }

  Future<void> _focusMarkerOnMap(
    double lat,
    double lng, {
    required double zoom,
  }) async {
    final adjustedLat = lat - (_markerFocusOffsetMeters / 111320.0);
    await _focusMapTo(adjustedLat, lng, zoom: zoom);
  }

  Future<void> _applyCurrentLocation(
    AppLocationState location, {
    required bool focusMap,
  }) async {
    final lastAppliedLocation = _viewState.lastAppliedLocation;
    final changed =
        lastAppliedLocation == null ||
        (lastAppliedLocation.latitude - location.latitude).abs() > 0.000001 ||
        (lastAppliedLocation.longitude - location.longitude).abs() > 0.000001 ||
        lastAppliedLocation.fromDevice != location.fromDevice;
    if (!changed || !mounted) return;

    setState(() {
      _viewState = _viewState.copyWith(
        mapLat: location.latitude,
        mapLng: location.longitude,
        isCurrentLocationResolved: location.fromDevice,
        lastAppliedLocation: location,
      );
    });

    if (kDebugMode) {
      debugPrint(
        '[MapHome] currentLocation=${_viewState.mapLat},${_viewState.mapLng}',
      );
    }
    if (focusMap && _viewState.isCurrentLocationResolved) {
      await _focusMapTo(_viewState.mapLat, _viewState.mapLng, zoom: 15);
    }
  }

  Future<void> _searchNearbyNewPlaces(List<StoreSummary> reviewedStores) async {
    final viewport = _viewState.viewport ??
        MapViewportData(
          lat: _viewState.mapLat,
          lng: _viewState.mapLng,
          zoom: 14,
        );

    setState(() {
      _viewState = _viewState.copyWith(
        isSearching: true,
        searchError: null,
        selectedStore: null,
        selectedPlace: null,
      );
    });

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

      setState(() {
        _viewState = _viewState.copyWith(
          newPlaces: filtered,
          searchError: filtered.isEmpty
              ? '현재 지도 영역에서 새 카페 결과가 없어요. 지도를 이동한 뒤 다시 시도해 주세요.'
              : null,
        );
      });
    } catch (_) {
      setState(() {
        _viewState = _viewState.copyWith(
          searchError: '새 카페를 찾지 못했어요. 다시 시도해 주세요.',
        );
      });
    } finally {
      if (mounted) {
        setState(() {
          _viewState = _viewState.copyWith(isSearching: false);
        });
      }
    }
  }

  void _handleCameraIdle(MapViewportData viewport) {
    if (!mounted) return;

    final currentViewport = _viewState.viewport;
    final hasMeaningfulChange =
        currentViewport == null ||
        (currentViewport.lat - viewport.lat).abs() > 0.000001 ||
        (currentViewport.lng - viewport.lng).abs() > 0.000001 ||
        (currentViewport.zoom - viewport.zoom).abs() > 0.001 ||
        currentViewport.southLat != viewport.southLat ||
        currentViewport.westLng != viewport.westLng ||
        currentViewport.northLat != viewport.northLat ||
        currentViewport.eastLng != viewport.eastLng;
    if (!hasMeaningfulChange) return;

    void applyViewport() {
      if (!mounted) return;
      setState(() {
        _viewState = _viewState.copyWith(
          viewport: viewport,
          mapLat: viewport.lat,
          mapLng: viewport.lng,
        );
      });
    }

    final schedulerPhase = SchedulerBinding.instance.schedulerPhase;
    final isBuildPhase =
        schedulerPhase == SchedulerPhase.transientCallbacks ||
        schedulerPhase == SchedulerPhase.midFrameMicrotasks ||
        schedulerPhase == SchedulerPhase.persistentCallbacks;

    if (isBuildPhase) {
      if (_cameraIdleUpdateQueued) return;
      _cameraIdleUpdateQueued = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _cameraIdleUpdateQueued = false;
        applyViewport();
      });
      return;
    }

    applyViewport();
  }

  Future<void> _searchPlaces(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      setState(() {
        _viewState = _viewState.copyWith(
          selectedStore: null,
          selectedPlace: null,
          searchResults: const [],
          placeSearchError: null,
        );
      });
      return;
    }

    setState(() {
      _viewState = _viewState.copyWith(
        isPlaceSearching: true,
        selectedStore: null,
        selectedPlace: null,
        searchResults: const [],
        placeSearchError: null,
      );
    });

    try {
      final repository = ref.read(placeSearchRepositoryProvider);
      final results = await repository.searchPlaces(trimmed, display: 8);
      setState(() {
        _viewState = _viewState.copyWith(
          searchResults: results,
          placeSearchError: results.isEmpty ? '검색 결과가 없어요.' : null,
        );
      });
    } catch (_) {
      setState(() {
        _viewState = _viewState.copyWith(
          placeSearchError: '검색에 실패했어요. 다시 시도해 주세요.',
        );
      });
    } finally {
      if (mounted) {
        setState(() {
          _viewState = _viewState.copyWith(isPlaceSearching: false);
        });
      }
    }
  }

  void _clearSearch() {
    setState(() {
      _searchController.clear();
      _viewState = _viewState.copyWith(
        searchResults: const [],
        placeSearchError: null,
      );
    });
  }

  void _clearNewPlaces() {
    setState(() {
      _searchController.clear();
      _viewState = _viewState.copyWith(
        newPlaces: const [],
        searchError: null,
        selectedStore: null,
        selectedPlace: null,
        searchResults: const [],
        placeSearchError: null,
      );
    });
  }

  String? _selectedPlaceMarkerId() {
    final selected = _viewState.selectedPlace;
    if (selected == null) return null;
    return MapHomePlaceLogic.placeMarkerId(selected);
  }

  Future<void> _selectSearchResult(PlaceSearchResult item) async {
    final coords = MapHomePlaceLogic.coordsFromPlace(item);
    if (coords == null) return;

    setState(() {
      _searchController.text = item.name;
      _viewState = _viewState.copyWith(
        selectedStore: null,
        selectedPlace: item,
        searchError: null,
        placeSearchError: null,
        searchResults: const [],
      );
    });
    await _focusMarkerOnMap(coords.$1, coords.$2, zoom: 16);
  }

  void _selectStore(StoreSummary store) {
    setState(() {
      _viewState = _viewState.copyWith(
        selectedStore: store,
        selectedPlace: null,
      );
    });
    _focusStoreOnMap(store);
  }

  Future<void> _openReviewWrite(PlaceSearchResult item) async {
    final isSignedIn = await ensureSignedInForReview(context, ref);
    if (!isSignedIn || !mounted) return;

    final uri = Uri(
      path: '/review/write',
      queryParameters: {
        'storeName': item.name,
        'address': MapHomePlaceLogic.resolveAddress(item),
        'placeId': item.placeId,
      },
    );
    context.push(uri.toString());
  }

  Future<void> _openPlaceLink(PlaceSearchResult item) async {
    final link = item.link.trim();
    if (link.isEmpty) return;

    final uri = Uri.tryParse(link);
    if (uri == null) return;

    if (kIsWeb) {
      await openExternalLink(uri.toString(), target: '_blank');
      return;
    }

    await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
      webOnlyWindowName: '_blank',
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentLocation = ref.watch(currentLocationProvider);
    final lastAppliedLocation = _viewState.lastAppliedLocation;
    final shouldApplyCurrentLocation =
        lastAppliedLocation == null ||
        (lastAppliedLocation.latitude - currentLocation.latitude).abs() >
            0.000001 ||
        (lastAppliedLocation.longitude - currentLocation.longitude).abs() >
            0.000001 ||
        lastAppliedLocation.fromDevice != currentLocation.fromDevice;

    if (shouldApplyCurrentLocation) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _applyCurrentLocation(currentLocation, focusMap: true);
      });
    }

    final stores = ref.watch(nearbyStoresProvider);
    final reviewedStores = stores.asData?.value ?? const <StoreSummary>[];
    final markerBundle = MapHomeMarkerBundle.fromData(
      reviewedStores: reviewedStores,
      newPlaces: _viewState.newPlaces,
      searchResults: _viewState.searchResults,
      selectedPlace: _viewState.selectedPlace,
      reviewedCafeMarkerIconUrl: _reviewedCafeMarkerIconUrl,
    );

    final bottomPadding = MediaQuery.paddingOf(context).bottom + 16;
    final statusBottomPadding =
        bottomPadding +
        ((_viewState.selectedStore != null || _viewState.selectedPlace != null)
            ? 104
            : 0);

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: ClipRect(
              child: buildNaverMapView(
                context: context,
                lat: _viewState.mapLat,
                lng: _viewState.mapLng,
                zoom: 14,
                markers: markerBundle.markers,
                selectedMarkerId:
                    _viewState.selectedStore?.id ?? _selectedPlaceMarkerId(),
                onMarkerTap: (markerId) {
                  final store = markerBundle.storeById[markerId];
                  if (store != null) {
                    _selectStore(store);
                    return;
                  }
                  final place = markerBundle.placeById[markerId];
                  if (place != null) {
                    _selectSearchResult(place);
                  }
                },
                onMapReady: _handleMapReady,
                onCameraIdle: _handleCameraIdle,
              ),
            ),
          ),
          MapHomeTopOverlay(
            searchController: _searchController,
            isPlaceSearching: _viewState.isPlaceSearching,
            isSearching: _viewState.isSearching,
            searchResults: _viewState.searchResults,
            placeSearchError: _viewState.placeSearchError,
            selectedStore: _viewState.selectedStore,
            selectedPlace: _viewState.selectedPlace,
            newPlaces: _viewState.newPlaces,
            onSearchSubmitted: _searchPlaces,
            onSearchChanged: (_) => setState(() {}),
            onSearchPressed: () => _searchPlaces(_searchController.text),
            onSearchClear: _clearSearch,
            onSearchResultSelected: _selectSearchResult,
            onDiscoverPressed: () => _searchNearbyNewPlaces(reviewedStores),
            onClearNewPlaces: _clearNewPlaces,
          ),
          if (_viewState.isSearching || _viewState.searchError != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: statusBottomPadding,
              child: PointerInterceptor(
                child: MapStatusBanner(
                  isSearching: _viewState.isSearching,
                  errorMessage: _viewState.searchError,
                  hasResolvedLocation: currentLocation.fromDevice,
                  reviewedStoreCount: reviewedStores.length,
                  newCafeCount: _viewState.newPlaces.length,
                ),
              ),
            ),
          if (_viewState.selectedStore != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: bottomPadding,
              child: PointerInterceptor(
                child: ReviewedStoreBottomCard(
                  store: _viewState.selectedStore!,
                  onTap: () =>
                      context.go('/map/store/${_viewState.selectedStore!.id}'),
                ),
              ),
            ),
          if (_viewState.selectedStore == null && _viewState.selectedPlace != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: bottomPadding,
              child: PointerInterceptor(
                child: NewCafeBottomCard(
                  place: _viewState.selectedPlace!,
                  onTap: () => _openPlaceLink(_viewState.selectedPlace!),
                  onReviewTap: () => _openReviewWrite(_viewState.selectedPlace!),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
