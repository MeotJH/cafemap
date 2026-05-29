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
  final RankingPurpose? initialPurpose;

  const RankingHomeCafe({super.key, this.initialPurpose});

  @override
  ConsumerState<RankingHomeCafe> createState() => _RankingHomeCafeState();
}

class _RankingHomeCafeState extends ConsumerState<RankingHomeCafe> {
  static const String _allDistrictLabel = '전국';

  RankingAudience _selectedAudience = RankingAudience.couple;
  StoreRankingSort _selectedSort = StoreRankingSort.rating;
  String? _selectedDistrict;
  RankingPurpose? _selectedPurpose;

  @override
  void initState() {
    super.initState();
    _selectedPurpose = widget.initialPurpose;
  }

  @override
  void didUpdateWidget(covariant RankingHomeCafe oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialPurpose != widget.initialPurpose) {
      _selectedPurpose = widget.initialPurpose;
    }
  }

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

  List<String> _districtOptions(List<StoreRanking> items) {
    final districts = items
        .map((item) => item.district.trim())
        .where((item) => item.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    return <String>[_allDistrictLabel, ...districts];
  }

  Future<void> _showDistrictPicker(
    BuildContext context,
    List<String> options,
  ) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '지역 선택',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                const Text(
                  '보고 싶은 지역 랭킹만 골라서 볼 수 있어요.',
                  style: TextStyle(fontSize: 13, color: Colors.black54),
                ),
                const SizedBox(height: 14),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: options.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final option = options[index];
                      final isSelected = (_selectedDistrict == null &&
                              option == _allDistrictLabel) ||
                          _selectedDistrict == option;
                      return Material(
                        color: isSelected
                            ? const Color(0xFFF5EEE7)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        child: ListTile(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                              color: isSelected
                                  ? const Color(0xFF6F4E37)
                                  : const Color(0xFFE1D4C7),
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 2,
                          ),
                          leading: Icon(
                            option == _allDistrictLabel
                                ? Icons.public
                                : Icons.location_on_outlined,
                            color: isSelected
                                ? const Color(0xFF6F4E37)
                                : Colors.black54,
                          ),
                          title: Text(
                            option,
                            style: TextStyle(
                              fontWeight: isSelected
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                              color: isSelected
                                  ? const Color(0xFF6F4E37)
                                  : Colors.black87,
                            ),
                          ),
                          trailing: isSelected
                              ? const Icon(
                                  Icons.check_rounded,
                                  color: Color(0xFF6F4E37),
                                )
                              : null,
                          onTap: () => Navigator.of(context).pop(option),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (!mounted || selected == null) return;
    setState(() {
      _selectedDistrict = selected == _allDistrictLabel ? null : selected;
    });
  }

  @override
  Widget build(BuildContext context) {
    final rankings = ref.watch(
      storeRankingListProvider(
        StoreRankingQuery(
          audience: _selectedAudience,
          purpose: _selectedPurpose,
        ),
      ),
    );
    final districtOptions = _districtOptions(rankings.asData?.value ?? const []);
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
              selectedPurpose: _selectedPurpose,
              selectedDistrictLabel: _selectedDistrict ?? _allDistrictLabel,
              onAudienceSelected: (value) =>
                  setState(() => _selectedAudience = value),
              onSortSelected: (value) => setState(() => _selectedSort = value),
              onDistrictPressed: () =>
                  _showDistrictPicker(context, districtOptions),
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
                  selectedPurpose: _selectedPurpose,
                  selectedDistrict: _selectedDistrict,
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
  final RankingPurpose? selectedPurpose;
  final String? selectedDistrict;
  final ValueChanged<StoreRanking> onSelectRanking;

  const _RankingHomeCafeList({
    required this.rankings,
    required this.currentLocation,
    required this.selectedAudience,
    required this.selectedSort,
    required this.selectedPurpose,
    required this.selectedDistrict,
    required this.onSelectRanking,
  });

  List<StoreRanking> _filterRankings(List<StoreRanking> items) {
    final district = selectedDistrict;
    if (district == null) return items;
    return items.where((item) => item.district == district).toList();
  }

  List<StoreRanking> _sortRankings(List<StoreRanking> items) {
    if (selectedPurpose != null && selectedSort == StoreRankingSort.rating) {
      return items;
    }
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
    final regionPrefix = selectedDistrict == null ? '' : '$selectedDistrict에는 ';
    if (selectedPurpose != null) {
      return '$regionPrefix${selectedPurpose!.label} 추천 데이터가 아직 부족해요.';
    }
    return switch (selectedAudience) {
      RankingAudience.couple => '$regionPrefix아직 부부픽 랭킹이 없어요.',
      RankingAudience.wife => '$regionPrefix아직 아내픽 랭킹이 없어요.',
      RankingAudience.husband => '$regionPrefix아직 남편픽 랭킹이 없어요.',
      RankingAudience.user => '$regionPrefix아직 사용자 평가가 부족해요.',
    };
  }

  @override
  Widget build(BuildContext context) {
    return rankings.when(
      data: (items) {
        final filtered = _sortRankings(_filterRankings(items));
        if (filtered.isEmpty) {
          return Center(child: Text(_emptyMessage()));
        }
        return ListView.separated(
          padding: const EdgeInsets.only(bottom: 24),
          itemBuilder: (context, index) {
            final ranking = filtered[index];
            return StoreRankingCard(
              key: ValueKey(
                '${selectedAudience.name}_${selectedSort.name}_${selectedDistrict ?? 'all'}_${ranking.storeId}',
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
