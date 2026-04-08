// ignore_for_file: use_null_aware_elements

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';

import 'package:front/core/constants/app_colors.dart';
import 'package:front/domain/entities/place_search_result.dart';
import 'package:front/domain/entities/store_summary.dart';
import 'package:front/presentation/providers/app_providers.dart';
import 'package:front/presentation/providers/store_providers.dart';
import 'package:front/presentation/widgets/naver_map_view.dart';

class MapHomePage extends ConsumerStatefulWidget {
  const MapHomePage({super.key});

  @override
  ConsumerState<MapHomePage> createState() => _MapHomePageState();
}

class _MapHomePageState extends ConsumerState<MapHomePage> {
  static const int _newCafeDisplayCount = 20;
  static const int _newCafePageCount = 4;
  final _searchController = TextEditingController();

  List<PlaceSearchResult> _newPlaces = [];
  List<PlaceSearchResult> _searchResults = [];
  bool _isSearching = false;
  bool _isPlaceSearching = false;
  String? _searchError;
  String? _placeSearchError;
  StoreSummary? _selectedStore;
  PlaceSearchResult? _selectedPlace;
  NaverMapController? _mapController;
  double _mapLat = AppLocationController.defaultLat;
  double _mapLng = AppLocationController.defaultLng;
  bool _isCurrentLocationResolved = false;
  MapViewportData? _viewport;

  final String _reviewedCafeMarkerIconUrl = _buildMarkerIconUrl(
    label: '☕',
    backgroundColor: '#6F4E37',
    borderColor: '#6F4E37',
    textColor: '#FFFFFF',
  );
  final String _newCafeMarkerIconUrl = _buildMarkerIconUrl(
    label: '+',
    backgroundColor: '#FFFFFF',
    borderColor: '#6F4E37',
    textColor: '#6F4E37',
  );
  static String _buildMarkerIconUrl({
    required String label,
    required String backgroundColor,
    required String borderColor,
    required String textColor,
  }) {
    final svg =
        '''
<svg xmlns="http://www.w3.org/2000/svg" width="34" height="34" viewBox="0 0 34 34">
  <circle cx="17" cy="17" r="15" fill="$backgroundColor" stroke="$borderColor" stroke-width="2"/>
  <text x="50%" y="50%" text-anchor="middle" dominant-baseline="central" font-size="16" font-weight="700" fill="$textColor">$label</text>
</svg>
''';
    return 'data:image/svg+xml;utf8,${Uri.encodeComponent(svg)}';
  }

  @override
  void initState() {
    super.initState();
    final location = ref.read(currentLocationProvider);
    _applyCurrentLocation(location, focusMap: false);
  }

