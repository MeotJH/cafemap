import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:another_flushbar/flushbar.dart';
import 'package:flutter/foundation.dart';
import 'package:front/app/write_cafe_review_button.dart';
import 'package:front/core/constants/app_colors.dart';
import 'package:front/core/constants/rating_dimensions.dart';
import 'package:front/domain/entities/review.dart';
import 'package:front/presentation/widgets/rating_slider.dart';
import 'package:front/domain/entities/brand.dart';
import 'package:front/domain/entities/menu.dart';
import 'package:front/presentation/providers/app_providers.dart';
import 'package:front/presentation/providers/review_providers.dart';
import 'package:front/presentation/providers/ranking_providers.dart';
import 'package:front/presentation/providers/auth_providers.dart';
import 'package:front/domain/entities/auth_context.dart';
import 'package:front/presentation/utils/web_image_picker.dart';
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
  });

  @override
  // 리뷰 작성 화면의 상태를 생성한다.
  ConsumerState<ReviewWritePage> createState() => _ReviewWritePageState();
}

class _ReviewWritePageState extends ConsumerState<ReviewWritePage> {
  static const String _localBrandId = 'brand-local';
  List<String> _activeDimensions = dimensionsForCategory(null);
  Map<String, double> _scores = {
    for (final key in dimensionsForCategory(null)) key: 3.0,
  };
  final Map<String, double> _storeScores = {
    for (final key in storeExperienceDimensions) key: 3.0,
  };
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
  final List<_SelectedReviewImage> _selectedImages = [];
  bool _isSubmitting = false;
  bool get _isBrandLocked =>
      (widget.brandId?.isNotEmpty ?? false) ||
      (widget.brandName?.isNotEmpty ?? false);
  bool get _isLocalBrandSelected => _selectedBrand?.id == _localBrandId;

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
    overall = _calculateOverall();
    _loadBrands();
  }

  @override
  void dispose() {
    _menuSearchController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadBrands() async {
    try {
      final repository = ref.read(menuRepositoryProvider);
      final brands = await repository.fetchBrands();
      final localBrand = _findBrandById(brands, _localBrandId);
      final matched = _resolveInitialBrand(brands, localBrand);
      setState(() {
        _brands = brands;
        _selectedBrand = matched;
        _lastConfirmedBrand = matched;
      });
      if (matched != null) {
        await _loadMenus(matched.id);
      }
    } catch (_) {
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
    final incomingBrandId = widget.brandId?.trim() ?? '';
    if (incomingBrandId.isNotEmpty) {
      if (incomingBrandId == _localBrandId ||
          incomingBrandId.toLowerCase() == 'local') {
        return localBrand ?? fallbackBrand;
      }
      return _findBrandById(brands, incomingBrandId) ??
          (_isLocalHint(_normalizeSearchText(widget.brandName ?? ''))
              ? localBrand
              : null) ??
          fallbackBrand;
    }

    return _findBrandByName(brands, widget.brandName ?? '') ??
        _matchBrand(brands, widget.storeName ?? '') ??
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
      final incomingMenuName = widget.menuName?.trim();
      if (incomingMenuName != null && incomingMenuName.isNotEmpty) {
        for (final menu in menus) {
          if (menu.name == incomingMenuName) {
            selectedMenu = menu;
            break;
          }
        }
      }
      setState(() {
        _menus = menus;
        _selectedMenu = selectedMenu;
        _selectedTemperatureOption = '';
        _menuSearchController.text =
            selectedMenu?.name ?? incomingMenuName ?? '';
        _syncActiveDimensions(selectedMenu?.category);
      });
    } catch (_) {
      setState(() {
        _menuError = '메뉴 목록을 불러오지 못했어요.';
      });
    } finally {
      setState(() {
        _loadingMenus = false;
      });
    }
  }

  Future<void> _submitReview() async {
    final auth = await ref.read(authControllerProvider).getAuthContext();
    if (auth == null) {
      await _showTopToast('리뷰 작성은 로그인 후 이용할 수 있어요.');
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
    final storeName = widget.storeName ?? '';
    if (storeName.isEmpty) {
      await _showTopToast('카페를 선택해주세요.');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });
    try {
      final imageUrls = await _uploadSelectedImages(auth);
      final review = await _createReviewWithRecovery(
        ReviewCreateRequest(
          storeName: storeName,
          address: widget.address ?? '',
          placeId: widget.placeId ?? '',
          link: widget.link ?? '',
          temperatureOption: _selectedTemperatureOption,
          lat: widget.lat,
          lng: widget.lng,
          brandId: _selectedBrand!.id,
          menuName: menuName,
          scores: _scores,
          storeScores: _storeScores,
          overall: overall,
          comment: _commentController.text.trim(),
          imageUrls: imageUrls,
        ),
        auth,
      );
      ref.invalidate(myReviewsProvider);
      ref.invalidate(rankingListProvider);
      ref.invalidate(storeRankingListProvider);
      if (!mounted) return;
      context.push('/review/${review.id}', extra: review);
    } on DioException catch (e, stackTrace) {
      debugPrint('Error submitting review: $e');
      debugPrint('Stack trace: $stackTrace');
      final needsReauth = _isRecoverableUserSessionError(e);
      await _showTopToast(
        needsReauth
            ? '로그인 정보를 확인하지 못했어요. 다시 로그인 후 리뷰를 등록해 주세요.'
            : _messageForSubmitError(e),
      );
      if (needsReauth && mounted) {
        context.push('/auth');
      }
    } catch (e, stackTrace) {
      debugPrint('Error submitting review: $e');
      debugPrint('Stack trace: $stackTrace');
      await _showTopToast('리뷰 제출에 실패했어요.');
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

  bool _isRecoverableUserSessionError(DioException error) {
    if (error.response?.statusCode != 401) return false;
    final detail = _errorDetail(error.response?.data).toLowerCase();
    return detail.contains('user session not initialized') ||
        detail.contains('user_not_synced');
  }

  String _messageForSubmitError(DioException error) {
    if (error.response?.statusCode == 401) {
      return '로그인 정보를 확인하지 못했어요. 다시 로그인 후 리뷰를 등록해 주세요.';
    }
    final detail = _errorDetail(error.response?.data);
    if (detail.isNotEmpty) {
      return '리뷰 등록에 실패했어요. $detail';
    }
    return '리뷰 등록에 실패했어요. 잠시 후 다시 시도해 주세요.';
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

  ChoiceChip _buildTemperatureChip({
    required String label,
    required String value,
  }) {
    final isSelected = _selectedTemperatureOption == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) {
        setState(() {
          _selectedTemperatureOption = value;
        });
      },
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppColors.textSecondary,
        fontWeight: FontWeight.w600,
      ),
      backgroundColor: Colors.white,
      selectedColor: AppColors.primary,
      side: BorderSide(
        color: isSelected ? AppColors.primary : AppColors.cardBorder,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
    );
  }

  Future<List<String>> _uploadSelectedImages(AuthContext auth) async {
    if (_selectedImages.isEmpty) return const [];
    final api = ref.read(reviewApiProvider);
    final uploadedUrls = <String>[];
    for (final image in _selectedImages) {
      final presigned = await api.requestReviewImagePresign(
        ReviewImagePresignRequest(
          fileName: image.fileName,
          contentType: image.contentType,
        ),
        auth: auth,
      );
      await api.uploadToPresignedUrl(
        uploadUrl: presigned.uploadUrl,
        bytes: image.bytes,
        contentType: image.contentType,
      );
      uploadedUrls.add(presigned.fileUrl);
    }
    return uploadedUrls;
  }

  Future<void> _pickImages() async {
    final remaining = 2 - _selectedImages.length;
    if (remaining <= 0) {
      await _showTopToast('사진은 최대 2장까지 첨부할 수 있어요.');
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
        await _showTopToast('사진은 최대 2장까지 첨부할 수 있어요.');
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
      await _showTopToast('사진은 최대 2장까지 첨부할 수 있어요.');
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

  void _removeImageAt(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  String _contentTypeFromName(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.gif')) return 'image/gif';
    if (lower.endsWith('.heic')) return 'image/heic';
    if (lower.endsWith('.heif')) return 'image/heif';
    return 'image/jpeg';
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

  void _syncActiveDimensions(String? category) {
    final next = dimensionsForCategory(category);
    _activeDimensions = next;
    _scores = {
      for (final key in next)
        key: _scores.containsKey(key) ? _scores[key]! : 3.0,
    };
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
        title: const Text('리뷰 작성'),
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
          child: ListView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.manual,
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
                    child: const Icon(Icons.store, color: AppColors.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.storeName ?? '카페를 선택해주세요.',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        if (widget.address != null &&
                            widget.address!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            widget.address!,
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
                              border: Border.all(color: AppColors.cardBorder),
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
                                    if (!await _confirmBrandChange(brand)) {
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
                              final menuText = _normalizeSearchText(menu.name);
                              return menuText.contains(
                                    _normalizeSearchText(query),
                                  ) ||
                                  queryKeys
                                      .intersection(_menuMatchKeys(menu.name))
                                      .isNotEmpty;
                            });
                          },
                          displayStringForOption: (menu) => menu.name,
                          onSelected: (menu) {
                            _selectMenu(menu);
                          },
                          fieldViewBuilder:
                              (context, controller, focusNode, onSubmitted) {
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
                                  onChanged: (value) {
                                    _menuSearchController.value =
                                        controller.value;
                                    final nextMenu = _findMenuByText(
                                      value.trim(),
                                    );
                                    if (_selectedMenu?.id != nextMenu?.id) {
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
                                        MediaQuery.of(context).size.width - 64,
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
                                  width: MediaQuery.of(context).size.width - 64,
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
                                _buildTemperatureChip(label: '핫', value: 'hot'),
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
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ..._activeDimensions.expand(
                (key) => [
                  RatingSlider(
                    label: ratingLabel(key),
                    value: _scores[key] ?? 3.0,
                    onChanged: (v) => _updateScore(key, v),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
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
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ...storeExperienceDimensions.expand(
                (key) => [
                  RatingSlider(
                    label: ratingLabel(key),
                    value: _storeScores[key] ?? 3.0,
                    onChanged: (v) => _updateStoreScore(key, v),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
              const SizedBox(height: 20),
              const Text(
                '사진 추가',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 106,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _selectedImages.length + 1,
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return _ReviewImageAddTile(
                        count: _selectedImages.length,
                        maxCount: 2,
                        disabled: _isSubmitting,
                        onTap: _pickImages,
                      );
                    }
                    final item = _selectedImages[index - 1];
                    return _ReviewImagePreviewTile(
                      bytes: item.bytes,
                      disabled: _isSubmitting,
                      onRemove: () => _removeImageAt(index - 1),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                '후기를 남겨주세요',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
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
                  hintText: '카페 분위기와 메뉴 평가를 자유롭게 남겨주세요. 다른 사용자에게 큰 도움이 됩니다.',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: AppColors.cardBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: AppColors.cardBorder),
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
                  text: _isSubmitting ? '제출 중...' : '리뷰 제출',
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

class _SelectedReviewImage {
  final String fileName;
  final String contentType;
  final Uint8List bytes;

  const _SelectedReviewImage({
    required this.fileName,
    required this.contentType,
    required this.bytes,
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
  final Uint8List bytes;
  final bool disabled;
  final VoidCallback onRemove;

  const _ReviewImagePreviewTile({
    required this.bytes,
    required this.disabled,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 106,
      height: 106,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.memory(
              bytes,
              width: 106,
              height: 106,
              fit: BoxFit.cover,
              gaplessPlayback: true,
            ),
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
