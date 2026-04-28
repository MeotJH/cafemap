import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:front/app/write_cafe_review_button.dart';
import 'package:front/core/constants/app_sizes.dart';
import 'package:front/presentation/providers/auth_providers.dart';
import 'package:front/presentation/providers/review_providers.dart';
import 'package:front/presentation/widgets/review_card.dart';

class MyReviewsPage extends ConsumerWidget {
  const MyReviewsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user =
        ref.watch(authStateProvider).asData?.value ??
        ref.read(authControllerProvider).currentUser;
    final reviews = ref.watch(myReviewsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('내 리뷰')),
      body: Padding(
        padding: const EdgeInsets.all(AppSizes.screenPadding),
        child: user == null
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('내 리뷰를 보려면 로그인해주세요.'),
                    const SizedBox(height: 12),
                    WriteCafeReviewButton(
                      onPressed: () => context.push('/auth'),
                      text: '로그인하기',
                    ),
                  ],
                ),
              )
            : reviews.when(
                data: (items) => ListView.separated(
                  itemBuilder: (context, index) {
                    final review = items[index];
                    return GestureDetector(
                      onTap: () =>
                          context.push('/review/${review.id}', extra: review),
                      child: ReviewCard(review: review),
                    );
                  },
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemCount: items.length,
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) {
                  final status = error is DioException
                      ? error.response?.statusCode
                      : null;
                  if (status == 401) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('로그인이 필요합니다. 다시 로그인해주세요.'),
                          const SizedBox(height: 12),
                          WriteCafeReviewButton(
                            onPressed: () => context.push('/auth'),
                            text: '로그인하기',
                          ),
                        ],
                      ),
                    );
                  }
                  return const Center(child: Text('리뷰를 불러오지 못했어요.'));
                },
              ),
      ),
    );
  }
}
