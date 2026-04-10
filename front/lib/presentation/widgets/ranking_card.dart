import 'package:flutter/material.dart';
import 'package:front/core/constants/app_colors.dart';
import 'package:front/core/constants/app_sizes.dart';
import 'package:front/core/utils/formatters.dart';
import 'package:front/domain/entities/brand_menu_ranking.dart';

const _rankingDefaultImageAsset = 'assets/cafe_default.png';

// 랭킹 카드 UI를 표현하는 위젯이다.
class RankingCard extends StatelessWidget {
  final BrandMenuRanking ranking;
  final int rankIndex;
  final VoidCallback onTap;

  const RankingCard({
    super.key,
    required this.ranking,
    required this.rankIndex,
    required this.onTap,
  });

  @override
  // 랭킹 카드 전체 레이아웃을 그린다.
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 1040;
          return Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF8F8F8),
              borderRadius: BorderRadius.circular(AppSizes.cardRadius + 8),
              border: Border.all(color: AppColors.cardBorder),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: isWide ? _buildWideCard(context) : _buildNarrowCard(context),
          );
        },
      ),
    );
  }

  Widget _buildWideCard(BuildContext context) {
    return SizedBox(
      height: 320,
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Row(
          children: [
            Expanded(
              flex: 10,
              child: _VisualPanel(
                ranking: ranking,
                rankIndex: rankIndex,
                height: 276,
                posterWidth: 190,
                posterHeight: 228,
                compact: true,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 11,
              child: _ContentPanel(ranking: ranking, emphasizeTitle: true),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNarrowCard(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _VisualPanel(
            ranking: ranking,
            rankIndex: rankIndex,
            height: 260,
            posterWidth: 172,
            posterHeight: 210,
            compact: false,
          ),
          const SizedBox(height: 16),
          _ContentPanel(ranking: ranking, emphasizeTitle: false),
        ],
      ),
    );
  }
}

class _VisualPanel extends StatelessWidget {
  final BrandMenuRanking ranking;
  final int rankIndex;
  final double height;
  final double posterWidth;
  final double posterHeight;
  final bool compact;

  const _VisualPanel({
    required this.ranking,
    required this.rankIndex,
    required this.height,
    required this.posterWidth,
    required this.posterHeight,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF0DCCF), Color(0xFFEDE1D8), Color(0xFFF5F5F3)],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            left: 18,
            top: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '${rankIndex + 1}위',
                style: const TextStyle(
                  color: Color(0xFF2D3B50),
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                ),
              ),
            ),
          ),
          Positioned(
            right: 18,
            top: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.88),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.star_rounded,
                    size: 16,
                    color: AppColors.ratingStar,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    RatingFormatter.score(ranking.rating),
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.center,
            child: Container(
              width: posterWidth,
              height: posterHeight,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.94),
                borderRadius: BorderRadius.circular(6),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFB57954).withValues(alpha: 0.25),
                    blurRadius: compact ? 34 : 26,
                    offset: const Offset(-8, 12),
                  ),
                ],
              ),
              child: _NetworkImageWithFallback(
                imageUrl: ranking.imageUrl,
                fallbackAssetPath: _rankingDefaultImageAsset,
                height: posterHeight - 24,
                width: posterWidth - 24,
                fit: BoxFit.cover,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContentPanel extends StatelessWidget {
  final BrandMenuRanking ranking;
  final bool emphasizeTitle;

  const _ContentPanel({required this.ranking, required this.emphasizeTitle});

  @override
  Widget build(BuildContext context) {
    final titleStyle =
        (emphasizeTitle
                ? Theme.of(context).textTheme.headlineMedium
                : Theme.of(context).textTheme.headlineSmall)
            ?.copyWith(
              color: const Color(0xFF09142A),
              fontWeight: FontWeight.w800,
              height: 1.15,
            );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _BrandMeta(
          brandLogoUrl: ranking.brandLogoUrl,
          brandName: ranking.brandName,
        ),
        const SizedBox(height: 10),
        Text(
          ranking.menuName,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: titleStyle,
        ),
        const SizedBox(height: 12),
        Text(
          _summaryText(),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 17,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            _HighlightChip(
              label: ranking.highlightLabelA,
              value: ranking.highlightScoreA,
            ),
            _HighlightChip(
              label: ranking.highlightLabelB,
              value: ranking.highlightScoreB,
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              '${ranking.reviewCount} Reviews',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 16,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFFF5E00),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Text(
                '자세히 보기',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _summaryText() {
    return '${ranking.category} 카테고리에서 ${ranking.highlightLabelA} '
        '${RatingFormatter.score(ranking.highlightScoreA)}, '
        '${ranking.highlightLabelB} ${RatingFormatter.score(ranking.highlightScoreB)}로 '
        '균형 잡힌 만족감을 보여주는 메뉴예요.';
  }
}

class _BrandMeta extends StatelessWidget {
  final String brandLogoUrl;
  final String brandName;

  const _BrandMeta({required this.brandLogoUrl, required this.brandName});

  @override
  Widget build(BuildContext context) {
    final hasLogo = _isValidHttpUrl(brandLogoUrl);
    return Row(
      children: [
        CircleAvatar(
          radius: 12,
          backgroundColor: Colors.white,
          child: hasLogo
              ? ClipOval(
                  child: Image.network(
                    brandLogoUrl,
                    width: 24,
                    height: 24,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.restaurant,
                      size: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                )
              : const Icon(
                  Icons.restaurant,
                  size: 14,
                  color: AppColors.textSecondary,
                ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            brandName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  bool _isValidHttpUrl(String value) {
    final v = value.trim();
    if (v.isEmpty || v.toLowerCase() == 'null') return false;
    final uri = Uri.tryParse(v);
    return uri != null && (uri.scheme == 'http' || uri.scheme == 'https');
  }
}

class _NetworkImageWithFallback extends StatelessWidget {
  final String imageUrl;
  final String fallbackAssetPath;
  final double height;
  final double width;
  final BoxFit fit;

  const _NetworkImageWithFallback({
    required this.imageUrl,
    required this.fallbackAssetPath,
    required this.height,
    required this.width,
    required this.fit,
  });

  @override
  Widget build(BuildContext context) {
    final url = imageUrl.trim();
    if (!_isValidHttpUrl(url)) {
      return _buildImageFrame(
        Image.asset(
          fallbackAssetPath,
          key: ValueKey('asset_$fallbackAssetPath'),
          fit: fit,
        ),
      );
    }
    return _buildImageFrame(
      Image.network(
        url,
        key: ValueKey('net_$url'),
        fit: fit,
        errorBuilder: (context, error, stackTrace) => Image.asset(
          fallbackAssetPath,
          key: ValueKey('asset_$fallbackAssetPath'),
          fit: fit,
        ),
      ),
    );
  }

  Widget _buildImageFrame(Widget image) {
    return SizedBox(height: height, width: width, child: image);
  }

  bool _isValidHttpUrl(String value) {
    if (value.isEmpty || value.toLowerCase() == 'null') return false;
    final uri = Uri.tryParse(value);
    return uri != null && (uri.scheme == 'http' || uri.scheme == 'https');
  }
}

// ??궧 移대뱶???섏씠?쇱씠????ぉ???쒖떆?섎뒗 移⑹씠??
class _HighlightChip extends StatelessWidget {
  final String label;
  final double value;

  const _HighlightChip({required this.label, required this.value});

  @override
  // ?섏씠?쇱씠????ぉ ?띿뒪?몃? 諛곗튂?쒕떎.
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF2F7),
        borderRadius: BorderRadius.circular(999),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 220),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.thumb_up_alt_rounded,
              size: 14,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                '$label ${RatingFormatter.score(value)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
