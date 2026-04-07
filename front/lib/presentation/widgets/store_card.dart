import 'package:flutter/material.dart';
import 'package:front/core/constants/app_colors.dart';
import 'package:front/core/constants/app_sizes.dart';
import 'package:front/core/utils/formatters.dart';
import 'package:front/domain/entities/store_summary.dart';

const _storeDefaultImageAsset = 'assets/cafe_store_default.png';

// 지점 하단 카드에서 사용하는 지점 카드 위젯이다.
class StoreCard extends StatelessWidget {
  final StoreSummary store;
  final VoidCallback onTap;
  final bool isSelected;

  const StoreCard({
    super.key,
    required this.store,
    required this.onTap,
    this.isSelected = false,
  });

  @override
  // 지점 카드에 요약 정보를 배치한다.
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 280,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppSizes.cardRadius),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.cardBorder,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: _StoreImageWithFallback(
                imageUrl: store.imageUrl,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    store.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    store.address,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.star, size: 16, color: AppColors.ratingStar),
                      const SizedBox(width: 4),
                      Text(
                        RatingFormatter.score(store.rating),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${store.reviewCount} 리뷰',
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StoreImageWithFallback extends StatelessWidget {
  final String imageUrl;

  const _StoreImageWithFallback({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    final url = imageUrl.trim();
    if (url.isEmpty) {
      return _buildSquareFrame(
        Image.asset(
          _storeDefaultImageAsset,
          fit: BoxFit.contain,
        ),
      );
    }
    return _buildSquareFrame(
      Image.network(
        url,
        fit: BoxFit.contain,
        webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
        errorBuilder: (context, error, stackTrace) => Image.asset(
          _storeDefaultImageAsset,
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  Widget _buildSquareFrame(Widget image) {
    return Container(
      width: 80,
      height: 80,
      color: Colors.white,
      padding: const EdgeInsets.all(6),
      child: image,
    );
  }
}

