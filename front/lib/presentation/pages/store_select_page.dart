import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:front/core/constants/app_colors.dart';
import 'package:front/domain/entities/place_search_result.dart';
import 'package:front/presentation/providers/app_providers.dart';
import 'package:front/presentation/utils/auth_navigation.dart';
import 'package:go_router/go_router.dart';

// ?? ???? ???? ?? ?? ????.
class StoreSelectPage extends ConsumerStatefulWidget {
  final String brandId;
  final String menuName;
  final String brandName;

  const StoreSelectPage({
    super.key,
    required this.brandId,
    required this.menuName,
    required this.brandName,
  });

  @override
  ConsumerState<StoreSelectPage> createState() => _StoreSelectPageState();
}

class _StoreSelectPageState extends ConsumerState<StoreSelectPage> {
  final _searchController = TextEditingController();
  List<PlaceSearchResult> _results = [];
  bool _isSearching = false;
  String? _searchError;

  @override
  void initState() {
    super.initState();
    _searchController.text = widget.brandName.isNotEmpty
        ? '${widget.brandName} '
        : '';
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchPlaces(String query) async {
    if (query.trim().isEmpty) return;
    setState(() {
      _isSearching = true;
      _searchError = null;
    });
    try {
      final repository = ref.read(placeSearchRepositoryProvider);
      final results = await repository.searchPlaces(query.trim());
      setState(() {
        _results = results;
      });
    } catch (_) {
      setState(() {
        _searchError = '매장을 찾지 못했습니다. 다시 시도해주세요.';
      });
    } finally {
      setState(() {
        _isSearching = false;
      });
    }
  }

  Future<void> _selectStore(PlaceSearchResult item) async {
    final isSignedIn = await ensureSignedInForReview(context, ref);
    if (!isSignedIn || !mounted) return;
    final address = item.roadAddress.isNotEmpty
        ? item.roadAddress
        : item.address;
    final uri = Uri(
      path: '/review/write',
      queryParameters: {
        'storeName': item.name,
        'address': address,
        'menuName': widget.menuName,
        'brandId': widget.brandId,
      },
    );
    context.push(uri.toString());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('매장 선택')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${widget.brandName} · ${widget.menuName}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _searchController,
                onSubmitted: _searchPlaces,
                decoration: InputDecoration(
                  hintText: '매장 검색',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (_isSearching)
                const Center(child: CircularProgressIndicator())
              else if (_searchError != null)
                Text(_searchError!, style: const TextStyle(color: Colors.red))
              else
                Expanded(
                  child: ListView.separated(
                    itemBuilder: (context, index) {
                      final item = _results[index];
                      final address = item.roadAddress.isNotEmpty
                          ? item.roadAddress
                          : item.address;
                      return ListTile(
                        leading: const Icon(
                          Icons.place,
                          color: AppColors.primary,
                        ),
                        title: Text(item.name),
                        subtitle: Text(address),
                        onTap: () => _selectStore(item),
                      );
                    },
                    separatorBuilder: (_, index) => const Divider(height: 1),
                    itemCount: _results.length,
                  ),
                ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _searchPlaces(_searchController.text),
        child: const Icon(Icons.search),
      ),
    );
  }
}
