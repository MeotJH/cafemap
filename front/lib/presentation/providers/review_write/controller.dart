import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:front/core/constants/rating_dimensions.dart';
import 'package:front/core/services/analytics_service.dart';
import 'package:front/data/remote/review_api.dart';
import 'package:front/domain/entities/auth_context.dart';
import 'package:front/domain/entities/brand.dart';
import 'package:front/domain/entities/menu.dart';
import 'package:front/domain/entities/review.dart';
import 'package:front/presentation/providers/app_providers.dart';
import 'package:front/presentation/providers/auth_providers.dart';
import 'package:front/presentation/providers/ranking_providers.dart';
import 'package:front/presentation/providers/review_providers.dart';
import 'package:front/presentation/providers/review_write/constants.dart';
import 'package:front/presentation/providers/review_write/local_media.dart';
import 'package:front/presentation/providers/review_write/route_args.dart';
import 'package:front/presentation/providers/review_write/state.dart';
import 'package:front/presentation/providers/review_write/submission_result.dart';
import 'package:front/presentation/providers/store_providers.dart';

/// 리뷰 작성 라우트의 핵심 상태와 비즈니스 흐름을 담당하는 Riverpod 컨트롤러.
///
/// 주요 책임:
/// - 생성/수정 모드 bootstrap
/// - 브랜드, 메뉴, 온도, 점수 등 파생 폼 상태 계산
/// - 기존/신규 미디어 관리와 정책 검증
/// - 제출, 업로드, 재시도, provider invalidation 오케스트레이션
///
/// 반대로 다이얼로그, 토스트, 파일 선택기, 네비게이션처럼
/// `BuildContext`나 플랫폼 API가 필요한 UI 장치는 페이지 셸에 남겨둔다.
class ReviewWriteController extends Notifier<ReviewWriteState> {
  ReviewWriteController(this.args);

  final ReviewWriteRouteArgs args;
  bool _didInitialize = false;

  @override
  ReviewWriteState build() => ReviewWriteState.initial(args);

  /// 생성/수정 진입 시 필요한 초기 데이터를 한 번만 복원한다.
  ///
  /// 수정 모드에서 상세 리뷰가 없으면 서버에서 다시 조회하고,
  /// 이후 브랜드/메뉴/점수/미디어 초기 상태를 채운다.
  Future<void> initialize() async {
    if (_didInitialize) return;
    _didInitialize = true;

    var editingReview = state.editingReview;
    if (state.isEditMode && editingReview == null) {
      try {
        final repository = ref.read(reviewRepositoryProvider);
        editingReview = await repository.fetchReviewDetail(state.reviewId!);
        state = state.copyWith(editingReview: editingReview);
      } catch (_) {
        state = state.copyWith(
          bootstrapError: '리뷰 정보를 불러오지 못했어요.',
          isBootstrapping: false,
        );
        return;
      }
    }

    if (editingReview != null) {
      _applyInitialReview(editingReview);
    } else {
      state = state.copyWith(overall: _calculateOverall(state.scores));
    }

    await _loadBrands();
    state = state.copyWith(isBootstrapping: false);
  }

  /// 후기 텍스트를 상태에 반영한다.
  void setComment(String value) {
    state = state.copyWith(commentText: value);
  }

  /// 커피 평가 점수를 갱신하고 총점도 같이 다시 계산한다.
  void updateScore(String key, double value) {
    final nextScores = {...state.scores, key: value};
    state = state.copyWith(
      scores: nextScores,
      overall: _calculateOverall(nextScores),
    );
  }

  /// 매장 평가 점수를 갱신한다.
  void updateStoreScore(String key, double value) {
    state = state.copyWith(storeScores: {...state.storeScores, key: value});
  }

  /// 선택형 속성 값을 갱신한다.
  void updateAttribute(String key, String value) {
    state = state.copyWith(attributes: {...state.attributes, key: value});
  }

  /// 온도 선택 상태를 갱신하고 현재 스키마에서 쓰는 속성이면 같이 반영한다.
  void updateTemperatureOption(String value) {
    final nextAttributes = state.usesCurrentRatingSchema
        ? {...state.attributes, 'temperature_option': value}
        : state.attributes;
    state = state.copyWith(
      selectedTemperatureOption: value,
      attributes: nextAttributes,
    );
  }

