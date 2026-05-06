class StoreRanking {
  final String id;
  final String storeId;
  final String storeName;
  final String brandName;
  final String storeType;
  final bool isLocal;
  final String link;
  final double rating;
  final double displayScore;
  final int reviewCount;
  final double distanceKm;
  final String imageUrl;
  final double lat;
  final double lng;
  final double coffeeQualityScore;
  final String topLabelA;
  final double topScoreA;
  final String topLabelB;
  final double topScoreB;
  final double workFriendlyScore;
  final double quietnessScore;
  final double dessertScore;
  final double coupleScore;
  final double wifeScore;
  final double husbandScore;
  final double userScore;
  final double revisitScore;
  final String summary;
  final List<String> tags;
  final DateTime? latestVisitedAt;

  const StoreRanking({
    required this.id,
    required this.storeId,
    required this.storeName,
    required this.brandName,
    required this.storeType,
    required this.isLocal,
    required this.link,
    required this.rating,
    required this.displayScore,
    required this.reviewCount,
    required this.distanceKm,
    required this.imageUrl,
    required this.lat,
    required this.lng,
    required this.coffeeQualityScore,
    required this.topLabelA,
    required this.topScoreA,
    required this.topLabelB,
    required this.topScoreB,
    required this.workFriendlyScore,
    required this.quietnessScore,
    required this.dessertScore,
    required this.coupleScore,
    required this.wifeScore,
    required this.husbandScore,
    required this.userScore,
    required this.revisitScore,
    required this.summary,
    required this.tags,
    required this.latestVisitedAt,
  });
}

class HomeRecommendedMenu {
  final String menuName;
  final String storeName;
  final double score;

  const HomeRecommendedMenu({
    required this.menuName,
    required this.storeName,
    required this.score,
  });
}

class HomeSummary {
  final StoreRanking? featuredCafe;
  final List<StoreRanking> wifeTop;
  final List<StoreRanking> husbandTop;
  final List<StoreRanking> recentCafes;
  final List<HomeRecommendedMenu> recommendedMenus;

  const HomeSummary({
    required this.featuredCafe,
    required this.wifeTop,
    required this.husbandTop,
    required this.recentCafes,
    required this.recommendedMenus,
  });
}
