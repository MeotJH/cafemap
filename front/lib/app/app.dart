import 'package:flutter/material.dart';
import 'package:front/app/router.dart';
import 'package:front/app/theme/app_theme.dart';
import 'package:front/core/constants/app_strings.dart';

// 앱 전체를 감싸는 루트 위젯이다.
class CafeMapApp extends StatelessWidget {
  const CafeMapApp({super.key});

  @override
  // 앱의 라우터와 테마를 연결해 화면을 구성한다.
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: AppStrings.appName,
      theme: AppTheme.light,
      routerConfig: appRouter,
    );
  }
}

