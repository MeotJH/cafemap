import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:front/data/local/user_preference_storage.dart';
import 'package:front/domain/entities/user_preference_preset.dart';

class UserPreferenceState {
  final List<String> selectedPreferenceIds;
  final bool hasCompletedInitialSelection;
  final bool isLoading;

  const UserPreferenceState({
    required this.selectedPreferenceIds,
    required this.hasCompletedInitialSelection,
    required this.isLoading,
  });

  factory UserPreferenceState.initial() {
    return const UserPreferenceState(
      selectedPreferenceIds: [],
      hasCompletedInitialSelection: false,
      isLoading: true,
    );
  }

  UserPreferenceState copyWith({
    List<String>? selectedPreferenceIds,
    bool? hasCompletedInitialSelection,
    bool? isLoading,
  }) {
    return UserPreferenceState(
      selectedPreferenceIds:
          selectedPreferenceIds ?? this.selectedPreferenceIds,
      hasCompletedInitialSelection:
          hasCompletedInitialSelection ?? this.hasCompletedInitialSelection,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class UserPreferenceController extends Notifier<UserPreferenceState> {
  static const int maxSelectionCount = 3;

  @override
  UserPreferenceState build() {
    return UserPreferenceState.initial();
  }

  Future<void> loadPreferences() async {
    final storage = ref.read(userPreferenceStorageProvider);
    final selection = await storage.load();
    final validIds = _sanitizeIds(selection.selectedPreferenceIds);
    state = state.copyWith(
      selectedPreferenceIds: validIds,
      hasCompletedInitialSelection: selection.hasCompletedInitialSelection,
      isLoading: false,
    );
  }

  void togglePreference(String id) {
    final current = state.selectedPreferenceIds.toList(growable: true);
    if (current.contains(id)) {
      current.remove(id);
      state = state.copyWith(selectedPreferenceIds: current);
      return;
    }
    if (current.length >= maxSelectionCount) return;
    current.add(id);
    state = state.copyWith(selectedPreferenceIds: current);
  }

  Future<void> completeSelection() async {
    await _save(hasCompletedInitialSelection: true);
  }

  Future<void> skipSelection() async {
    state = state.copyWith(selectedPreferenceIds: const []);
    await _save(hasCompletedInitialSelection: true);
  }

  Future<void> clearPreferences() async {
    state = state.copyWith(
      selectedPreferenceIds: const [],
      hasCompletedInitialSelection: true,
    );
    await _save(hasCompletedInitialSelection: true);
  }

  Future<void> _save({required bool hasCompletedInitialSelection}) async {
    final storage = ref.read(userPreferenceStorageProvider);
    final selection = UserPreferenceSelection(
      selectedPreferenceIds: state.selectedPreferenceIds,
      hasCompletedInitialSelection: hasCompletedInitialSelection,
      updatedAt: DateTime.now(),
    );
    await storage.save(selection);
    state = state.copyWith(hasCompletedInitialSelection: hasCompletedInitialSelection);
  }

  List<String> _sanitizeIds(List<String> ids) {
    final allowed = ref.read(userPreferencePresetsProvider).map((e) => e.id).toSet();
    final sanitized = <String>[];
    for (final id in ids) {
      if (!allowed.contains(id) || sanitized.contains(id)) continue;
      sanitized.add(id);
      if (sanitized.length >= maxSelectionCount) break;
    }
    return sanitized;
  }
}

final userPreferenceStorageProvider = Provider<UserPreferenceStorage>((ref) {
  return const UserPreferenceStorage();
});

final userPreferencePresetsProvider = Provider<List<UserPreferencePreset>>((ref) {
  return defaultUserPreferencePresets.where((preset) => preset.enabled).toList();
});

final userPreferenceControllerProvider =
    NotifierProvider<UserPreferenceController, UserPreferenceState>(
  UserPreferenceController.new,
);

final selectedPreferenceIdsProvider = Provider<List<String>>((ref) {
  return ref.watch(userPreferenceControllerProvider).selectedPreferenceIds;
});
