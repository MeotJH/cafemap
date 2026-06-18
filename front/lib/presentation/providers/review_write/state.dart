import 'package:front/core/constants/rating_dimensions.dart';
import 'package:front/domain/entities/brand.dart';
import 'package:front/domain/entities/menu.dart';
import 'package:front/domain/entities/review.dart';
import 'package:front/presentation/providers/review_write/constants.dart';
import 'package:front/presentation/providers/review_write/local_media.dart';
import 'package:front/presentation/providers/review_write/route_args.dart';

/// 리뷰 작성 화면 전체를 표현하는 불변 상태 객체.
///
/// bootstrap으로 복원한 초기값과 사용자가 수정 중인 폼 값을 함께 담고 있으며,
/// 페이지가 직접 비즈니스 상태를 들고 있지 않고 provider 상태만 렌더링하도록
/// 만드는 기준이 된다.
class ReviewWriteState {
  final List<String> activeDimensions;
  final Map<String, double> scores;
  final Map<String, double> storeScores;
  final Map<String, String> attributes;
  final double overall;
  final List<Brand> brands;
  final Brand? selectedBrand;
  final List<Menu> menus;
  final Menu? selectedMenu;
  final String selectedTemperatureOption;
  final String menuSearchText;
  final bool loadingMenus;
  final String? menuError;
  final Brand? lastConfirmedBrand;
  final String commentText;
  final List<ReviewWriteLocalMedia> selectedMediaItems;
  final List<ReviewMediaItem> existingMediaItems;
  final Review? editingReview;
  final bool isBootstrapping;
  final String? bootstrapError;
  final bool isSubmitting;
  final String? storeName;
  final String? address;
  final String? placeId;
  final String? link;
  final double? lat;
  final double? lng;
  final String? incomingMenuName;
  final String? incomingBrandId;
  final String? incomingBrandName;
  final String? reviewId;

  const ReviewWriteState({
    required this.activeDimensions,
    required this.scores,
    required this.storeScores,
    required this.attributes,
    required this.overall,
    required this.brands,
    required this.selectedBrand,
    required this.menus,
    required this.selectedMenu,
    required this.selectedTemperatureOption,
    required this.menuSearchText,
    required this.loadingMenus,
    required this.menuError,
    required this.lastConfirmedBrand,
    required this.commentText,
    required this.selectedMediaItems,
    required this.existingMediaItems,
    required this.editingReview,
    required this.isBootstrapping,
    required this.bootstrapError,
    required this.isSubmitting,
    required this.storeName,
    required this.address,
    required this.placeId,
    required this.link,
    required this.lat,
    required this.lng,
    required this.incomingMenuName,
    required this.incomingBrandId,
    required this.incomingBrandName,
    required this.reviewId,
  });

  factory ReviewWriteState.initial(ReviewWriteRouteArgs args) {
    final activeDimensions = dimensionsForCategoryForSchema(
      null,
      currentRatingSchemaVersion,
    );
    return ReviewWriteState(
      activeDimensions: activeDimensions,
      scores: {for (final key in activeDimensions) key: 3.0},
      storeScores: {
        for (final key in storeDimensionsForSchema(currentRatingSchemaVersion))
          key: 3.0,
      },
      attributes: const {},
      overall: 3.0,
      brands: const [],
      selectedBrand: null,
      menus: const [],
      selectedMenu: null,
      selectedTemperatureOption: '',
      menuSearchText: args.menuName ?? args.initialReview?.menuName ?? '',
      loadingMenus: false,
      menuError: null,
      lastConfirmedBrand: null,
      commentText: args.initialReview?.comment ?? '',
      selectedMediaItems: const [],
      existingMediaItems: const [],
      editingReview: args.initialReview,
      isBootstrapping: true,
      bootstrapError: null,
      isSubmitting: false,
      storeName: args.storeName ?? args.initialReview?.storeName,
      address: args.address ?? args.initialReview?.address,
      placeId: args.placeId ?? args.initialReview?.placeId,
      link: args.link ?? args.initialReview?.link,
      lat: args.lat ?? args.initialReview?.lat,
      lng: args.lng ?? args.initialReview?.lng,
      incomingMenuName: args.menuName ?? args.initialReview?.menuName,
      incomingBrandId: args.brandId ?? args.initialReview?.brandId,
      incomingBrandName: args.brandName ?? args.initialReview?.brandName,
      reviewId: args.reviewId,
    );
  }

