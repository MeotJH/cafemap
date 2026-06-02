import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:another_flushbar/flushbar.dart';
import 'package:flutter/foundation.dart';
import 'package:front/app/write_cafe_review_button.dart';
import 'package:front/core/constants/app_colors.dart';
import 'package:front/core/constants/rating_dimensions.dart';
import 'package:front/core/services/analytics_service.dart';
import 'package:front/domain/entities/review.dart';
import 'package:front/presentation/widgets/rating_slider.dart';
import 'package:front/domain/entities/brand.dart';
import 'package:front/domain/entities/menu.dart';
import 'package:front/presentation/providers/app_providers.dart';
import 'package:front/presentation/providers/review_providers.dart';
import 'package:front/presentation/providers/ranking_providers.dart';
import 'package:front/presentation/providers/auth_providers.dart';
import 'package:front/presentation/providers/store_providers.dart';
import 'package:front/domain/entities/auth_context.dart';
import 'package:front/presentation/utils/web_image_picker.dart';
import 'package:front/presentation/utils/review_video_metadata.dart';
import 'package:front/presentation/utils/web_review_media_picker.dart';
import 'package:front/presentation/widgets/rating_choice_chip.dart';
import 'package:go_router/go_router.dart';
import 'package:front/data/remote/review_api.dart';
import 'package:dio/dio.dart';
import 'package:flutter/gestures.dart';
import 'package:image_picker/image_picker.dart';

// 리뷰 작성 화면이다.
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
  // 리뷰 작성 화면의 상태를 생성한다.
  ConsumerState<ReviewWritePage> createState() => _ReviewWritePageState();
}

class _ReviewWritePageState extends ConsumerState<ReviewWritePage> {
  static const String _localBrandId = 'brand-local';
  static const int _maxReviewMedia = 5;
  static const int _maxVideoDurationMs = 30000;
  List<String> _activeDimensions = dimensionsForCategoryForSchema(
    null,
    currentRatingSchemaVersion,
  );
  Map<String, double> _scores = {
    for (final key in dimensionsForCategoryForSchema(
      null,
      currentRatingSchemaVersion,
    ))
      key: 3.0,
  };
  Map<String, double> _storeScores = {
    for (final key in storeDimensionsForSchema(currentRatingSchemaVersion))
      key: 3.0,
  };
  Map<String, String> _attributes = {};
  double overall = 3.0;
  List<Brand> _brands = [];
  Brand? _selectedBrand;
  List<Menu> _menus = [];
  Menu? _selectedMenu;
  String _selectedTemperatureOption = '';
  final _menuSearchController = TextEditingController();
  bool _loadingMenus = false;
  String? _menuError;
  Brand? _lastConfirmedBrand;
  final _commentController = TextEditingController();
  final _imagePicker = ImagePicker();
  final List<_SelectedReviewMedia> _selectedMediaItems = [];
  final List<ReviewMediaItem> _existingMediaItems = [];
  Review? _editingReview;
  bool _isBootstrapping = true;
  String? _bootstrapError;
  bool _isSubmitting = false;
  bool get _isEditMode => (widget.reviewId?.isNotEmpty ?? false);
  bool get _isBrandLocked =>
      (widget.brandId?.isNotEmpty ?? false) ||
      (widget.brandName?.isNotEmpty ?? false);
  bool get _isLocalBrandSelected => _selectedBrand?.id == _localBrandId;
  String get _pageTitle => _isEditMode ? '리뷰 수정' : '리뷰 작성';
  String get _submitButtonText => _isEditMode ? '리뷰 수정 저장' : '리뷰 제출';
  String get _submittingButtonText => _isEditMode ? '저장 중...' : '제출 중...';
  String get _reviewActionNoun => _isEditMode ? '수정' : '등록';
  int get _ratingSchemaVersion =>
      _editingReview?.ratingSchemaVersion ?? currentRatingSchemaVersion;
  bool get _usesCurrentRatingSchema =>
      normalizeRatingSchemaVersion(_ratingSchemaVersion) ==
      currentRatingSchemaVersion;
  int get _currentMediaCount =>
      _existingMediaItems.length + _selectedMediaItems.length;
  int get _maxReviewImages => _maxReviewMedia;
  int get _currentImageCount => _currentMediaCount;
  List<_SelectedReviewMedia> get _selectedImages => _selectedMediaItems;
  String? get _resolvedStoreName =>
      widget.storeName ?? _editingReview?.storeName;
  String? get _resolvedAddress => widget.address ?? _editingReview?.address;
  String? get _resolvedPlaceId => widget.placeId ?? _editingReview?.placeId;
  String? get _resolvedLink => widget.link ?? _editingReview?.link;
  double? get _resolvedLat => widget.lat ?? _editingReview?.lat;
  double? get _resolvedLng => widget.lng ?? _editingReview?.lng;
  String? get _resolvedMenuName => widget.menuName ?? _editingReview?.menuName;
  String? get _resolvedBrandId => widget.brandId ?? _editingReview?.brandId;
  String? get _resolvedBrandName =>
      widget.brandName ?? _editingReview?.brandName;

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