  /// 메뉴 검색 입력값을 반영하고, 현재 입력으로 식별 가능한 메뉴를 다시 매칭한다.
  void updateMenuSearchText(String value) {
    final nextMenu = _findMenuByText(value, state.menus);
    state = state.copyWith(
      menuSearchText: value,
      selectedMenu: nextMenu,
      selectedTemperatureOption: nextMenu?.id == state.selectedMenu?.id
          ? state.selectedTemperatureOption
          : '',
    );
    _syncActiveDimensions(nextMenu?.category);
  }

  /// 사용자가 메뉴를 명시적으로 선택했을 때 관련 파생 상태를 동기화한다.
  void selectMenu(Menu? menu) {
    state = state.copyWith(
      selectedMenu: menu,
      menuSearchText: menu?.name ?? '',
      selectedTemperatureOption: '',
    );
    _syncActiveDimensions(menu?.category);
  }

  /// 브랜드 변경 시 메뉴/온도 상태를 초기화하고 해당 브랜드 메뉴를 다시 불러온다.
  Future<void> selectBrand(Brand brand) async {
    state = state.copyWith(
      selectedBrand: brand,
      lastConfirmedBrand: brand,
      clearSelectedMenu: true,
      selectedTemperatureOption: '',
      menuSearchText: '',
      menus: const [],
    );
    _syncActiveDimensions(null);
    await _loadMenus(brand.id);
  }

  /// 현재 메뉴가 온도 선택 UI를 노출해야 하는 카테고리인지 판단한다.
  bool shouldShowTemperatureSelector(Menu? menu) {
    if (menu == null) return false;
    final category = normalizeRatingCategory(menu.category);
    return temperatureSelectableCategories.contains(category);
  }

  /// 자동완성 메뉴 목록을 현재 검색어 기준으로 필터링한다.
  Iterable<Menu> menuOptionsForQuery(String query) {
    final trimmed = query.trim().toLowerCase();
    if (trimmed.isEmpty) return state.menus;
    final queryKeys = _menuMatchKeys(trimmed);
    return state.menus.where((menu) {
      final menuText = _normalizeSearchText(menu.name);
      return menuText.contains(_normalizeSearchText(trimmed)) ||
          queryKeys.intersection(_menuMatchKeys(menu.name)).isNotEmpty;
    });
  }

  /// 페이지 셸이 선택기에서 가져온 로컬 미디어를 상태에 추가한다.
  ///
  /// 여기서 개수 제한과 영상 길이 제한을 함께 검사하고,
  /// 사용자에게 보여줄 메시지가 있으면 문자열로 돌려준다.
  String? appendSelectedMedia(List<ReviewWriteLocalMedia> items) {
    final remaining = reviewWriteMaxMedia - state.currentMediaCount;
    if (remaining <= 0) {
      return '사진과 영상은 최대 $reviewWriteMaxMedia개까지 첨부할 수 있어요.';
    }

    final next = <ReviewWriteLocalMedia>[];
    var skippedForDuration = false;
    for (final item in items) {
      if (next.length >= remaining) break;
      if (item.type == 'video' &&
          item.durationMs != null &&
          item.durationMs! > reviewWriteMaxVideoDurationMs) {
        skippedForDuration = true;
        continue;
      }
      next.add(item);
    }

    if (next.isNotEmpty) {
      state = state.copyWith(
        selectedMediaItems: [...state.selectedMediaItems, ...next],
      );
    }

    if (skippedForDuration) {
      return '30초 이하의 영상만 첨부할 수 있어요.';
    }
    if (items.length > remaining) {
      return '사진과 영상은 최대 $reviewWriteMaxMedia개까지 첨부할 수 있어요.';
    }
    return null;
  }

  /// 아직 업로드되지 않은 신규 미디어를 제거한다.
  void removeSelectedMediaAt(int index) {
    final next = [...state.selectedMediaItems]..removeAt(index);
    state = state.copyWith(selectedMediaItems: next);
  }

  /// 수정 모드에서 기존에 저장돼 있던 미디어를 최종 payload에서 제외한다.
  void removeExistingMediaAt(int index) {
    final next = [...state.existingMediaItems]..removeAt(index);
    state = state.copyWith(existingMediaItems: next);
  }

