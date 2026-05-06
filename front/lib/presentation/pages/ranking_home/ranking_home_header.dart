import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'package:front/core/constants/app_colors.dart';
import 'package:front/core/constants/app_strings.dart';
import 'package:front/presentation/pages/ranking_home/ranking_home_types.dart';
import 'package:front/presentation/widgets/app_filter_chip.dart';
import 'package:front/presentation/widgets/section_title.dart';

class RankingHomeHeader extends StatelessWidget {
  final RankingAudience selectedAudience;
  final StoreRankingSort selectedSort;
  final ValueChanged<RankingAudience> onAudienceSelected;
  final ValueChanged<StoreRankingSort> onSortSelected;
  final bool isLoggedIn;
  final ValueChanged<ProfileMenuAction> onProfileMenuSelect;

  const RankingHomeHeader({
    super.key,
    required this.selectedAudience,
    required this.selectedSort,
    required this.onAudienceSelected,
    required this.onSortSelected,
    required this.isLoggedIn,
    required this.onProfileMenuSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
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
                    value: ProfileMenuAction.myRecord,
                    child: Text('내기록'),
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
          const SizedBox(height: 4),
          const Padding(
            padding: EdgeInsets.only(top: 2, bottom: 8),
            child: Text(
              '부부픽과 취향별 랭킹을 나눠서 보고, 실제 방문 기준으로 카페를 고를 수 있어요.',
              style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
          ),
          _RankingFilterScroller(
            children: [
              AppFilterChip(
                label: '부부픽',
                selected: selectedAudience == RankingAudience.couple,
                onSelected: (_) => onAudienceSelected(RankingAudience.couple),
                margin: const EdgeInsets.only(right: 8),
                width: null,
              ),
              AppFilterChip(
                label: '아내픽',
                selected: selectedAudience == RankingAudience.wife,
                onSelected: (_) => onAudienceSelected(RankingAudience.wife),
                margin: const EdgeInsets.only(right: 8),
                width: null,
              ),
              AppFilterChip(
                label: '남편픽',
                selected: selectedAudience == RankingAudience.husband,
                onSelected: (_) => onAudienceSelected(RankingAudience.husband),
                margin: const EdgeInsets.only(right: 8),
                width: null,
              ),
              AppFilterChip(
                label: '사용자픽',
                selected: selectedAudience == RankingAudience.user,
                onSelected: (_) => onAudienceSelected(RankingAudience.user),
                margin: const EdgeInsets.only(right: 8),
                width: null,
              ),
            ],
          ),
          const SizedBox(height: 4),
          _RankingFilterScroller(
            children: [
              AppFilterChip(
                label: '평점 높은순',
                selected: selectedSort == StoreRankingSort.rating,
                onSelected: (_) => onSortSelected(StoreRankingSort.rating),
                margin: const EdgeInsets.only(right: 8),
                width: null,
              ),
              AppFilterChip(
                label: '최근 방문순',
                selected: selectedSort == StoreRankingSort.recent,
                onSelected: (_) => onSortSelected(StoreRankingSort.recent),
                margin: const EdgeInsets.only(right: 8),
                width: null,
              ),
              AppFilterChip(
                label: '재방문 의사순',
                selected: selectedSort == StoreRankingSort.revisit,
                onSelected: (_) => onSortSelected(StoreRankingSort.revisit),
                margin: EdgeInsets.zero,
                width: null,
              ),
            ],
          ),
          const SizedBox(height: 8),
          SectionTitle(
            title: _titleForAudience(selectedAudience),
            trailing: '실제 방문 기준',
          ),
          const SizedBox(height: 2),
          Text(
            _descriptionForAudience(selectedAudience),
            style: const TextStyle(fontSize: 11, color: Colors.black54),
          ),
        ],
      ),
    );
  }

  String _titleForAudience(RankingAudience audience) {
    return switch (audience) {
      RankingAudience.couple => '부부픽 랭킹',
      RankingAudience.wife => '아내픽 랭킹',
      RankingAudience.husband => '남편픽 랭킹',
      RankingAudience.user => '사용자픽 랭킹',
    };
  }

  String _descriptionForAudience(RankingAudience audience) {
    return switch (audience) {
      RankingAudience.couple => '둘 다 좋게 평가한 카페부터 보여줍니다.',
      RankingAudience.wife => '감성, 분위기, 디저트 만족도가 높은 카페 기준입니다.',
      RankingAudience.husband => '커피, 작업성, 실용성이 좋은 카페 기준입니다.',
      RankingAudience.user => '일반 사용자 평균 점수 기준 랭킹입니다.',
    };
  }
}

class _RankingFilterScroller extends StatelessWidget {
  final List<Widget> children;

  const _RankingFilterScroller({required this.children});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
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
