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
import 'package:front/presentation/pages/map_home/map_home_widgets.dart';
import 'package:front/presentation/providers/app_providers.dart';
import 'package:front/presentation/providers/map_home_provider.dart';
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
  static const double _markerFocusOffsetMeters = 140;

  final _searchController = TextEditingController();
  final _reviewedCafeMarkerIconUrl =
      MapHomePlaceLogic.buildReviewedCafeMarkerIconUrl();

  NaverMapController? _mapController;
  bool _cameraIdleUpdateQueued = false;
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
  }

  @override
  void dispose() {
    _locationSubscription?.close();
    _searchController.dispose();
    super.dispose();
  }

  void _handleMapReady(dynamic controller) {
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
