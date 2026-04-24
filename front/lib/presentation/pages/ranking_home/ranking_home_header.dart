import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'package:front/core/constants/app_colors.dart';
import 'package:front/core/constants/app_strings.dart';
import 'package:front/presentation/pages/ranking_home/ranking_home_types.dart';
import 'package:front/presentation/widgets/app_filter_chip.dart';
import 'package:front/presentation/widgets/section_title.dart';

class RankingHomeHeader extends StatelessWidget {
  final RankingMode selectedMode;
  final StoreSegment selectedSegment;
  final StoreRankingSort selectedSort;
  final ValueChanged<StoreSegment> onSegmentSelected;
  final ValueChanged<StoreRankingSort> onSortSelected;
  final bool isLoggedIn;
  final ValueChanged<ProfileMenuAction> onProfileMenuSelect;

  const RankingHomeHeader({
    super.key,
    required this.selectedMode,
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
              PopupMenuButton<ProfileMenuAction>(
                tooltip: '프로필 메뉴',
                onSelected: onProfileMenuSelect,
                itemBuilder: (context) => [
                  const PopupMenuItem<ProfileMenuAction>(
                    value: ProfileMenuAction.activity,
                    child: Text('내 활동'),
                  ),
                  PopupMenuItem<ProfileMenuAction>(
                    value: isLoggedIn
                        ? ProfileMenuAction.logout
                        : ProfileMenuAction.login,
                    child: Text(isLoggedIn ? '로그아웃' : '로그인'),
                  ),
                ],
                icon: const Icon(Icons.account_circle),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (selectedMode == RankingMode.stores)
            const Padding(
              padding: EdgeInsets.only(top: 2, bottom: 12),
              child: Text(
                '랭킹은 리뷰가 쌓인 카페만 보여줘요. 실제 카페 검색은 지도에서 확인할 수 있어요.',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ),
          _RankingFilterScroller(
            children: [
              if (selectedMode == RankingMode.stores) ...[
                AppFilterChip(
                  label: '전체',
                  selected: selectedSegment == StoreSegment.all,
                  onSelected: (_) => onSegmentSelected(StoreSegment.all),
                  margin: const EdgeInsets.only(right: 8),
                  width: null,
                ),
                AppFilterChip(
                  label: '로컬',
                  selected: selectedSegment == StoreSegment.local,
                  onSelected: (_) => onSegmentSelected(StoreSegment.local),
                  margin: const EdgeInsets.only(right: 8),
                  width: null,
                ),
                AppFilterChip(
                  label: '프랜차이즈',
                  selected: selectedSegment == StoreSegment.franchise,
                  onSelected: (_) => onSegmentSelected(StoreSegment.franchise),
                  margin: const EdgeInsets.only(right: 8),
                  width: null,
                ),
              ],
              AppFilterChip(
                label: '평점순',
                selected: selectedSort == StoreRankingSort.rating,
                onSelected: (_) => onSortSelected(StoreRankingSort.rating),
                margin: const EdgeInsets.only(right: 8),
                width: null,
              ),
              AppFilterChip(
                label: '추천순',
                selected: selectedSort == StoreRankingSort.recommended,
                onSelected: (_) =>
                    onSortSelected(StoreRankingSort.recommended),
                margin: const EdgeInsets.only(right: 8),
                width: null,
              ),
              AppFilterChip(
                label: '리뷰 많은 순',
                selected: selectedSort == StoreRankingSort.reviews,
                onSelected: (_) => onSortSelected(StoreRankingSort.reviews),
                margin: EdgeInsets.zero,
                width: null,
              ),
            ],
          ),
          const SizedBox(height: 16),
          SectionTitle(
            title: selectedMode == RankingMode.stores
                ? 'Cafe Store Rankings'
                : 'Cafe Menu Rankings',
            trailing: selectedMode == RankingMode.stores
                ? '신뢰도 보정'
                : 'Franchise Menus',
          ),
          if (selectedMode == RankingMode.stores) ...[
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
