import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:front/core/constants/app_colors.dart';
import 'package:front/domain/entities/place_search_result.dart';
import 'package:front/presentation/providers/store_providers.dart';
import 'package:front/presentation/providers/app_providers.dart';
import 'package:front/presentation/widgets/app_filter_chip.dart';
import 'package:front/presentation/widgets/store_card.dart';
import 'package:go_router/go_router.dart';
import 'package:front/presentation/widgets/naver_map_view.dart';
import 'package:front/domain/entities/store_summary.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';

enum _MapSortType { rating, distance, reviews, workFriendly, quiet, dessert }

enum _MapStoreSegment { all, local, franchise }

// 지점 평점 지도를 보여주는 홈 화면이다.
class MapHomePage extends ConsumerStatefulWidget {
  const MapHomePage({super.key});

  @override
  ConsumerState<MapHomePage> createState() => _MapHomePageState();
}

class _MapHomePageState extends ConsumerState<MapHomePage> {
  static const double _sheetInitialExtent = 0.28;
  static const double _sheetMinExtent = 0.2;
  static const double _sheetMaxExtent = 0.6;
  final _searchController = TextEditingController();

  List<PlaceSearchResult> _results = [];
  bool _isSearching = false;
  String? _searchError;
  StoreSummary? _selectedStore;
  PlaceSearchResult? _selectedPlace;
  NaverMapController? _mapController;
  double _mapLat = AppLocationController.defaultLat;
  double _mapLng = AppLocationController.defaultLng;
  bool _isCurrentLocationResolved = false;
  double _sheetExtent = _sheetInitialExtent;
  _MapSortType _selectedSortType = _MapSortType.rating;
  _MapStoreSegment _selectedSegment = _MapStoreSegment.all;
  final String _cafeMarkerIconUrl = _buildCafeMarkerIconUrl();

