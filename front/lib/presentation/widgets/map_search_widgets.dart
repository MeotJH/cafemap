import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:front/core/constants/app_colors.dart';
import 'package:front/data/local/map_search_history_storage.dart';
import 'package:front/domain/entities/place_search_result.dart';
import 'package:front/presentation/pages/map_home/map_home_place_logic.dart';

class MapSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isSearching;
  final VoidCallback onBack;
  final VoidCallback onClear;
  final ValueChanged<String> onSubmitted;

  const MapSearchBar({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.isSearching,
    required this.onBack,
    required this.onClear,
    required this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    final hasText = controller.text.trim().isNotEmpty;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.chipBackground,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              textInputAction: TextInputAction.search,
              onSubmitted: onSubmitted,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                hintText: '장소, 카페, 주소를 검색해 보세요',
                hintStyle: TextStyle(color: AppColors.textSecondary),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
          if (hasText)
            IconButton(
              onPressed: onClear,
              icon: const Icon(Icons.close_rounded),
            ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: isSearching || !hasText
                ? null
                : () => onSubmitted(controller.text),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size(48, 40),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: isSearching
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.search),
          ),
        ],
      ),
    );
  }
}

class MapSearchGuide extends StatelessWidget {
  final String keyword;
  final VoidCallback onSearch;

  const MapSearchGuide({
    super.key,
    required this.keyword,
    required this.onSearch,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
      children: [
        const Text(
          '검색',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          '"$keyword"로 장소 검색을 실행합니다.',
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 20),
        InkWell(
          onTap: onSearch,
          borderRadius: BorderRadius.circular(16),
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            decoration: BoxDecoration(
              color: AppColors.chipBackground,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: const Row(
              children: [
                Icon(Icons.search_rounded, color: AppColors.primary),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '이 검색어로 지도에서 찾아보기',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                Icon(Icons.arrow_forward_ios_rounded, size: 16),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class MapSearchResultSection extends StatelessWidget {
  final bool isSearching;
  final List<PlaceSearchResult> results;
  final String? errorMessage;
  final ValueChanged<PlaceSearchResult> onSelect;

  const MapSearchResultSection({
    super.key,
    required this.isSearching,
    required this.results,
    required this.errorMessage,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    if (isSearching) {
      return const Center(child: CircularProgressIndicator());
    }

    if (errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Text(
            errorMessage!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              height: 1.5,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: results.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final item = results[index];
        return Material(
          color: AppColors.chipBackground,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: () => onSelect(item),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: AppColors.backgroundLight,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.place_rounded,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          MapHomePlaceLogic.resolveAddress(item),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class MapSearchHistorySection extends StatelessWidget {
  final List<MapSearchHistoryItem> history;
  final DateFormat dateFormat;
  final ValueChanged<String> onSelect;
  final ValueChanged<String> onDelete;
  final VoidCallback onClearAll;

  const MapSearchHistorySection({
    super.key,
    required this.history,
    required this.dateFormat,
    required this.onSelect,
    required this.onDelete,
    required this.onClearAll,
  });

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 32),
          child: Text(
            '아직 검색 기록이 없습니다.\n검색어를 입력하면 여기에 저장됩니다.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 10),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  '최근 검색',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              TextButton(
                onPressed: onClearAll,
                child: const Text('전체 삭제'),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            itemCount: history.length,
            separatorBuilder: (context, index) => const SizedBox(height: 6),
            itemBuilder: (context, index) {
              final item = history[index];
              return MapSearchHistoryTile(
                keyword: item.keyword,
                dateLabel: dateFormat.format(item.searchedAt),
                onTap: () => onSelect(item.keyword),
                onDelete: () => onDelete(item.keyword),
              );
            },
          ),
        ),
      ],
    );
  }
}

class MapSearchHistoryTile extends StatelessWidget {
  final String keyword;
  final String dateLabel;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const MapSearchHistoryTile({
    super.key,
    required this.keyword,
    required this.dateLabel,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.chipBackground,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: AppColors.backgroundLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.history_rounded,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  keyword,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                dateLabel,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(
                  Icons.close_rounded,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
