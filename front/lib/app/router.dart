import 'package:flutter/material.dart';
import 'package:front/presentation/pages/auth_start_page.dart';
import 'package:front/presentation/pages/main_shell.dart';
import 'package:front/presentation/pages/map_home_page.dart';
import 'package:front/presentation/pages/my_activity_page.dart';
import 'package:front/presentation/pages/ranking_detail_page.dart';
import 'package:front/presentation/pages/ranking_home_page.dart';
import 'package:front/presentation/pages/review_detail_page.dart';
import 'package:front/presentation/pages/review_write_page.dart';
import 'package:front/presentation/pages/store_select_page.dart';
import 'package:front/presentation/pages/store_detail_page.dart';
import 'package:front/domain/entities/review.dart';
import 'package:front/domain/entities/brand_menu_ranking.dart';
import 'package:go_router/go_router.dart';

// 앱 내 라우팅 규칙을 정의한다.
final GoRouter appRouter = GoRouter(
  initialLocation: '/ranking',
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
          path: '/ranking',
          builder: (BuildContext context, GoRouterState state) {
            return const RankingHomePage();
          },
          routes: <RouteBase>[
            GoRoute(
              path: ':id',
              builder: (BuildContext context, GoRouterState state) {
                final id = state.pathParameters['id'] ?? '';
                final extra = state.extra;
                return RankingDetailPage(
                  rankingId: id,
                  ranking: extra is BrandMenuRanking ? extra : null,
                );
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
          path: '/activity',
          builder: (BuildContext context, GoRouterState state) {
            return const MyActivityPage();
          },
        ),
      ],
    ),
    GoRoute(
      path: '/review/write',
      builder: (BuildContext context, GoRouterState state) {
        final params = state.uri.queryParameters;
        return ReviewWritePage(
          storeName: params['storeName'],
          address: params['address'],
          menuName: params['menuName'],
          brandId: params['brandId'],
          brandName: params['brandName'],
        );
      },
    ),
    GoRoute(
      path: '/review/select-store',
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
