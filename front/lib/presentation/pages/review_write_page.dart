import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:another_flushbar/flushbar.dart';
import 'package:flutter/foundation.dart';
import 'package:front/app/write_cafe_review_button.dart';
import 'package:front/core/constants/app_colors.dart';
import 'package:front/core/constants/rating_dimensions.dart';
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
import 'package:image_picker/image_picker.dart';

// 리뷰 작성 화면이다.
class ReviewWritePage extends ConsumerStatefulWidget {
  final String? storeName;
  final String? address;
  final String? menuName;
  final String? brandId;
  final String? brandName;

  const ReviewWritePage({
    super.key,
    this.storeName,
    this.address,
    this.menuName,
    this.brandId,
    this.brandName,
  });

  @override
  // 리뷰 작성 화면의 상태를 생성한다.
  ConsumerState<ReviewWritePage> createState() => _ReviewWritePageState();
}

class _ReviewWritePageState extends ConsumerState<ReviewWritePage> {
  List<String> _activeDimensions = dimensionsForCategory(null);
  Map<String, double> _scores = {
    for (final key in dimensionsForCategory(null)) key: 3.0,
  };
  double overall = 3.0;
  List<Brand> _brands = [];
  Brand? _selectedBrand;
  List<Menu> _menus = [];
  Menu? _selectedMenu;
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
      final matched = widget.brandId == null || widget.brandId!.isEmpty
          ? (_findBrandByName(brands, widget.brandName ?? '') ??
                _matchBrand(brands, widget.storeName ?? '') ??
                _findBrandById(brands, 'brand-local'))
          : _findBrandById(brands, widget.brandId!) ?? brands.first;
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
    final normalized = storeName.replaceAll(' ', '').toLowerCase();
    for (final brand in brands) {
      final token = brand.name.replaceAll(' ', '').toLowerCase();
      if (token.isNotEmpty && normalized.contains(token)) {
        return brand;
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
    final target = brandName.replaceAll(' ', '').toLowerCase();
    if (target.isEmpty) return null;
    for (final brand in brands) {
      final normalized = brand.name.replaceAll(' ', '').toLowerCase();
      if (normalized == target) return brand;
    }
    return null;
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
        _menuSearchController.text = selectedMenu?.name ?? '';
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
    final selectedMenu = _selectedMenu;
    if (selectedMenu == null) {
      await _showTopToast('메뉴를 선택해주세요.');
      return;
    }
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
      final repository = ref.read(reviewRepositoryProvider);
      final review = await repository.createReview(
        ReviewCreateRequest(
          storeName: storeName,
          address: widget.address ?? '',
          brandId: _selectedBrand!.id,
          menuName: selectedMenu.name,
          scores: _scores,
          overall: overall,
          comment: _commentController.text.trim(),
          imageUrls: imageUrls,
        ),
        auth: auth,
      );
      ref.invalidate(myReviewsProvider);
      ref.invalidate(rankingListProvider);
      ref.invalidate(storeRankingListProvider);
      if (!mounted) return;
      context.push('/review/${review.id}', extra: review);
    } on DioException catch (e, stackTrace) {
      print('Error submitting review: $e');
      print('Stack trace: $stackTrace');
      final status = e.response?.statusCode;
      final detail = e.response?.data;
      await _showTopToast(
        '리뷰 제출 실패${status == null ? '' : ' ($status)'}: ${detail ?? e.message}',
      );
    } catch (e, stackTrace) {
      print('Error submitting review: $e');
      print('Stack trace: $stackTrace');
      await _showTopToast('리뷰 제출에 실패했어요.');
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('리뷰 작성'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
              return;
            }
            context.go('/ranking');
          },
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.primary.withOpacity(0.2),
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
                        const SizedBox(height: 8),
                        Autocomplete<Menu>(
                          optionsBuilder: (textEditingValue) {
                            final query = textEditingValue.text
                                .trim()
                                .toLowerCase();
                            if (query.isEmpty) return _menus;
                            return _menus.where(
                              (menu) => menu.name.toLowerCase().contains(query),
                            );
                          },
                          displayStringForOption: (menu) => menu.name,
                          onSelected: (menu) {
                            setState(() {
                              _selectedMenu = menu;
                              _syncActiveDimensions(menu.category);
                            });
                            _menuSearchController.text = menu.name;
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
                                  decoration: InputDecoration(
                                    hintText: _loadingMenus
                                        ? '메뉴 불러오는 중...'
                                        : '메뉴 검색 또는 선택',
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
                                    final selected = _selectedMenu;
                                    if (selected != null &&
                                        selected.name != value) {
                                      setState(() {
                                        _selectedMenu = null;
                                        _syncActiveDimensions(null);
                                      });
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
                                      child: Text('검색 결과가 없어요.'),
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
                                  child: ListView.builder(
                                    padding: const EdgeInsets.all(8),
                                    shrinkWrap: true,
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
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
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
                    '사진 추가',
                    style: TextStyle(
                      fontSize: 32 / 2,
                      fontWeight: FontWeight.w800,
                    ),
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
                    style: TextStyle(
                      fontSize: 32 / 2,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _commentController,
                    maxLines: 6,
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
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: WriteCafeReviewButton(
                onPressed: _isSubmitting ? () {} : _submitReview,
                text: _isSubmitting ? '제출 중...' : '리뷰 제출',
              ),
            ),
          ],
        ),
      ),
    );
  }
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