  /// 제출 전 검증부터 업로드, create/update, retry까지 전체 제출 흐름을 실행한다.
  Future<ReviewWriteSubmissionResult> submit() async {
    final auth = await ref.read(authControllerProvider).getAuthContext();
    if (auth == null) {
      return ReviewWriteSubmissionResult(
        message: '리뷰 ${state.reviewActionNoun}은 로그인 후 이용할 수 있어요.',
        needsAuth: true,
      );
    }

    if (state.selectedBrand == null) {
      return const ReviewWriteSubmissionResult(message: '브랜드를 선택해주세요.');
    }

    final selectedMenu = _resolveSelectedMenu();
    if (selectedMenu == null) {
      return const ReviewWriteSubmissionResult(
        message: '표준 메뉴 목록에서 메뉴를 선택해주세요.',
      );
    }

    if (shouldShowTemperatureSelector(selectedMenu) &&
        state.selectedTemperatureOption.isEmpty) {
      return const ReviewWriteSubmissionResult(message: '핫 또는 아이스를 선택해주세요.');
    }

    final storeName = state.storeName ?? '';
    if (storeName.isEmpty) {
      return const ReviewWriteSubmissionResult(message: '카페를 선택해주세요.');
    }

    state = state.copyWith(isSubmitting: true);
    try {
      final uploadedMediaItems = await _uploadSelectedMedia(auth);
      final mediaItems = [...state.existingMediaItems, ...uploadedMediaItems];
      final imageUrls = mediaItems
          .where((item) => item.isImage)
          .map((item) => item.url)
          .toList(growable: false);

      final payload = ReviewCreateRequest(
        storeName: storeName,
        address: state.address ?? '',
        placeId: state.placeId ?? '',
        link: state.link ?? '',
        temperatureOption: state.selectedTemperatureOption,
        lat: state.lat,
        lng: state.lng,
        brandId: state.selectedBrand!.id,
        menuName: selectedMenu.name,
        ratingSchemaVersion: state.ratingSchemaVersion,
        scores: state.scores,
        storeScores: state.storeScores,
        attributes: _attributesForPayload(selectedMenu),
        overall: state.overall,
        comment: state.commentText.trim(),
        imageUrls: imageUrls,
        mediaItems: mediaItems,
      );

      final review = state.isEditMode
          ? await _updateReviewWithRecovery(state.reviewId!, payload, auth)
          : await _createReviewWithRecovery(payload, auth);

      analyticsService.trackEvent(
        state.isEditMode ? 'review_update_success' : 'review_submit_success',
        <String, Object?>{
          'rating_schema_version': state.ratingSchemaVersion,
          'menu_category': normalizeRatingCategory(selectedMenu.category),
          'media_count': payload.mediaItems.length,
        },
      );

      _invalidateReviewRelatedProviders(review.id);
      return ReviewWriteSubmissionResult(review: review);
    } on DioException catch (error) {
      final needsReauth = _isRecoverableUserSessionError(error);
      return ReviewWriteSubmissionResult(
        message: needsReauth
            ? '로그인 정보를 확인하지 못했어요. 다시 로그인 후 리뷰를 ${state.reviewActionNoun}해 주세요.'
            : _messageForSubmitError(error),
        needsAuth: needsReauth,
      );
    } catch (_) {
      return ReviewWriteSubmissionResult(
        message: '리뷰 ${state.reviewActionNoun}에 실패했어요.',
      );
    } finally {
      state = state.copyWith(isSubmitting: false);
    }
  }

