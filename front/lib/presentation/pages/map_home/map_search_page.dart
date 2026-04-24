import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:front/core/constants/app_colors.dart';
import 'package:front/data/local/map_search_history_storage.dart';
import 'package:front/domain/entities/place_search_result.dart';
import 'package:front/presentation/providers/map_search_controller.dart';
import 'package:front/presentation/widgets/map_search_widgets.dart';

Future<PlaceSearchResult?> showFullScreenSearchDialog(
  BuildContext context, {
  String initialQuery = '',
}) {
  FocusScope.of(context).unfocus();

  return showGeneralDialog<PlaceSearchResult>(
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

class _FullScreenSearchDialog extends ConsumerStatefulWidget {
  final String initialQuery;

  const _FullScreenSearchDialog({required this.initialQuery});

  @override
  ConsumerState<_FullScreenSearchDialog> createState() =>
      _FullScreenSearchDialogState();
}

class _FullScreenSearchDialogState
    extends ConsumerState<_FullScreenSearchDialog> {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();
  final _historyStorage = const MapSearchHistoryStorage();
  final _dateFormat = DateFormat('MM.dd.');

  late final MapSearchController _controller;

  @override
  void initState() {
    super.initState();
    _searchController.text = widget.initialQuery;
    _searchController.selection = TextSelection.fromPosition(
      TextPosition(offset: _searchController.text.length),
    );

    _controller = MapSearchController(
      ref: ref,
      textController: _searchController,
      historyStorage: _historyStorage,
    );

    _searchController.addListener(_handleTextChanged);
    _controller.loadHistory(_refresh);

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

  void _refresh() {
    if (mounted) {
      setState(() {});
    }
  }

  void _handleTextChanged() {
    if (_searchController.text.trim().isEmpty && _controller.hasActiveSearch) {
      _controller.resetSearchState(_refresh);
    } else {
      _refresh();
    }
  }

  void _selectResult(PlaceSearchResult item) {
    Navigator.of(context).pop(item);
  }

  Widget _buildBody() {
    if (_controller.isLoadingHistory) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_controller.hasActiveSearch) {
      return MapSearchResultSection(
        isSearching: _controller.isSearching,
        results: _controller.results,
        errorMessage: _controller.errorMessage,
        onSelect: _selectResult,
      );
    }

    if (_controller.hasQuery) {
      return MapSearchGuide(
        keyword: _searchController.text.trim(),
        onSearch: () => _controller.performSearch(_refresh),
      );
    }

    return MapSearchHistorySection(
      history: _controller.history,
      dateFormat: _dateFormat,
      onSelect: (keyword) => _controller.performSearch(_refresh, keyword),
      onDelete: (keyword) => _controller.removeHistory(keyword, _refresh),
      onClearAll: () => _controller.clearHistory(_refresh),
    );
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
                child: MapSearchBar(
                  controller: _searchController,
                  focusNode: _focusNode,
                  isSearching: _controller.isSearching,
                  onBack: () => Navigator.of(context).pop(),
                  onClear: () {
                    _searchController.clear();
                    _controller.resetSearchState(_refresh);
                  },
                  onSubmitted: (value) =>
                      _controller.performSearch(_refresh, value),
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
                  child: _buildBody(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
