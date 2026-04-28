import 'package:flutter/material.dart';
import 'package:front/presentation/widgets/app_filter_chip.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';

import 'package:front/core/constants/app_colors.dart';
import 'package:front/domain/entities/place_search_result.dart';
import 'package:front/domain/entities/store_summary.dart';
import 'package:front/presentation/pages/map_home/map_home_place_logic.dart';
import 'package:front/presentation/pages/map_home/map_search_page.dart';

class MapHomeTopOverlay extends StatelessWidget {
  final TextEditingController searchController;
  final bool isSearching;
  final String preferenceSummary;
  final String mapMode;
  final PlaceSearchResult? selectedPlace;
  final List<PlaceSearchResult> newPlaces;

  final VoidCallback onSearchClear;
  final ValueChanged<PlaceSearchResult> onSearchResultSelected;
  final VoidCallback onDiscoverPressed;
  final VoidCallback onClearNewPlaces;
  final ValueChanged<String> onMapModeChanged;

  const MapHomeTopOverlay({
    super.key,
    required this.searchController,
    required this.isSearching,
    required this.preferenceSummary,
    required this.mapMode,
    required this.selectedPlace,
    required this.newPlaces,
    required this.onSearchClear,
    required this.onSearchResultSelected,
    required this.onDiscoverPressed,
    required this.onClearNewPlaces,
    required this.onMapModeChanged,
  });

