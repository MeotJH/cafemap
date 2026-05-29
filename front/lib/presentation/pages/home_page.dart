import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:front/core/constants/app_colors.dart';
import 'package:front/core/constants/app_strings.dart';
import 'package:front/core/utils/formatters.dart';
import 'package:front/domain/entities/store_ranking.dart';
import 'package:front/presentation/pages/ranking_home/ranking_home_types.dart';
import 'package:front/presentation/providers/ranking_providers.dart';
import 'package:front/presentation/widgets/stacked_image_gallery.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final Set<String> _precachedUrls = <String>{};

  @override
  Widget build(BuildContext context) {
    final summary = ref.watch(homeSummaryProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: summary.when(
          data: (data) {
            _scheduleThumbnailPrecache(context, data);
            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 32),
              children: [
                const _HeroCard(),
                const SizedBox(height: 28),
                const _PurposeExplorerSection(),
                const SizedBox(height: 30),
                _RankingSection(
                  title: '아내픽 TOP 3',
                  subtitle: "Wife's Pick",
                  description: '감성과 커피맛에 진심인 아내',
                  cafes: data.wifeTop,
                ),
                const SizedBox(height: 30),
                _RankingSection(
                  title: '남편픽 TOP 3',
                  subtitle: "Husband's Pick",
                  description: '구수한 아메리카노에 진심인 남편',
                  cafes: data.husbandTop,
                ),
                if (data.featuredCafe != null) ...[
                  const SizedBox(height: 30),
                  _FeaturedSection(cafe: data.featuredCafe!),
                ],
                if (data.recentCafes.isNotEmpty) ...[
                  const SizedBox(height: 30),
                  _SimpleHistorySection(cafes: data.recentCafes),
                ],
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => ListView(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 32),
            children: const [
              _HeroCard(),
              SizedBox(height: 28),
              _EmptyCard(
                title: '홈 정보를 불러오지 못했어요.',
                body: '랭킹과 지도는 정상적으로 사용할 수 있습니다.',
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _scheduleThumbnailPrecache(BuildContext context, HomeSummary data) {
    final urls = _thumbnailUrlsForSummary(
      data,
    ).where((url) => _precachedUrls.add(url)).toList(growable: false);
    if (urls.isEmpty) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (final url in urls) {
        precacheImage(CachedNetworkImageProvider(url), context);
      }
    });
  }

  List<String> _thumbnailUrlsForSummary(HomeSummary data) {
    final urls = <String>[];

    void collect(StoreRanking? cafe) {
      if (cafe == null) return;
      for (final url in _galleryUrls(cafe)) {
        if (!urls.contains(url)) {
          urls.add(url);
        }
        if (urls.length >= 8) {
          return;
        }
      }
    }

    for (final cafe in data.wifeTop.take(3)) {
      collect(cafe);
      if (urls.length >= 8) return urls;
    }
    for (final cafe in data.husbandTop.take(3)) {
      collect(cafe);
      if (urls.length >= 8) return urls;
    }
    collect(data.featuredCafe);

    return urls;
  }

  List<String> _galleryUrls(StoreRanking cafe) {
    final urls = <String>[];
    for (final url in cafe.thumbnailImageUrls) {
      final trimmed = url.trim();
      if (trimmed.isEmpty || trimmed.toLowerCase().endsWith('.svg')) {
        continue;
      }
      if (!urls.contains(trimmed)) {
        urls.add(trimmed);
      }
      if (urls.length >= 2) {
        return urls;
      }
    }
    return urls.take(2).toList(growable: false);
  }
}

class _PurposeExplorerSection extends StatelessWidget {
  const _PurposeExplorerSection();

  static const List<RankingPurpose> _purposes = [
    RankingPurpose.date,
    RankingPurpose.conversation,
    RankingPurpose.photo,
    RankingPurpose.coffee,
    RankingPurpose.longStay,
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '상황별 추천 카페',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: Color(0xFF390C00),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          '지금 찾는 목적에 맞춰 바로 랭킹으로 들어가세요.',
          style: TextStyle(
            fontSize: 14,
            color: Color(0xFF661F00),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 186,
          child: Stack(
            children: [
              ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.only(right: 48),
                itemCount: _purposes.length,
                separatorBuilder: (_, _) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final purpose = _purposes[index];
                  return _PurposeCard(purpose: purpose);
                },
              ),
              Positioned(
                top: 0,
                right: 0,
                bottom: 0,
                child: IgnorePointer(
                  child: Container(
                    width: 44,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [Color(0x00F6F0E8), AppColors.backgroundLight],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PurposeCard extends StatelessWidget {
  final RankingPurpose purpose;

  const _PurposeCard({required this.purpose});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () {
          final uri = Uri(
            path: '/rankings',
            queryParameters: {'purpose': purpose.queryValue},
          );
          context.push(uri.toString());
        },
        child: Ink(
          width: 188,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.cardBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E8),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(_iconForPurpose(purpose), color: AppColors.primary),
              ),
              const SizedBox(height: 14),
              Text(
                purpose.label,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF390C00),
                ),
              ),
              const SizedBox(height: 6),
              Expanded(
                child: Text(
                  purpose.homeDescription,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: Color(0xFF8A6B5C),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: const [
                  Text(
                    '랭킹 보기',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 16,
                    color: AppColors.primary,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _iconForPurpose(RankingPurpose purpose) {
    return switch (purpose) {
      RankingPurpose.date => Icons.favorite_rounded,
      RankingPurpose.conversation => Icons.forum_rounded,
      RankingPurpose.photo => Icons.photo_camera_rounded,
      RankingPurpose.coffee => Icons.local_cafe_rounded,
      RankingPurpose.longStay => Icons.chair_alt_rounded,
    };
  }
}

class _HeroCard extends StatefulWidget {
  const _HeroCard();

  @override
  State<_HeroCard> createState() => _HeroCardState();
}

class _HeroCardState extends State<_HeroCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..forward();
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.15, 0.75, curve: Curves.easeOutCubic),
          ),
        );
    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.25, 1.0, curve: Curves.easeOut),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Container(
              padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: AppColors.cardBorder),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color.lerp(
                      Colors.white,
                      const Color(0xFFFFF8F3),
                      _glowAnimation.value,
                    )!,
                    Color.lerp(
                      Colors.white,
                      const Color(0xFFF7E6DB),
                      _glowAnimation.value,
                    )!,
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                  BoxShadow(
                    color: const Color(
                      0xFFC28D73,
                    ).withValues(alpha: 0.10 * _glowAnimation.value),
                    blurRadius: 32,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShaderMask(
                    shaderCallback: (bounds) => LinearGradient(
                      colors: [
                        const Color(0xFF390C00),
                        Color.lerp(
                          const Color(0xFF390C00),
                          const Color(0xFFA03200),
                          _glowAnimation.value,
                        )!,
                      ],
                    ).createShader(bounds),
                    child: const Text(
                      AppStrings.appName,
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.9,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    AppStrings.appSlogan,
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      height: 1.35,
                      color: Color.lerp(
                        const Color(0xFF661F00),
                        const Color(0xFF4D1700),
                        _glowAnimation.value,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '취향별 랭킹과 지도에서 다시 가고 싶은 카페를 찾아보세요.',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      height: 1.55,
                      color: Color.lerp(
                        const Color(0xFFA46F55),
                        const Color(0xFF832700),
                        _glowAnimation.value,
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      Icon(
                        Icons.auto_awesome_outlined,
                        size: 15,
                        color: Color.lerp(
                          const Color(0xFFDAB7A4),
                          const Color(0xFFC28D73),
                          _glowAnimation.value,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'OUR COFFEE JOURNEY',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.3,
                          color: Color.lerp(
                            const Color(0xFFDAB7A4),
                            const Color(0xFFC28D73),
                            _glowAnimation.value,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _RankingSection extends StatelessWidget {
  final String title;
  final String subtitle;
  final String description;
  final List<StoreRanking> cafes;

  const _RankingSection({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.cafes,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.end,
          spacing: 6,
          runSpacing: 6,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.4,
                color: Color(0xFF390C00),
              ),
            ),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF832700),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          description,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF661F00),
          ),
        ),
        const SizedBox(height: 16),
        if (cafes.isEmpty)
          const _EmptyCard(title: '아직 카페가 없습니다.', body: '리뷰가 쌓이면 이 섹션부터 채워집니다.')
        else
          ...cafes
              .take(3)
              .map(
                (cafe) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: _CafeScoreCard(
                    cafe: cafe,
                    score: _scoreForSection(cafe),
                    scoreLabel: _scoreLabel,
                  ),
                ),
              ),
      ],
    );
  }

  double _scoreForSection(StoreRanking cafe) {
    if (subtitle.startsWith('Wife')) return cafe.wifeScore;
    return cafe.husbandScore;
  }

  String get _scoreLabel {
    if (subtitle.startsWith('Wife')) return '아내픽';
    return '남편픽';
  }
}

class _FeaturedSection extends StatelessWidget {
  final StoreRanking cafe;

  const _FeaturedSection({required this.cafe});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '오늘의 부부픽',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: Color(0xFF390C00),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          '둘이 모두 좋게 보거나, 한 명이라도 강하게 추천한 카페',
          style: TextStyle(
            fontSize: 14,
            color: Color(0xFF661F00),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 16),
        _CafeScoreCard(
          cafe: cafe,
          score: cafe.coupleScore > 0 ? cafe.coupleScore : cafe.displayScore,
          scoreLabel: '부부픽',
        ),
      ],
    );
  }
}

class _SimpleHistorySection extends StatelessWidget {
  final List<StoreRanking> cafes;

  const _SimpleHistorySection({required this.cafes});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '최근 다녀온 카페',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: Color(0xFF390C00),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          '최근 방문 기준으로 다시 보기 좋은 카페를 남겨둡니다.',
          style: TextStyle(
            fontSize: 14,
            color: Color(0xFF661F00),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 16),
        ...cafes
            .take(3)
            .map(
              (cafe) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _CafeScoreCard(
                  cafe: cafe,
                  score: cafe.coupleScore > 0
                      ? cafe.coupleScore
                      : cafe.displayScore,
                  scoreLabel: '평균',
                ),
              ),
            ),
      ],
    );
  }
}

