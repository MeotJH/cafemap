import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:front/core/constants/app_colors.dart';
import 'package:front/core/constants/app_sizes.dart';
import 'package:front/core/constants/app_strings.dart';
import 'package:front/domain/entities/brand_menu_ranking.dart';
import 'package:front/domain/entities/place_search_result.dart';
import 'package:front/domain/entities/store_ranking.dart';
import 'package:front/presentation/providers/app_providers.dart';
import 'package:front/presentation/providers/auth_providers.dart';
import 'package:front/presentation/providers/ranking_providers.dart';
import 'package:front/presentation/widgets/app_filter_chip.dart';
import 'package:front/presentation/widgets/ranking_card.dart';
import 'package:front/presentation/widgets/section_title.dart';
import 'package:front/presentation/widgets/store_ranking_card.dart';
import 'package:go_router/go_router.dart';

enum _StoreSegment { all, local, franchise }

enum _StoreRankingSort { recommended, rating, reviews }

enum _RankingMode { stores, menus }

class RankingHomePage extends ConsumerStatefulWidget {
  final _RankingMode _initialMode;

  const RankingHomePage({super.key}) : _initialMode = _RankingMode.stores;

  const RankingHomePage.menu({super.key}) : _initialMode = _RankingMode.menus;

  @override
  ConsumerState<RankingHomePage> createState() => _RankingHomePageState();
}

class _RankingHomePageState extends ConsumerState<RankingHomePage> {
  final _searchController = TextEditingController();
  String _query = '';
  List<PlaceSearchResult> _placeResults = [];
  _StoreSegment _selectedSegment = _StoreSegment.all;
  _StoreRankingSort _selectedSort = _StoreRankingSort.rating;
  bool _isPlaceSearching = false;
  String? _placeSearchError;

  _RankingMode get _selectedMode => widget._initialMode;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<StoreRanking> _filterRankings(List<StoreRanking> items) {
    final query = _query.trim().toLowerCase();
    var filtered = items.where((item) {
      return switch (_selectedSegment) {
        _StoreSegment.all => true,
        _StoreSegment.local => item.isLocal,
        _StoreSegment.franchise => !item.isLocal,
      };
    }).toList();

    if (query.isNotEmpty) {
      filtered = filtered.where((item) {
        final haystack =
            '${item.storeName} ${item.brandName} ${item.topLabelA} ${item.topLabelB}'
                .toLowerCase();
        return haystack.contains(query);
      }).toList();
    }

    filtered.sort((a, b) {
      return switch (_selectedSort) {
        _StoreRankingSort.recommended => _compareRecommended(a, b),
        _StoreRankingSort.rating => b.rating.compareTo(a.rating),
        _StoreRankingSort.reviews => b.reviewCount.compareTo(a.reviewCount),
      };
    });
    return filtered;
  }

  List<BrandMenuRanking> _filterMenuRankings(List<BrandMenuRanking> items) {
    final query = _query.trim().toLowerCase();
    var filtered = items;
    if (query.isNotEmpty) {
      filtered = filtered.where((item) {
        final haystack = '${item.menuName} ${item.brandName} ${item.category} '
                '${item.highlightLabelA} ${item.highlightLabelB}'
            .toLowerCase();
        return haystack.contains(query);
      }).toList();
    }
    filtered.sort((a, b) {
      if (_selectedSort == _StoreRankingSort.reviews) {
        final byReviews = b.reviewCount.compareTo(a.reviewCount);
        if (byReviews != 0) return byReviews;
      }
      return b.rating.compareTo(a.rating);
    });
    return filtered;
  }

  int _compareRecommended(StoreRanking a, StoreRanking b) {
    final byDisplayScore = b.displayScore.compareTo(a.displayScore);
    if (byDisplayScore != 0) return byDisplayScore;
    final byReviews = b.reviewCount.compareTo(a.reviewCount);
    if (byReviews != 0) return byReviews;
    return b.rating.compareTo(a.rating);
  }