  @override
  void initState() {
    super.initState();
    _editingReview = widget.initialReview;
    _initializePage();
  }

  @override
  void dispose() {
    _menuSearchController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _initializePage() async {
    // 수정 진입인데 상세 데이터를 직접 받지 못한 경우 서버에서 다시 읽어 초기값을 만든다.
    if (_isEditMode && _editingReview == null) {
      try {
        final repository = ref.read(reviewRepositoryProvider);
        _editingReview = await repository.fetchReviewDetail(widget.reviewId!);
      } catch (_) {
        if (!mounted) return;
        setState(() {
          _bootstrapError = '리뷰 정보를 불러오지 못했어요.';
          _isBootstrapping = false;
        });
        return;
      }
    }

    if (_editingReview != null) {
      _applyInitialReview(_editingReview!);
    } else {
      overall = _calculateOverall();
    }

    await _loadBrands();
    if (!mounted) return;
    setState(() {
      _isBootstrapping = false;
    });
  }

  void _applyInitialReview(Review review) {
    // 기존 리뷰를 작성 폼 상태로 그대로 옮겨서 작성/수정 화면을 하나로 재사용한다.
    final schemaVersion = normalizeRatingSchemaVersion(
      review.ratingSchemaVersion,
    );
    final nextDimensions = dimensionsForCategoryForSchema(
      review.menuCategory,
      schemaVersion,
    );
    _activeDimensions = nextDimensions;
    _scores = {
      for (final key in nextDimensions) key: review.scores[key] ?? 3.0,
    };
    _storeScores = {
      for (final key in storeDimensionsForSchema(schemaVersion))
        key: review.scores[key] ?? 3.0,
    };
    _attributes = _attributeDefaultsForCategory(review.menuCategory)
      ..addAll(review.attributes);
    overall = review.overall > 0 ? review.overall : _calculateOverall();
    _selectedTemperatureOption = review.temperatureOption;
    _commentController.text = review.comment;
    _existingMediaItems
      ..clear()
      ..addAll(review.mediaItems.take(_maxReviewMedia));
    _menuSearchController.text = review.menuName;
  }

  Future<void> _loadBrands() async {
    try {
      final repository = ref.read(menuRepositoryProvider);
      final brands = await repository.fetchBrands();
      final localBrand = _findBrandById(brands, _localBrandId);
      final matched = _resolveInitialBrand(brands, localBrand);
      if (!mounted) return;
      setState(() {
        _brands = brands;
        _selectedBrand = matched;
        _lastConfirmedBrand = matched;
      });
      if (matched != null) {
        await _loadMenus(matched.id);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _menuError = '메뉴 목록을 불러오지 못했어요.';
      });
    }
  }

  Brand? _matchBrand(List<Brand> brands, String storeName) {
    final normalized = _normalizeSearchText(storeName);
    if (_isLocalHint(normalized)) {
      return _findBrandById(brands, _localBrandId);
    }
    for (final brand in brands) {
      for (final token in _brandMatchTokens(brand)) {
        if (token.isNotEmpty && normalized.contains(token)) {
          return brand;
        }
      }
    }
    return null;
  }

  Brand? _findBrandById(List<Brand> brands, String brandId) {
    for (final brand in brands) {
      if (brand.id == brandId) return brand;
    }
    return null;
  }

  Brand? _findBrandByName(List<Brand> brands, String brandName) {
    final target = _normalizeSearchText(brandName);
    if (target.isEmpty) return null;
    if (_isLocalHint(target)) {
      return _findBrandById(brands, _localBrandId);
    }
    for (final brand in brands) {
      if (_brandMatchTokens(brand).contains(target)) return brand;
    }
    return null;
  }

  Brand? _resolveInitialBrand(List<Brand> brands, Brand? localBrand) {
    final fallbackBrand = brands.isNotEmpty ? brands.first : null;
    final incomingBrandId = _resolvedBrandId?.trim() ?? '';
    if (incomingBrandId.isNotEmpty) {
      if (incomingBrandId == _localBrandId ||
          incomingBrandId.toLowerCase() == 'local') {
        return localBrand ?? fallbackBrand;
      }
      return _findBrandById(brands, incomingBrandId) ??
          (_isLocalHint(_normalizeSearchText(_resolvedBrandName ?? ''))
              ? localBrand
              : null) ??
          fallbackBrand;
    }

    return _findBrandByName(brands, _resolvedBrandName ?? '') ??
        _matchBrand(brands, _resolvedStoreName ?? '') ??
        localBrand ??
        fallbackBrand;
  }

