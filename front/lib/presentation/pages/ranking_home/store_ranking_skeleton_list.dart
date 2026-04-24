import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import 'package:front/core/constants/app_colors.dart';
import 'package:front/core/constants/app_sizes.dart';

class StoreRankingSkeletonList extends StatelessWidget {
  static const int _itemCount = 5;

  const StoreRankingSkeletonList({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFE8DDD2),
      highlightColor: Colors.white,
      child: ListView.separated(
        padding: const EdgeInsets.only(bottom: 24),
        itemCount: _itemCount,
        separatorBuilder: (_, _) => const SizedBox(height: 16),
        itemBuilder: (context, index) => const _StoreRankingSkeletonCard(),
      ),
    );
  }
}

class _StoreRankingSkeletonCard extends StatelessWidget {
  const _StoreRankingSkeletonCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.cardRadius + 6),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SkeletonBox(width: 32, height: 32, borderRadius: 999),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          _SkeletonBox(
                            width: 112,
                            height: 40,
                            borderRadius: 12,
                          ),
                          SizedBox(height: 10),
                          _SkeletonBox(width: 168, height: 20, borderRadius: 8),
                          SizedBox(height: 6),
                          _SkeletonBox(width: 92, height: 14, borderRadius: 8),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Padding(
                      padding: EdgeInsets.only(top: 2),
                      child: _SkeletonBox(
                        width: 74,
                        height: 24,
                        borderRadius: 999,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _SkeletonBox(width: 58, height: 24, borderRadius: 999),
                    _SkeletonBox(width: 76, height: 24, borderRadius: 999),
                    _SkeletonBox(width: 64, height: 24, borderRadius: 999),
                  ],
                ),
                const SizedBox(height: 12),
                const _SkeletonBox(
                  width: double.infinity,
                  height: 14,
                  borderRadius: 8,
                ),
                const SizedBox(height: 6),
                const _SkeletonBox(width: 220, height: 14, borderRadius: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SkeletonBox extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const _SkeletonBox({
    required this.width,
    required this.height,
    required this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.chipBackground,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}
