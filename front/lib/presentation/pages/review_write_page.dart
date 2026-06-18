import 'package:another_flushbar/flushbar.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:front/app/write_cafe_review_button.dart';
import 'package:front/core/constants/app_colors.dart';
import 'package:front/core/constants/rating_dimensions.dart';
import 'package:front/domain/entities/review.dart';
import 'package:front/domain/entities/brand.dart';
import 'package:front/domain/entities/menu.dart';
import 'package:front/presentation/pages/review_write/review_write_media_widgets.dart';
import 'package:front/presentation/providers/review_write_provider.dart';
import 'package:front/presentation/utils/review_video_metadata.dart';
import 'package:front/presentation/utils/web_image_picker.dart';
import 'package:front/presentation/utils/web_review_media_picker.dart';
import 'package:front/presentation/widgets/rating_choice_chip.dart';
import 'package:front/presentation/widgets/rating_slider.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

class ReviewWritePage extends ConsumerStatefulWidget {
  final String? storeName;
  final String? address;
  final String? placeId;
  final String? link;
  final double? lat;
  final double? lng;
  final String? menuName;
  final String? brandId;
  final String? brandName;
  final String? reviewId;
  final Review? initialReview;

  const ReviewWritePage({
    super.key,
    this.storeName,
    this.address,
    this.placeId,
    this.link,
    this.lat,
    this.lng,
    this.menuName,
    this.brandId,
    this.brandName,
    this.reviewId,
    this.initialReview,
  });

  @override
  ConsumerState<ReviewWritePage> createState() => _ReviewWritePageState();
}

class _ReviewWritePageState extends ConsumerState<ReviewWritePage> {
  final _menuSearchController = TextEditingController();
  final _commentController = TextEditingController();
  final _imagePicker = ImagePicker();

  ReviewWriteRouteArgs get _args => ReviewWriteRouteArgs(
    storeName: widget.storeName,
    address: widget.address,
    placeId: widget.placeId,
    link: widget.link,
    lat: widget.lat,
    lng: widget.lng,
    menuName: widget.menuName,
    brandId: widget.brandId,
    brandName: widget.brandName,
    reviewId: widget.reviewId,
    initialReview: widget.initialReview,
  );

  ReviewWriteController get _controller =>
      ref.read(reviewWriteControllerProvider(_args).notifier);

  @override
  void initState() {
    super.initState();
    Future.microtask(() => _controller.initialize());
  }