  Future<void> _openSearch(BuildContext context) async {
    final result = await showFullScreenSearchDialog(
      context,
      initialQuery: searchController.text,
    );
    if (result == null) return;

    searchController.text = result.name;
    searchController.selection = TextSelection.fromPosition(
      TextPosition(offset: result.name.length),
    );
    onSearchResultSelected(result);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final actionWidth = (screenWidth * 0.26).clamp(104.0, 132.0);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PointerInterceptor(
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppColors.cardBorder),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 10,
                            offset: Offset(0, 6),
                          ),
                        ],
                      ),
                      child: TextField(
                        readOnly: true,
                        onTap: () => _openSearch(context),
                        controller: searchController,
                        decoration: InputDecoration(
                          hintText: '카페 검색',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: ValueListenableBuilder<TextEditingValue>(
                            valueListenable: searchController,
                            builder: (context, value, child) {
                              if (value.text.isEmpty) {
                                return const SizedBox.shrink();
                              }
                              return IconButton(
                                onPressed: onSearchClear,
                                icon: const Icon(Icons.close),
                              );
                            },
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () => _openSearch(context),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(68, 52),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Icon(Icons.search),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            PointerInterceptor(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.cardBorder),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.tune_rounded,
                          color: AppColors.primary,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            preferenceSummary,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            AppFilterChip(
                              label: '전체 보기',
                              selected: mapMode == 'all',
                              onSelected: (_) => onMapModeChanged('all'),
                              margin: const EdgeInsets.only(right: 8),
                              width: null,
                            ),
                            AppFilterChip(
                              label: '추천만 보기',
                              selected: mapMode == 'recommended_only',
                              onSelected: (_) =>
                                  onMapModeChanged('recommended_only'),
                              margin: const EdgeInsets.only(right: 8),
                              width: null,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MapStatusBanner extends StatelessWidget {
  final bool isSearching;
  final String? errorMessage;
  final bool hasResolvedLocation;
  final int reviewedStoreCount;
  final int newCafeCount;

  const MapStatusBanner({
    super.key,
    required this.isSearching,
    required this.errorMessage,
    required this.hasResolvedLocation,
    required this.reviewedStoreCount,
    required this.newCafeCount,
  });

  @override
  Widget build(BuildContext context) {
    String message;
    if (isSearching) {
      message = '현재 지도 영역에서 새 카페를 찾는 중이에요.';
    } else if (errorMessage != null) {
      message = errorMessage!;
    } else if (newCafeCount > 0) {
      message =
          '리뷰된 카페 $reviewedStoreCount곳과 새 카페 $newCafeCount곳을 지도에 표시하고 있어요.';
    } else if (!hasResolvedLocation) {
      message = '위치 권한이 없어도 현재 보고 있는 지도를 기준으로 새 카페를 찾을 수 있어요.';
    } else {
      message = '리뷰가 있는 카페를 지도에 보여주고 있어요. 새 카페 찾기로 미평가 장소도 탐색할 수 있어요.';
    }

    final isError = !isSearching && errorMessage != null;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isError ? const Color(0xFFFFF1F2) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isError ? const Color(0xFFFDA4AF) : AppColors.cardBorder,
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          if (isSearching)
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2.2),
            )
          else
            Icon(
              isError ? Icons.error_outline : Icons.info_outline,
              color: isError ? const Color(0xFFE11D48) : AppColors.primary,
            ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 12,
                color: isError
                    ? const Color(0xFFBE123C)
                    : AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ReviewedStoreBottomCard extends StatelessWidget {
  final StoreSummary store;
  final VoidCallback onTap;

  const ReviewedStoreBottomCard({
    super.key,
    required this.store,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.cardBorder),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 16,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            MapHomeCardImage(
              imageUrl: store.imageUrl,
              fallbackIcon: Icons.local_cafe_rounded,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    store.isPersonalizedMatch ? '취향 추천 카페' : '리뷰된 카페',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    store.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      RatingBadge(rating: store.rating),
                      SizedBox(width: 6),
                      Text(
                        '${store.reviewCount}',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '리뷰',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  if (store.personalizedReasons.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      store.personalizedReasons.join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}

class NewCafeBottomCard extends StatelessWidget {
  final PlaceSearchResult place;
  final VoidCallback onTap;
  final VoidCallback onReviewTap;

  const NewCafeBottomCard({
    super.key,
    required this.place,
    required this.onTap,
    required this.onReviewTap,
  });

  @override
  Widget build(BuildContext context) {
    final address = MapHomePlaceLogic.resolveAddress(place);
    final hasLink = place.link.trim().isNotEmpty;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: hasLink ? onTap : null,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.cardBorder),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 16,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              const MapHomeCardImage(
                imageUrl: '',
                fallbackIcon: Icons.place_rounded,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasLink ? '새 카페 · 상세 보기' : '새 카페',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      place.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      address,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: onReviewTap,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  minimumSize: const Size(74, 38),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                ),
                child: const Text('리뷰'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MapHomeCardImage extends StatelessWidget {
  final String imageUrl;
  final IconData fallbackIcon;

  const MapHomeCardImage({
    super.key,
    required this.imageUrl,
    required this.fallbackIcon,
  });

  @override
  Widget build(BuildContext context) {
    final url = imageUrl.trim();
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 72,
        height: 72,
        color: AppColors.backgroundLight,
        padding: const EdgeInsets.all(8),
        child: url.isEmpty
            ? Icon(fallbackIcon, color: AppColors.primary, size: 28)
            : Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) =>
                    Icon(fallbackIcon, color: AppColors.primary, size: 28),
              ),
      ),
    );
  }
}

class RatingTone {
  final Color background;
  final Color foreground;

  const RatingTone({required this.background, required this.foreground});

  static RatingTone fromScore(double score) {
    if (score < 2.0) {
      return const RatingTone(
        background: Color(0xFFFFE8E8), // 옅은 빨강
        foreground: Color(0xFFD32F2F), // 진한 빨강
      );
    }

    if (score < 3.0) {
      return const RatingTone(
        background: Color(0xFFFFF4D6), // 옅은 노랑
        foreground: Color(0xFFF59E0B), // 진한 노랑/주황
      );
    }

    return const RatingTone(
      background: Color(0xFFDCFCE7), // 옅은 초록
      foreground: Color(0xFF166534), // 진한 초록
    );
  }
}

class RatingBadge extends StatelessWidget {
  final double rating;
  final int fractionDigits;

  const RatingBadge({super.key, required this.rating, this.fractionDigits = 2});

  @override
  Widget build(BuildContext context) {
    final tone = RatingTone.fromScore(rating);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: tone.background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '${rating.toStringAsFixed(fractionDigits)}점',
        style: TextStyle(
          color: tone.foreground,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          height: 1.1,
        ),
      ),
    );
  }
}
