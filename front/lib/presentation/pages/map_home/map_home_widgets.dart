import 'package:flutter/material.dart';
import 'package:front/presentation/pages/map_home/map_search_page.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';

import 'package:front/core/constants/app_colors.dart';
import 'package:front/domain/entities/place_search_result.dart';
import 'package:front/domain/entities/store_summary.dart';
import 'package:front/presentation/pages/map_home/map_home_place_logic.dart';

class MapHomeTopOverlay extends StatelessWidget {
  final TextEditingController searchController;
  final bool isPlaceSearching;
  final bool isSearching;
  final List<PlaceSearchResult> searchResults;
  final String? placeSearchError;
  final StoreSummary? selectedStore;
  final PlaceSearchResult? selectedPlace;
  final List<PlaceSearchResult> newPlaces;
  final ValueChanged<String> onSearchSubmitted;
  final VoidCallback onSearchPressed;
  final VoidCallback onSearchClear;
  final ValueChanged<PlaceSearchResult> onSearchResultSelected;
  final VoidCallback onDiscoverPressed;
  final VoidCallback onClearNewPlaces;

  const MapHomeTopOverlay({
    super.key,
    required this.searchController,
    required this.isPlaceSearching,
    required this.isSearching,
    required this.searchResults,
    required this.placeSearchError,
    required this.selectedStore,
    required this.selectedPlace,
    required this.newPlaces,
    required this.onSearchSubmitted,
    required this.onSearchPressed,
    required this.onSearchClear,
    required this.onSearchResultSelected,
    required this.onDiscoverPressed,
    required this.onClearNewPlaces,
  });

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
                        onTap: () async {
                          final keyword = await showFullScreenSearchDialog(
                            context,
                            initialQuery: searchController.text,
                          );
                          if (keyword == null || keyword.trim().isEmpty) {
                            return;
                          }

                          searchController.text = keyword;
                          searchController.selection =
                              TextSelection.fromPosition(
                                TextPosition(offset: keyword.length),
                              );
                          onSearchSubmitted(keyword);
                        },
                        controller: searchController,
                        onSubmitted: onSearchSubmitted,
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
                    onPressed: isPlaceSearching ? null : onSearchPressed,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(68, 52),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: isPlaceSearching
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
            ),
            if (selectedStore == null &&
                selectedPlace == null &&
                (searchResults.isNotEmpty || placeSearchError != null)) ...[
              const SizedBox(height: 10),
              PointerInterceptor(
                child: MapSearchResultPanel(
                  results: searchResults,
                  errorMessage: placeSearchError,
                  onSelect: onSearchResultSelected,
                ),
              ),
            ],
            const SizedBox(height: 10),
            PointerInterceptor(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: actionWidth,
                    child: FilledButton(
                      onPressed: isSearching ? null : onDiscoverPressed,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(48),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.explore_outlined, size: 18),
                          const SizedBox(height: 4),
                          Text(
                            newPlaces.isEmpty ? '새 카페 찾기' : '새 지역 다시',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (newPlaces.isNotEmpty || selectedPlace != null) ...[
                    const SizedBox(width: 8),
                    IconButton.filledTonal(
                      onPressed: onClearNewPlaces,
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.primary,
                        minimumSize: const Size(48, 48),
                      ),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ],
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
      message = '리뷰된 카페 $reviewedStoreCount곳과 새 카페 $newCafeCount곳을 지도에 표시했어요.';
    } else if (!hasResolvedLocation) {
      message = '위치 권한이 없어도 현재 보고 있는 지도 기준으로 새 카페를 찾을 수 있어요.';
    } else {
      message = '리뷰가 쌓인 카페만 지도에 보여줘요. 새 카페 버튼으로 바로 탐색할 수 있어요.';
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

class MapSearchResultPanel extends StatelessWidget {
  final List<PlaceSearchResult> results;
  final String? errorMessage;
  final ValueChanged<PlaceSearchResult> onSelect;

  const MapSearchResultPanel({
    super.key,
    required this.results,
    required this.errorMessage,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 280),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: errorMessage != null
          ? Padding(
              padding: const EdgeInsets.all(14),
              child: Text(
                errorMessage!,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
            )
          : ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: results.length,
              separatorBuilder: (context, index) =>
                  const Divider(height: 1, color: AppColors.cardBorder),
              itemBuilder: (context, index) {
                final item = results[index];
                return ListTile(
                  leading: const Icon(
                    Icons.place_outlined,
                    color: AppColors.primary,
                  ),
                  title: Text(
                    item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    MapHomePlaceLogic.resolveAddress(item),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () => onSelect(item),
                );
              },
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
                  const Text(
                    '리뷰된 카페',
                    style: TextStyle(
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
                  Text(
                    '${store.rating.toStringAsFixed(2)}점 · ${store.reviewCount} 리뷰',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
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
