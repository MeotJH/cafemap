import 'package:front/domain/entities/brand_menu_ranking.dart';
import 'package:front/domain/entities/rating_breakdown.dart';
import 'package:front/domain/entities/review.dart';
import 'package:front/domain/entities/store_ranking.dart';
import 'package:front/domain/entities/store_summary.dart';

// 데모 화면을 위한 목업 데이터를 제공한다.
class MockDataSource {
  List<StoreRanking> storeRankings() => const [
    StoreRanking(
      id: 'store-1',
      storeId: 'store-1',
      storeName: '로컬 브루어스',
      brandName: '개인 카페',
      isLocal: true,
      rating: 4.7,
      displayScore: 4.35,
      reviewCount: 18,
      distanceKm: 0.6,
      imageUrl: '',
      lat: 37.6132,
      lng: 127.0945,
      topLabelA: '원두 품질',
      topScoreA: 4.8,
      topLabelB: '분위기',
      topScoreB: 4.6,
    ),
    StoreRanking(
      id: 'store-2',
      storeId: 'store-2',
      storeName: '스타벅스 시청점',
      brandName: '스타벅스',
      isLocal: false,
      rating: 4.4,
      displayScore: 4.22,
      reviewCount: 42,
      distanceKm: 0.8,
      imageUrl: '',
      lat: 37.5663,
      lng: 126.9779,
      topLabelA: '온도 만족도',
      topScoreA: 4.6,
      topLabelB: '가성비',
      topScoreB: 4.2,
    ),
  ];

