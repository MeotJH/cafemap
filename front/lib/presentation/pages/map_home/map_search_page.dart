import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:front/core/constants/app_colors.dart';

Future<String?> showFullScreenSearchDialog(
  BuildContext context, {
  String initialQuery = '',
}) {
  FocusScope.of(context).unfocus();

  return showGeneralDialog<String>(
    context: context,
    barrierDismissible: false,
    barrierLabel: 'Full Screen Search',
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 250),
    pageBuilder: (context, animation, secondaryAnimation) {
      return _FullScreenSearchDialog(initialQuery: initialQuery);
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(opacity: animation, child: child);
    },
  );
}

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
    if (trimmed.isEmpty) {
      return load();
    }

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

class _FullScreenSearchDialog extends StatefulWidget {
  final String initialQuery;

  const _FullScreenSearchDialog({required this.initialQuery});

  @override
  State<_FullScreenSearchDialog> createState() =>
      _FullScreenSearchDialogState();
}

class _FullScreenSearchDialogState extends State<_FullScreenSearchDialog> {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();
  final _historyStorage = const MapSearchHistoryStorage();
  final _dateFormat = DateFormat('MM.dd.');

  List<MapSearchHistoryItem> _history = const <MapSearchHistoryItem>[];
  bool _isLoading = true;

  bool get _hasQuery => _searchController.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    _searchController.text = widget.initialQuery;
    _searchController.selection = TextSelection.fromPosition(
      TextPosition(offset: _searchController.text.length),
    );
    _searchController.addListener(_handleTextChanged);
    _loadHistory();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_handleTextChanged)
      ..dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleTextChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _loadHistory() async {
    final history = await _historyStorage.load();
    if (!mounted) return;

    setState(() {
      _history = history;
      _isLoading = false;
    });
  }

  Future<void> _submitSearch([String? keyword]) async {
    final value = (keyword ?? _searchController.text).trim();
    if (value.isEmpty) return;

    await _historyStorage.add(value);
    if (!mounted) return;
    Navigator.of(context).pop(value);
  }

  Future<void> _removeHistory(String keyword) async {
    final history = await _historyStorage.remove(keyword);
    if (!mounted) return;

    setState(() {
      _history = history;
    });
  }

  Future<void> _clearHistory() async {
    await _historyStorage.clear();
    if (!mounted) return;

    setState(() {
      _history = const <MapSearchHistoryItem>[];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.backgroundLight,
      child: SafeArea(
        bottom: false,
        child: Scaffold(
          backgroundColor: AppColors.backgroundLight,
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: _SearchBar(
                  controller: _searchController,
                  focusNode: _focusNode,
                  onBack: () => Navigator.of(context).pop(),
                  onClear: () => _searchController.clear(),
                  onSubmitted: _submitSearch,
                ),
              ),
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: AppColors.backgroundLight,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                  ),
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _hasQuery
                      ? _SearchGuide(
                          keyword: _searchController.text.trim(),
                          onSearch: () => _submitSearch(),
                        )
                      : _SearchHistorySection(
                          history: _history,
                          dateFormat: _dateFormat,
                          onSelect: _submitSearch,
                          onDelete: _removeHistory,
                          onClearAll: _clearHistory,
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onBack;
  final VoidCallback onClear;
  final ValueChanged<String> onSubmitted;

  const _SearchBar({
    required this.controller,
    required this.focusNode,
    required this.onBack,
    required this.onClear,
    required this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    final hasText = controller.text.trim().isNotEmpty;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.chipBackground,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              textInputAction: TextInputAction.search,
              onSubmitted: onSubmitted,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                hintText: '장소, 카페, 주소를 검색해 보세요',
                hintStyle: TextStyle(color: AppColors.textSecondary),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
          if (hasText)
            IconButton(
              onPressed: onClear,
              icon: const Icon(Icons.close_rounded),
            ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: hasText ? () => onSubmitted(controller.text) : null,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size(48, 40),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Icon(Icons.search),
          ),
        ],
      ),
    );
  }
}

class _SearchGuide extends StatelessWidget {
  final String keyword;
  final VoidCallback onSearch;

  const _SearchGuide({
    required this.keyword,
    required this.onSearch,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
      children: [
        const Text(
          '검색',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          '"$keyword"로 장소 검색을 실행합니다.',
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 20),
        InkWell(
          onTap: onSearch,
          borderRadius: BorderRadius.circular(16),
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            decoration: BoxDecoration(
              color: AppColors.chipBackground,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: const Row(
              children: [
                Icon(Icons.search_rounded, color: AppColors.primary),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '이 검색어로 지도에서 찾아보기',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                Icon(Icons.arrow_forward_ios_rounded, size: 16),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SearchHistorySection extends StatelessWidget {
  final List<MapSearchHistoryItem> history;
  final DateFormat dateFormat;
  final ValueChanged<String> onSelect;
  final ValueChanged<String> onDelete;
  final VoidCallback onClearAll;

  const _SearchHistorySection({
    required this.history,
    required this.dateFormat,
    required this.onSelect,
    required this.onDelete,
    required this.onClearAll,
  });

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 32),
          child: Text(
            '아직 검색 기록이 없습니다.\n검색어를 입력하면 여기에 저장됩니다.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 10),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  '최근 검색',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              TextButton(
                onPressed: onClearAll,
                child: const Text('전체 삭제'),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            itemCount: history.length,
            separatorBuilder: (context, index) => const SizedBox(height: 6),
            itemBuilder: (context, index) {
              final item = history[index];
              return _HistoryListTile(
                keyword: item.keyword,
                dateLabel: dateFormat.format(item.searchedAt),
                onTap: () => onSelect(item.keyword),
                onDelete: () => onDelete(item.keyword),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _HistoryListTile extends StatelessWidget {
  final String keyword;
  final String dateLabel;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _HistoryListTile({
    required this.keyword,
    required this.dateLabel,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.chipBackground,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: AppColors.backgroundLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.history_rounded,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  keyword,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                dateLabel,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(
                  Icons.close_rounded,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