  bool _isLocalHint(String normalized) {
    if (normalized.isEmpty) return false;
    return normalized == 'local' ||
        normalized == '로컬' ||
        normalized == '개인카페' ||
        normalized == '개인카페로리뷰를작성해요' ||
        normalized.contains('개인카페') ||
        normalized.contains('로컬카페');
  }

  Set<String> _brandMatchTokens(Brand brand) {
    final normalized = _normalizeSearchText(brand.name);
    final tokens = <String>{normalized};
    if (brand.id == _localBrandId) {
      tokens.addAll({'개인카페', '개인', '로컬', '로컬카페', 'local', 'localcafe'});
    }
    if (normalized.contains('메가')) {
      tokens.addAll({'메가커피', '메가mgc커피'});
    }
    if (normalized.contains('이디야')) {
      tokens.addAll({'이디야', '이디야커피', 'ediya'});
    }
    return tokens;
  }

  String _normalizeSearchText(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), '')
        .replaceAll(RegExp(r'[^0-9a-z가-힣]'), '');
  }

  Set<String> _menuMatchKeys(String value) {
    final normalized = _normalizeSearchText(value);
    final keys = <String>{if (normalized.isNotEmpty) normalized};
    if (normalized.contains('아메리카노')) {
      keys.add(normalized.replaceFirst(RegExp(r'^(아이스|핫)'), ''));
    }
    if (normalized.contains('americano')) {
      keys.add(normalized.replaceFirst(RegExp(r'^(ice|iced|hot)'), ''));
    }
    keys.removeWhere((key) => key.isEmpty);
    return keys;
  }

  Future<void> _loadMenus(String brandId) async {
    setState(() {
      _loadingMenus = true;
      _menuError = null;
    });
    try {
      final repository = ref.read(menuRepositoryProvider);
      final menus = await repository.fetchMenus(brandId);
      Menu? selectedMenu;
      final incomingMenuName = _resolvedMenuName?.trim();
      if (incomingMenuName != null && incomingMenuName.isNotEmpty) {
        for (final menu in menus) {
          if (menu.name == incomingMenuName) {
            selectedMenu = menu;
            break;
          }
        }
      }
      final nextTemperatureOption =
          selectedMenu != null &&
              _editingReview != null &&
              _editingReview!.menuName == selectedMenu.name
          ? _editingReview!.temperatureOption
          : '';
      // 메뉴가 유지될 때만 온도 선택도 같이 복원하고, 메뉴가 바뀌면 다시 고르게 한다.
      if (!mounted) return;
      setState(() {
        _menus = menus;
        _selectedMenu = selectedMenu;
        _selectedTemperatureOption = nextTemperatureOption;
        _menuSearchController.text =
            selectedMenu?.name ?? incomingMenuName ?? '';
        _syncActiveDimensions(selectedMenu?.category);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _menuError = '메뉴 목록을 불러오지 못했어요.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _loadingMenus = false;
        });
      }
    }
  }

  Future<void> _submitReview() async {
    final auth = await ref.read(authControllerProvider).getAuthContext();
    if (auth == null) {
      await _showTopToast('리뷰 $_reviewActionNoun은 로그인 후 이용할 수 있어요.');
      if (!mounted) return;
      context.push('/auth');
      return;
    }

    if (_selectedBrand == null) {
      await _showTopToast('브랜드를 선택해주세요.');
      return;
    }
    final selectedMenu = _resolveSelectedMenu();
    if (selectedMenu == null) {
      await _showTopToast('표준 메뉴 목록에서 메뉴를 선택해주세요.');
      return;
    }
    if (_showsTemperatureSelector(selectedMenu) &&
        _selectedTemperatureOption.isEmpty) {
      await _showTopToast('핫 또는 아이스를 선택해주세요.');
      return;
    }
    final menuName = selectedMenu.name;
    final storeName = _resolvedStoreName ?? '';
    if (storeName.isEmpty) {
      await _showTopToast('카페를 선택해주세요.');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });
    try {
      final uploadedMediaItems = await _uploadSelectedMedia(auth);
      final mediaItems = [..._existingMediaItems, ...uploadedMediaItems];
      final imageUrls = mediaItems
          .where((item) => item.isImage)
          .map((item) => item.url)
          .toList(growable: false);
      // 수정 시에는 남겨둔 기존 이미지와 새로 업로드한 이미지를 합쳐 최종 payload를 만든다.
      final payload = ReviewCreateRequest(
        storeName: storeName,
        address: _resolvedAddress ?? '',
        placeId: _resolvedPlaceId ?? '',
        link: _resolvedLink ?? '',
        temperatureOption: _selectedTemperatureOption,
        lat: _resolvedLat,
        lng: _resolvedLng,
        brandId: _selectedBrand!.id,
        menuName: menuName,
        ratingSchemaVersion: _ratingSchemaVersion,
        scores: _scores,
        storeScores: _storeScores,
        attributes: _attributesForPayload(selectedMenu),
        overall: overall,
        comment: _commentController.text.trim(),
        imageUrls: imageUrls,
        mediaItems: mediaItems,
      );
      // 같은 폼을 쓰되 저장 직전에만 생성/수정 API를 분기한다.
      final review = _isEditMode
          ? await _updateReviewWithRecovery(widget.reviewId!, payload, auth)
          : await _createReviewWithRecovery(payload, auth);
      analyticsService.trackEvent(
        _isEditMode ? 'review_update_success' : 'review_submit_success',
        <String, Object?>{
          'rating_schema_version': _ratingSchemaVersion,
          'menu_category': normalizeRatingCategory(selectedMenu.category),
          'media_count': payload.mediaItems.length,
        },
      );
      _invalidateReviewRelatedProviders(review.id);
      if (!mounted) return;
      if (_isEditMode) {
        context.go('/review/${review.id}', extra: review);
      } else {
        context.push('/review/${review.id}', extra: review);
      }
    } on DioException catch (e, stackTrace) {
      debugPrint('Error submitting review: $e');
      debugPrint('Stack trace: $stackTrace');
      final needsReauth = _isRecoverableUserSessionError(e);
      await _showTopToast(
        needsReauth
            ? '로그인 정보를 확인하지 못했어요. 다시 로그인 후 리뷰를 $_reviewActionNoun해 주세요.'
            : _messageForSubmitError(e),
      );
      if (needsReauth && mounted) {
        context.push('/auth');
      }
    } catch (e, stackTrace) {
      debugPrint('Error submitting review: $e');
      debugPrint('Stack trace: $stackTrace');
      await _showTopToast('리뷰 $_reviewActionNoun에 실패했어요.');
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<Review> _createReviewWithRecovery(
    ReviewCreateRequest payload,
    AuthContext auth,
  ) async {
    final repository = ref.read(reviewRepositoryProvider);
    try {
      return await repository.createReview(payload, auth: auth);
    } on DioException catch (e) {
      if (!_isRecoverableUserSessionError(e)) rethrow;
      await ref.read(authApiProvider).syncUser(auth);
      return repository.createReview(payload, auth: auth);
    }
  }

  Future<Review> _updateReviewWithRecovery(
    String reviewId,
    ReviewCreateRequest payload,
    AuthContext auth,
  ) async {
    final repository = ref.read(reviewRepositoryProvider);
    try {
      return await repository.updateReview(reviewId, payload, auth: auth);
    } on DioException catch (e) {
      if (!_isRecoverableUserSessionError(e)) rethrow;
      await ref.read(authApiProvider).syncUser(auth);
      return repository.updateReview(reviewId, payload, auth: auth);
    }
  }

  void _invalidateReviewRelatedProviders(String reviewId) {
    // 수정 결과가 상세/리스트/집계 화면 전체에 반영되도록 관련 provider 캐시를 비운다.
    ref.invalidate(myReviewsProvider);
    ref.invalidate(rankingListProvider);
    ref.invalidate(storeRankingListProvider);
    ref.invalidate(reviewDetailProvider(reviewId));
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

  String _messageForSubmitError(DioException error) {
    if (error.response?.statusCode == 401) {
      return '로그인 정보를 확인하지 못했어요. 다시 로그인 후 리뷰를 $_reviewActionNoun해 주세요.';
    }
    final detail = _errorDetail(error.response?.data);
    if (detail.isNotEmpty) {
      return '리뷰 $_reviewActionNoun에 실패했어요. $detail';
    }
    return '리뷰 $_reviewActionNoun에 실패했어요. 잠시 후 다시 시도해 주세요.';
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

  Menu? _resolveSelectedMenu() {
    final selected = _selectedMenu;
    final typed = _menuSearchController.text.trim();
    if (selected != null && selected.name == typed) {
      return selected;
    }
    return _findMenuByText(typed);
  }

  Menu? _findMenuByText(String typed) {
    final typedKeys = _menuMatchKeys(typed);
    for (final menu in _menus) {
      if (menu.name == typed ||
          typedKeys.intersection(_menuMatchKeys(menu.name)).isNotEmpty) {
        return menu;
      }
    }
    return null;
  }

  bool _showsTemperatureSelector(Menu? menu) {
    if (menu == null) return false;
    final category = normalizeRatingCategory(menu.category);
    return temperatureSelectableCategories.contains(category);
  }

  void _selectMenu(Menu? menu) {
    setState(() {
      _selectedMenu = menu;
      _selectedTemperatureOption = '';
      _syncActiveDimensions(menu?.category);
    });
    if (menu != null) {
      _menuSearchController.text = menu.name;
    }
  }

  Widget _buildTemperatureChip({required String label, required String value}) {
    final isSelected = _selectedTemperatureOption == value;
    return RatingChoiceChip(
      label: label,
      selected: isSelected,
      onTap: () {
        setState(() {
          _selectedTemperatureOption = value;
          if (_usesCurrentRatingSchema) {
            _attributes['temperature_option'] = value;
          }
        });
      },
    );
  }

  Widget _buildAttributeChoiceGroup(String key) {
    final options = ratingAttributeValueLabels[key] ?? const <String, String>{};
    final selected = _attributes[key] ?? defaultAttributeValue(key);
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
              Builder(
                builder: (context) {
                  final isSelected = selected == entry.key;
                  final isNeutral =
                      entry.key == 'unknown' ||
                      entry.key == 'not_used' ||
                      entry.key == 'unspecified';
                  return RatingChoiceChip(
                    label: entry.value,
                    selected: isSelected,
                    neutral: isNeutral,
                    onTap: () => _updateAttribute(key, entry.key),
                  );
                },
              ),
          ],
        ),
      ],
    );
  }

  Future<List<ReviewMediaItem>> _uploadSelectedMedia(AuthContext auth) async {
    if (_selectedMediaItems.isEmpty) return const [];
    final api = ref.read(reviewApiProvider);
    final uploadedItems = <ReviewMediaItem>[];
    for (final item in _selectedMediaItems) {
      final presigned = await api.requestReviewImagePresign(
        ReviewImagePresignRequest(
          fileName: item.fileName,
          contentType: item.contentType,
        ),
        auth: auth,
      );
      await api.uploadToPresignedUrl(
        uploadUrl: presigned.uploadUrl,
        bytes: item.bytes,
        contentType: item.contentType,
      );
      uploadedItems.add(
        ReviewMediaItem(
          type: item.type,
          url: presigned.fileUrl,
          durationMs: item.durationMs,
        ),
      );
    }
    return uploadedItems;
  }

  Future<void> _showMediaPickerOptions() async {
    final remaining = _maxReviewMedia - _currentMediaCount;
    if (remaining <= 0) {
      await _showTopToast('사진과 영상은 최대 $_maxReviewMedia개까지 첨부할 수 있어요.');
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
    final next = <_SelectedReviewMedia>[];
    for (final item in webPicked) {
      if (next.length >= remaining) break;
      if (!_isSupportedMediaContentType(item.mimeType)) continue;
      final contentType = _contentTypeFromName(
        item.fileName,
        fallbackContentType: item.mimeType,
      );
      final selected = _SelectedReviewMedia(
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
      );
      if (!_isWithinVideoDurationLimit(selected)) {
        continue;
      }
      next.add(selected);
    }
    if (!mounted || next.isEmpty) return;
    setState(() {
      _selectedMediaItems.addAll(next);
    });
    if (webPicked.length > remaining) {
      await _showTopToast('사진과 영상은 최대 $_maxReviewMedia개까지 첨부할 수 있어요.');
    }
  }

  Future<void> _pickImages() async {
    final remaining = _maxReviewMedia - _currentMediaCount;
    if (remaining <= 0) {
      await _showTopToast('사진은 최대 $_maxReviewImages장까지 첨부할 수 있어요.');
      return;
    }

    List<XFile> picked;
    if (kIsWeb) {
      final webPicked = await pickWebImages(multiple: remaining > 1);
      if (webPicked.isEmpty) return;
      final next = webPicked.take(remaining).map((item) {
        return _SelectedReviewImage(
          fileName: item.fileName.isNotEmpty
              ? item.fileName
              : 'review_${DateTime.now().millisecondsSinceEpoch}.jpg',
          contentType: item.mimeType,
          bytes: item.bytes,
        );
      }).toList();
      if (!mounted) return;
      setState(() {
        _selectedImages.addAll(next);
      });
      if (webPicked.length > remaining) {
        await _showTopToast('사진은 최대 $_maxReviewImages장까지 첨부할 수 있어요.');
      }
      return;
    } else {
      try {
        picked = await _imagePicker.pickMultiImage(imageQuality: 85);
      } catch (_) {
        // 일부 기기에서는 다중 선택이 실패할 수 있어 단일 선택으로 대체한다.
        final single = await _tryPickSingleImage();
        if (single == null) return;
        picked = [single];
      }
    }
    if (picked.isEmpty) return;

    final next = <_SelectedReviewImage>[];
    for (final file in picked.take(remaining)) {
      final bytes = await file.readAsBytes();
      next.add(
        _SelectedReviewImage(
          fileName: file.name.isNotEmpty
              ? file.name
              : 'review_${DateTime.now().millisecondsSinceEpoch}.jpg',
          contentType: _contentTypeFromName(file.name),
          bytes: bytes,
        ),
      );
    }
    if (!mounted) return;
    setState(() {
      _selectedImages.addAll(next);
    });
    if (picked.length > remaining) {
      await _showTopToast('사진은 최대 $_maxReviewImages장까지 첨부할 수 있어요.');
    }
  }

  Future<XFile?> _tryPickSingleImage() async {
    try {
      return await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
    } on PlatformException catch (e) {
      if (e.code == 'photo_access_denied') {
        await _showTopToast('사진 권한이 꺼져 있어요. 설정에서 허용해주세요.');
        return null;
      }
      await _showTopToast('사진 선택 실패: ${e.message ?? e.code}');
      return null;
    } catch (e) {
      await _showTopToast('사진 선택 실패: $e');
      return null;
    }
  }

  Future<void> _pickVideo() async {
    final remaining = _maxReviewMedia - _currentMediaCount;
    if (remaining <= 0) {
      await _showTopToast('사진과 영상은 최대 $_maxReviewMedia개까지 첨부할 수 있어요.');
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
      final selected = _SelectedReviewMedia(
        fileName: file.name.isNotEmpty
            ? file.name
            : 'review_${DateTime.now().millisecondsSinceEpoch}.mp4',
        contentType: _contentTypeFromName(file.name),
        bytes: bytes,
        durationMs: durationMs,
      );
      if (!_isWithinVideoDurationLimit(selected)) {
        return;
      }
      if (!mounted) return;
      setState(() {
        _selectedMediaItems.add(selected);
      });
    } on PlatformException catch (e) {
      await _showTopToast('영상 선택에 실패했어요: ${e.message ?? e.code}');
    } catch (e) {
      await _showTopToast('영상 선택에 실패했어요: $e');
    }
  }

  void _removeImageAt(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  void _removeExistingImageAt(int index) {
    setState(() {
      // 저장 시 남아 있는 URL만 서버에 다시 보내므로 여기서 빠진 이미지는 최종적으로 삭제된다.
      _existingMediaItems.removeAt(index);
    });
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

  bool _isWithinVideoDurationLimit(_SelectedReviewMedia item) {
    if (item.type != 'video') {
      return true;
    }
    final durationMs = item.durationMs;
    if (durationMs == null || durationMs <= _maxVideoDurationMs) {
      return true;
    }
    _showTopToast('?곸긽???덉씠??30珥덇퉴吏留?泥⑤?????덉뼱??');
    return false;
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

  double _calculateOverall() {
    if (_scores.isEmpty) return 0;
    final total = _scores.values.reduce((a, b) => a + b);
    return total / _scores.length;
  }

  void _updateScore(String key, double value) {
    setState(() {
      _scores[key] = value;
      overall = _calculateOverall();
    });
  }

  void _updateStoreScore(String key, double value) {
    setState(() {
      _storeScores[key] = value;
    });
  }

  void _updateAttribute(String key, String value) {
    setState(() {
      _attributes[key] = value;
    });
  }

  Map<String, String> _attributeDefaultsForCategory(String? category) {
    if (!_usesCurrentRatingSchema) return const {};
    final defaults = <String, String>{};
    for (final key in menuAttributeKeysForCategory(category)) {
      defaults[key] = defaultAttributeValue(key);
    }
    for (final key in v2StoreAttributeKeys) {
      defaults[key] = defaultAttributeValue(key);
    }
    if (_selectedTemperatureOption.isNotEmpty &&
        defaults.containsKey('temperature_option')) {
      defaults['temperature_option'] = _selectedTemperatureOption;
    }
    return defaults;
  }

  Map<String, String> _attributesForPayload(Menu menu) {
    if (!_usesCurrentRatingSchema) return const {};
    final defaults = _attributeDefaultsForCategory(menu.category);
    return {
      for (final entry in defaults.entries)
        entry.key:
            entry.key == 'temperature_option' &&
                _selectedTemperatureOption.isNotEmpty
            ? _selectedTemperatureOption
            : (_attributes[entry.key] ?? entry.value),
    };
  }

  void _syncActiveDimensions(String? category) {
    final schemaVersion = _ratingSchemaVersion;
    final next = dimensionsForCategoryForSchema(category, schemaVersion);
    _activeDimensions = next;
    _scores = {
      for (final key in next)
        key: _scores.containsKey(key) ? _scores[key]! : 3.0,
    };
    final storeKeys = storeDimensionsForSchema(schemaVersion);
    _storeScores = {
      for (final key in storeKeys)
        key: _storeScores.containsKey(key) ? _storeScores[key]! : 3.0,
    };
    if (_usesCurrentRatingSchema) {
      final defaults = _attributeDefaultsForCategory(category);
      _attributes = {
        for (final entry in defaults.entries)
          entry.key: _attributes[entry.key] ?? entry.value,
      };
    } else {
      _attributes = {};
    }
    overall = _calculateOverall();
  }

  Future<bool> _confirmBrandChange(Brand nextBrand) async {
    final current = _lastConfirmedBrand;
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

  @override
  // 리뷰 작성 UI를 렌더링한다.
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.viewInsetsOf(context);
    final bottomSafeArea = MediaQuery.paddingOf(context).bottom;
    final isKeyboardVisible = viewInsets.bottom > 0;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text(_pageTitle),
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
          child: _isBootstrapping
              ? const Center(child: CircularProgressIndicator())
              : _bootstrapError != null
              ? Center(child: Text(_bootstrapError!))
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
                                _resolvedStoreName ?? '카페를 선택해주세요.',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if ((_resolvedAddress ?? '').isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  _resolvedAddress!,
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 8),
                              if (_isLocalBrandSelected && !_isBrandLocked) ...[
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
                                  initialValue: _selectedBrand,
                                  items: _brands
                                      .map(
                                        (brand) => DropdownMenuItem(
                                          value: brand,
                                          child: Text(brand.name),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: _isBrandLocked
                                      ? null
                                      : (brand) async {
                                          if (brand == null) return;
                                          if (!await _confirmBrandChange(
                                            brand,
                                          )) {
                                            return;
                                          }
                                          setState(() {
                                            _selectedBrand = brand;
                                            _lastConfirmedBrand = brand;
                                            _selectedMenu = null;
                                            _selectedTemperatureOption = '';
                                            _menuSearchController.clear();
                                            _syncActiveDimensions(null);
                                          });
                                          _loadMenus(brand.id);
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
                                  final query = textEditingValue.text
                                      .trim()
                                      .toLowerCase();
                                  if (query.isEmpty) return _menus;
                                  final queryKeys = _menuMatchKeys(query);
                                  return _menus.where((menu) {
                                    final menuText = _normalizeSearchText(
                                      menu.name,
                                    );
                                    return menuText.contains(
                                          _normalizeSearchText(query),
                                        ) ||
                                        queryKeys
                                            .intersection(
                                              _menuMatchKeys(menu.name),
                                            )
                                            .isNotEmpty;
                                  });
                                },
                                displayStringForOption: (menu) => menu.name,
                                onSelected: (menu) {
                                  _selectMenu(menu);
                                },
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
                                          hintText: _loadingMenus
                                              ? '메뉴 불러오는 중...'
                                              : '표준 메뉴 검색 후 선택',
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
                                        onChanged: (value) {
                                          _menuSearchController.value =
                                              controller.value;
                                          final nextMenu = _findMenuByText(
                                            value.trim(),
                                          );
                                          if (_selectedMenu?.id !=
                                              nextMenu?.id) {
                                            _selectMenu(nextMenu);
                                          }
                                        },
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
                                            child: Text('등록된 표준 메뉴가 없어요.'),
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
                                                const _MenuOptionsScrollBehavior(),
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
                              if (_menuError != null) ...[
                                const SizedBox(height: 6),
                                Text(
                                  _menuError!,
                                  style: const TextStyle(
                                    color: Colors.red,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                              if (_showsTemperatureSelector(_selectedMenu)) ...[
                                const SizedBox(height: 4),
                                SizedBox(
                                  height: 36,
                                  child: Row(
                                    children: [
                                      _buildTemperatureChip(
                                        label: '핫',
                                        value: 'hot',
                                      ),
                                      const SizedBox(width: 8),
                                      _buildTemperatureChip(
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
                    ..._activeDimensions.expand(
                      (key) => [
                        RatingSlider(
                          label: ratingLabelForSchema(
                            key,
                            _ratingSchemaVersion,
                          ),
                          value: _scores[key] ?? 3.0,
                          onChanged: (v) => _updateScore(key, v),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                    if (_usesCurrentRatingSchema &&
                        _selectedMenu != null &&
                        visibleMenuAttributeKeysForCategory(
                          _selectedMenu?.category,
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
                        _selectedMenu?.category,
                      ).expand(
                        (key) => [
                          _buildAttributeChoiceGroup(key),
                          const SizedBox(height: 14),
                        ],
                      ),
                    ],
                    const SizedBox(height: 8),
                    RatingSlider(
                      label: '총점',
                      value: overall,
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
                    ...storeDimensionsForSchema(_ratingSchemaVersion).expand(
                      (key) => [
                        RatingSlider(
                          label: ratingLabelForSchema(
                            key,
                            _ratingSchemaVersion,
                          ),
                          value: _storeScores[key] ?? 3.0,
                          onChanged: (v) => _updateStoreScore(key, v),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                    if (_usesCurrentRatingSchema) ...[
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
                          _buildAttributeChoiceGroup(key),
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
                        itemCount: _currentImageCount + 1,
                        separatorBuilder: (context, index) =>
                            const SizedBox(width: 12),
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            return _ReviewImageAddTile(
                              count: _currentImageCount,
                              maxCount: _maxReviewImages,
                              disabled: _isSubmitting,
                              onTap: _showMediaPickerOptions,
                            );
                          }
                          final imageIndex = index - 1;
                          if (imageIndex < _existingMediaItems.length) {
                            final item = _existingMediaItems[imageIndex];
                            return _ReviewImagePreviewTile(
                              imageUrl: item.url,
                              contentType: item.isVideo
                                  ? 'video/mp4'
                                  : 'image/jpeg',
                              durationLabel: _formatMediaDuration(
                                item.durationMs,
                              ),
                              disabled: _isSubmitting,
                              onRemove: () =>
                                  _removeExistingImageAt(imageIndex),
                            );
                          }
                          final item =
                              _selectedImages[imageIndex -
                                  _existingMediaItems.length];
                          return _ReviewImagePreviewTile(
                            bytes: item.bytes,
                            contentType: item.contentType,
                            durationLabel: _formatMediaDuration(
                              item.durationMs,
                            ),
                            disabled: _isSubmitting,
                            onRemove: () => _removeImageAt(
                              imageIndex - _existingMediaItems.length,
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
                        onPressed: _isSubmitting ? () {} : _submitReview,
                        text: _isSubmitting
                            ? _submittingButtonText
                            : _submitButtonText,
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

class _MenuOptionsScrollBehavior extends MaterialScrollBehavior {
  const _MenuOptionsScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.trackpad,
    PointerDeviceKind.stylus,
    PointerDeviceKind.unknown,
  };
}

class _SelectedReviewMedia {
  final String fileName;
  final String contentType;
  final Uint8List bytes;
  final int? durationMs;

  const _SelectedReviewMedia({
    required this.fileName,
    required this.contentType,
    required this.bytes,
    this.durationMs,
  });

  String get type =>
      contentType.toLowerCase().startsWith('video/') ? 'video' : 'image';
}

class _SelectedReviewImage extends _SelectedReviewMedia {
  const _SelectedReviewImage({
    required super.fileName,
    required super.contentType,
    required super.bytes,
  });
}

class _ReviewImageAddTile extends StatelessWidget {
  final int count;
  final int maxCount;
  final bool disabled;
  final VoidCallback onTap;

  const _ReviewImageAddTile({
    required this.count,
    required this.maxCount,
    required this.disabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: CustomPaint(
        painter: _DashedBorderPainter(
          color: const Color(0xFFCBD5E1),
          radius: 14,
        ),
        child: Container(
          width: 106,
          height: 106,
          decoration: BoxDecoration(
            color: const Color(0xFFFCFDFE),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.add_a_photo_outlined,
                color: Color(0xFF94A3B8),
                size: 30,
              ),
              const SizedBox(height: 6),
              Text(
                '$count/$maxCount',
                style: const TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReviewImagePreviewTile extends StatelessWidget {
  final Uint8List? bytes;
  final String? imageUrl;
  final String? contentType;
  final String durationLabel;
  final bool disabled;
  final VoidCallback onRemove;

  const _ReviewImagePreviewTile({
    this.bytes,
    this.imageUrl,
    this.contentType,
    this.durationLabel = '',
    required this.disabled,
    required this.onRemove,
  }) : assert(bytes != null || imageUrl != null);

  @override
  Widget build(BuildContext context) {
    final isVideo =
        (contentType ?? '').toLowerCase().startsWith('video/') ||
        (imageUrl ?? '').toLowerCase().endsWith('.mp4') ||
        (imageUrl ?? '').toLowerCase().endsWith('.mov') ||
        (imageUrl ?? '').toLowerCase().endsWith('.webm');
    final imageWidget = isVideo
        ? Container(
            width: 106,
            height: 106,
            color: const Color(0xFF0F172A),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.play_circle_fill_rounded,
                  size: 34,
                  color: Colors.white,
                ),
                SizedBox(height: 6),
                Text(
                  'VIDEO',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          )
        : bytes != null
        ? Image.memory(
            bytes!,
            width: 106,
            height: 106,
            fit: BoxFit.cover,
            gaplessPlayback: true,
          )
        : Image.network(
            imageUrl!,
            width: 106,
            height: 106,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: 106,
                height: 106,
                color: const Color(0xFFF8FAFC),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.broken_image_outlined,
                  color: Color(0xFF94A3B8),
                ),
              );
            },
          );
    return SizedBox(
      width: 106,
      height: 106,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: imageWidget,
          ),
          Positioned(
            top: 8,
            right: 8,
            child: GestureDetector(
              onTap: disabled ? null : onRemove,
              child: Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(
                  color: Color(0xFF1F2937),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, size: 16, color: Colors.white),
              ),
            ),
          ),
          if (isVideo && durationLabel.isNotEmpty)
            Positioned(
              left: 8,
              bottom: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.68),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  durationLabel,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double radius;

  const _DashedBorderPainter({required this.color, required this.radius});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    const dashWidth = 6.0;
    const dashSpace = 4.0;
    final path = Path()..addRRect(rect);
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = distance + dashWidth;
        canvas.drawPath(metric.extractPath(distance, next), paint);
        distance = next + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.radius != radius;
  }
}
