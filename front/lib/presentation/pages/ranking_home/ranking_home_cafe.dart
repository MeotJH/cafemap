import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';

import 'package:front/core/constants/app_sizes.dart';
import 'package:front/domain/entities/store_ranking.dart';
import 'package:front/presentation/pages/ranking_home/ranking_home_header.dart';
import 'package:front/presentation/pages/ranking_home/ranking_home_types.dart';
import 'package:front/presentation/pages/ranking_home/store_ranking_skeleton_list.dart';
import 'package:front/presentation/providers/app_providers.dart';
import 'package:front/presentation/providers/auth_providers.dart';
import 'package:front/presentation/providers/ranking_providers.dart';
import 'package:front/presentation/widgets/store_ranking_card.dart';

class RankingHomeCafe extends ConsumerStatefulWidget {
  const RankingHomeCafe({super.key});

  @override
  ConsumerState<RankingHomeCafe> createState() => _RankingHomeCafeState();
}

class _RankingHomeCafeState extends ConsumerState<RankingHomeCafe> {
  RankingAudience _selectedAudience = RankingAudience.couple;
  StoreRankingSort _selectedSort = StoreRankingSort.rating;

  Future<void> _handleProfileMenuSelect(
    BuildContext context,
    ProfileMenuAction action,
  ) async {
    switch (action) {
      case ProfileMenuAction.myRecord:
        final user =
            ref.read(authStateProvider).asData?.value ??
            ref.read(authControllerProvider).currentUser;
        if (user == null) {
          context.push('/auth');
          return;
        }
        context.go('/my');
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
        context.go('/rankings');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final rankings = ref.watch(storeRankingListProvider(_selectedAudience));
    final currentLocation = ref.watch(currentLocationProvider);
    final user =
        ref.watch(authStateProvider).asData?.value ??
        ref.read(authControllerProvider).currentUser;
    final isLoggedIn = user != null;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            RankingHomeHeader(
              selectedAudience: _selectedAudience,
              selectedSort: _selectedSort,
              onAudienceSelected: (value) =>
                  setState(() => _selectedAudience = value),
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
                child: _RankingHomeCafeList(
                  rankings: rankings,
                  currentLocation: currentLocation,
                  selectedAudience: _selectedAudience,
                  selectedSort: _selectedSort,
                  onSelectRanking: (ranking) =>
                      context.push('/cafes/${ranking.storeId}'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RankingHomeCafeList extends StatelessWidget {
  final AsyncValue<List<StoreRanking>> rankings;
  final AppLocationState currentLocation;
  final RankingAudience selectedAudience;
  final StoreRankingSort selectedSort;
  final ValueChanged<StoreRanking> onSelectRanking;

  const _RankingHomeCafeList({
    required this.rankings,
    required this.currentLocation,
    required this.selectedAudience,
    required this.selectedSort,
    required this.onSelectRanking,
  });

  List<StoreRanking> _sortRankings(List<StoreRanking> items) {
    final sorted = [...items];
    sorted.sort((a, b) {
      return switch (selectedSort) {
        StoreRankingSort.rating => _scoreForAudience(
          b,
        ).compareTo(_scoreForAudience(a)),
        StoreRankingSort.recent =>
          (b.latestVisitedAt ?? DateTime(1970)).compareTo(
            a.latestVisitedAt ?? DateTime(1970),
          ),
        StoreRankingSort.revisit => b.revisitScore.compareTo(a.revisitScore),
      };
    });
    return sorted;
  }

  double _scoreForAudience(StoreRanking ranking) {
    return switch (selectedAudience) {
      RankingAudience.couple => ranking.coupleScore,
      RankingAudience.wife => ranking.wifeScore,
      RankingAudience.husband => ranking.husbandScore,
      RankingAudience.user => ranking.userScore,
    };
  }

  double _distanceFromCurrentKm(StoreRanking ranking) {
    if (ranking.lat == 0.0 && ranking.lng == 0.0) {
      return ranking.distanceKm;
    }
    final meters = Geolocator.distanceBetween(
      currentLocation.latitude,
      currentLocation.longitude,
      ranking.lat,
      ranking.lng,
    );
    return meters / 1000;
  }

  String _emptyMessage() {
    return switch (selectedAudience) {
      RankingAudience.couple => '아직 부부픽 랭킹이 없어요.',
      RankingAudience.wife => '아직 아내픽 랭킹이 없어요.',
      RankingAudience.husband => '아직 남편픽 랭킹이 없어요.',
      RankingAudience.user => '아직 사용자 평가가 부족합니다.',
    };
  }

  @override
  Widget build(BuildContext context) {
    return rankings.when(
      data: (items) {
        final filtered = _sortRankings(items);
        if (filtered.isEmpty) {
          return Center(child: Text(_emptyMessage()));
        }
        return ListView.separated(
          padding: const EdgeInsets.only(bottom: 24),
          itemBuilder: (context, index) {
            final ranking = filtered[index];
            return StoreRankingCard(
              key: ValueKey(
                '${selectedAudience.name}_${selectedSort.name}_${ranking.storeId}',
              ),
              ranking: ranking,
              rankIndex: index,
              distanceKm: _distanceFromCurrentKm(ranking),
              audience: selectedAudience,
              onTap: () => onSelectRanking(ranking),
            );
          },
          separatorBuilder: (_, _) => const SizedBox(height: 16),
          itemCount: filtered.length,
        );
      },
      loading: () => const StoreRankingSkeletonList(),
      error: (_, _) => const Center(child: Text('카페 랭킹을 불러오지 못했어요.')),
    );
  }
}