  double _distanceFromCurrentKm(
    StoreRanking ranking,
    AppLocationState location,
  ) {
    if (ranking.lat == 0.0 && ranking.lng == 0.0) {
      return ranking.distanceKm;
    }
    final meters = Geolocator.distanceBetween(
      location.latitude,
      location.longitude,
      ranking.lat,
      ranking.lng,
    );
    return meters / 1000;
  }

  Future<void> _handleSearchSubmitted(String value) async {
    setState(() => _query = value);
    if (_selectedMode != _RankingMode.stores) return;
    await _searchPlaces(value);
  }

  Future<void> _searchPlaces(String value) async {
    final query = value.trim();
    if (query.length < 2) {
      setState(() {
        _placeResults = [];
        _placeSearchError = query.isEmpty ? null : '두 글자 이상 입력해주세요.';
      });
      return;
    }

    setState(() {
      _isPlaceSearching = true;
      _placeSearchError = null;
    });
    try {
      final repository = ref.read(placeSearchRepositoryProvider);
      final results = await repository.searchPlaces(query);
      setState(() {
        _placeResults = results;
        _placeSearchError = results.isEmpty ? '실제 카페 검색 결과가 없어요.' : null;
      });
    } catch (_) {
      setState(() {
        _placeSearchError = '실제 카페 검색에 실패했어요.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isPlaceSearching = false;
        });
      }
    }
  }

  void _openPlaceReview(PlaceSearchResult item) {
    final address =
        item.roadAddress.isNotEmpty ? item.roadAddress : item.address;
    final uri = Uri(
      path: '/review/write',
      queryParameters: {
        'storeName': item.name,
        'address': address,
        'placeId': item.placeId,
        'brandId': item.brandId,
        'brandName': item.brandName,
      },
    );
    context.push(uri.toString());
  }

  Future<void> _handleProfileMenuSelect(
    BuildContext context,
    _ProfileMenuAction action,
  ) async {
    switch (action) {
      case _ProfileMenuAction.activity:
        final user = ref.read(authStateProvider).asData?.value ??
            ref.read(authControllerProvider).currentUser;
        if (user == null) {
          context.push('/auth');
          return;
        }
        context.go('/activity');
        break;
      case _ProfileMenuAction.login:
        context.push('/auth');
        break;
      case _ProfileMenuAction.logout:
        await ref.read(authControllerProvider).signOut();
        if (!context.mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('로그아웃 되었어요.')));
        context.go('/ranking');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final storeRankings = ref.watch(storeRankingListProvider);
    final currentLocation = ref.watch(currentLocationProvider);
    final menuRankings = ref.watch(rankingListProvider);
    final user = ref.watch(authStateProvider).asData?.value ??
        ref.read(authControllerProvider).currentUser;
    final isLoggedIn = user != null;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _RankingHeader(
              controller: _searchController,
              selectedMode: _selectedMode,
              selectedSegment: _selectedSegment,
              selectedSort: _selectedSort,
              onSearchChanged: (value) => setState(() => _query = value),
              onSearchSubmitted: _handleSearchSubmitted,
              onSearchPressed: () => _handleSearchSubmitted(_query),
              onSegmentSelected: (value) =>
                  setState(() => _selectedSegment = value),
              onSortSelected: (value) => setState(() => _selectedSort = value),
              isLoggedIn: isLoggedIn,
              onProfileMenuSelect: (action) =>
                  _handleProfileMenuSelect(context, action),
            ),
            if (_selectedMode == _RankingMode.stores &&
                (_isPlaceSearching ||
                    _placeResults.isNotEmpty ||
                    _placeSearchError != null))
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: _PlaceSearchPanel(
                  isLoading: _isPlaceSearching,
                  errorMessage: _placeSearchError,
                  results: _placeResults,
                  onSelect: _openPlaceReview,
                ),
              ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.screenPadding,
                ),
                child: _selectedMode == _RankingMode.stores
                    ? storeRankings.when(
                        data: (items) {
                          final filtered = _filterRankings(items);
                          if (filtered.isEmpty) {
                            return const Center(child: Text('검색 결과가 없어요.'));
                          }
                          return ListView.separated(
                            padding: const EdgeInsets.only(bottom: 24),
                            itemBuilder: (context, index) {
                              final ranking = filtered[index];
                              return StoreRankingCard(
                                key: ValueKey(
                                  '${_selectedSegment.name}_${_selectedSort.name}_${ranking.storeId}',
                                ),
                                ranking: ranking,
                                rankIndex: index,
                                distanceKm: _distanceFromCurrentKm(
                                  ranking,
                                  currentLocation,
                                ),
                                onTap: () =>
                                    context.go('/map/store/${ranking.storeId}'),
                              );
                            },
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 16),
                            itemCount: filtered.length,
                          );
                        },
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (_, _) =>
                            const Center(child: Text('카페 랭킹을 불러오지 못했어요.')),
                      )
                    : menuRankings.when(
                        data: (items) {
                          final filtered = _filterMenuRankings(items);
                          if (filtered.isEmpty) {
                            return const Center(child: Text('검색 결과가 없어요.'));
                          }
                          return ListView.separated(
                            padding: const EdgeInsets.only(bottom: 24),
                            itemBuilder: (context, index) {
                              final ranking = filtered[index];
                              return RankingCard(
                                key: ValueKey(
                                  'menu_${_selectedSort.name}_${ranking.id}',
                                ),
                                ranking: ranking,
                                rankIndex: index,
                                onTap: () => context.go(
                                  '/menu-ranking/${ranking.id}',
                                  extra: ranking,
                                ),
                              );
                            },
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 16),
                            itemCount: filtered.length,
                          );
                        },
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (_, _) =>
                            const Center(child: Text('메뉴 랭킹을 불러오지 못했어요.')),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RankingHeader extends StatelessWidget {
  final TextEditingController controller;
  final _RankingMode selectedMode;
  final _StoreSegment selectedSegment;
  final _StoreRankingSort selectedSort;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onSearchSubmitted;
  final VoidCallback onSearchPressed;
  final ValueChanged<_StoreSegment> onSegmentSelected;
  final ValueChanged<_StoreRankingSort> onSortSelected;
  final bool isLoggedIn;
  final ValueChanged<_ProfileMenuAction> onProfileMenuSelect;

  const _RankingHeader({
    required this.controller,
    required this.selectedMode,
    required this.selectedSegment,
    required this.selectedSort,
    required this.onSearchChanged,
    required this.onSearchSubmitted,
    required this.onSearchPressed,
    required this.onSegmentSelected,
    required this.onSortSelected,
    required this.isLoggedIn,
    required this.onProfileMenuSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(
                      Icons.local_cafe_rounded,
                      color: Colors.deepOrange,
                      size: 28,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        AppStrings.appName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<_ProfileMenuAction>(
                tooltip: '프로필 메뉴',
                onSelected: onProfileMenuSelect,
                itemBuilder: (context) => [
                  const PopupMenuItem<_ProfileMenuAction>(
                    value: _ProfileMenuAction.activity,
                    child: Text('내 활동'),
                  ),
                  PopupMenuItem<_ProfileMenuAction>(
                    value: isLoggedIn
                        ? _ProfileMenuAction.logout
                        : _ProfileMenuAction.login,
                    child: Text(isLoggedIn ? '로그아웃' : '로그인'),
                  ),
                ],
                icon: const Icon(Icons.account_circle),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  onChanged: onSearchChanged,
                  onSubmitted: onSearchSubmitted,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: selectedMode == _RankingMode.stores
                        ? '실제 카페명 또는 랭킹 검색'
                        : '메뉴명, 브랜드, 카테고리 검색',
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
              if (selectedMode == _RankingMode.stores) ...[
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: onSearchPressed,
                  icon: const Icon(Icons.search),
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          _RankingFilterScroller(
            children: [
              if (selectedMode == _RankingMode.stores) ...[
                AppFilterChip(
                  label: '전체',
                  selected: selectedSegment == _StoreSegment.all,
                  onSelected: (_) => onSegmentSelected(_StoreSegment.all),
                  margin: const EdgeInsets.only(right: 8),
                  width: null,
                ),
                AppFilterChip(
                  label: '로컬',
                  selected: selectedSegment == _StoreSegment.local,
                  onSelected: (_) => onSegmentSelected(_StoreSegment.local),
                  margin: const EdgeInsets.only(right: 8),
                  width: null,
                ),
                AppFilterChip(
                  label: '프랜차이즈',
                  selected: selectedSegment == _StoreSegment.franchise,
                  onSelected: (_) => onSegmentSelected(_StoreSegment.franchise),
                  margin: const EdgeInsets.only(right: 8),
                  width: null,
                ),
              ],
              AppFilterChip(
                label: '평점순',
                selected: selectedSort == _StoreRankingSort.rating,
                onSelected: (_) => onSortSelected(_StoreRankingSort.rating),
                margin: const EdgeInsets.only(right: 8),
                width: null,
              ),
              AppFilterChip(
                label: '추천순',
                selected: selectedSort == _StoreRankingSort.recommended,
                onSelected: (_) =>
                    onSortSelected(_StoreRankingSort.recommended),
                margin: const EdgeInsets.only(right: 8),
                width: null,
              ),
              AppFilterChip(
                label: '리뷰 많은 순',
                selected: selectedSort == _StoreRankingSort.reviews,
                onSelected: (_) => onSortSelected(_StoreRankingSort.reviews),
                margin: EdgeInsets.zero,
                width: null,
              ),
            ],
          ),
          const SizedBox(height: 16),
          SectionTitle(
            title: selectedMode == _RankingMode.stores
                ? 'Cafe Store Rankings'
                : 'Cafe Menu Rankings',
            trailing: selectedMode == _RankingMode.stores
                ? '신뢰도 보정'
                : 'Franchise Menus',
          ),
          if (selectedMode == _RankingMode.stores) ...[
            const SizedBox(height: 6),
            const Text(
              '추천순은 표시 별점만이 아니라 리뷰 수 신뢰도도 함께 반영해요.',
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ],
        ],
      ),
    );
  }
}

class _RankingFilterScroller extends StatelessWidget {
  final List<Widget> children;

  const _RankingFilterScroller({required this.children});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ScrollConfiguration(
        behavior: const _RankingFilterScrollBehavior(),
        child: ListView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          children: children,
        ),
      ),
    );
  }
}

