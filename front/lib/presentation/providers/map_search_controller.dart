import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:front/data/local/map_search_history_storage.dart';
import 'package:front/domain/entities/place_search_result.dart';
import 'package:front/presentation/providers/app_providers.dart';

class MapSearchController {
  final WidgetRef ref;
  final TextEditingController textController;
  final MapSearchHistoryStorage historyStorage;

  List<MapSearchHistoryItem> history = const <MapSearchHistoryItem>[];
  List<PlaceSearchResult> results = const <PlaceSearchResult>[];
  String? errorMessage;
  bool isLoadingHistory = true;
  bool isSearching = false;
  bool hasActiveSearch = false;

  MapSearchController({
    required this.ref,
    required this.textController,
    required this.historyStorage,
  });

  bool get hasQuery => textController.text.trim().isNotEmpty;

  Future<void> loadHistory(VoidCallback onChanged) async {
    history = await historyStorage.load();
    isLoadingHistory = false;
    onChanged();
  }

  void resetSearchState(VoidCallback onChanged) {
    results = const <PlaceSearchResult>[];
    errorMessage = null;
    hasActiveSearch = false;
    isSearching = false;
    onChanged();
  }

  Future<void> performSearch(
    VoidCallback onChanged, [
    String? keyword,
  ]) async {
    final query = (keyword ?? textController.text).trim();
    if (query.isEmpty) {
      textController.clear();
      resetSearchState(onChanged);
      return;
    }

    textController.text = query;
    textController.selection = TextSelection.fromPosition(
      TextPosition(offset: query.length),
    );

    isSearching = true;
    hasActiveSearch = true;
    results = const <PlaceSearchResult>[];
    errorMessage = null;
    onChanged();

    await historyStorage.add(query);
    final updatedHistory = await historyStorage.load();

    try {
      final repository = ref.read(placeSearchRepositoryProvider);
      final fetched = await repository.searchPlaces(query, display: 8);

      history = updatedHistory;
      results = fetched;
      errorMessage = fetched.isEmpty ? '검색 결과가 없어요.' : null;
      onChanged();
    } catch (_) {
      history = updatedHistory;
      errorMessage = '검색에 실패했어요. 다시 시도해 주세요.';
      onChanged();
    } finally {
      isSearching = false;
      onChanged();
    }
  }

  Future<void> removeHistory(
    String keyword,
    VoidCallback onChanged,
  ) async {
    history = await historyStorage.remove(keyword);
    onChanged();
  }

  Future<void> clearHistory(VoidCallback onChanged) async {
    await historyStorage.clear();
    history = const <MapSearchHistoryItem>[];
    onChanged();
  }
}
