import 'dart:async';

// ignore_for_file: use_null_aware_elements

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';

import 'package:front/domain/entities/place_search_result.dart';
import 'package:front/domain/entities/store_summary.dart';
import 'package:front/presentation/pages/map_home/map_home_marker_bundle.dart';
import 'package:front/presentation/pages/map_home/map_home_place_logic.dart';
import 'package:front/presentation/pages/map_home/map_home_widgets.dart';
import 'package:front/presentation/providers/app_providers.dart';
import 'package:front/presentation/providers/map_home_provider.dart';
import 'package:front/presentation/providers/store_providers.dart';
import 'package:front/presentation/utils/auth_navigation.dart';
import 'package:front/presentation/utils/place_external_link.dart';
import 'package:front/presentation/widgets/naver_map_view.dart';

class MapHomePage extends ConsumerStatefulWidget {
  const MapHomePage({super.key});

  @override
  ConsumerState<MapHomePage> createState() => _MapHomePageState();
}

class _MapHomePageState extends ConsumerState<MapHomePage> {
  static const double _markerFocusOffsetMeters = 140;
  static const Duration _mapReadyTimeout = Duration(seconds: 8);

  final _searchController = TextEditingController();
  final _reviewedCafeMarkerIconUrl =
      MapHomePlaceLogic.buildReviewedCafeMarkerIconUrl();

  NaverMapController? _mapController;
  bool _cameraIdleUpdateQueued = false;
  bool _isMapReady = false;
  bool _showMapRecoveryHint = false;
  int _mapReloadNonce = 0;
  Timer? _mapReadyTimer;
  ProviderSubscription<AppLocationState>? _locationSubscription;

  @override
  void initState() {
    super.initState();
    _locationSubscription = ref.listenManual<AppLocationState>(
      currentLocationProvider,
      (previous, next) async {
        Future<void>(() async {
          final changed =
              ref.read(mapHomeControllerProvider.notifier).applyCurrentLocation(
                    next,
                  );
          if (changed && next.fromDevice) {
            await _focusMapTo(next.latitude, next.longitude, zoom: 15);
          }
        });
      },
    );

    Future<void>(() async {
      final location = ref.read(currentLocationProvider);
      ref.read(mapHomeControllerProvider.notifier).applyCurrentLocation(
            location,
          );
    });
    _armMapReadyWatchdog();
  }

  @override
  void dispose() {
    _mapReadyTimer?.cancel();
    _locationSubscription?.close();
    _searchController.dispose();
    super.dispose();
  }

  void _armMapReadyWatchdog() {
    if (!kIsWeb) return;
    _mapReadyTimer?.cancel();
    _mapReadyTimer = Timer(_mapReadyTimeout, () {
      if (!mounted || _isMapReady) return;
      setState(() {
        _showMapRecoveryHint = true;
      });
    });
  }

  void _retryMapMount() {
    _mapReadyTimer?.cancel();
    setState(() {
      _isMapReady = false;
      _showMapRecoveryHint = false;
      _mapReloadNonce += 1;
    });
    _armMapReadyWatchdog();
  }

