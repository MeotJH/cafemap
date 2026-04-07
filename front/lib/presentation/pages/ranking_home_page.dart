import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:front/core/constants/app_sizes.dart';
import 'package:front/core/constants/app_strings.dart';
import 'package:front/domain/entities/brand_menu_ranking.dart';
import 'package:front/presentation/providers/ranking_providers.dart';
import 'package:front/presentation/providers/auth_providers.dart';
import 'package:front/presentation/widgets/app_filter_chip.dart';
import 'package:front/presentation/widgets/ranking_card.dart';
import 'package:front/presentation/widgets/section_title.dart';
import 'package:go_router/go_router.dart';

// 브랜드 메뉴 랭킹 홈 화면이다.
class RankingHomePage extends ConsumerStatefulWidget {
  const RankingHomePage({super.key});

  @override
  ConsumerState<RankingHomePage> createState() => _RankingHomePageState();
}

class _RankingHomePageState extends ConsumerState<RankingHomePage> {
  final _searchController = TextEditingController();
  String _query = '';
  String _selectedCategory = '전체';
  static const _defaultCategory = '전체';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<BrandMenuRanking> _filterRankings(List<BrandMenuRanking> items) {
    final query = _query.trim().toLowerCase();
    var filtered = items;
    if (_selectedCategory != _defaultCategory) {
      final category = _selectedCategory.toLowerCase();
      filtered = filtered
          .where((item) => item.category.toLowerCase() == category)
          .toList();
    }
    if (query.isEmpty) return filtered;
    return filtered.where((item) {
      final haystack = '${item.brandName} ${item.menuName}'.toLowerCase();
      return haystack.contains(query);
    }).toList();
  }

  List<String> _categoryOptions(List<BrandMenuRanking> items) {
    final preferredOrder = <String>[
      '커피',
      '라떼',
      '콜드브루',
      '핸드드립',
      '시그니처',
      '디저트음료',
    ];

    final categories = <String>{
      for (final item in items)
        item.category.trim().isEmpty ? '커피' : item.category.trim(),
    };
    final ordered = <String>[
      ...preferredOrder.where(categories.contains),
      ...categories.where((c) => !preferredOrder.contains(c)).toList()..sort(),
    ];
    return [_defaultCategory, ...ordered];
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
  // 랭킹 리스트와 상단 UI를 구성한다.
  Widget build(BuildContext context) {
    final rankings = ref.watch(rankingListProvider);
    final user =
        ref.watch(authStateProvider).asData?.value ??
        ref.read(authControllerProvider).currentUser;
    final isLoggedIn = user != null;
    final categories = rankings.maybeWhen(
      data: _categoryOptions,
      orElse: () => const [_defaultCategory],
    );
    final selectedCategory = categories.contains(_selectedCategory)
        ? _selectedCategory
        : _defaultCategory;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _RankingHeader(
              controller: _searchController,
              categories: categories,
              selectedCategory: selectedCategory,
              onSearchChanged: (value) => setState(() => _query = value),
              onCategorySelected: (value) =>
                  setState(() => _selectedCategory = value),
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
                    final rankIndexById = <String, int>{
                      for (var i = 0; i < items.length; i++) items[i].id: i,
                    };
                    final filtered = _filterRankings(items);
                    if (filtered.isEmpty) {
                      return const Center(child: Text('검색 결과가 없어요.'));
                    }
                    return ListView.separated(
                      padding: const EdgeInsets.only(bottom: 24),
                      itemBuilder: (context, index) {
                        final rankIndex =
                            rankIndexById[filtered[index].id] ?? index;
                        return RankingCard(
                          key: ValueKey(
                            '${_selectedCategory}_${filtered[index].id}_${filtered[index].imageUrl}',
                          ),
                          ranking: filtered[index],
                          rankIndex: rankIndex,
                          onTap: () => context.push(
                            '/ranking/${filtered[index].id}',
                            extra: filtered[index],
                          ),
                        );
                      },
                      separatorBuilder: (_, _) => const SizedBox(height: 16),
                      itemCount: filtered.length,
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (_, _) =>
                      const Center(child: Text('랭킹 정보를 불러오지 못했어요.')),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 랭킹 상단 영역을 구성한다.
class _RankingHeader extends StatelessWidget {
  final TextEditingController controller;
  final List<String> categories;
  final String selectedCategory;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onCategorySelected;
  final bool isLoggedIn;
  final ValueChanged<_ProfileMenuAction> onProfileMenuSelect;

  const _RankingHeader({
    required this.controller,
    required this.categories,
    required this.selectedCategory,
    required this.onSearchChanged,
    required this.onCategorySelected,
    required this.isLoggedIn,
    required this.onProfileMenuSelect,
  });

  @override
  // 검색창과 필터, 타이틀 영역을 구성한다.
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
                      Icons.restaurant,
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
              hintText: AppStrings.searchHintRanking,
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
                for (final category in categories)
                  AppFilterChip(
                    label: category,
                    selected: selectedCategory == category,
                    onSelected: onCategorySelected,
                    width: null,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const SectionTitle(
            title: 'Cafe Rankings',
            trailing: 'Updated Today',
          ),
        ],
      ),
    );
  }
}

enum _ProfileMenuAction { activity, login, logout }

