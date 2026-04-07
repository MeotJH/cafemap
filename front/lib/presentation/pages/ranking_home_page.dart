import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:front/core/constants/app_sizes.dart';
import 'package:front/core/constants/app_strings.dart';
import 'package:front/domain/entities/store_ranking.dart';
import 'package:front/presentation/providers/auth_providers.dart';
import 'package:front/presentation/providers/ranking_providers.dart';
import 'package:front/presentation/widgets/app_filter_chip.dart';
import 'package:front/presentation/widgets/section_title.dart';
import 'package:front/presentation/widgets/store_ranking_card.dart';
import 'package:go_router/go_router.dart';

enum _StoreSegment { all, local, franchise }

enum _StoreRankingSort { recommended, rating, reviews }

class RankingHomePage extends ConsumerStatefulWidget {
  const RankingHomePage({super.key});

  @override
  ConsumerState<RankingHomePage> createState() => _RankingHomePageState();
}

class _RankingHomePageState extends ConsumerState<RankingHomePage> {
  final _searchController = TextEditingController();
  String _query = '';
  _StoreSegment _selectedSegment = _StoreSegment.all;
  _StoreRankingSort _selectedSort = _StoreRankingSort.recommended;

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

  int _compareRecommended(StoreRanking a, StoreRanking b) {
    if (_selectedSegment == _StoreSegment.all && a.isLocal != b.isLocal) {
      return a.isLocal ? -1 : 1;
    }
    final byDisplayScore = b.displayScore.compareTo(a.displayScore);
    if (byDisplayScore != 0) return byDisplayScore;
    final byReviews = b.reviewCount.compareTo(a.reviewCount);
    if (byReviews != 0) return byReviews;
    return b.rating.compareTo(a.rating);
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
    final rankings = ref.watch(storeRankingListProvider);
    final user =
        ref.watch(authStateProvider).asData?.value ??
        ref.read(authControllerProvider).currentUser;
    final isLoggedIn = user != null;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _RankingHeader(
              controller: _searchController,
              selectedSegment: _selectedSegment,
              selectedSort: _selectedSort,
              onSearchChanged: (value) => setState(() => _query = value),
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
                child: rankings.when(
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
                          onTap: () =>
                              context.go('/map/store/${ranking.storeId}'),
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
  final TextEditingController controller;
  final _StoreSegment selectedSegment;
  final _StoreRankingSort selectedSort;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<_StoreSegment> onSegmentSelected;
  final ValueChanged<_StoreRankingSort> onSortSelected;
  final bool isLoggedIn;
  final ValueChanged<_ProfileMenuAction> onProfileMenuSelect;

  const _RankingHeader({
    required this.controller,
    required this.selectedSegment,
    required this.selectedSort,
    required this.onSearchChanged,
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
          TextField(
            controller: controller,
            onChanged: onSearchChanged,
            decoration: InputDecoration(
              hintText: '카페명, 브랜드, 강점 검색',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                AppFilterChip(
                  label: '전체',
                  selected: selectedSegment == _StoreSegment.all,
                  onSelected: (_) => onSegmentSelected(_StoreSegment.all),
                  width: null,
                ),
                AppFilterChip(
                  label: '로컬',
                  selected: selectedSegment == _StoreSegment.local,
                  onSelected: (_) => onSegmentSelected(_StoreSegment.local),
                  width: null,
                ),
                AppFilterChip(
                  label: '프랜차이즈',
                  selected: selectedSegment == _StoreSegment.franchise,
                  onSelected: (_) => onSegmentSelected(_StoreSegment.franchise),
                  width: null,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                AppFilterChip(
                  label: '추천순',
                  selected: selectedSort == _StoreRankingSort.recommended,
                  onSelected: (_) =>
                      onSortSelected(_StoreRankingSort.recommended),
                  width: null,
                ),
                AppFilterChip(
                  label: '평점순',
                  selected: selectedSort == _StoreRankingSort.rating,
                  onSelected: (_) => onSortSelected(_StoreRankingSort.rating),
                  width: null,
                ),
                AppFilterChip(
                  label: '리뷰 많은 순',
                  selected: selectedSort == _StoreRankingSort.reviews,
                  onSelected: (_) => onSortSelected(_StoreRankingSort.reviews),
                  width: null,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const SectionTitle(
            title: 'Cafe Store Rankings',
            trailing: 'Local First',
          ),
        ],
      ),
    );
  }
}

enum _ProfileMenuAction { activity, login, logout }
