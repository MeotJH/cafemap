import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class MapSearchHistoryItem {
  final String keyword;
  final DateTime searchedAt;

  const MapSearchHistoryItem({
    required this.keyword,
    required this.searchedAt,
  });

  String serialize() => jsonEncode({
    'keyword': keyword,
    'searchedAt': searchedAt.toIso8601String(),
  });

  static MapSearchHistoryItem? deserialize(String value) {
    try {
      final decoded = jsonDecode(value);
      if (decoded is! Map<String, dynamic>) return null;

      final keyword = (decoded['keyword'] as String? ?? '').trim();
      final searchedAt = DateTime.tryParse(
        decoded['searchedAt'] as String? ?? '',
      );
      if (keyword.isEmpty || searchedAt == null) return null;

      return MapSearchHistoryItem(keyword: keyword, searchedAt: searchedAt);
    } catch (_) {
      return null;
    }
  }
}

class MapSearchHistoryStorage {
  static const String _storageKey = 'map_search_history';
  static const int _maxItems = 20;

  const MapSearchHistoryStorage();

  Future<List<MapSearchHistoryItem>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final rawItems = prefs.getStringList(_storageKey) ?? const <String>[];

    final parsed = rawItems
        .map(MapSearchHistoryItem.deserialize)
        .whereType<MapSearchHistoryItem>()
        .toList()
      ..sort((a, b) => b.searchedAt.compareTo(a.searchedAt));

    return parsed;
  }

  Future<List<MapSearchHistoryItem>> add(String keyword) async {
    final trimmed = keyword.trim();
    if (trimmed.isEmpty) return load();

    final items = await load();
    final deduped = items.where((item) => item.keyword != trimmed).toList();
    deduped.insert(
      0,
      MapSearchHistoryItem(keyword: trimmed, searchedAt: DateTime.now()),
    );

    final limited = deduped.take(_maxItems).toList();
    await _save(limited);
    return limited;
  }

  Future<List<MapSearchHistoryItem>> remove(String keyword) async {
    final items = await load();
    final updated = items.where((item) => item.keyword != keyword).toList();
    await _save(updated);
    return updated;
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }

  Future<void> _save(List<MapSearchHistoryItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _storageKey,
      items.map((item) => item.serialize()).toList(),
    );
  }
}