  /// 기존 리뷰 데이터를 현재 작성 폼 상태로 옮겨 수정 화면 초기값을 만든다.
  void _applyInitialReview(Review review) {
    final schemaVersion = normalizeRatingSchemaVersion(
      review.ratingSchemaVersion,
    );
    final nextDimensions = dimensionsForCategoryForSchema(
      review.menuCategory,
      schemaVersion,
    );
    final nextScores = {
      for (final key in nextDimensions) key: review.scores[key] ?? 3.0,
    };
    final nextStoreScores = {
      for (final key in storeDimensionsForSchema(schemaVersion))
        key: review.scores[key] ?? 3.0,
    };
    state = state.copyWith(
      activeDimensions: nextDimensions,
      scores: nextScores,
      storeScores: nextStoreScores,
      attributes: _attributeDefaultsForCategory(
        review.menuCategory,
        usesCurrentSchema:
            normalizeRatingSchemaVersion(review.ratingSchemaVersion) ==
            currentRatingSchemaVersion,
        selectedTemperatureOption: review.temperatureOption,
      )..addAll(review.attributes),
      overall: review.overall > 0
          ? review.overall
          : _calculateOverall(nextScores),
      selectedTemperatureOption: review.temperatureOption,
      commentText: review.comment,
      existingMediaItems: review.mediaItems.take(reviewWriteMaxMedia).toList(),
      menuSearchText: review.menuName,
      editingReview: review,
      storeName: state.storeName ?? review.storeName,
      address: state.address ?? review.address,
      placeId: state.placeId ?? review.placeId,
      link: state.link ?? review.link,
      lat: state.lat ?? review.lat,
      lng: state.lng ?? review.lng,
      incomingMenuName: state.incomingMenuName ?? review.menuName,
      incomingBrandId: state.incomingBrandId ?? review.brandId,
      incomingBrandName: state.incomingBrandName ?? review.brandName,
    );
  }

  /// 브랜드 목록을 불러오고, 라우트/리뷰 정보 기준으로 초기 브랜드를 정한다.
  Future<void> _loadBrands() async {
    try {
      final repository = ref.read(menuRepositoryProvider);
      final brands = await repository.fetchBrands();
      final localBrand = _findBrandById(brands, reviewWriteLocalBrandId);
      final matched = _resolveInitialBrand(brands, localBrand);
      state = state.copyWith(
        brands: brands,
        selectedBrand: matched,
        lastConfirmedBrand: matched,
      );
      if (matched != null) {
        await _loadMenus(matched.id);
      }
    } catch (_) {
      state = state.copyWith(menuError: '메뉴 목록을 불러오지 못했어요.');
    }
  }

  /// 선택된 브랜드의 메뉴 목록을 불러오고 초기 메뉴/온도 상태를 복원한다.
  Future<void> _loadMenus(String brandId) async {
    state = state.copyWith(loadingMenus: true, clearMenuError: true);
    try {
      final repository = ref.read(menuRepositoryProvider);
      final menus = await repository.fetchMenus(brandId);

      Menu? selectedMenu;
      final incomingMenuName = state.incomingMenuName?.trim();
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
              state.editingReview != null &&
              state.editingReview!.menuName == selectedMenu.name
          ? state.editingReview!.temperatureOption
          : '';

      state = state.copyWith(
        menus: menus,
        selectedMenu: selectedMenu,
        selectedTemperatureOption: nextTemperatureOption,
        menuSearchText: selectedMenu?.name ?? incomingMenuName ?? '',
      );
      _syncActiveDimensions(selectedMenu?.category);
    } catch (_) {
      state = state.copyWith(menuError: '메뉴 목록을 불러오지 못했어요.');
    } finally {
      state = state.copyWith(loadingMenus: false);
    }
  }

  /// 커피 평가 점수들의 평균 총점을 계산한다.
  double _calculateOverall(Map<String, double> scores) {
    if (scores.isEmpty) return 0;
    final total = scores.values.reduce((a, b) => a + b);
    return total / scores.length;
  }

  /// 메뉴 카테고리 변화에 맞춰 점수 차원과 속성 기본값을 다시 맞춘다.
  void _syncActiveDimensions(String? category) {
    final next = dimensionsForCategoryForSchema(
      category,
      state.ratingSchemaVersion,
    );
    final nextScores = {
      for (final key in next)
        key: state.scores.containsKey(key) ? state.scores[key]! : 3.0,
    };
    final storeKeys = storeDimensionsForSchema(state.ratingSchemaVersion);
    final nextStoreScores = {
      for (final key in storeKeys)
        key: state.storeScores.containsKey(key) ? state.storeScores[key]! : 3.0,
    };
    final nextAttributes = state.usesCurrentRatingSchema
        ? {
            for (final entry in _attributeDefaultsForCategory(
              category,
              usesCurrentSchema: true,
              selectedTemperatureOption: state.selectedTemperatureOption,
            ).entries)
              entry.key: state.attributes[entry.key] ?? entry.value,
          }
        : <String, String>{};
    state = state.copyWith(
      activeDimensions: next,
      scores: nextScores,
      storeScores: nextStoreScores,
      attributes: nextAttributes,
      overall: _calculateOverall(nextScores),
    );
  }

