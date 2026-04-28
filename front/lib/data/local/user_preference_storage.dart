import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class UserPreferenceSelection {
  final List<String> selectedPreferenceIds;
  final bool hasCompletedInitialSelection;
  final DateTime updatedAt;

  const UserPreferenceSelection({
    required this.selectedPreferenceIds,
    required this.hasCompletedInitialSelection,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
    'selectedPreferenceIds': selectedPreferenceIds,
    'hasCompletedInitialSelection': hasCompletedInitialSelection,
    'updatedAt': updatedAt.toIso8601String(),
  };

  static UserPreferenceSelection empty() {
    return UserPreferenceSelection(
      selectedPreferenceIds: const [],
      hasCompletedInitialSelection: false,
      updatedAt: DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  static UserPreferenceSelection? fromJson(Map<String, dynamic> json) {
    final rawIds = json['selectedPreferenceIds'];
    final ids = rawIds is List
        ? rawIds.whereType<String>().toList()
        : const <String>[];
    final updatedAt = DateTime.tryParse(json['updatedAt'] as String? ?? '');
    if (updatedAt == null) return null;
    return UserPreferenceSelection(
      selectedPreferenceIds: ids,
      hasCompletedInitialSelection:
          json['hasCompletedInitialSelection'] as bool? ?? false,
      updatedAt: updatedAt,
    );
  }
}

class UserPreferenceStorage {
  static const String _storageKey = 'user_preference_selection_v1';

  const UserPreferenceStorage();

  Future<UserPreferenceSelection> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) {
      return UserPreferenceSelection.empty();
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        return UserPreferenceSelection.empty();
      }
      return UserPreferenceSelection.fromJson(decoded) ??
          UserPreferenceSelection.empty();
    } catch (_) {
      return UserPreferenceSelection.empty();
    }
  }

  Future<void> save(UserPreferenceSelection selection) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(selection.toJson()));
  }
}