  static String _buildCafeMarkerIconUrl() {
    const svg = '''
<svg xmlns="http://www.w3.org/2000/svg" width="28" height="28">
  <text x="50%" y="50%" text-anchor="middle" dominant-baseline="central" font-size="18">☕</text>
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchPlaces(String query) async {
    if (query.trim().isEmpty) return;
    setState(() {
      _isSearching = true;
      _searchError = null;
    });
    try {
      final repository = ref.read(placeSearchRepositoryProvider);
      final results = await repository.searchPlaces(query.trim());
      setState(() {
        _results = results;
        if (results.isEmpty) {
          _searchError = '카페 검색 결과가 없어요.';
        }
      });
    } catch (_) {
      setState(() {
        _searchError = '검색에 실패했어요. 다시 시도해주세요.';
      });
    } finally {
      setState(() {
        _isSearching = false;
      });
    }
  }

  void _openReviewWrite(PlaceSearchResult item) {
    final address = item.roadAddress.isNotEmpty
        ? item.roadAddress
        : item.address;
    final uri = Uri(
      path: '/review/write',
      queryParameters: {'storeName': item.name, 'address': address},
    );
    context.push(uri.toString());
  }

  String? _selectedPlaceMarkerId() {
    final selected = _selectedPlace;
    if (selected == null) return null;
    return 'place-${selected.mapx}-${selected.mapy}';
  }

  (double lat, double lng)? _coordsFromPlace(PlaceSearchResult item) {
    final lat = item.mapy / 10000000.0;
    final lng = item.mapx / 10000000.0;
    if (lat.abs() > 90 || lng.abs() > 180) return null;
    return (lat, lng);
  }

  Future<void> _selectSearchResult(PlaceSearchResult item) async {
    final coords = _coordsFromPlace(item);
    if (coords == null) return;
    setState(() {
      _selectedStore = null;
      _selectedPlace = item;
      _results = const [];
      _searchError = null;
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

  List<StoreSummary> _sortStores(
    List<StoreSummary> items,
    AppLocationState location,
  ) {
    final sorted = items.where((store) {
      return switch (_selectedSegment) {
        _MapStoreSegment.all => true,
        _MapStoreSegment.local => store.isLocal,
        _MapStoreSegment.franchise => !store.isLocal,
      };
    }).toList();
    sorted.sort((a, b) {
      if (_selectedSortType == _MapSortType.distance) {
        final distanceA = _distanceFromCurrentKm(a, location);
        final distanceB = _distanceFromCurrentKm(b, location);
        if (kDebugMode) {
          debugPrint(
            '[MapHome] distance(${a.name})=${distanceA.toStringAsFixed(2)}km, '
            'distance(${b.name})=${distanceB.toStringAsFixed(2)}km',
          );
        }
        final byDistance = distanceA.compareTo(distanceB);
        if (byDistance != 0) return byDistance;
        return b.rating.compareTo(a.rating);
      }
      if (_selectedSortType == _MapSortType.reviews) {
        final byReviewCount = b.reviewCount.compareTo(a.reviewCount);
        if (byReviewCount != 0) return byReviewCount;
        return b.rating.compareTo(a.rating);
      }
      if (_selectedSortType == _MapSortType.workFriendly) {
        return _compareByScore(a, b, (store) => store.workFriendlyScore);
      }
      if (_selectedSortType == _MapSortType.quiet) {
        return _compareByScore(a, b, (store) => store.quietnessScore);
      }
      if (_selectedSortType == _MapSortType.dessert) {
        return _compareByScore(a, b, (store) => store.dessertScore);
      }
      final byRating = b.rating.compareTo(a.rating);
      if (byRating != 0) return byRating;
      final byReviewCount = b.reviewCount.compareTo(a.reviewCount);
      if (byReviewCount != 0) return byReviewCount;
      return a.distanceKm.compareTo(b.distanceKm);
    });
    return sorted;
  }

  int _compareByScore(
    StoreSummary a,
    StoreSummary b,
    double Function(StoreSummary store) scoreOf,
  ) {
    final bySignal = scoreOf(b).compareTo(scoreOf(a));
    if (bySignal != 0) return bySignal;
    final byReviewCount = b.reviewCount.compareTo(a.reviewCount);
    if (byReviewCount != 0) return byReviewCount;
    return b.rating.compareTo(a.rating);
  }

  double _distanceFromCurrentKm(StoreSummary store, AppLocationState location) {
    final meters = Geolocator.distanceBetween(
      location.latitude,
      location.longitude,
      store.lat,
      store.lng,
    );
    return meters / 1000;
  }

  void _selectSortType(_MapSortType sortType) {
    if (_selectedSortType == sortType) return;
    setState(() {
      _selectedSortType = sortType;
    });
  }

  void _selectSegment(_MapStoreSegment segment) {
    if (_selectedSegment == segment) return;
    setState(() {
      _selectedSegment = segment;
      _selectedStore = null;
    });
  }

  @override
  // 지도와 바텀시트를 함께 렌더링한다.
  Widget build(BuildContext context) {
    final currentLocation = ref.watch(currentLocationProvider);
    if ((_mapLat - currentLocation.latitude).abs() > 0.000001 ||
        (_mapLng - currentLocation.longitude).abs() > 0.000001 ||
        _isCurrentLocationResolved != currentLocation.fromDevice) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _applyCurrentLocation(currentLocation, focusMap: true);
      });
    }

    final screenHeight = MediaQuery.of(context).size.height;
    final sheetTopOffsetFromBottom = screenHeight * _sheetExtent;
    final selectedCardBottom = (sheetTopOffsetFromBottom + 12).clamp(
      12.0,
      screenHeight - 160,
    );
    final stores = ref.watch(nearbyStoresProvider);
    final storeItems = _sortStores(stores.asData?.value ?? [], currentLocation);
    if (kDebugMode) {
      debugPrint('[MapHome] storeItems=${storeItems.length}');
    }
    final markers = storeItems
        .map(
          (store) => MapMarkerData(
            id: store.id,
            lat: store.lat,
            lng: store.lng,
            caption: store.name,
            description: store.address,
            iconUrl: _cafeMarkerIconUrl,
          ),
        )
        .toList();
    final selectedPlace = _selectedPlace;
    if (selectedPlace != null) {
      final coords = _coordsFromPlace(selectedPlace);
      if (coords != null) {
        markers.add(
          MapMarkerData(
            id: _selectedPlaceMarkerId()!,
            lat: coords.$1,
            lng: coords.$2,
            caption: selectedPlace.name,
            description: selectedPlace.roadAddress.isNotEmpty
                ? selectedPlace.roadAddress
                : selectedPlace.address,
            useDefaultMarker: true,
          ),
        );
      }
    }
    final storeById = {for (final store in storeItems) store.id: store};

    return Scaffold(
      body: Stack(
        children: [
          // 네이버 지도 위젯 (API 키 설정 필요)
          KeyedSubtree(
            key: const ValueKey('map-static'),
            child: buildNaverMapView(
              context: context,
              lat: _mapLat,
              lng: _mapLng,
              zoom: 14,
              markers: markers,
              selectedMarkerId: _selectedStore?.id ?? _selectedPlaceMarkerId(),
              onMarkerTap: (markerId) {
                final store = storeById[markerId];
                if (store == null) return;
                _selectStore(store);
              },
              onMapReady: _handleMapReady,
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
                        // IconButton(
                        //   onPressed: () {},
                        //   icon: const Icon(
                        //     Icons.menu,
                        //     color: AppColors.textPrimary,
                        //   ),
                        //   style: IconButton.styleFrom(
                        //     backgroundColor: Colors.white,
                        //   ),
                        // ),
                        // const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            onSubmitted: _searchPlaces,
                            decoration: InputDecoration(
                              hintText: '카페 검색',
                              prefixIcon: const Icon(Icons.search),
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: () =>
                              _searchPlaces(_searchController.text),
                          icon: const Icon(Icons.search, color: Colors.white),
                          style: IconButton.styleFrom(
                            backgroundColor: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    if (_isSearching ||
                        _results.isNotEmpty ||
                        _searchError != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: _SearchResultPanel(
                          isLoading: _isSearching,
                          errorMessage: _searchError,
                          results: _results,
                          onSelect: _selectSearchResult,
                        ),
                      ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 36,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          AppFilterChip(
                            label: '전체',
                            selected: _selectedSegment == _MapStoreSegment.all,
                            onSelected: (_) =>
                                _selectSegment(_MapStoreSegment.all),
                            margin: const EdgeInsets.only(right: 8),
                          ),
                          AppFilterChip(
                            label: '로컬',
                            selected:
                                _selectedSegment == _MapStoreSegment.local,
                            onSelected: (_) =>
                                _selectSegment(_MapStoreSegment.local),
                            margin: const EdgeInsets.only(right: 8),
                          ),
                          AppFilterChip(
                            label: '프랜차이즈',
                            selected:
                                _selectedSegment == _MapStoreSegment.franchise,
                            onSelected: (_) =>
                                _selectSegment(_MapStoreSegment.franchise),
                            margin: const EdgeInsets.only(right: 8),
                          ),
                          AppFilterChip(
                            label: '평점 높은 순',
                            selected: _selectedSortType == _MapSortType.rating,
                            onSelected: (_) =>
                                _selectSortType(_MapSortType.rating),
                            margin: const EdgeInsets.only(right: 8),
                          ),
                          AppFilterChip(
                            label: '가까운 순',
                            selected:
                                _selectedSortType == _MapSortType.distance,
                            onSelected: (_) =>
                                _selectSortType(_MapSortType.distance),
                            margin: const EdgeInsets.only(right: 8),
                          ),
                          AppFilterChip(
                            label: '리뷰 많은 순',
                            selected: _selectedSortType == _MapSortType.reviews,
                            onSelected: (_) =>
                                _selectSortType(_MapSortType.reviews),
                            margin: const EdgeInsets.only(right: 8),
                          ),
                          AppFilterChip(
                            label: '작업하기 좋은',
                            selected:
                                _selectedSortType == _MapSortType.workFriendly,
                            onSelected: (_) =>
                                _selectSortType(_MapSortType.workFriendly),
                            margin: const EdgeInsets.only(right: 8),
                          ),
                          AppFilterChip(
                            label: '조용한',
                            selected: _selectedSortType == _MapSortType.quiet,
                            onSelected: (_) =>
                                _selectSortType(_MapSortType.quiet),
                            margin: const EdgeInsets.only(right: 8),
                          ),
                          AppFilterChip(
                            label: '디저트 좋은',
                            selected: _selectedSortType == _MapSortType.dessert,
                            onSelected: (_) =>
                                _selectSortType(_MapSortType.dessert),
                            margin: const EdgeInsets.only(right: 8),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: NotificationListener<DraggableScrollableNotification>(
              onNotification: (notification) {
                final newExtent = notification.extent;
                if ((newExtent - _sheetExtent).abs() > 0.001 && mounted) {
                  setState(() {
                    _sheetExtent = newExtent;
                  });
                }
                return false;
              },
              child: DraggableScrollableSheet(
                initialChildSize: _sheetInitialExtent,
                minChildSize: _sheetMinExtent,
                maxChildSize: _sheetMaxExtent,
                builder: (context, controller) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(24),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 20,
                          offset: Offset(0, -8),
                        ),
                      ],
                    ),
                    child: PointerInterceptor(
                      child: Column(
                        children: [
                          Container(
                            width: 40,
                            height: 5,
                            decoration: BoxDecoration(
                              color: Colors.black12,
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Expanded(
                            child: stores.when(
                              data: (items) {
                                final sortedItems = _sortStores(
                                  items,
                                  currentLocation,
                                );
                                return ListView(
                                  controller: controller,
                                  children: [
                                    ListView.separated(
                                      shrinkWrap: true,
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      itemBuilder: (context, index) {
                                        final item = sortedItems[index];
                                        return StoreCard(
                                          store: item,
                                          isSelected:
                                              _selectedStore?.id == item.id,
                                          onTap: () => _selectStore(item),
                                        );
                                      },
                                      separatorBuilder: (context, index) =>
                                          const SizedBox(height: 12),
                                      itemCount: sortedItems.length,
                                    ),
                                  ],
                                );
                              },
                              loading: () => const Center(
                                child: CircularProgressIndicator(),
                              ),
                              error: (error, stackTrace) => const Center(
                                child: Text('지점 정보를 불러오지 못했어요.'),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          if (_selectedStore != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: selectedCardBottom,
              child: PointerInterceptor(
                child: GestureDetector(
                  onTap: () => context.go('/map/store/${_selectedStore!.id}'),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.cardBorder),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 12,
                          offset: Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: AppColors.backgroundLight,
                          child: const Icon(
                            Icons.store,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _selectedStore!.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${_selectedStore!.rating.toStringAsFixed(2)} · ${_selectedStore!.reviewCount} 리뷰',
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          if (_selectedStore == null && _selectedPlace != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: selectedCardBottom,
              child: PointerInterceptor(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.cardBorder),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 12,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  //여기
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: AppColors.backgroundLight,
                        child: const Icon(
                          Icons.place,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _selectedPlace!.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _selectedPlace!.roadAddress.isNotEmpty
                                  ? _selectedPlace!.roadAddress
                                  : _selectedPlace!.address,
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
                        onPressed: () => _openReviewWrite(_selectedPlace!),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          minimumSize: const Size(64, 36),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                        ),
                        child: const Text('리뷰'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SearchResultPanel extends StatelessWidget {
  final bool isLoading;
  final String? errorMessage;
  final List<PlaceSearchResult> results;
  final ValueChanged<PlaceSearchResult> onSelect;

  const _SearchResultPanel({
    required this.isLoading,
    required this.errorMessage,
    required this.results,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          if (isLoading)
            const Padding(
              padding: EdgeInsets.all(12),
              child: CircularProgressIndicator(),
            ),
          if (!isLoading && errorMessage != null)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          if (!isLoading && errorMessage == null)
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemBuilder: (context, index) {
                final item = results[index];
                final address = item.roadAddress.isNotEmpty
                    ? item.roadAddress
                    : item.address;
                return ListTile(
                  leading: const Icon(Icons.place, color: AppColors.primary),
                  title: Text(item.name),
                  subtitle: Text(address),
                  onTap: () => onSelect(item),
                );
              },
              separatorBuilder: (context, index) =>
                  const Divider(height: 1, color: AppColors.cardBorder),
              itemCount: results.length,
            ),
        ],
      ),
    );
  }
}
