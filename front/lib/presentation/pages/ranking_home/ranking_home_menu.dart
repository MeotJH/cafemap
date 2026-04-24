import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:front/core/constants/app_sizes.dart';
import 'package:front/domain/entities/brand_menu_ranking.dart';
import 'package:front/presentation/pages/ranking_home/ranking_home_header.dart';
import 'package:front/presentation/pages/ranking_home/ranking_home_types.dart';
import 'package:front/presentation/providers/auth_providers.dart';
import 'package:front/presentation/providers/ranking_providers.dart';
import 'package:front/presentation/widgets/ranking_card.dart';

class RankingHomeMenu extends ConsumerStatefulWidget {
  const RankingHomeMenu({super.key});

  @override
  ConsumerState<RankingHomeMenu> createState() => _RankingHomeMenuState();
}

class _RankingHomeMenuState extends ConsumerState<RankingHomeMenu> {
  StoreRankingSort _selectedSort = StoreRankingSort.rating;

  Future<void> _handleProfileMenuSelect(
    BuildContext context,
    ProfileMenuAction action,
  ) async {
    switch (action) {
      case ProfileMenuAction.activity:
        final user =
            ref.read(authStateProvider).asData?.value ??
            ref.read(authControllerProvider).currentUser;
        if (user == null) {
          context.push('/auth');
          return;
        }
        context.go('/activity');
        break;
      case ProfileMenuAction.login:
        context.push('/auth');
        break;
      case ProfileMenuAction.logout:
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
    final rankings = ref.watch(rankingListProvider);
    final user =
        ref.watch(authStateProvider).asData?.value ??
        ref.read(authControllerProvider).currentUser;
    final isLoggedIn = user != null;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            RankingHomeHeader(
              selectedMode: RankingMode.menus,
              selectedSegment: StoreSegment.all,
              selectedSort: _selectedSort,
              onSegmentSelected: (_) {},
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
                child: _RankingHomeMenuList(
                  rankings: rankings,
                  selectedSort: _selectedSort,
                  onSelectRanking: (ranking) => context.go(
                    '/menu-ranking/${ranking.id}',
                    extra: ranking,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RankingHomeMenuList extends StatelessWidget {
  final AsyncValue<List<BrandMenuRanking>> rankings;
  final StoreRankingSort selectedSort;
  final ValueChanged<BrandMenuRanking> onSelectRanking;

  const _RankingHomeMenuList({
    required this.rankings,
    required this.selectedSort,
    required this.onSelectRanking,
  });

  List<BrandMenuRanking> _filterMenuRankings(List<BrandMenuRanking> items) {
    final filtered = items.toList();
    filtered.sort((a, b) {
      if (selectedSort == StoreRankingSort.reviews) {
        final byReviews = b.reviewCount.compareTo(a.reviewCount);
        if (byReviews != 0) return byReviews;
      }
      return b.rating.compareTo(a.rating);
    });
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return rankings.when(
      data: (items) {
        final filtered = _filterMenuRankings(items);
        if (filtered.isEmpty) {
          return const Center(child: Text('아직 메뉴 랭킹이 없어요.'));
        }
        return ListView.separated(
          padding: const EdgeInsets.only(bottom: 24),
          itemBuilder: (context, index) {
            final ranking = filtered[index];
            return RankingCard(
              key: ValueKey('menu_${selectedSort.name}_${ranking.id}'),
              ranking: ranking,
              rankIndex: index,
              onTap: () => onSelectRanking(ranking),
            );
          },
          separatorBuilder: (_, _) => const SizedBox(height: 16),
          itemCount: filtered.length,
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => const Center(child: Text('메뉴 랭킹을 불러오지 못했어요.')),
    );
  }
}