  ReviewWriteState copyWith({
    List<String>? activeDimensions,
    Map<String, double>? scores,
    Map<String, double>? storeScores,
    Map<String, String>? attributes,
    double? overall,
    List<Brand>? brands,
    Brand? selectedBrand,
    bool clearSelectedBrand = false,
    List<Menu>? menus,
    Menu? selectedMenu,
    bool clearSelectedMenu = false,
    String? selectedTemperatureOption,
    String? menuSearchText,
    bool? loadingMenus,
    String? menuError,
    bool clearMenuError = false,
    Brand? lastConfirmedBrand,
    bool clearLastConfirmedBrand = false,
    String? commentText,
    List<ReviewWriteLocalMedia>? selectedMediaItems,
    List<ReviewMediaItem>? existingMediaItems,
    Review? editingReview,
    bool? isBootstrapping,
    String? bootstrapError,
    bool clearBootstrapError = false,
    bool? isSubmitting,
    String? storeName,
    String? address,
    String? placeId,
    String? link,
    double? lat,
    double? lng,
    String? incomingMenuName,
    String? incomingBrandId,
    String? incomingBrandName,
    String? reviewId,
  }) {
    return ReviewWriteState(
      activeDimensions: activeDimensions ?? this.activeDimensions,
      scores: scores ?? this.scores,
      storeScores: storeScores ?? this.storeScores,
      attributes: attributes ?? this.attributes,
      overall: overall ?? this.overall,
      brands: brands ?? this.brands,
      selectedBrand: clearSelectedBrand
          ? null
          : (selectedBrand ?? this.selectedBrand),
      menus: menus ?? this.menus,
      selectedMenu: clearSelectedMenu
          ? null
          : (selectedMenu ?? this.selectedMenu),
      selectedTemperatureOption:
          selectedTemperatureOption ?? this.selectedTemperatureOption,
      menuSearchText: menuSearchText ?? this.menuSearchText,
      loadingMenus: loadingMenus ?? this.loadingMenus,
      menuError: clearMenuError ? null : (menuError ?? this.menuError),
      lastConfirmedBrand: clearLastConfirmedBrand
          ? null
          : (lastConfirmedBrand ?? this.lastConfirmedBrand),
      commentText: commentText ?? this.commentText,
      selectedMediaItems: selectedMediaItems ?? this.selectedMediaItems,
      existingMediaItems: existingMediaItems ?? this.existingMediaItems,
      editingReview: editingReview ?? this.editingReview,
      isBootstrapping: isBootstrapping ?? this.isBootstrapping,
      bootstrapError: clearBootstrapError
          ? null
          : (bootstrapError ?? this.bootstrapError),
      isSubmitting: isSubmitting ?? this.isSubmitting,
      storeName: storeName ?? this.storeName,
      address: address ?? this.address,
      placeId: placeId ?? this.placeId,
      link: link ?? this.link,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      incomingMenuName: incomingMenuName ?? this.incomingMenuName,
      incomingBrandId: incomingBrandId ?? this.incomingBrandId,
      incomingBrandName: incomingBrandName ?? this.incomingBrandName,
      reviewId: reviewId ?? this.reviewId,
    );
  }

  bool get isEditMode => (reviewId?.isNotEmpty ?? false);

  bool get isBrandLocked =>
      (incomingBrandId?.isNotEmpty ?? false) ||
      (incomingBrandName?.isNotEmpty ?? false);

  bool get isLocalBrandSelected => selectedBrand?.id == reviewWriteLocalBrandId;

  String get pageTitle => isEditMode ? '리뷰 수정' : '리뷰 작성';

  String get submitButtonText => isEditMode ? '리뷰 수정 완료' : '리뷰 제출';

  String get submittingButtonText => isEditMode ? '수정 중..' : '제출 중..';

  String get reviewActionNoun => isEditMode ? '수정' : '등록';

  int get ratingSchemaVersion =>
      editingReview?.ratingSchemaVersion ?? currentRatingSchemaVersion;

  bool get usesCurrentRatingSchema =>
      normalizeRatingSchemaVersion(ratingSchemaVersion) ==
      currentRatingSchemaVersion;

  int get currentMediaCount =>
      existingMediaItems.length + selectedMediaItems.length;
}
