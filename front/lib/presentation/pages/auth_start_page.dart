import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:front/core/constants/app_colors.dart';
import 'package:front/core/constants/app_strings.dart';
import 'package:front/core/services/analytics_service.dart';
import 'package:front/presentation/providers/auth_providers.dart';
import 'package:front/presentation/providers/app_providers.dart';
import 'package:go_router/go_router.dart';

// 로그인 시작 화면을 표시한다.
class AuthStartPage extends ConsumerWidget {
  const AuthStartPage({super.key});

  Future<void> _signInWithGoogle(BuildContext context, WidgetRef ref) async {
    try {
      analyticsService.trackEvent('login_start', {'provider': 'google'});
      final authController = ref.read(authControllerProvider);
      await authController.signInWithGoogle();
      await _syncSignedInUser(ref, authController);
      analyticsService.trackEvent('login_success', {'provider': 'google'});
      if (!context.mounted) return;
      context.go('/rankings');
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

  Future<void> _signInWithKakao(BuildContext context, WidgetRef ref) async {
    try {
      analyticsService.trackEvent('login_start', {'provider': 'kakao'});
      final authController = ref.read(authControllerProvider);
      await authController.signInWithKakao();
      await _syncSignedInUser(ref, authController);
      analyticsService.trackEvent('login_success', {'provider': 'kakao'});
      if (!context.mounted) return;
      context.go('/rankings');
    } on FirebaseAuthException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('카카오 로그인 실패: ${e.code}')));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('카카오 로그인 실패: $e')));
    }
  }

  Future<void> _syncSignedInUser(
    WidgetRef ref,
    AuthController authController,
  ) async {
    final auth = await authController.getAuthContext();
    if (auth == null) {
      throw StateError('인증 컨텍스트를 가져오지 못했습니다.');
    }
    // 로그인 성공 후 사용자 정보를 동기화한다.
    await ref.read(authApiProvider).syncUser(auth);
  }

  @override
  // 로그인 시작 화면 UI를 렌더링한다.
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final showKakaoLogin = ref.watch(kakaoLoginEnabledProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: IconButton.filledTonal(
                          onPressed: () {
                            if (context.canPop()) {
                              context.pop();
                              return;
                            }
                            context.go('/rankings');
                          },
                          icon: const Icon(Icons.arrow_back),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.white.withValues(
                              alpha: 0.8,
                            ),
                            foregroundColor: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 36),
                      Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 420),
                          child: Column(
                            children: [
                              const _AuthBrandMark(),
                              const SizedBox(height: 28),
                              Text(
                                AppStrings.appName,
                                textAlign: TextAlign.center,
                                style: textTheme.displaySmall?.copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -1.2,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                '내 취향에 맞는 카페와 메뉴를\n가볍게 탐색해보세요.',
                                textAlign: TextAlign.center,
                                style: textTheme.titleMedium?.copyWith(
                                  color: AppColors.textSecondary,
                                  height: 1.45,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 28),
                              const Wrap(
                                alignment: WrapAlignment.center,
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  _FeaturePill(label: '랭킹', route: '/rankings'),
                                  _FeaturePill(label: '홈', route: '/'),
                                  _FeaturePill(label: '지도 탐색', route: '/map'),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const Spacer(),
                      Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 420),
                          child: Column(
                            children: [
                              const SizedBox(height: 40),
                              _AuthButton(
                                label: 'Google로 계속하기',
                                icon: SvgPicture.string(
                                  _AuthButton.googleLogoSvg,
                                  width: 24,
                                  height: 24,
                                ),
                                onPressed: () =>
                                    _signInWithGoogle(context, ref),
                              ),
                              if (showKakaoLogin) ...[
                                const SizedBox(height: 12),
                                _AuthButton(
                                  label: '카카오로 계속하기',
                                  backgroundColor: const Color(0xFFFEE500),
                                  foregroundColor: const Color(0xFF191919),
                                  icon: const Icon(
                                    Icons.chat_bubble_rounded,
                                    size: 22,
                                    color: Color(0xFF191919),
                                  ),
                                  onPressed: () =>
                                      _signInWithKakao(context, ref),
                                ),
                              ],
                              const SizedBox(height: 14),
                              TextButton(
                                onPressed: () => context.go('/'),
                                style: TextButton.styleFrom(
                                  foregroundColor: AppColors.textSecondary,
                                  minimumSize: const Size.fromHeight(48),
                                ),
                                child: Text(
                                  '로그인 없이 둘러보기',
                                  style: textTheme.bodyLarge?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _AuthBrandMark extends StatelessWidget {
  const _AuthBrandMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.12),
            blurRadius: 32,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: const Icon(
        Icons.local_cafe_rounded,
        color: AppColors.primary,
        size: 46,
      ),
    );
  }
}

class _FeaturePill extends StatelessWidget {
  final String label;
  final String route;

  const _FeaturePill({required this.label, required this.route});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.72),
      shape: StadiumBorder(side: BorderSide(color: AppColors.cardBorder)),
      child: InkWell(
        onTap: () => context.go(route),
        customBorder: const StadiumBorder(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

// 커스텀 로그인 버튼을 그리는 위젯이다.
class _AuthButton extends StatelessWidget {
  static const String googleLogoSvg =
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48">'
      '<path fill="#EA4335" d="M24 9.5c3.54 0 6.71 1.22 9.21 3.6l6.85-6.85C35.9 2.38 30.47 0 24 0 14.62 0 6.51 5.38 2.56 13.22l7.98 6.19C12.43 13.72 17.74 9.5 24 9.5z"/>'
      '<path fill="#4285F4" d="M46.98 24.55c0-1.57-.15-3.09-.38-4.55H24v9.02h12.94c-.58 2.96-2.26 5.48-4.78 7.18l7.73 6c4.51-4.18 7.09-10.36 7.09-17.65z"/>'
      '<path fill="#FBBC05" d="M10.53 28.59c-.48-1.45-.76-2.99-.76-4.59s.27-3.14.76-4.59l-7.98-6.19C.92 16.46 0 20.12 0 24c0 3.88.92 7.54 2.56 10.78l7.97-6.19z"/>'
      '<path fill="#34A853" d="M24 48c6.48 0 11.93-2.13 15.89-5.81l-7.73-6c-2.15 1.45-4.92 2.3-8.16 2.3-6.26 0-11.57-4.22-13.47-9.91l-7.98 6.19C6.51 42.62 14.62 48 24 48z"/>'
      '<path fill="none" d="M0 0h48v48H0z"/>'
      '</svg>';

  final String label;
  final Widget icon;
  final VoidCallback onPressed;
  final Color backgroundColor;
  final Color foregroundColor;

  const _AuthButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.backgroundColor = Colors.white,
    this.foregroundColor = AppColors.textPrimary,
  });

  @override
  // 커스텀 로그인 버튼 스타일을 적용한다.
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          elevation: 2,
          shadowColor: AppColors.primary.withValues(alpha: 0.14),
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
          side: const BorderSide(color: AppColors.cardBorder),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          minimumSize: const Size.fromHeight(58),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon,
            const SizedBox(width: 12),
            Text(
              label,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: foregroundColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
