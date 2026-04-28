import 'package:another_flushbar/flushbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:front/core/constants/app_strings.dart';
import 'package:front/presentation/providers/auth_providers.dart';
import 'package:go_router/go_router.dart';

class MainShell extends ConsumerWidget {
  final Widget child;

  const MainShell({super.key, required this.child});

  int _currentIndex(String location) {
    if (location.startsWith('/ranking')) return 1;
    if (location.startsWith('/map')) return 2;
    if (location.startsWith('/my-reviews')) return 3;
    return 0;
  }

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
        context.go('/preference');
        break;
      case 1:
        context.go('/ranking');
        break;
      case 2:
        context.go('/map');
        break;
      case 3:
        final user =
            ref.read(authStateProvider).asData?.value ??
            ref.read(authControllerProvider).currentUser;
        if (user == null) {
          await _showTopToast(context, '내 리뷰는 로그인 후에 확인할 수 있어요.');
          if (context.mounted) context.go('/auth');
          return;
        }
        context.go('/my-reviews');
        break;
    }
  }

  @override
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
            icon: Icon(Icons.tune_outlined),
            selectedIcon: Icon(Icons.tune),
            label: AppStrings.preferenceTab,
          ),
          NavigationDestination(
            icon: Icon(Icons.emoji_events_outlined),
            selectedIcon: Icon(Icons.emoji_events),
            label: AppStrings.cafeRankingTab,
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