  // 랭킹 화면에 사용할 목업 리스트를 제공한다.
  List<BrandMenuRanking> rankings() => const [
    BrandMenuRanking(
      id: 'rank-1',
      brandId: 'brand-bbq',
      menuId: 'menu-bbq-hwanggeum-olive-fried',
      brandName: 'BBQ',
      menuName: '황금올리브카페',
      category: '후라이드',
      rating: 4.9,
      reviewCount: 2482,
      highlightScoreA: 4.9,
      highlightLabelA: '바삭함',
      highlightScoreB: 4.7,
      highlightLabelB: '육즙',
      imageUrl:
          'https://static.bbqorder.co.kr/menu/be246fc85975bcc13819c8184_ffa589a9-da4b-42dd-a04d-91dcfca7b74e.png',
      brandLogoUrl:
          'https://lh3.googleusercontent.com/aida-public/AB6AXuBm0bsKt3eeVGTfif4RUC_jbzMu3Q1sSDJQR_6HGfBPCmr0tm7C2x5pnZofeHeH8-BLGs5vpsvj9AbK4ly09yPDhCHAb5_bN4gvIYrbSFoKOxZSxjnB2-8DbNy_Xa6NK0FyMLwrE11wnQR1MwUePJvyIYvAYs08QfkiFCDJB4TJxB8DtL9ipETT73Nz81Xq7HlfIRsVZTb0kC-ZKxqr__93UfbFOnaXS9RBOdtssynznB4EqP7-b59OpCHyLoPBfoL-VMv3GqvZ3s4g',
    ),
    BrandMenuRanking(
      id: 'rank-2',
      brandId: 'brand-bhc',
      menuId: 'menu-bhc-bburinkle',
      brandName: 'BHC',
      menuName: '뿌링클',
      category: '양념',
      rating: 4.8,
      reviewCount: 1905,
      highlightScoreA: 4.8,
      highlightLabelA: '매직파우더',
      highlightScoreB: 4.9,
      highlightLabelB: '풍미',
      imageUrl:
          'https://lh3.googleusercontent.com/aida-public/AB6AXuCtS7WTy2RwhOpC0qrl1BeoOUrMj9rgj5H39CzVFDi8ldRRx7Gc26KTYB6WlEEZk3YIS96CHYZdRMAlbhU772u-maFdVSYkPx-fpPrfV0p0Mes0P4kZxqWUc57XhQWqbRHStJsH_jIiwdISti6wCm4PEha1qi3yK5ZsaTsua8wYsb7g1N8N13DFKv-ToeSwljfwyvq1sl5M6jNf9qDu6BSevE-QzGImEoHItshw6N22ROC5tO5xJqpnz_Ax99gYGyj2X6eBFYR8BgaQ',
      brandLogoUrl:
          'https://lh3.googleusercontent.com/aida-public/AB6AXuB--TzmdRa1Qk4TLud9vdw3ttfoNDA9jvmqrRpZXMl-M0mBqUfhmK6oBUSJpnCTtUPXv7WZ2BdqhbKOiygM8XLK3yrh-Z4uSEs_32zrUiY5HiEJkV3gjrqnP4YC7PW-27BnB04EDputzwhqqZNU-DySujvbVtNEWIYiCStiqqrHAiA8PPGCO7oVlXcoWouI8GZKZxAwcKO-MkM2mtWE30IlddqmQPZ4lsrodTZns7v2g7DhxtYJtJXkb9mqdseRu_8bgJtm1GGsShUr',
    ),
    BrandMenuRanking(
      id: 'rank-3',
      brandId: 'brand-kyochon',
      menuId: 'menu-kyochon-honey',
      brandName: '교촌',
      menuName: '허니콤보',
      category: '양념',
      rating: 4.7,
      reviewCount: 3120,
      highlightScoreA: 4.6,
      highlightLabelA: '바삭함',
      highlightScoreB: 4.8,
      highlightLabelB: '단맛',
      imageUrl:
          'https://lh3.googleusercontent.com/aida-public/AB6AXuDEPxO9awoBLaA-mkeylM1DNgb8uzGHvEG4WSp8oPjNji9BLGPkwQt6s50f2wEP8bZCQ72jMQXAnUjx5sUTwbZHjMOeGvZJH62PKbMqy-CcWoJL7cWa_iUPxWxkYtOEstWgOlJIYdVNQ2ZmHdnsUaUKN7h10m3nwskKNHLODohET5TtivzS7jy9wXjktAIED7bqRn5OOEu3mQ9hfskS8t6v1OSXzXqAbufeOyhCGZiU9kPoFBpbd0ARibN4HLaKwpU1kyUx2OaSqUuT',
      brandLogoUrl:
          'https://lh3.googleusercontent.com/aida-public/AB6AXuBUSMKs4gekdXjZzAzJqvZ9uyDG474nIQ2TK--TwGGWuig7P8a9nCjsX7BIDQaDkwrxlBjjxqpWMqGI8Dy83umlmAjIfAJMGc-TqN0Qx_st--DtzKGlukUYJKInbIpBOHLyAIZ79Ag8LFUbuEjeVP3aD51E8R0_VPDfRBDZpJ6lNUwWacrcpFAzjlQ-g-wUv_v3XbOwj7R7wGcTNyexV0Wmeri6Bjq_xzX1GffPjNc7EcSe2nfS9POGiA8lXkNQH3O78Cpj_u9Qrucq',
    ),
  ];