  void _handleMapReady(dynamic controller) {
    if (controller is NaverMapController) {
      _mapController = controller;
      if (_isCurrentLocationResolved) {
        _focusMapTo(_mapLat, _mapLng, zoom: 15);
      }
    }

    final selectedStore = _selectedStore;
    if (selectedStore != null) {
      _focusStoreOnMap(selectedStore);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _focusStoreOnMap(StoreSummary store) async {
    await _focusMapTo(store.lat, store.lng, zoom: 16);
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

  Future<void> _applyCurrentLocation(
    AppLocationState location, {
    required bool focusMap,
  }) async {
    final changed =
        (_mapLat - location.latitude).abs() > 0.000001 ||
        (_mapLng - location.longitude).abs() > 0.000001 ||
        _isCurrentLocationResolved != location.fromDevice;
    if (!changed || !mounted) return;

    setState(() {
      _mapLat = location.latitude;
      _mapLng = location.longitude;
      _isCurrentLocationResolved = location.fromDevice;
    });

    if (kDebugMode) {
      debugPrint('[MapHome] currentLocation=$_mapLat,$_mapLng');
    }
    if (focusMap && _isCurrentLocationResolved) {
      await _focusMapTo(_mapLat, _mapLng, zoom: 15);
    }
  }

  Future<void> _searchNearbyNewPlaces(List<StoreSummary> reviewedStores) async {
    final viewport =
        _viewport ?? MapViewportData(lat: _mapLat, lng: _mapLng, zoom: 14);
    final radiusKm = _radiusKmForZoom(viewport.zoom);

    setState(() {
      _isSearching = true;
      _searchError = null;
      _selectedStore = null;
      _selectedPlace = null;
    });

    try {
      final repository = ref.read(placeSearchRepositoryProvider);
      final results = await repository.searchPlaces(
        '카페',
        display: _newCafeDisplayCount,
        lat: viewport.lat,
        lng: viewport.lng,
        radiusKm: radiusKm,
        pages: _newCafePageCount,
      );
      final filtered = _filterNearbyPlaces(results, reviewedStores);

      setState(() {
        _newPlaces = filtered;
        if (filtered.isEmpty) {
          _searchError = '이 지도 영역에서 새 카페 결과가 없어요. 지도를 이동한 뒤 다시 시도해주세요.';
        }
      });
    } catch (_) {
      setState(() {
        _searchError = '새로운 카페를 찾지 못했어요. 다시 시도해주세요.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
      }
    }
  }

  void _handleCameraIdle(MapViewportData viewport) {
    if (!mounted) return;
    setState(() {
      _viewport = viewport;
      _mapLat = viewport.lat;
      _mapLng = viewport.lng;
    });
  }

  double _radiusKmForZoom(double zoom) {
    if (zoom >= 17) return 0.5;
    if (zoom >= 16) return 0.8;
    if (zoom >= 15) return 1.2;
    if (zoom >= 14) return 2.0;
    if (zoom >= 13) return 3.5;
    if (zoom >= 12) return 6.0;
    return 10.0;
  }

  Future<void> _searchPlaces(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      setState(() {
        _searchResults = [];
        _placeSearchError = null;
      });
      return;
    }

    setState(() {
      _isPlaceSearching = true;
      _placeSearchError = null;
    });

    try {
      final repository = ref.read(placeSearchRepositoryProvider);
      final results = await repository.searchPlaces(trimmed, display: 8);
      setState(() {
        _searchResults = results;
        if (results.isEmpty) {
          _placeSearchError = '검색 결과가 없어요.';
        }
      });
    } catch (_) {
      setState(() {
        _placeSearchError = '검색에 실패했어요. 다시 시도해주세요.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isPlaceSearching = false;
        });
      }
    }
  }

  void _clearNewPlaces() {
    setState(() {
      _newPlaces = [];
      _searchError = null;
      _selectedPlace = null;
    });
  }

  List<PlaceSearchResult> _filterNearbyPlaces(
    List<PlaceSearchResult> items,
    List<StoreSummary> reviewedStores,
  ) {
    final nearby = items
        .where(_hasPlaceCoords)
        .where((item) => !_looksLikeReviewedStore(item, reviewedStores))
        .toList();
    nearby.sort((a, b) {
      final aDistance = a.distanceKm ?? double.infinity;
      final bDistance = b.distanceKm ?? double.infinity;
      return aDistance.compareTo(bDistance);
    });
    return nearby.take(12).toList();
  }

  bool _looksLikeReviewedStore(
    PlaceSearchResult place,
    List<StoreSummary> reviewedStores,
  ) {
    final placeCoords = _coordsFromPlace(place);
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

  String _normalizeMatchText(String value) {
    return value.replaceAll(RegExp(r'[^0-9a-zA-Z가-힣]'), '').toLowerCase();
  }

  String? _selectedPlaceMarkerId() {
    final selected = _selectedPlace;
    if (selected == null) return null;
    return _placeMarkerId(selected);
  }

  bool _hasPlaceCoords(PlaceSearchResult item) =>
      item.lat != null && item.lng != null;

  (double lat, double lng)? _coordsFromPlace(PlaceSearchResult item) {
    final lat = item.lat;
    final lng = item.lng;
    if (lat == null || lng == null) return null;
    if (lat.abs() > 90 || lng.abs() > 180) return null;
    return (lat, lng);
  }

  Future<void> _selectSearchResult(PlaceSearchResult item) async {
    final coords = _coordsFromPlace(item);
    if (coords == null) return;

    setState(() {
      _selectedStore = null;
      _selectedPlace = item;
      _searchError = null;
      _placeSearchError = null;
      _searchResults = const [];
      _searchController.text = item.name;
    });
    await _focusMapTo(coords.$1, coords.$2, zoom: 16);
  }

  void _selectStore(StoreSummary store) {
    setState(() {
      _selectedStore = store;
      _selectedPlace = null;
    });
    _focusStoreOnMap(store);
  }

  void _openReviewWrite(PlaceSearchResult item) {
    final address = item.roadAddress.isNotEmpty
        ? item.roadAddress
        : item.address;
    final uri = Uri(
      path: '/review/write',
      queryParameters: {
        'storeName': item.name,
        'address': address,
        'placeId': item.placeId,
      },
    );
    context.push(uri.toString());
  }

  @override
  Widget build(BuildContext context) {
    final currentLocation = ref.watch(currentLocationProvider);
    if ((_mapLat - currentLocation.latitude).abs() > 0.000001 ||
        (_mapLng - currentLocation.longitude).abs() > 0.000001 ||
        _isCurrentLocationResolved != currentLocation.fromDevice) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _applyCurrentLocation(currentLocation, focusMap: true);
      });
    }

    final stores = ref.watch(nearbyStoresProvider);
    final reviewedStores = stores.asData?.value ?? const <StoreSummary>[];
    final reviewedMarkers = reviewedStores
        .map(
          (store) => MapMarkerData(
            id: store.id,
            lat: store.lat,
            lng: store.lng,
            caption: store.name,
            description: store.address,
            iconUrl: _reviewedCafeMarkerIconUrl,
            badgeText: '☕',
          ),
        )
        .toList();
    final newPlaceMarkers = _newPlaces
        .map((place) {
          final coords = _coordsFromPlace(place);
          if (coords == null) return null;
          return MapMarkerData(
            id: _placeMarkerId(place),
            lat: coords.$1,
            lng: coords.$2,
            caption: place.name,
            description: place.roadAddress.isNotEmpty
                ? place.roadAddress
                : place.address,
            iconUrl: _newCafeMarkerIconUrl,
            useDefaultMarker: true,
            badgeText: '+',
          );
        })
        .whereType<MapMarkerData>()
        .toList();
    final searchResultMarkers = _searchResults
        .where(
          (place) => !_newPlaces.any((item) => item.placeId == place.placeId),
        )
        .map((place) {
          final coords = _coordsFromPlace(place);
          if (coords == null) return null;
          return MapMarkerData(
            id: _placeMarkerId(place),
            lat: coords.$1,
            lng: coords.$2,
            caption: place.name,
            description: place.roadAddress.isNotEmpty
                ? place.roadAddress
                : place.address,
            useDefaultMarker: true,
          );
        })
        .whereType<MapMarkerData>()
        .toList();
    final selectedPlaceMarker = (() {
      final place = _selectedPlace;
      if (place == null) return null;
      if (_newPlaces.any((item) => item.placeId == place.placeId) ||
          _searchResults.any((item) => item.placeId == place.placeId)) {
        return null;
      }
      final coords = _coordsFromPlace(place);
      if (coords == null) return null;
      return MapMarkerData(
        id: _placeMarkerId(place),
        lat: coords.$1,
        lng: coords.$2,
        caption: place.name,
        description: place.roadAddress.isNotEmpty
            ? place.roadAddress
            : place.address,
        useDefaultMarker: true,
      );
    })();
    final markers = [
      ...reviewedMarkers,
      ...newPlaceMarkers,
      ...searchResultMarkers,
      ...[if (selectedPlaceMarker != null) selectedPlaceMarker],
    ];
    final storeById = {for (final store in reviewedStores) store.id: store};
    final placeById = {
      for (final place in [
        ..._newPlaces,
        ..._searchResults,
        ...[if (_selectedPlace != null) _selectedPlace!],
      ])
        _placeMarkerId(place): place,
    };
    final mapKey = ValueKey(
      'map-${markers.map((marker) => marker.id).join('|')}-${_selectedStore?.id ?? _selectedPlaceMarkerId() ?? 'none'}',
    );
    final bottomPadding = MediaQuery.paddingOf(context).bottom + 16;
    final statusBottomPadding =
        bottomPadding +
        ((_selectedStore != null || _selectedPlace != null) ? 104 : 0);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final actionWidth = (screenWidth * 0.26).clamp(104.0, 132.0);

    return Scaffold(
      body: Stack(
        children: [
          KeyedSubtree(
            key: mapKey,
            child: buildNaverMapView(
              context: context,
              lat: _mapLat,
              lng: _mapLng,
              zoom: 14,
              markers: markers,
              selectedMarkerId: _selectedStore?.id ?? _selectedPlaceMarkerId(),
              onMarkerTap: (markerId) {
                final store = storeById[markerId];
                if (store != null) {
                  _selectStore(store);
                  return;
                }
                final place = placeById[markerId];
                if (place != null) {
                  _selectSearchResult(place);
                }
              },
              onMapReady: _handleMapReady,
              onCameraIdle: _handleCameraIdle,
            ),
          ),
          SafeArea(
            child: PointerInterceptor(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: AppColors.cardBorder),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 10,
                                  offset: Offset(0, 6),
                                ),
                              ],
                            ),
                            child: TextField(
                              controller: _searchController,
                              onSubmitted: _searchPlaces,
                              decoration: InputDecoration(
                                hintText: '카페 검색',
                                prefixIcon: const Icon(Icons.search),
                                suffixIcon: _searchController.text.isEmpty
                                    ? null
                                    : IconButton(
                                        onPressed: () {
                                          setState(() {
                                            _searchController.clear();
                                            _searchResults = const [];
                                            _placeSearchError = null;
                                          });
                                        },
                                        icon: const Icon(Icons.close),
                                      ),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                              ),
                              onChanged: (_) {
                                setState(() {});
                              },
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton.filled(
                          onPressed: _isPlaceSearching
                              ? null
                              : () => _searchPlaces(_searchController.text),
                          style: IconButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(52, 52),
                          ),
                          icon: _isPlaceSearching
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.search),
                        ),
                      ],
                    ),
                    if (_searchResults.isNotEmpty ||
                        _placeSearchError != null) ...[
                      const SizedBox(height: 10),
                      _MapSearchResultPanel(
                        results: _searchResults,
                        errorMessage: _placeSearchError,
                        onSelect: _selectSearchResult,
                      ),
                    ],
                    const SizedBox(height: 10),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: actionWidth,
                          child: FilledButton(
                            onPressed: _isSearching
                                ? null
                                : () => _searchNearbyNewPlaces(reviewedStores),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              minimumSize: const Size.fromHeight(48),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 10,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.explore_outlined, size: 18),
                                const SizedBox(height: 4),
                                Text(
                                  _newPlaces.isEmpty ? '이 지역 찾기' : '이 지역 다시',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (_newPlaces.isNotEmpty ||
                            _selectedPlace != null) ...[
                          const SizedBox(width: 8),
                          IconButton.filledTonal(
                            onPressed: _clearNewPlaces,
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: AppColors.primary,
                              minimumSize: const Size(48, 48),
                            ),
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_isSearching || _searchError != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: statusBottomPadding,
              child: PointerInterceptor(
                child: _MapStatusBanner(
                  isSearching: _isSearching,
                  errorMessage: _searchError,
                  hasResolvedLocation: currentLocation.fromDevice,
                  reviewedStoreCount: reviewedStores.length,
                  newCafeCount: _newPlaces.length,
                ),
              ),
            ),
          if (_selectedStore != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: bottomPadding,
              child: PointerInterceptor(
                child: _ReviewedStoreBottomCard(
                  store: _selectedStore!,
                  onTap: () => context.go('/map/store/${_selectedStore!.id}'),
                ),
              ),
            ),
          if (_selectedStore == null && _selectedPlace != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: bottomPadding,
              child: PointerInterceptor(
                child: _NewCafeBottomCard(
                  place: _selectedPlace!,
                  onReviewTap: () => _openReviewWrite(_selectedPlace!),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _placeMarkerId(PlaceSearchResult place) {
    return 'place-${place.placeId}';
  }
}

class _MapStatusBanner extends StatelessWidget {
  final bool isSearching;
  final String? errorMessage;
  final bool hasResolvedLocation;
  final int reviewedStoreCount;
  final int newCafeCount;

  const _MapStatusBanner({
    required this.isSearching,
    required this.errorMessage,
    required this.hasResolvedLocation,
    required this.reviewedStoreCount,
    required this.newCafeCount,
  });

  @override
  Widget build(BuildContext context) {
    String message;
    if (isSearching) {
      message = '이 지도 영역에서 새로운 카페를 찾는 중이에요.';
    } else if (errorMessage != null) {
      message = errorMessage!;
    } else if (newCafeCount > 0) {
      message = '리뷰된 카페 $reviewedStoreCount곳과 새 카페 $newCafeCount곳을 지도에 표시했어요.';
    } else if (!hasResolvedLocation) {
      message = '위치 권한이 없더라도 현재 보고 있는 지도 기준으로 새 카페를 찾을 수 있어요.';
    } else {
      message = '리뷰가 쌓인 카페만 지도에 보여줘요. 새로운 카페는 버튼으로 탐색할 수 있어요.';
    }

    final isError = !isSearching && errorMessage != null;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isError ? const Color(0xFFFFF1F2) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isError ? const Color(0xFFFDA4AF) : AppColors.cardBorder,
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          if (isSearching)
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2.2),
            )
          else
            Icon(
              isError ? Icons.error_outline : Icons.info_outline,
              color: isError ? const Color(0xFFE11D48) : AppColors.primary,
            ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 12,
                color: isError
                    ? const Color(0xFFBE123C)
                    : AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MapSearchResultPanel extends StatelessWidget {
  final List<PlaceSearchResult> results;
  final String? errorMessage;
  final ValueChanged<PlaceSearchResult> onSelect;

  const _MapSearchResultPanel({
    required this.results,
    required this.errorMessage,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 280),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: errorMessage != null
          ? Padding(
              padding: const EdgeInsets.all(14),
              child: Text(
                errorMessage!,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
            )
          : ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: results.length,
              separatorBuilder: (context, index) =>
                  const Divider(height: 1, color: AppColors.cardBorder),
              itemBuilder: (context, index) {
                final item = results[index];
                final address = item.roadAddress.isNotEmpty
                    ? item.roadAddress
                    : item.address;
                return ListTile(
                  leading: const Icon(
                    Icons.place_outlined,
                    color: AppColors.primary,
                  ),
                  title: Text(
                    item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    address,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () => onSelect(item),
                );
              },
            ),
    );
  }
}

class _ReviewedStoreBottomCard extends StatelessWidget {
  final StoreSummary store;
  final VoidCallback onTap;

  const _ReviewedStoreBottomCard({required this.store, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.cardBorder),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 16,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            _CardImage(
              imageUrl: store.imageUrl,
              fallbackIcon: Icons.local_cafe_rounded,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '리뷰된 카페',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    store.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${store.rating.toStringAsFixed(2)} · ${store.reviewCount} 리뷰',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}

class _NewCafeBottomCard extends StatelessWidget {
  final PlaceSearchResult place;
  final VoidCallback onReviewTap;

  const _NewCafeBottomCard({required this.place, required this.onReviewTap});

  @override
  Widget build(BuildContext context) {
    final address = place.roadAddress.isNotEmpty
        ? place.roadAddress
        : place.address;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          const _CardImage(imageUrl: '', fallbackIcon: Icons.place_rounded),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '새로운 카페',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  place.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  address,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: onReviewTap,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              minimumSize: const Size(74, 38),
              padding: const EdgeInsets.symmetric(horizontal: 14),
            ),
            child: const Text('리뷰'),
          ),
        ],
      ),
    );
  }
}

class _CardImage extends StatelessWidget {
  final String imageUrl;
  final IconData fallbackIcon;

  const _CardImage({required this.imageUrl, required this.fallbackIcon});

  @override
  Widget build(BuildContext context) {
    final url = imageUrl.trim();
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 72,
        height: 72,
        color: AppColors.backgroundLight,
        padding: const EdgeInsets.all(8),
        child: url.isEmpty
            ? Icon(fallbackIcon, color: AppColors.primary, size: 28)
            : Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) =>
                    Icon(fallbackIcon, color: AppColors.primary, size: 28),
              ),
      ),
    );
  }
}