class _CafeScoreCard extends StatelessWidget {
  final StoreRanking cafe;
  final double score;
  final String scoreLabel;

  const _CafeScoreCard({
    required this.cafe,
    required this.score,
    required this.scoreLabel,
  });

  @override
  Widget build(BuildContext context) {
    final scoreStyle = _scoreTone(score);
    final galleryImages = _galleryImages(cafe);
    final metricPins = _metricPins(cafe);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () => context.push('/cafes/${cafe.storeId}'),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.cardBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cafe.storeName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.4,
                            height: 1.16,
                            color: Color(0xFF390C00),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              cafe.brandName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF8A6B5C),
                              ),
                            ),
                            _ScorePin(
                              icon: Icons.push_pin_rounded,
                              label: scoreLabel,
                              value: score,
                              tone: scoreStyle,
                              emphasized: true,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (galleryImages.isNotEmpty) ...[
                    const SizedBox(width: 12),
                    StackedImageGallery(
                      images: galleryImages,
                      placeholder: const _CafeThumbnailPlaceholder(),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ...metricPins.map(
                    (pin) => _ScorePin(
                      icon: Icons.local_cafe_rounded,
                      label: pin.label,
                      value: pin.value,
                      tone: _scoreTone(pin.value),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<GalleryImageItem> _galleryImages(StoreRanking cafe) {
    final thumbnailUrls = _uniqueGalleryUrls(cafe.thumbnailImageUrls);
    final viewerUrls = _uniqueGalleryUrls(cafe.imageUrls);
    final imageCount = thumbnailUrls.isNotEmpty
        ? thumbnailUrls.length
        : viewerUrls.length;

    return List.generate(imageCount.clamp(0, 2), (index) {
      final thumbnailUrl = index < thumbnailUrls.length
          ? thumbnailUrls[index]
          : viewerUrls[index];
      final viewerUrl = index < viewerUrls.length
          ? viewerUrls[index]
          : thumbnailUrl;
      return GalleryImageItem.url(thumbnailUrl, viewerUrl: viewerUrl);
    }, growable: false);
  }

  List<String> _uniqueGalleryUrls(List<String> rawUrls) {
    final urls = <String>[];
    for (final url in rawUrls) {
      final trimmed = url.trim();
      if (trimmed.isNotEmpty &&
          !trimmed.toLowerCase().endsWith('.svg') &&
          !urls.contains(trimmed)) {
        urls.add(trimmed);
      }
      if (urls.length >= 2) {
        return urls;
      }
    }
    return urls.take(2).toList(growable: false);
  }

  List<_MetricPinData> _metricPins(StoreRanking cafe) {
    return [
      if (cafe.topLabelA.trim().isNotEmpty && cafe.topScoreA > 0)
        _MetricPinData(cafe.topLabelA.trim(), cafe.topScoreA),
      if (cafe.topLabelB.trim().isNotEmpty && cafe.topScoreB > 0)
        _MetricPinData(cafe.topLabelB.trim(), cafe.topScoreB),
    ];
  }
}

class _MetricPinData {
  final String label;
  final double value;

  const _MetricPinData(this.label, this.value);
}

class _ScorePin extends StatelessWidget {
  final IconData icon;
  final String label;
  final double value;
  final _ScoreTone tone;
  final bool emphasized;

  const _ScorePin({
    required this.icon,
    required this.label,
    required this.value,
    required this.tone,
    this.emphasized = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 34),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: emphasized ? tone.backgroundColor : const Color(0xFFFFF8F3),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: emphasized
              ? tone.valueColor.withValues(alpha: 0.18)
              : const Color(0xFFF0DDD2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: emphasized ? tone.valueColor : AppColors.primary,
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: emphasized ? tone.valueColor : const Color(0xFF661F00),
            ),
          ),
          const SizedBox(width: 5),
          Text(
            value > 0 ? RatingFormatter.score(value) : '-',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: emphasized ? tone.valueColor : const Color(0xFF390C00),
            ),
          ),
        ],
      ),
    );
  }
}

