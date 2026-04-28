import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:front/core/constants/app_colors.dart';
import 'package:front/core/constants/app_sizes.dart';
import 'package:front/domain/entities/user_preference_preset.dart';
import 'package:front/presentation/providers/ranking_providers.dart';
import 'package:front/presentation/providers/user_preference_providers.dart';
import 'package:front/presentation/widgets/store_ranking_card.dart';

class PreferenceHomePage extends ConsumerStatefulWidget {
  const PreferenceHomePage({super.key});

  @override
  ConsumerState<PreferenceHomePage> createState() => _PreferenceHomePageState();
}

class _PreferenceHomePageState extends ConsumerState<PreferenceHomePage> {
  bool _didTriggerInitialSheet = false;

  @override
  void initState() {
    super.initState();
    Future<void>(() {
      ref.read(userPreferenceControllerProvider.notifier).loadPreferences();
    });
  }

  Future<void> _openPreferenceSheet({required bool dismissible}) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      isDismissible: dismissible,
      enableDrag: dismissible,
      builder: (context) {
        return const _PreferenceSelectionSheet();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final preferenceState = ref.watch(userPreferenceControllerProvider);
    final presets = ref.watch(userPreferencePresetsProvider);
    final rankingsAsync = ref.watch(personalizedStoreRankingListProvider);

    if (!preferenceState.isLoading &&
        !preferenceState.hasCompletedInitialSelection &&
        !_didTriggerInitialSheet) {
      _didTriggerInitialSheet = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _openPreferenceSheet(dismissible: false);
      });
    }

    final selectedPresets = presets
        .where(
          (preset) => preferenceState.selectedPreferenceIds.contains(preset.id),
        )
        .toList();

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: preferenceState.isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '내 취향',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          selectedPresets.isEmpty
                              ? '취향을 고르면 나에게 맞는 카페를 먼저 보여드려요.'
                              : '선택한 기준에 맞춰 카페를 다시 정렬했어요.',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final preset in selectedPresets)
                              _SelectedPreferenceChip(label: preset.label),
                            if (selectedPresets.isEmpty)
                              const _SelectedPreferenceChip(label: '아직 선택 없음'),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            FilledButton(
                              onPressed: () =>
                                  _openPreferenceSheet(dismissible: true),
                              child: const Text('취향 수정'),
                            ),
                            const SizedBox(width: 8),
                            OutlinedButton(
                              onPressed: () {
                                ref
                                    .read(
                                      userPreferenceControllerProvider.notifier,
                                    )
                                    .clearPreferences();
                              },
                              child: const Text('초기화'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: rankingsAsync.when(
                      data: (items) {
                        if (items.isEmpty) {
                          return const Center(
                            child: Text('추천할 카페가 아직 없어요.'),
                          );
                        }
                        return ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                          itemCount: items.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 16),
                          itemBuilder: (context, index) {
                            final ranking = items[index];
                            return StoreRankingCard(
                              ranking: ranking,
                              rankIndex: index,
                              distanceKm: ranking.distanceKm,
                              onTap: () =>
                                  context.push('/ranking/store/${ranking.storeId}'),
                            );
                          },
                        );
                      },
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (error, stackTrace) => Center(
                        child: Padding(
                          padding: const EdgeInsets.all(AppSizes.screenPadding),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('취향 기반 추천을 불러오지 못했어요.'),
                              const SizedBox(height: 12),
                              FilledButton(
                                onPressed: () => ref.invalidate(
                                  personalizedStoreRankingListProvider,
                                ),
                                child: const Text('다시 시도'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _PreferenceSelectionSheet extends ConsumerWidget {
  const _PreferenceSelectionSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(userPreferenceControllerProvider);
    final presets = ref.watch(userPreferencePresetsProvider);
    final controller = ref.read(userPreferenceControllerProvider.notifier);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '어떤 카페를 찾고 있나요?',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 8),
            const Text(
              '2~3개를 고르면 취향 탭과 지도를 그 기준으로 보여드릴게요.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final preset in presets)
                  _SelectablePreferenceChip(
                    preset: preset,
                    selected: state.selectedPreferenceIds.contains(preset.id),
                    onTap: () => controller.togglePreference(preset.id),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async {
                      await controller.skipSelection();
                      if (context.mounted) Navigator.of(context).pop();
                    },
                    child: const Text('건너뛰기'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () async {
                      await controller.completeSelection();
                      if (context.mounted) Navigator.of(context).pop();
                    },
                    child: const Text('선택 완료'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectablePreferenceChip extends StatelessWidget {
  final UserPreferencePreset preset;
  final bool selected;
  final VoidCallback onTap;

  const _SelectablePreferenceChip({
    required this.preset,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 160,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFFFF4EC) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.cardBorder,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              IconData(preset.iconCodePoint, fontFamily: 'MaterialIcons'),
              color: selected ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(height: 10),
            Text(
              preset.label,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              preset.description,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectedPreferenceChip extends StatelessWidget {
  final String label;

  const _SelectedPreferenceChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
