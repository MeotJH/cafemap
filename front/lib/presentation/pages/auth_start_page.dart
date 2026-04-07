import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:front/core/constants/app_colors.dart';
import 'package:front/presentation/providers/auth_providers.dart';
import 'package:front/presentation/providers/app_providers.dart';
import 'package:go_router/go_router.dart';

// 로그인 시작 화면을 표시한다.
class AuthStartPage extends ConsumerWidget {
  const AuthStartPage({super.key});

  Future<void> _signInWithGoogle(BuildContext context, WidgetRef ref) async {
    try {
      final authController = ref.read(authControllerProvider);
      await authController.signInWithGoogle();
      final auth = await authController.getAuthContext();
      if (auth == null) {
        throw StateError('인증 컨텍스트를 가져오지 못했습니다.');
      }
      // 로그인 성공 후 사용자 정보를 동기화한다.
      await ref.read(authApiProvider).syncUser(auth);
      if (!context.mounted) return;
      context.go('/ranking');
    } on FirebaseAuthException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Google 로그인 실패: ${e.code}')));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Google 로그인 실패: $e')));
    }
  }

  @override
  // 로그인 시작 화면 UI를 렌더링한다.
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.backgroundLight, Color(0xFFF3F0EF)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    onPressed: () {
                      if (context.canPop()) {
                        context.pop();
                        return;
                      }
                      context.go('/ranking');
                    },
                    icon: const Icon(Icons.arrow_back),
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      const SizedBox(height: 28),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.45),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: const Color(0xFFD7DCE2)),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x22000000),
                              blurRadius: 14,
                              offset: Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Text(
                          '??TOP RANKING',
                          style: textTheme.labelLarge?.copyWith(
                            letterSpacing: 2,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF323C4E),
                          ),
                        ),
                      ),
                      const SizedBox(height: 42),
                      Text(
                        'CAFE',
                        style: textTheme.displayLarge?.copyWith(
                          height: 0.9,
                          fontWeight: FontWeight.w900,
                          fontStyle: FontStyle.italic,
                          color: const Color(0xFF0B1530),
                        ),
                      ),
                      Text(
                        'MAP',
                        style: textTheme.displayLarge?.copyWith(
                          height: 0.9,
                          fontWeight: FontWeight.w900,
                          fontStyle: FontStyle.italic,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'DISCOVER THE BEST CAFE IN YOUR AREA!',
                        textAlign: TextAlign.center,
                        style: textTheme.titleMedium?.copyWith(
                          color: const Color(0xFF7C8594),
                          letterSpacing: 1.4,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '로그인하고 내 주변\n카페 지도를 만들어보세요!',
                        textAlign: TextAlign.center,
                        style: textTheme.headlineSmall?.copyWith(
                          color: const Color(0xFF131D2F),
                          height: 1.35,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 34),
                      _AuthButton(
                        label: 'Google로 시작하기',
                        onPressed: () => _signInWithGoogle(context, ref),
                      ),
                      const SizedBox(height: 22),
                      TextButton(
                        onPressed: () => context.go('/ranking'),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFFB3B8C3),
                        ),
                        child: Text(
                          '鍮꾪쉶?먯쑝濡??섎윭蹂닿린',
                          style: textTheme.titleMedium?.copyWith(
                            decoration: TextDecoration.underline,
                            decorationColor: const Color(0xFFC6CBD3),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// 커스텀 로그인 버튼을 그리는 위젯이다.
class _AuthButton extends StatelessWidget {
  static const String _googleLogoSvg =
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48">'
      '<path fill="#EA4335" d="M24 9.5c3.54 0 6.71 1.22 9.21 3.6l6.85-6.85C35.9 2.38 30.47 0 24 0 14.62 0 6.51 5.38 2.56 13.22l7.98 6.19C12.43 13.72 17.74 9.5 24 9.5z"/>'
      '<path fill="#4285F4" d="M46.98 24.55c0-1.57-.15-3.09-.38-4.55H24v9.02h12.94c-.58 2.96-2.26 5.48-4.78 7.18l7.73 6c4.51-4.18 7.09-10.36 7.09-17.65z"/>'
      '<path fill="#FBBC05" d="M10.53 28.59c-.48-1.45-.76-2.99-.76-4.59s.27-3.14.76-4.59l-7.98-6.19C.92 16.46 0 20.12 0 24c0 3.88.92 7.54 2.56 10.78l7.97-6.19z"/>'
      '<path fill="#34A853" d="M24 48c6.48 0 11.93-2.13 15.89-5.81l-7.73-6c-2.15 1.45-4.92 2.3-8.16 2.3-6.26 0-11.57-4.22-13.47-9.91l-7.98 6.19C6.51 42.62 14.62 48 24 48z"/>'
      '<path fill="none" d="M0 0h48v48H0z"/>'
      '</svg>';

  final String label;
  final VoidCallback onPressed;

  const _AuthButton({
    required this.label,
    required this.onPressed,
  });

  @override
  // 커스텀 로그인 버튼 스타일을 적용한다.
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF131D2F),
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 20),
          side: const BorderSide(color: Color(0xFFE0E4E9)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.string(_googleLogoSvg, width: 24, height: 24),
            const SizedBox(width: 12),
            Text(
              label,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: const Color(0xFF131D2F),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

