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
  StoreSegment _selectedSegment = StoreSegment.all;
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
    final rankings = ref.watch(storeRankingListProvider);
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
              selectedMode: RankingMode.stores,
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
                child: _RankingHomeCafeList(
                  rankings: rankings,
                  currentLocation: currentLocation,
                  selectedSegment: _selectedSegment,
                  selectedSort: _selectedSort,
                  onSelectRanking: (ranking) =>
                      context.push('/ranking/store/${ranking.storeId}'),
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
  final StoreSegment selectedSegment;
  final StoreRankingSort selectedSort;
  final ValueChanged<StoreRanking> onSelectRanking;

  const _RankingHomeCafeList({
    required this.rankings,
    required this.currentLocation,
    required this.selectedSegment,
    required this.selectedSort,
    required this.onSelectRanking,
  });

  List<StoreRanking> _filterRankings(List<StoreRanking> items) {
    final filtered = items.where((item) {
      return switch (selectedSegment) {
        StoreSegment.all => true,
        StoreSegment.local => item.isLocal,
        StoreSegment.franchise => !item.isLocal,
      };
    }).toList();

    filtered.sort((a, b) {
      return switch (selectedSort) {
        StoreRankingSort.recommended => _compareRecommended(a, b),
        StoreRankingSort.rating => b.rating.compareTo(a.rating),
        StoreRankingSort.reviews => b.reviewCount.compareTo(a.reviewCount),
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

  @override
  Widget build(BuildContext context) {
    return rankings.when(
      data: (items) {
        final filtered = _filterRankings(items);
        if (filtered.isEmpty) {
          return const Center(child: Text('아직 카페 랭킹이 없어요.'));
        }
        return ListView.separated(
          padding: const EdgeInsets.only(bottom: 24),
          itemBuilder: (context, index) {
            final ranking = filtered[index];
            return StoreRankingCard(
              key: ValueKey(
                '${selectedSegment.name}_${selectedSort.name}_${ranking.storeId}',
              ),
              ranking: ranking,
              rankIndex: index,
              distanceKm: _distanceFromCurrentKm(ranking),
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
