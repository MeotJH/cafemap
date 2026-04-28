import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:front/presentation/pages/auth_start_page.dart';
import 'package:front/presentation/pages/main_shell.dart';
import 'package:front/presentation/pages/map_home_page.dart';
import 'package:front/presentation/pages/my_reviews_page.dart';
import 'package:front/presentation/pages/preference_home_page.dart';
import 'package:front/presentation/pages/ranking_home_page.dart';
import 'package:front/presentation/pages/review_detail_page.dart';
import 'package:front/presentation/pages/review_write_page.dart';
import 'package:front/presentation/pages/store_select_page.dart';
import 'package:front/presentation/pages/store_detail_page.dart';
import 'package:front/domain/entities/review.dart';
import 'package:go_router/go_router.dart';

// 앱 내 라우팅 규칙을 정의한다.
final GoRouter appRouter = GoRouter(
  initialLocation: '/preference',
  routes: <RouteBase>[
    GoRoute(
      path: '/auth',
      builder: (BuildContext context, GoRouterState state) {
        return const AuthStartPage();
      },
    ),
    ShellRoute(
      builder: (BuildContext context, GoRouterState state, Widget child) {
        return MainShell(child: child);
      },
      routes: <RouteBase>[
        GoRoute(
          path: '/preference',
          builder: (BuildContext context, GoRouterState state) {
            return const PreferenceHomePage();
          },
        ),
        GoRoute(
          path: '/ranking',
          builder: (BuildContext context, GoRouterState state) {
            return const RankingHomePage();
          },
          routes: <RouteBase>[
            GoRoute(
              path: 'store/:id',
              builder: (BuildContext context, GoRouterState state) {
                final id = state.pathParameters['id'] ?? '';
                return StoreDetailPage(storeId: id);
              },
            ),
          ],
        ),
        GoRoute(
          path: '/map',
          builder: (BuildContext context, GoRouterState state) {
            return const MapHomePage();
          },
          routes: <RouteBase>[
            GoRoute(
              path: 'store/:id',
              builder: (BuildContext context, GoRouterState state) {
                final id = state.pathParameters['id'] ?? '';
                return StoreDetailPage(storeId: id);
              },
            ),
          ],
        ),
        GoRoute(
          path: '/my-reviews',
          builder: (BuildContext context, GoRouterState state) {
            return const MyReviewsPage();
          },
        ),
      ],
    ),
    GoRoute(
      path: '/review/write',
      redirect: (BuildContext context, GoRouterState state) {
        if (FirebaseAuth.instance.currentUser == null) {
          return '/auth';
        }
        return null;
      },
      builder: (BuildContext context, GoRouterState state) {
        final params = state.uri.queryParameters;
        return ReviewWritePage(
          storeName: params['storeName'],
          address: params['address'],
          placeId: params['placeId'],
          lat: double.tryParse(params['lat'] ?? ''),
          lng: double.tryParse(params['lng'] ?? ''),
          menuName: params['menuName'],
          brandId: params['brandId'],
          brandName: params['brandName'],
        );
      },
    ),
    GoRoute(
      path: '/review/select-store',
      redirect: (BuildContext context, GoRouterState state) {
        if (FirebaseAuth.instance.currentUser == null) {
          return '/auth';
        }
        return null;
      },
      builder: (BuildContext context, GoRouterState state) {
        final params = state.uri.queryParameters;
        return StoreSelectPage(
          brandId: params['brandId'] ?? '',
          menuName: params['menuName'] ?? '',
          brandName: params['brandName'] ?? '',
        );
      },
    ),
    GoRoute(
      path: '/review/:id',
      builder: (BuildContext context, GoRouterState state) {
        final reviewId = state.pathParameters['id'] ?? '';
        final extra = state.extra;
        return ReviewDetailPage(
          reviewId: reviewId,
          initialReview: extra is Review ? extra : null,
        );
      },
    ),
  ],
);
