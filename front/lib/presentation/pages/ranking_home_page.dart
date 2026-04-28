import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';

import 'package:front/core/constants/app_colors.dart';
import 'package:front/core/constants/app_sizes.dart';
import 'package:front/core/constants/app_strings.dart';
import 'package:front/domain/entities/store_ranking.dart';
import 'package:front/presentation/providers/app_providers.dart';
import 'package:front/presentation/providers/auth_providers.dart';
import 'package:front/presentation/providers/ranking_providers.dart';
import 'package:front/presentation/widgets/app_filter_chip.dart';
import 'package:front/presentation/widgets/section_title.dart';
import 'package:front/presentation/widgets/store_ranking_card.dart';

enum _StoreSegment { all, local, franchise }

enum _StoreRankingSort { recommended, rating, reviews }

class RankingHomePage extends ConsumerStatefulWidget {
  const RankingHomePage({super.key});

  @override
  ConsumerState<RankingHomePage> createState() => _RankingHomePageState();
}

class _RankingHomePageState extends ConsumerState<RankingHomePage> {
  _StoreSegment _selectedSegment = _StoreSegment.all;
  _StoreRankingSort _selectedSort = _StoreRankingSort.rating;

  List<StoreRanking> _filterRankings(List<StoreRanking> items) {
    final filtered = items.where((item) {
      return switch (_selectedSegment) {
        _StoreSegment.all => true,
        _StoreSegment.local => item.isLocal,
        _StoreSegment.franchise => !item.isLocal,
      };
    }).toList();

    filtered.sort((a, b) {
      return switch (_selectedSort) {
        _StoreRankingSort.recommended => _compareRecommended(a, b),
        _StoreRankingSort.rating => b.rating.compareTo(a.rating),
        _StoreRankingSort.reviews => b.reviewCount.compareTo(a.reviewCount),
      };
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

  Future<void> _handleProfileMenuSelect(
    BuildContext context,
    _ProfileMenuAction action,
  ) async {
    switch (action) {
      case _ProfileMenuAction.activity:
        final user =
            ref.read(authStateProvider).asData?.value ??
            ref.read(authControllerProvider).currentUser;
        if (user == null) {
          context.push('/auth');
          return;
        }
        context.go('/my-reviews');
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
        context.go('/preference');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final storeRankings = ref.watch(storeRankingListProvider);
    final currentLocation = ref.watch(currentLocationProvider);
    final user =
        ref.watch(authStateProvider).asData?.value ??
        ref.read(authControllerProvider).currentUser;
    final isLoggedIn = user != null;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _RankingHeader(
              selectedSegment: _selectedSegment,
              selectedSort: _selectedSort,
              onSegmentSelected: (value) =>
                  setState(() => _selectedSegment = value),
              onSortSelected: (value) => setState(() => _selectedSort = value),
              isLoggedIn: isLoggedIn,
              onProfileMenuSelect: (action) =>
                  _handleProfileMenuSelect(context, action),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.screenPadding,
                ),
                child: storeRankings.when(
                  data: (items) {
                    final filtered = _filterRankings(items);
                    if (filtered.isEmpty) {
                      return const Center(child: Text('아직 카페 랭킹 데이터가 없어요.'));
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
                              context.push('/ranking/store/${ranking.storeId}'),
                        );
                      },
                      separatorBuilder: (_, _) => const SizedBox(height: 16),
                      itemCount: filtered.length,
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (_, _) =>
                      const Center(child: Text('카페 랭킹을 불러오지 못했어요.')),
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
  final _StoreSegment selectedSegment;
  final _StoreRankingSort selectedSort;
  final ValueChanged<_StoreSegment> onSegmentSelected;
  final ValueChanged<_StoreRankingSort> onSortSelected;
  final bool isLoggedIn;
  final ValueChanged<_ProfileMenuAction> onProfileMenuSelect;

  const _RankingHeader({
    required this.selectedSegment,
    required this.selectedSort,
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
                    child: Text('내 리뷰'),
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
          const Padding(
            padding: EdgeInsets.only(top: 2, bottom: 12),
            child: Text(
              '이 탭은 전체 사용자 평점과 리뷰를 기준으로 정렬된 카페 랭킹입니다.',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          _RankingFilterScroller(
            children: [
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
                onSelected: (_) => onSortSelected(_StoreRankingSort.recommended),
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
          const SectionTitle(
            title: '전체 카페 랭킹',
            trailing: '평점 + 리뷰 기준',
          ),
          const SizedBox(height: 6),
          const Text(
            '추천순은 표시 점수와 리뷰 수를 함께 반영합니다.',
            style: TextStyle(fontSize: 12, color: Colors.black54),
          ),
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

enum _ProfileMenuAction { activity, login, logout }