  // 지도 화면에 사용할 지점 목록을 제공한다.
  List<StoreSummary> stores() => const [
    StoreSummary(
      id: 'store-1',
      name: 'BBQ 신내동점',
      brandName: 'BBQ',
      isLocal: false,
      address: '서울 중랑구 신내로 12',
      rating: 4.5,
      reviewCount: 1240,
      distanceKm: 0.8,
      imageUrl:
          'https://lh3.googleusercontent.com/aida-public/AB6AXuA5cmmZoBqb8t3ZO7yn4tDph7Afg4aSTZqWCKgESnccgHJhx669Lnk9VuZBkhdZhGHM8h3QY--WdR9sSvO_Nk_o_SJTXx4o-3NZ-87FXmUmm2Hz5H2za-WdMFy8zc0sd5Brw6TNJ6g-tYzVvJ23qY4SPkDNlLO0A3J0CcCke6XgFk13uwdtzMiceUHTtgX2u2UOj6evZAG6hE_3PlvvRzyygYT9T2-XUeXuWnrRtIV3hQRb_7uSLpr74PU_-cOtzLgDmv4AHqYm3iNo',
      lat: 37.6132,
      lng: 127.0945,
    ),
    StoreSummary(
      id: 'store-2',
      name: '교촌 중화점',
      brandName: '교촌',
      isLocal: false,
      address: '서울 중랑구 중화로 101',
      rating: 4.2,
      reviewCount: 840,
      distanceKm: 1.2,
      imageUrl:
          'https://lh3.googleusercontent.com/aida-public/AB6AXuB1gg2lNpk4P7ztq-ka6X63NEEtvJmYnisFYu9Chi7uGAEtBHrhicZNgQME0s7RcWguaLLOjfYPWlEESrNqNyiSsVyDOtOwak6rYPgQdrWBcCxP45gk7tfsihBQbVTVDrnaCGzHcXzNoMDV1maltUSgsNZWwoOXfUDQAAH3kG7rISf0U6CFaDqm0QoXQJyKSnom-Fl-XuFdM5eQ94Cwil3eKr3FP6p1yGeckGWzASHTCpIqH8hZrYGskobqoFkW5-QIe_9esjn4i1AP',
      lat: 37.5978,
      lng: 127.0785,
    ),
    StoreSummary(
      id: 'store-3',
      name: 'BHC 망우점',
      brandName: 'BHC',
      isLocal: false,
      address: '서울 중랑구 망우로 45',
      rating: 3.9,
      reviewCount: 560,
      distanceKm: 1.9,
      imageUrl:
          'https://lh3.googleusercontent.com/aida-public/AB6AXuAow-nYLE0k-RrRFeq2b1rj8dHJ3kHorivP0rCLZMDNgGVfJn62iJzDncCQrngIOc8SuS1392d_Gx1PUEs2FwnnHzN94pG_EbS-uJSjN5UaiE8floBee14ubSYSBOUhRL0xcvavuDIgSz0rL2OKnB5wE4rHLxuyRwtN10LQL9OESLRr5SPGG9Z7H5_juqHUoXmAYawK_ZU8w4I7QGt7c-3WWuataX0Z8aRQHBygVlbEuS7pbROAJzy3jUU6NwjeiCLwXVyw3iV2FMXm',
      lat: 37.5992,
      lng: 127.0924,
    ),
  ];

  // 랭킹 상세 화면의 점수 분해 데이터를 제공한다.
  RatingBreakdown rankingBreakdown() => const RatingBreakdown(
    scores: {
      'crispy': 4.7,
      'juicy': 4.6,
      'salty': 4.2,
      'oil': 4.4,
      'coffee_quality': 4.8,
      'fry_quality': 4.7,
      'portion': 4.3,
    },
    overall: 4.8,
  );

  // 지점 상세 화면의 점수 분해 데이터를 제공한다.
  RatingBreakdown storeBreakdown() => const RatingBreakdown(
    scores: {
      'crispy': 4.4,
      'juicy': 4.3,
      'salty': 4.1,
      'oil': 4.2,
      'coffee_quality': 4.5,
      'fry_quality': 4.4,
      'portion': 4.0,
    },
    overall: 4.5,
  );

  // 리뷰 리스트를 제공한다.
  List<Review> reviews() => [
    Review(
      id: 'review-1',
      storeName: 'BBQ 신내동점',
      brandName: 'BBQ',
      menuName: '황금올리브카페',
      menuCategory: '후라이드',
      userEmail: 'marionette934@gmail.com',
      scores: {
        'crispy': 4.7,
        'juicy': 4.6,
        'salty': 4.2,
        'oil': 4.4,
        'coffee_quality': 4.8,
        'fry_quality': 4.7,
        'portion': 4.3,
      },
      overall: 4.6,
      comment: '바삭함이 오래가고 기름 냄새가 덜했어요.',
      imageUrls: const [],
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
    Review(
      id: 'review-2',
      storeName: 'BBQ 신내동점',
      brandName: 'BBQ',
      menuName: '자메이카 통다리',
      menuCategory: '구이',
      userEmail: 'businesskim93@gmail.com',
      scores: {
        'smoky': 4.1,
        'juicy': 4.0,
        'seasoning_balance': 3.9,
        'skin_texture': 4.0,
        'grill_quality': 4.2,
        'coffee_quality': 4.1,
        'portion': 4.0,
      },
      overall: 4.2,
      comment: '양은 좋았는데 살짝 짭짤했어요.',
      imageUrls: const [],
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
    ),
  ];
}