  @override
  void dispose() {
    ref.invalidate(reviewWriteControllerProvider(_args));
    _menuSearchController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _showTopToast(String message) async {
    if (!mounted) return;
    await Flushbar<void>(
      message: message,
      duration: const Duration(seconds: 2),
      flushbarPosition: FlushbarPosition.TOP,
      backgroundColor: const Color(0xFF2A2A2A),
      margin: const EdgeInsets.all(12),
      borderRadius: BorderRadius.circular(10),
      icon: const Icon(Icons.info_outline, color: Colors.white),
    ).show(context);
  }

  void _syncControllers(ReviewWriteState state) {
    if (_menuSearchController.text != state.menuSearchText) {
      _menuSearchController.value = TextEditingValue(
        text: state.menuSearchText,
        selection: TextSelection.collapsed(offset: state.menuSearchText.length),
      );
    }
    if (_commentController.text != state.commentText) {
      _commentController.value = TextEditingValue(
        text: state.commentText,
        selection: TextSelection.collapsed(offset: state.commentText.length),
      );
    }
  }

  Future<bool> _confirmBrandChange(
    ReviewWriteState state,
    Brand nextBrand,
  ) async {
    final current = state.lastConfirmedBrand;
    if (current == null || current.id == nextBrand.id) {
      return true;
    }
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('브랜드 변경'),
        content: Text(
          '${current.name}에서 ${nextBrand.name}로 변경할까요?\n메뉴 선택이 초기화될 수 있어요.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('변경'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _handleSubmit(ReviewWriteState state) async {
    final result = await _controller.submit();
    if (!mounted) return;

    if (result.message != null && result.message!.isNotEmpty) {
      await _showTopToast(result.message!);
    }

    if (result.needsAuth) {
      if (!mounted) return;
      context.push('/auth');
      return;
    }

    final review = result.review;
    if (review == null) return;
    if (!mounted) return;
    if (state.isEditMode) {
      context.go('/review/${review.id}', extra: review);
    } else {
      context.push('/review/${review.id}', extra: review);
    }
  }

  Future<void> _showMediaPickerOptions(ReviewWriteState state) async {
    final remaining = reviewWriteMaxMedia - state.currentMediaCount;
    if (remaining <= 0) {
      await _showTopToast('사진과 영상은 최대 $reviewWriteMaxMedia개까지 첨부할 수 있어요.');
      return;
    }
    if (kIsWeb) {
      await _pickWebMedia(remaining);
      return;
    }
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('사진 추가'),
              onTap: () async {
                Navigator.of(context).pop();
                await _pickImages();
              },
            ),
            ListTile(
              leading: const Icon(Icons.videocam_outlined),
              title: const Text('영상 추가'),
              onTap: () async {
                Navigator.of(context).pop();
                await _pickVideo();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickWebMedia(int remaining) async {
    final webPicked = await pickWebReviewMedia(multiple: remaining > 1);
    if (webPicked.isEmpty) return;

    final next = <ReviewWriteLocalMedia>[];
    for (final item in webPicked) {
      if (next.length >= remaining) break;
      if (!_isSupportedMediaContentType(item.mimeType)) continue;
      final contentType = _contentTypeFromName(
        item.fileName,
        fallbackContentType: item.mimeType,
      );
      next.add(
        ReviewWriteLocalMedia(
          fileName: item.fileName.isNotEmpty
              ? item.fileName
              : 'review_${DateTime.now().millisecondsSinceEpoch}',
          contentType: contentType,
          bytes: item.bytes,
          durationMs: contentType.startsWith('video/')
              ? await _readWebVideoDurationMs(
                  bytes: item.bytes,
                  contentType: contentType,
                )
              : null,
        ),
      );
    }

    final message = _controller.appendSelectedMedia(next);
    if (message != null) {
      await _showTopToast(message);
    }
  }

  Future<void> _pickImages() async {
    final state = ref.read(reviewWriteControllerProvider(_args));
    final remaining = reviewWriteMaxMedia - state.currentMediaCount;
    if (remaining <= 0) {
      await _showTopToast('사진은 최대 $reviewWriteMaxMedia개까지 첨부할 수 있어요.');
      return;
    }

    List<XFile> picked;
    if (kIsWeb) {
      final webPicked = await pickWebImages(multiple: remaining > 1);
      if (webPicked.isEmpty) return;
      final next = webPicked
          .take(remaining)
          .map(
            (item) => ReviewWriteLocalMedia(
              fileName: item.fileName.isNotEmpty
                  ? item.fileName
                  : 'review_${DateTime.now().millisecondsSinceEpoch}.jpg',
              contentType: item.mimeType,
              bytes: item.bytes,
            ),
          )
          .toList();
      final message = _controller.appendSelectedMedia(next);
      if (message != null) {
        await _showTopToast(message);
      }
      return;
    }

    try {
      picked = await _imagePicker.pickMultiImage(imageQuality: 85);
    } catch (_) {
      final single = await _tryPickSingleImage();
      if (single == null) return;
      picked = [single];
    }
    if (picked.isEmpty) return;

    final next = <ReviewWriteLocalMedia>[];
    for (final file in picked.take(remaining)) {
      final bytes = await file.readAsBytes();
      next.add(
        ReviewWriteLocalMedia(
          fileName: file.name.isNotEmpty
              ? file.name
              : 'review_${DateTime.now().millisecondsSinceEpoch}.jpg',
          contentType: _contentTypeFromName(file.name),
          bytes: bytes,
        ),
      );
    }

    final message = _controller.appendSelectedMedia(next);
    if (message != null) {
      await _showTopToast(message);
    }
  }

  Future<XFile?> _tryPickSingleImage() async {
    try {
      return await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
    } on PlatformException catch (error) {
      if (error.code == 'photo_access_denied') {
        await _showTopToast('사진 권한이 꺼져 있어요. 설정에서 허용해주세요.');
        return null;
      }
      await _showTopToast('사진 선택 실패: ${error.message ?? error.code}');
      return null;
    } catch (error) {
      await _showTopToast('사진 선택 실패: $error');
      return null;
    }
  }

  Future<void> _pickVideo() async {
    final state = ref.read(reviewWriteControllerProvider(_args));
    final remaining = reviewWriteMaxMedia - state.currentMediaCount;
    if (remaining <= 0) {
      await _showTopToast('사진과 영상은 최대 $reviewWriteMaxMedia개까지 첨부할 수 있어요.');
      return;
    }
    try {
      final file = await _imagePicker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(seconds: 30),
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      final durationMs = await _readNativeVideoDurationMs(file);
      final message = _controller.appendSelectedMedia([
        ReviewWriteLocalMedia(
          fileName: file.name.isNotEmpty
              ? file.name
              : 'review_${DateTime.now().millisecondsSinceEpoch}.mp4',
          contentType: _contentTypeFromName(file.name),
          bytes: bytes,
          durationMs: durationMs,
        ),
      ]);
      if (message != null) {
        await _showTopToast(message);
      }
    } on PlatformException catch (error) {
      await _showTopToast('영상 선택에 실패했어요. ${error.message ?? error.code}');
    } catch (error) {
      await _showTopToast('영상 선택에 실패했어요. $error');
    }
  }

  String _contentTypeFromName(
    String fileName, {
    String fallbackContentType = 'image/jpeg',
  }) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.gif')) return 'image/gif';
    if (lower.endsWith('.heic')) return 'image/heic';
    if (lower.endsWith('.heif')) return 'image/heif';
    if (lower.endsWith('.mp4')) return 'video/mp4';
    if (lower.endsWith('.mov')) return 'video/quicktime';
    if (lower.endsWith('.webm')) return 'video/webm';
    if (_isSupportedMediaContentType(fallbackContentType)) {
      return fallbackContentType.toLowerCase();
    }
    return 'image/jpeg';
  }

  bool _isSupportedMediaContentType(String contentType) {
    return {
      'image/jpeg',
      'image/jpg',
      'image/png',
      'image/webp',
      'image/gif',
      'image/heic',
      'image/heif',
      'video/mp4',
      'video/quicktime',
      'video/webm',
    }.contains(contentType.toLowerCase());
  }

  Future<int?> _readNativeVideoDurationMs(XFile file) async {
    final metadata = await loadReviewVideoMetadata(filePath: file.path);
    return metadata.durationMs;
  }

  Future<int?> _readWebVideoDurationMs({
    required Uint8List bytes,
    required String contentType,
  }) async {
    final metadata = await loadReviewVideoMetadata(
      bytes: bytes,
      contentType: contentType,
    );
    return metadata.durationMs;
  }

  String _formatMediaDuration(int? durationMs) {
    if (durationMs == null || durationMs <= 0) {
      return '';
    }
    final totalSeconds = durationMs ~/ 1000;
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  Widget _buildTemperatureChip({
    required ReviewWriteState state,
    required String label,
    required String value,
  }) {
    return RatingChoiceChip(
      label: label,
      selected: state.selectedTemperatureOption == value,
      onTap: () => _controller.updateTemperatureOption(value),
    );
  }

  Widget _buildAttributeChoiceGroup(ReviewWriteState state, String key) {
    final options = ratingAttributeValueLabels[key] ?? const <String, String>{};
    final selected = state.attributes[key] ?? defaultAttributeValue(key);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          attributeLabel(key),
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final entry in options.entries)
              RatingChoiceChip(
                label: entry.value,
                selected: selected == entry.key,
                neutral:
                    entry.key == 'unknown' ||
                    entry.key == 'not_used' ||
                    entry.key == 'unspecified',
                onTap: () => _controller.updateAttribute(key, entry.key),
              ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(reviewWriteControllerProvider(_args));
    _syncControllers(state);

    final viewInsets = MediaQuery.viewInsetsOf(context);
    final bottomSafeArea = MediaQuery.paddingOf(context).bottom;
    final isKeyboardVisible = viewInsets.bottom > 0;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text(state.pageTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
              return;
            }
            context.go('/rankings');
          },
        ),
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => FocusScope.of(context).unfocus(),
        child: SafeArea(
          child: state.isBootstrapping
              ? const Center(child: CircularProgressIndicator())
              : state.bootstrapError != null
              ? Center(child: Text(state.bootstrapError!))
              : ListView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.manual,
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 24 + bottomSafeArea),
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.2),
                            ),
                            color: AppColors.backgroundLight,
                          ),
                          child: const Icon(
                            Icons.store,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                state.storeName ?? '카페를 선택해주세요.',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if ((state.address ?? '').isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  state.address!,
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 8),
                              if (state.isLocalBrandSelected &&
                                  !state.isBrandLocked) ...[
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 14,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: AppColors.cardBorder,
                                    ),
                                  ),
                                  child: const Row(
                                    children: [
                                      Icon(
                                        Icons.storefront_rounded,
                                        color: AppColors.primary,
                                        size: 18,
                                      ),
                                      SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          '개인 카페로 리뷰를 작성해요',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ] else ...[
                                DropdownButtonFormField<Brand>(
                                  initialValue: state.selectedBrand,
                                  items: state.brands
                                      .map(
                                        (brand) => DropdownMenuItem(
                                          value: brand,
                                          child: Text(brand.name),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: state.isBrandLocked
                                      ? null
                                      : (brand) async {
                                          if (brand == null) return;
                                          if (!await _confirmBrandChange(
                                            state,
                                            brand,
                                          )) {
                                            return;
                                          }
                                          await _controller.selectBrand(brand);
                                        },
                                  decoration: InputDecoration(
                                    hintText: '브랜드 선택',
                                    filled: true,
                                    fillColor: Colors.white,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                        color: AppColors.cardBorder,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                        color: AppColors.cardBorder,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                        color: AppColors.cardBorder,
                                        width: 1.4,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                              const SizedBox(height: 8),
                              Autocomplete<Menu>(
                                optionsBuilder: (textEditingValue) {
                                  return _controller.menuOptionsForQuery(
                                    textEditingValue.text,
                                  );
                                },
                                displayStringForOption: (menu) => menu.name,
                                onSelected: _controller.selectMenu,
                                fieldViewBuilder:
                                    (
                                      context,
                                      controller,
                                      focusNode,
                                      onSubmitted,
                                    ) {
                                      if (controller.text !=
                                          _menuSearchController.text) {
                                        controller.value =
                                            _menuSearchController.value;
                                      }
                                      return TextField(
                                        controller: controller,
                                        focusNode: focusNode,
                                        scrollPadding: const EdgeInsets.only(
                                          left: 16,
                                          right: 16,
                                          top: 24,
                                          bottom: 160,
                                        ),
                                        decoration: InputDecoration(
                                          hintText: state.loadingMenus
                                              ? '메뉴 불러오는 중..'
                                              : '표준 메뉴 검색 또는 선택',
                                          filled: true,
                                          fillColor: Colors.white,
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            borderSide: const BorderSide(
                                              color: AppColors.cardBorder,
                                            ),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            borderSide: const BorderSide(
                                              color: AppColors.cardBorder,
                                            ),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            borderSide: const BorderSide(
                                              color: AppColors.cardBorder,
                                              width: 1.4,
                                            ),
                                          ),
                                        ),
                                        onChanged:
                                            _controller.updateMenuSearchText,
                                        onSubmitted: (_) => onSubmitted(),
                                      );
                                    },
                                optionsViewBuilder: (context, onSelected, options) {
                                  final list = options.toList(growable: false);
                                  if (list.isEmpty) {
                                    return Align(
                                      alignment: Alignment.topLeft,
                                      child: Material(
                                        elevation: 4,
                                        borderRadius: BorderRadius.circular(12),
                                        child: SizedBox(
                                          width:
                                              MediaQuery.of(
                                                context,
                                              ).size.width -
                                              64,
                                          child: const Padding(
                                            padding: EdgeInsets.all(12),
                                            child: Text('등록된 표준 메뉴가 없어요'),
                                          ),
                                        ),
                                      ),
                                    );
                                  }
                                  return Align(
                                    alignment: Alignment.topLeft,
                                    child: Material(
                                      elevation: 4,
                                      borderRadius: BorderRadius.circular(12),
                                      child: SizedBox(
                                        width:
                                            MediaQuery.of(context).size.width -
                                            64,
                                        child: ConstrainedBox(
                                          constraints: const BoxConstraints(
                                            maxHeight: 280,
                                          ),
                                          child: ScrollConfiguration(
                                            behavior:
                                                const ReviewWriteMenuOptionsScrollBehavior(),
                                            child: ListView.builder(
                                              primary: false,
                                              padding: const EdgeInsets.all(8),
                                              itemCount: list.length,
                                              itemBuilder: (context, index) {
                                                final menu = list[index];
                                                return ListTile(
                                                  title: Text(menu.name),
                                                  onTap: () => onSelected(menu),
                                                );
                                              },
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                              if (state.menuError != null) ...[
                                const SizedBox(height: 6),
                                Text(
                                  state.menuError!,
                                  style: const TextStyle(
                                    color: Colors.red,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                              if (_controller.shouldShowTemperatureSelector(
                                state.selectedMenu,
                              )) ...[
                                const SizedBox(height: 4),
                                SizedBox(
                                  height: 36,
                                  child: Row(
                                    children: [
                                      _buildTemperatureChip(
                                        state: state,
                                        label: '핫',
                                        value: 'hot',
                                      ),
                                      const SizedBox(width: 8),
                                      _buildTemperatureChip(
                                        state: state,
                                        label: '아이스',
                                        value: 'ice',
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      '경험을 평가해주세요',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...state.activeDimensions.expand(
                      (key) => [
                        RatingSlider(
                          label: ratingLabelForSchema(
                            key,
                            state.ratingSchemaVersion,
                          ),
                          value: state.scores[key] ?? 3.0,
                          onChanged: (value) =>
                              _controller.updateScore(key, value),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                    if (state.usesCurrentRatingSchema &&
                        state.selectedMenu != null &&
                        visibleMenuAttributeKeysForCategory(
                          state.selectedMenu?.category,
                        ).isNotEmpty) ...[
                      const SizedBox(height: 12),
                      const Text(
                        '취향 정보',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...visibleMenuAttributeKeysForCategory(
                        state.selectedMenu?.category,
                      ).expand(
                        (key) => [
                          _buildAttributeChoiceGroup(state, key),
                          const SizedBox(height: 14),
                        ],
                      ),
                    ],
                    const SizedBox(height: 8),
                    RatingSlider(
                      label: '총점',
                      value: state.overall,
                      isOverall: true,
                      onChanged: (_) {},
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      '매장 경험도 알려주세요',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...storeDimensionsForSchema(
                      state.ratingSchemaVersion,
                    ).expand(
                      (key) => [
                        RatingSlider(
                          label: ratingLabelForSchema(
                            key,
                            state.ratingSchemaVersion,
                          ),
                          value: state.storeScores[key] ?? 3.0,
                          onChanged: (value) =>
                              _controller.updateStoreScore(key, value),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                    if (state.usesCurrentRatingSchema) ...[
                      const SizedBox(height: 8),
                      const Text(
                        '방문 정보',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...v2StoreAttributeKeys.expand(
                        (key) => [
                          _buildAttributeChoiceGroup(state, key),
                          const SizedBox(height: 14),
                        ],
                      ),
                    ],
                    const SizedBox(height: 20),
                    const Text(
                      '사진/영상 추가',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 106,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: state.currentMediaCount + 1,
                        separatorBuilder: (context, index) =>
                            const SizedBox(width: 12),
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            return ReviewWriteImageAddTile(
                              count: state.currentMediaCount,
                              maxCount: reviewWriteMaxMedia,
                              disabled: state.isSubmitting,
                              onTap: () => _showMediaPickerOptions(state),
                            );
                          }

                          final mediaIndex = index - 1;
                          if (mediaIndex < state.existingMediaItems.length) {
                            final item = state.existingMediaItems[mediaIndex];
                            return ReviewWriteImagePreviewTile(
                              imageUrl: item.url,
                              contentType: item.isVideo
                                  ? 'video/mp4'
                                  : 'image/jpeg',
                              durationLabel: _formatMediaDuration(
                                item.durationMs,
                              ),
                              disabled: state.isSubmitting,
                              onRemove: () =>
                                  _controller.removeExistingMediaAt(mediaIndex),
                            );
                          }

                          final selectedIndex =
                              mediaIndex - state.existingMediaItems.length;
                          final item = state.selectedMediaItems[selectedIndex];
                          return ReviewWriteImagePreviewTile(
                            bytes: item.bytes,
                            contentType: item.contentType,
                            durationLabel: _formatMediaDuration(
                              item.durationMs,
                            ),
                            disabled: state.isSubmitting,
                            onRemove: () => _controller.removeSelectedMediaAt(
                              selectedIndex,
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      '후기를 남겨주세요',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _commentController,
                      maxLines: 6,
                      scrollPadding: const EdgeInsets.only(
                        left: 16,
                        right: 16,
                        top: 24,
                        bottom: 160,
                      ),
                      onChanged: _controller.setComment,
                      decoration: InputDecoration(
                        hintText:
                            '카페 분위기와 메뉴 평가를 자유롭게 남겨주세요. 다른 사용자에게 큰 도움이 됩니다.',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: AppColors.cardBorder,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: AppColors.cardBorder,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: AppColors.cardBorder,
                            width: 1.4,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (!isKeyboardVisible)
                      WriteCafeReviewButton(
                        onPressed: state.isSubmitting
                            ? () {}
                            : () => _handleSubmit(state),
                        text: state.isSubmitting
                            ? state.submittingButtonText
                            : state.submitButtonText,
                      )
                    else
                      const SizedBox(height: 16),
                  ],
                ),
        ),
      ),
    );
  }
}
