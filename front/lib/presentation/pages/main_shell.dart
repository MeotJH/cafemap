import 'package:another_flushbar/flushbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:front/core/constants/app_strings.dart';
import 'package:front/presentation/providers/auth_providers.dart';
import 'package:go_router/go_router.dart';

// 하단 탭을 공통으로 제공하는 셸 위젯이다.
class MainShell extends ConsumerWidget {
  final Widget child;

  const MainShell({
    super.key,
    required this.child,
  });

  // 현재 라우트 위치로 탭 인덱스를 계산한다.
  int _currentIndex(String location) {
    if (location.startsWith('/map')) return 1;
    if (location.startsWith('/activity')) return 2;
    return 0;
  }

  // 탭 선택에 따라 라우트를 이동한다.
  Future<void> _showTopToast(BuildContext context, String message) {
    return Flushbar<void>(
      message: message,
      duration: const Duration(seconds: 2),
      flushbarPosition: FlushbarPosition.TOP,
      backgroundColor: const Color(0xFF2A2A2A),
      margin: const EdgeInsets.all(12),
      borderRadius: BorderRadius.circular(10),
      icon: const Icon(Icons.info_outline, color: Colors.white),
    ).show(context);
  }

  Future<void> _onTap(BuildContext context, WidgetRef ref, int index) async {
    switch (index) {
      case 0:
        context.go('/ranking');
        break;
      case 1:
        context.go('/map');
        break;
      case 2:
        final user = ref.read(authStateProvider).asData?.value ??
            ref.read(authControllerProvider).currentUser;
        if (user == null) {
          await _showTopToast(context, '내 활동은 로그인 후 확인할 수 있어요.');
          if (context.mounted) context.go('/auth');
          return;
        }
        context.go('/activity');
        break;
    }
  }

  @override
  // 하단 탭과 자식 화면을 함께 구성한다.
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).matchedLocation;
    final currentIndex = _currentIndex(location);

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) => _onTap(context, ref, index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.emoji_events_outlined),
            selectedIcon: Icon(Icons.emoji_events),
            label: AppStrings.rankingTab,
          ),
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map),
            label: AppStrings.mapTab,
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: AppStrings.activityTab,
          ),
        ],
      ),
    );
  }
}
