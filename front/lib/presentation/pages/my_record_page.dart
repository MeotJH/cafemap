import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:front/app/write_cafe_review_button.dart';
import 'package:front/core/constants/app_sizes.dart';
import 'package:front/presentation/providers/auth_providers.dart';
import 'package:front/presentation/providers/review_providers.dart';
import 'package:front/presentation/widgets/review_card.dart';

class MyRecordPage extends ConsumerWidget {
  const MyRecordPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user =
        ref.watch(authStateProvider).asData?.value ??
        ref.read(authControllerProvider).currentUser;
    final reviews = ref.watch(myReviewsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('내기록')),
      body: Padding(
        padding: const EdgeInsets.all(AppSizes.screenPadding),
        child: user == null
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('내기록을 보려면 로그인해주세요'),
                    const SizedBox(height: 12),
                    WriteCafeReviewButton(
                      onPressed: () => context.push('/auth'),
                      text: '로그인하기',
                    ),
                  ],
                ),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF6F0E8),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '내가 평가한 카페',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          '저장한 카페와 설정은 다음 단계에서 확장합니다.',
                          style: TextStyle(color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: reviews.when(
                      data: (items) => items.isEmpty
                          ? const Center(child: Text('아직 기록한 리뷰가 없습니다.'))
                          : ListView.separated(
                              itemBuilder: (context, index) {
                                final review = items[index];
                                return GestureDetector(
                                  onTap: () => context.push(
                                    '/review/${review.id}',
                                    extra: review,
                                  ),
                                  child: ReviewCard(review: review),
                                );
                              },
                              separatorBuilder: (_, _) =>
                                  const SizedBox(height: 12),
                              itemCount: items.length,
                            ),
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (error, _) {
                        final status = error is DioException
                            ? error.response?.statusCode
                            : null;
                        if (status == 401) {
                          return Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text('로그인이 필요합니다. 다시 로그인해주세요'),
                                const SizedBox(height: 12),
                                WriteCafeReviewButton(
                                  onPressed: () => context.push('/auth'),
                                  text: '로그인하기',
                                ),
                              ],
                            ),
                          );
                        }
                        return const Center(child: Text('기록을 불러오는데 실패했습니다.'));
                      },
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