  void _handleMapReady(dynamic controller) {
    _mapReadyTimer?.cancel();
    if (mounted && (!_isMapReady || _showMapRecoveryHint)) {
      setState(() {
        _isMapReady = true;
        _showMapRecoveryHint = false;
      });
    }
    if (controller is! NaverMapController) return;
    _mapController = controller;

    final state = ref.read(mapHomeControllerProvider);
    if (state.isCurrentLocationResolved) {
      _focusMapTo(state.mapLat, state.mapLng, zoom: 15);
    }

    final selectedStore = state.selectedStore;
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

  void _handleCameraIdle(MapViewportData viewport) {
    final notifier = ref.read(mapHomeControllerProvider.notifier);

    void applyViewport() {
      notifier.updateViewport(viewport);
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

  Future<void> _selectSearchResult(PlaceSearchResult item) async {
    final coords = MapHomePlaceLogic.coordsFromPlace(item);
    if (coords == null) return;

    _searchController.text = item.name;
    ref.read(mapHomeControllerProvider.notifier).selectSearchResult(item);
    await _focusMarkerOnMap(coords.$1, coords.$2, zoom: 16);
  }

  void _selectStore(StoreSummary store) {
    ref.read(mapHomeControllerProvider.notifier).selectStore(store);
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
        'link': item.link,
        if (item.lat != null) 'lat': item.lat!.toString(),
        if (item.lng != null) 'lng': item.lng!.toString(),
      },
    );
    context.push(uri.toString());
  }

  Future<void> _openPlaceLink(PlaceSearchResult item) async {
    await openPlaceExternalLink(
      name: item.name,
      address: MapHomePlaceLogic.resolveAddress(item),
      directLink: item.link,
    );
  }

  String? _selectedPlaceMarkerId(PlaceSearchResult? place) {
    if (place == null) return null;
    return MapHomePlaceLogic.placeMarkerId(place);
  }

  @override
  Widget build(BuildContext context) {
    final currentLocation = ref.watch(currentLocationProvider);
    final state = ref.watch(mapHomeControllerProvider);
    final notifier = ref.read(mapHomeControllerProvider.notifier);

    final stores = ref.watch(nearbyStoresProvider);
    final reviewedStores = stores.asData?.value ?? const <StoreSummary>[];
    final markerBundle = MapHomeMarkerBundle.fromData(
      reviewedStores: reviewedStores,
      newPlaces: state.newPlaces,
      selectedPlace: state.selectedPlace,
      reviewedCafeMarkerIconUrl: _reviewedCafeMarkerIconUrl,
    );

    final bottomPadding = MediaQuery.paddingOf(context).bottom + 16;
    final statusBottomPadding =
        bottomPadding +
        ((state.selectedStore != null || state.selectedPlace != null)
            ? 104
            : 0);

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: ClipRect(
              child: buildNaverMapView(
                key: ValueKey('map-static-$_mapReloadNonce'),
                context: context,
                lat: state.mapLat,
                lng: state.mapLng,
                zoom: 14,
                markers: markerBundle.markers,
                selectedMarkerId:
                    state.selectedStore?.id ??
                    _selectedPlaceMarkerId(state.selectedPlace),
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
          if (_showMapRecoveryHint)
            Positioned(
              left: 20,
              right: 20,
              top: MediaQuery.paddingOf(context).top + 20,
              child: PointerInterceptor(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.black12),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 20,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          '지도를 다시 불러오는 중이에요',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          '아이폰 Safari에서 위치 권한 변경 직후 지도가 늦게 뜰 수 있어요. 다시 시도하면 대부분 복구됩니다.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.black54,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerRight,
                          child: FilledButton(
                            onPressed: _retryMapMount,
                            child: const Text('다시 시도'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          MapHomeTopOverlay(
            searchController: _searchController,
            isSearching: state.isSearching,
            selectedPlace: state.selectedPlace,
            newPlaces: state.newPlaces,
            onSearchClear: () {
              _searchController.clear();
              notifier.clearSearch();
            },
            onSearchResultSelected: _selectSearchResult,
            onDiscoverPressed: () => notifier.searchNearbyNewPlaces(reviewedStores),
            onClearNewPlaces: () {
              _searchController.clear();
              notifier.clearNewPlaces();
            },
          ),
          if (state.isSearching || state.searchError != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: statusBottomPadding,
              child: PointerInterceptor(
                child: MapStatusBanner(
                  isSearching: state.isSearching,
                  errorMessage: state.searchError,
                  hasResolvedLocation: currentLocation.fromDevice,
                  reviewedStoreCount: reviewedStores.length,
                  newCafeCount: state.newPlaces.length,
                ),
              ),
            ),
          if (state.selectedStore != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: bottomPadding,
              child: PointerInterceptor(
                child: ReviewedStoreBottomCard(
                  store: state.selectedStore!,
                  onTap: () => context.go('/map/store/${state.selectedStore!.id}'),
                ),
              ),
            ),
          if (state.selectedStore == null && state.selectedPlace != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: bottomPadding,
              child: PointerInterceptor(
                child: NewCafeBottomCard(
                  place: state.selectedPlace!,
                  onTap: () => _openPlaceLink(state.selectedPlace!),
                  onReviewTap: () => _openReviewWrite(state.selectedPlace!),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