class _RankingFilterScrollBehavior extends MaterialScrollBehavior {
  const _RankingFilterScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
      };
}

class _PlaceSearchPanel extends StatelessWidget {
  final bool isLoading;
  final String? errorMessage;
  final List<PlaceSearchResult> results;
  final ValueChanged<PlaceSearchResult> onSelect;

  const _PlaceSearchPanel({
    required this.isLoading,
    required this.errorMessage,
    required this.results,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(14, 4, 14, 8),
              child: Text(
                '실제 카페 검색 결과',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
            if (isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (errorMessage != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
                child: Text(
                  errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
              )
            else
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 220),
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  itemCount: results.length,
                  separatorBuilder: (_, _) =>
                      const Divider(height: 1, color: Color(0xFFE5E7EB)),
                  itemBuilder: (context, index) {
                    final item = results[index];
                    final address = item.roadAddress.isNotEmpty
                        ? item.roadAddress
                        : item.address;
                    return ListTile(
                      dense: true,
                      leading:
                          const Icon(Icons.place, color: AppColors.primary),
                      title: Text(item.name),
                      subtitle: Text(address),
                      trailing: const Text(
                        '리뷰 쓰기',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                      onTap: () => onSelect(item),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

enum _ProfileMenuAction { activity, login, logout }
