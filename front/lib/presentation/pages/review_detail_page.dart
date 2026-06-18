import 'package:another_flushbar/flushbar.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:front/core/constants/app_colors.dart';
import 'package:front/core/constants/app_strings.dart';
import 'package:front/core/constants/rating_dimensions.dart';
import 'package:front/core/utils/formatters.dart';
import 'package:front/domain/entities/review.dart';
import 'package:front/presentation/providers/app_providers.dart';
import 'package:front/presentation/providers/auth_providers.dart';
import 'package:front/presentation/providers/ranking_providers.dart';
import 'package:front/presentation/providers/review_providers.dart';
import 'package:front/presentation/providers/store_providers.dart';
import 'package:front/presentation/widgets/review_media_gallery.dart';
import 'package:front/presentation/widgets/review_temperature_badge.dart';
import 'package:go_router/go_router.dart';

class ReviewDetailPage extends ConsumerWidget {
  final String reviewId;
  final Review? initialReview;

  const ReviewDetailPage({
    super.key,
    required this.reviewId,
    this.initialReview,
  });

  Future<void> _showTopToast(BuildContext context, String message) {
    return Flushbar<void>(
      message: message,
      duration: const Duration(seconds: 2),
      flushbarPosition: FlushbarPosition.TOP,
      backgroundColor: const Color(0xFF2A2A2A),
      margin: const EdgeInsets.all(12),
      borderRadius: BorderRadius.circular(10),
      icon: const Icon(Icons.info_outline, color: Colors.white),
    ).show(context);
  }

  Future<void> _onDestinationSelected(
    BuildContext context,
    WidgetRef ref,
    int index,
  ) async {
    switch (index) {
      case 0:
        context.go('/');
        break;
      case 1:
        context.go('/rankings');
        break;
      case 2:
        context.go('/map');
        break;
      case 3:
        final user =
            ref.read(authStateProvider).asData?.value ??
            ref.read(authControllerProvider).currentUser;
        if (user == null) {
          await _showTopToast(context, '내기록은 로그인 후에 확인할 수 있어요.');
          if (context.mounted) context.go('/auth');
          return;
        }
        context.go('/my');
        break;
    }
  }

  bool _canEditReview(WidgetRef ref, Review review) {
    // 현재 로그인 사용자와 리뷰 작성자가 같을 때만 수정 버튼을 노출한다.
    final user =
        ref.read(authStateProvider).asData?.value ??
        ref.read(authControllerProvider).currentUser;
    final currentEmail = user?.email?.trim().toLowerCase() ?? '';
    final reviewEmail = review.userEmail.trim().toLowerCase();
    return currentEmail.isNotEmpty && currentEmail == reviewEmail;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviewAsync = ref.watch(reviewDetailProvider(reviewId));

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(title: const Text('리뷰 상세'), centerTitle: true),
      body: reviewAsync.when(
        data: (review) => _ReviewDetailBody(
          review: review,
          canEdit: _canEditReview(ref, review),
        ),
        loading: () => initialReview == null
            ? const Center(child: CircularProgressIndicator())
            : _ReviewDetailBody(
                review: initialReview!,
                canEdit: _canEditReview(ref, initialReview!),
              ),
        error: (error, stackTrace) => initialReview == null
            ? const Center(child: Text('리뷰를 불러오지 못했어요.'))
            : _ReviewDetailBody(
                review: initialReview!,
                canEdit: _canEditReview(ref, initialReview!),
              ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
        onDestinationSelected: (index) =>
            _onDestinationSelected(context, ref, index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: AppStrings.homeTab,
          ),
          NavigationDestination(
            icon: Icon(Icons.emoji_events_outlined),
            selectedIcon: Icon(Icons.emoji_events),
            label: AppStrings.cafeRankingTab,
          ),
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map),
            label: AppStrings.mapTab,
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: AppStrings.activityTab,
          ),
        ],
      ),
    );
  }
}

class _ReviewDetailBody extends ConsumerStatefulWidget {
  final Review review;
  final bool canEdit;

  const _ReviewDetailBody({required this.review, required this.canEdit});

  @override
  ConsumerState<_ReviewDetailBody> createState() => _ReviewDetailBodyState();
}

class _ReviewDetailBodyState extends ConsumerState<_ReviewDetailBody> {
  static const String _coffeeSection = 'coffee';
  static const String _storeSection = 'store';

  String _selectedSection = _coffeeSection;
  bool _isDeleting = false;