  /// 현재 카테고리에서 필요한 속성 기본값 집합을 만든다.
  Map<String, String> _attributeDefaultsForCategory(
    String? category, {
    required bool usesCurrentSchema,
    required String selectedTemperatureOption,
  }) {
    if (!usesCurrentSchema) return const {};
    final defaults = <String, String>{};
    for (final key in menuAttributeKeysForCategory(category)) {
      defaults[key] = defaultAttributeValue(key);
    }
    for (final key in v2StoreAttributeKeys) {
      defaults[key] = defaultAttributeValue(key);
    }
    if (selectedTemperatureOption.isNotEmpty &&
        defaults.containsKey('temperature_option')) {
      defaults['temperature_option'] = selectedTemperatureOption;
    }
    return defaults;
  }

  /// 제출 payload에 들어갈 최종 속성 맵을 현재 메뉴 기준으로 조립한다.
  Map<String, String> _attributesForPayload(Menu menu) {
    if (!state.usesCurrentRatingSchema) return const {};
    final defaults = _attributeDefaultsForCategory(
      menu.category,
      usesCurrentSchema: true,
      selectedTemperatureOption: state.selectedTemperatureOption,
    );
    return {
      for (final entry in defaults.entries)
        entry.key:
            entry.key == 'temperature_option' &&
                state.selectedTemperatureOption.isNotEmpty
            ? state.selectedTemperatureOption
            : (state.attributes[entry.key] ?? entry.value),
    };
  }