class _CafeThumbnailPlaceholder extends StatelessWidget {
  const _CafeThumbnailPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Color(0xFFF4EFEA),
      child: Center(
        child: Icon(
          Icons.local_cafe_rounded,
          size: 18,
          color: Color(0xFFC28D73),
        ),
      ),
    );
  }
}

class _ScoreTone {
  final Color backgroundColor;
  final Color labelColor;
  final Color valueColor;

  const _ScoreTone({
    required this.backgroundColor,
    required this.labelColor,
    required this.valueColor,
  });
}

_ScoreTone _scoreTone(double score) {
  if (score >= 4.5) {
    return const _ScoreTone(
      backgroundColor: Color(0xFFE4F5EA),
      labelColor: Color(0xFF166534),
      valueColor: Color(0xFF166534),
    );
  }
  if (score >= 4.0) {
    return const _ScoreTone(
      backgroundColor: Color(0xFFEBF8F0),
      labelColor: Color(0xFF1E8E4D),
      valueColor: Color(0xFF1E8E4D),
    );
  }
  if (score >= 3.5) {
    return const _ScoreTone(
      backgroundColor: Color(0xFFF1FAF4),
      labelColor: Color(0xFF389A60),
      valueColor: Color(0xFF2F8E57),
    );
  }
  if (score >= 3.0) {
    return const _ScoreTone(
      backgroundColor: Color(0xFFF7FCF8),
      labelColor: Color(0xFF72B086),
      valueColor: Color(0xFF5AA16F),
    );
  }
  return const _ScoreTone(
    backgroundColor: Color(0xFFF4F5F6),
    labelColor: Color(0xFF9AA4B2),
    valueColor: Color(0xFF7E8897),
  );
}

class _EmptyCard extends StatelessWidget {
  final String title;
  final String body;

  const _EmptyCard({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: const TextStyle(
              fontSize: 14,
              height: 1.45,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