  Future<void> _deleteReview() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('리뷰를 삭제할까요?'),
        content: const Text('삭제한 리뷰는 되돌릴 수 없어요.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
            ),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() {
      _isDeleting = true;
    });

    try {
      final auth = await ref.read(authControllerProvider).getAuthContext();
      if (auth == null) {
        throw const _DeleteReviewAuthRequired();
      }

      try {
        await ref
            .read(reviewRepositoryProvider)
            .deleteReview(widget.review.id, auth: auth);
      } on DioException catch (error) {
        if (!_isRecoverableUserSessionError(error)) rethrow;
        await ref.read(authApiProvider).syncUser(auth);
        await ref
            .read(reviewRepositoryProvider)
            .deleteReview(widget.review.id, auth: auth);
      }

      _invalidateReviewRelatedProviders();
      if (!mounted) return;
      if (context.canPop()) {
        context.pop(true);
      } else {
        context.go('/my');
      }
    } on _DeleteReviewAuthRequired {
      if (!mounted) return;
      await _showDeleteError('로그인이 필요해요. 다시 로그인해 주세요.');
      if (mounted) {
        context.go('/auth');
      }
    } on DioException catch (error) {
      if (!mounted) return;
      await _showDeleteError(_messageForDeleteError(error));
    } catch (_) {
      if (!mounted) return;
      await _showDeleteError('리뷰 삭제에 실패했어요. 잠시 후 다시 시도해 주세요.');
    } finally {
      if (mounted) {
        setState(() {
          _isDeleting = false;
        });
      }
    }
  }

  void _invalidateReviewRelatedProviders() {
    ref.invalidate(myReviewsProvider);
    ref.invalidate(rankingListProvider);
    ref.invalidate(storeRankingListProvider);
    ref.invalidate(reviewDetailProvider(widget.review.id));
    ref.invalidate(storeDetailProvider);
    ref.invalidate(storeBreakdownProvider);
    ref.invalidate(storeReviewsProvider);
    ref.invalidate(rankingReviewsProvider);
  }

  bool _isRecoverableUserSessionError(DioException error) {
    if (error.response?.statusCode != 401) return false;
    final detail = _errorDetail(error.response?.data).toLowerCase();
    return detail.contains('user session not initialized') ||
        detail.contains('user_not_synced');
  }

  String _messageForDeleteError(DioException error) {
    if (error.response?.statusCode == 401) {
      return '로그인 정보를 확인하지 못했어요. 다시 로그인해 주세요.';
    }
    final detail = _errorDetail(error.response?.data);
    if (detail.isNotEmpty) {
      return '리뷰 삭제에 실패했어요. $detail';
    }
    return '리뷰 삭제에 실패했어요. 잠시 후 다시 시도해 주세요.';
  }

  String _errorDetail(dynamic data) {
    if (data is Map<String, dynamic>) {
      final detail = data['detail'];
      if (detail is String && detail.isNotEmpty) return detail;
      final code = data['code'];
      if (code is String && code.isNotEmpty) return code;
    }
    return data?.toString() ?? '';
  }

  Future<void> _showDeleteError(String message) {
    return Flushbar<void>(
      message: message,
      duration: const Duration(seconds: 2),
      flushbarPosition: FlushbarPosition.TOP,
      backgroundColor: const Color(0xFF2A2A2A),
      margin: const EdgeInsets.all(12),
      borderRadius: BorderRadius.circular(10),
      icon: const Icon(Icons.error_outline, color: Colors.white),
    ).show(context);
  }

  @override
  Widget build(BuildContext context) {
    final entries = _selectedSection == _coffeeSection
        ? _orderedCoffeeEntries()
        : _orderedStoreEntries();
    final reviewMediaItems = reviewGalleryImagesFromMediaItems(
      widget.review.mediaItems,
    );

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.review.storeName,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Wrap(
                      spacing: 10,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          widget.review.menuName,
                          style: const TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF09142A),
                          ),
                        ),
                        if (widget.review.temperatureOption.isNotEmpty)
                          ReviewTemperatureBadge(
                            temperatureOption: widget.review.temperatureOption,
                          ),
                      ],
                    ),
                  ),
                  if (widget.canEdit) ...[
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      onPressed: _isDeleting
                          ? null
                          : () => context.push(
                              '/review/${widget.review.id}/edit',
                              extra: widget.review,
                            ),
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: const Text('수정'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: _isDeleting ? null : _deleteReview,
                      icon: _isDeleting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.delete_outline, size: 18),
                      label: Text(_isDeleting ? '삭제 중' : '삭제'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFDC2626),
                        side: const BorderSide(color: Color(0xFFDC2626)),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${widget.review.createdAt.year}년 ${widget.review.createdAt.month}월 ${widget.review.createdAt.day}일 작성',
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 17,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1, thickness: 1, color: Color(0xFFE8EDF3)),
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 32),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.star, size: 56, color: AppColors.ratingStar),
                  const SizedBox(width: 10),
                  Text(
                    RatingFormatter.score(widget.review.overall),
                    style: const TextStyle(
                      fontSize: 64,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                      height: 1,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                '평균 별점',
                style: TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 19,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1, thickness: 1, color: Color(0xFFE8EDF3)),
        if (reviewMediaItems.isNotEmpty)
          ReviewMediaSection(
            images: reviewMediaItems,
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
          ),
        if (reviewMediaItems.isNotEmpty)
          const Divider(height: 1, thickness: 1, color: Color(0xFFE8EDF3)),
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.analytics_rounded, color: AppColors.primary),
                  SizedBox(width: 8),
                  Text(
                    '상세 항목 평가',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              SizedBox(
                height: 36,
                child: Row(
                  children: [
                    ChoiceChip(
                      label: const Text('커피'),
                      selected: _selectedSection == _coffeeSection,
                      onSelected: (_) {
                        setState(() {
                          _selectedSection = _coffeeSection;
                        });
                      },
                      labelStyle: TextStyle(
                        color: _selectedSection == _coffeeSection
                            ? Colors.white
                            : AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                      backgroundColor: Colors.white,
                      selectedColor: AppColors.primary,
                      side: BorderSide(
                        color: _selectedSection == _coffeeSection
                            ? AppColors.primary
                            : AppColors.cardBorder,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('가게'),
                      selected: _selectedSection == _storeSection,
                      onSelected: (_) {
                        setState(() {
                          _selectedSection = _storeSection;
                        });
                      },
                      labelStyle: TextStyle(
                        color: _selectedSection == _storeSection
                            ? Colors.white
                            : AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                      backgroundColor: Colors.white,
                      selectedColor: AppColors.primary,
                      side: BorderSide(
                        color: _selectedSection == _storeSection
                            ? AppColors.primary
                            : AppColors.cardBorder,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              if (entries.isEmpty)
                const Text(
                  '표시할 평가 항목이 없어요.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ...entries.expand(
                (entry) => [
                  _ScoreRow(
                    label: ratingLabelForSchema(
                      entry.key,
                      widget.review.ratingSchemaVersion,
                    ),
                    value: entry.value,
                  ),
                  const SizedBox(height: 18),
                ],
              ),
              if (_visibleAttributes().isNotEmpty) ...[
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final attribute in _visibleAttributes())
                      _AttributeChip(label: attribute),
                  ],
                ),
              ],
            ],
          ),
        ),
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.15),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.chat_bubble, size: 18, color: AppColors.primary),
                    SizedBox(width: 6),
                    Text(
                      '코멘트',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w800,
                        fontSize: 17,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  widget.review.comment.isEmpty
                      ? '작성된 코멘트가 없어요.'
                      : widget.review.comment,
                  style: const TextStyle(
                    fontSize: 16,
                    height: 1.5,
                    color: Color(0xFF1F2937),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<MapEntry<String, double>> _orderedCoffeeEntries() {
    final preferred = dimensionsForCategoryForSchema(
      widget.review.menuCategory,
      widget.review.ratingSchemaVersion,
    );
    final result = <MapEntry<String, double>>[];

    for (final key in preferred) {
      final value = widget.review.scores[key];
      if (value != null) {
        result.add(MapEntry(key, value));
      }
    }

    return result;
  }

  List<MapEntry<String, double>> _orderedStoreEntries() {
    final result = <MapEntry<String, double>>[];

    for (final key in storeDimensionsForSchema(
      widget.review.ratingSchemaVersion,
      includeOptional: true,
    )) {
      final value = widget.review.scores[key];
      if (value != null) {
        result.add(MapEntry(key, value));
      }
    }

    return result;
  }

  List<String> _visibleAttributes() {
    final labels = <String>[];
    for (final entry in widget.review.attributes.entries) {
      if (entry.key == 'temperature_option') continue;
      final valueLabel = attributeValueLabel(entry.key, entry.value);
      if (valueLabel == '잘 모르겠음' || valueLabel == '미선택') continue;
      labels.add(_attributeBadgeLabel(entry.key, valueLabel));
    }
    return labels;
  }

  String _attributeBadgeLabel(String key, String valueLabel) {
    final label = attributeLabel(key);
    final normalizedValue = valueLabel.startsWith(label)
        ? valueLabel.substring(label.length).trim()
        : valueLabel;
    return '$label: $normalizedValue';
  }
}

class _AttributeChip extends StatelessWidget {
  final String label;

  const _AttributeChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ScoreRow extends StatelessWidget {
  final String label;
  final double value;

  const _ScoreRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final safeValue = value.clamp(0.0, 5.0);

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF334155),
                fontSize: 17,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '${safeValue.toStringAsFixed(1)} / 5.0',
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 9),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            minHeight: 12,
            value: safeValue / 5.0,
            backgroundColor: const Color(0xFFE7ECF2),
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
      ],
    );
  }
}

class _DeleteReviewAuthRequired implements Exception {
  const _DeleteReviewAuthRequired();
}