  /// 신규 로컬 미디어를 presigned URL로 업로드하고 서버용 미디어 목록으로 변환한다.
  Future<List<ReviewMediaItem>> _uploadSelectedMedia(AuthContext auth) async {
    if (state.selectedMediaItems.isEmpty) return const [];
    final api = ref.read(reviewApiProvider);
    final uploadedItems = <ReviewMediaItem>[];
    for (final item in state.selectedMediaItems) {
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

  /// 리뷰 생성 API 호출과 recoverable auth sync 재시도를 담당한다.
  Future<Review> _createReviewWithRecovery(
    ReviewCreateRequest payload,
    AuthContext auth,
  ) async {
    final repository = ref.read(reviewRepositoryProvider);
    try {
      return await repository.createReview(payload, auth: auth);
    } on DioException catch (error) {
      if (!_isRecoverableUserSessionError(error)) rethrow;
      await ref.read(authApiProvider).syncUser(auth);
      return repository.createReview(payload, auth: auth);
    }
  }

  /// 리뷰 수정 API 호출과 recoverable auth sync 재시도를 담당한다.
  Future<Review> _updateReviewWithRecovery(
    String reviewId,
    ReviewCreateRequest payload,
    AuthContext auth,
  ) async {
    final repository = ref.read(reviewRepositoryProvider);
    try {
      return await repository.updateReview(reviewId, payload, auth: auth);
    } on DioException catch (error) {
      if (!_isRecoverableUserSessionError(error)) rethrow;
      await ref.read(authApiProvider).syncUser(auth);
      return repository.updateReview(reviewId, payload, auth: auth);
    }
  }

  /// 리뷰 생성/수정 뒤 관련 화면들이 최신 데이터를 다시 읽도록 provider를 무효화한다.
  void _invalidateReviewRelatedProviders(String reviewId) {
    ref.invalidate(myReviewsProvider);
    ref.invalidate(rankingListProvider);
    ref.invalidate(storeRankingListProvider);
    ref.invalidate(reviewDetailProvider(reviewId));
    ref.invalidate(storeDetailProvider);
    ref.invalidate(storeBreakdownProvider);
    ref.invalidate(storeReviewsProvider);
    ref.invalidate(rankingReviewsProvider);
  }

  /// 401 에러 중에서 자동 복구 가능한 사용자 세션 불일치인지 판별한다.
  bool _isRecoverableUserSessionError(DioException error) {
    if (error.response?.statusCode != 401) return false;
    final detail = _errorDetail(error.response?.data).toLowerCase();
    return detail.contains('user session not initialized') ||
        detail.contains('user_not_synced');
  }

  String _messageForSubmitError(DioException error) {
    if (error.response?.statusCode == 401) {
      return '로그인 정보를 확인하지 못했어요. 다시 로그인 후 리뷰를 ${state.reviewActionNoun}해 주세요.';
    }
    final detail = _errorDetail(error.response?.data);
    if (detail.isNotEmpty) {
      return '리뷰 ${state.reviewActionNoun}에 실패했어요. $detail';
    }
    return '리뷰 ${state.reviewActionNoun}에 실패했어요. 잠시 후 다시 시도해 주세요.';
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

  /// 메뉴 입력값과 선택 상태를 비교해 실제로 제출할 메뉴를 결정한다.
  Menu? _resolveSelectedMenu() {
    final selected = state.selectedMenu;
    final typed = state.menuSearchText.trim();
    if (selected != null && selected.name == typed) {
      return selected;
    }
    return _findMenuByText(typed, state.menus);
  }

  /// 자유 입력 텍스트를 현재 브랜드 메뉴 목록과 비교해 가장 가까운 메뉴를 찾는다.
  Menu? _findMenuByText(String typed, List<Menu> menus) {
    final typedKeys = _menuMatchKeys(typed);
    for (final menu in menus) {
      if (menu.name == typed ||
          typedKeys.intersection(_menuMatchKeys(menu.name)).isNotEmpty) {
        return menu;
      }
    }
    return null;
  }

  /// 매장명 힌트를 바탕으로 브랜드 후보를 추정한다.
  Brand? _matchBrand(List<Brand> brands, String storeName) {
    final normalized = _normalizeSearchText(storeName);
    if (_isLocalHint(normalized)) {
      return _findBrandById(brands, reviewWriteLocalBrandId);
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

  /// 브랜드 id로 정확히 일치하는 브랜드를 찾는다.
  Brand? _findBrandById(List<Brand> brands, String brandId) {
    for (final brand in brands) {
      if (brand.id == brandId) return brand;
    }
    return null;
  }

  /// 브랜드명을 정규화해서 일치하는 브랜드를 찾는다.
  Brand? _findBrandByName(List<Brand> brands, String brandName) {
    final target = _normalizeSearchText(brandName);
    if (target.isEmpty) return null;
    if (_isLocalHint(target)) {
      return _findBrandById(brands, reviewWriteLocalBrandId);
    }
    for (final brand in brands) {
      if (_brandMatchTokens(brand).contains(target)) return brand;
    }
    return null;
  }

  /// 라우트 인자, 리뷰 초기값, 매장명 힌트를 이용해 초기 브랜드를 결정한다.
  Brand? _resolveInitialBrand(List<Brand> brands, Brand? localBrand) {
    final fallbackBrand = brands.isNotEmpty ? brands.first : null;
    final incomingBrandId = state.incomingBrandId?.trim() ?? '';
    if (incomingBrandId.isNotEmpty) {
      if (incomingBrandId == reviewWriteLocalBrandId ||
          incomingBrandId.toLowerCase() == 'local') {
        return localBrand ?? fallbackBrand;
      }
      return _findBrandById(brands, incomingBrandId) ??
          (_isLocalHint(_normalizeSearchText(state.incomingBrandName ?? ''))
              ? localBrand
              : null) ??
          fallbackBrand;
    }

    return _findBrandByName(brands, state.incomingBrandName ?? '') ??
        _matchBrand(brands, state.storeName ?? '') ??
        localBrand ??
        fallbackBrand;
  }

  /// 로컬 카페를 의미하는 텍스트 힌트인지 판별한다.
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
    if (brand.id == reviewWriteLocalBrandId) {
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
}

/// 라우트 인자를 key로 쓰는 family provider.
///
/// 같은 앱 세션 안에서도 리뷰 작성 화면 인스턴스마다 독립된 상태를 가지도록
/// 분리해준다.
final reviewWriteControllerProvider =
    NotifierProvider.family<
      ReviewWriteController,
      ReviewWriteState,
      ReviewWriteRouteArgs
    >(ReviewWriteController.new);
