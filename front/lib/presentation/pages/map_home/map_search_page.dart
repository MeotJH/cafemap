import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> showFullScreenSearchDialog(BuildContext context) {
  FocusScope.of(context).unfocus();

  return showGeneralDialog(
    context: context,
    barrierDismissible: false,
    barrierLabel: 'Full Screen Search',
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 250),
    pageBuilder: (context, animation, secondaryAnimation) {
      return const _FullScreenSearchDialog();
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(opacity: animation, child: child);
    },
  );
}

class _FullScreenSearchDialog extends StatelessWidget {
  const _FullScreenSearchDialog();
  final String prefStr = 'map_search_history';

  Future<List<String>> loadSearchResults() async {
    final prefs = SharedPreferencesAsync();
    final results = await prefs.getStringList('map_search_results');
    return results ?? [];
  }

  Future<void> saveSearchResults(String keyword) async {
    final prefs = SharedPreferencesAsync();
    final searchHistory = await prefs.getStringList(prefStr) ?? [];
    searchHistory.add(keyword);
    await prefs.setStringList(prefStr, searchHistory);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Scaffold(
        body: Column(
          children: [
            SizedBox(height: MediaQuery.of(context).padding.top + 16),
            Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextField(
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: 'Search...',
                        prefixIcon: IconButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          icon: Icon(Icons.arrow_back_ios_new),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const Expanded(child: Center(child: Text('현재 화면 위를 전부 덮는 모달입니다'))),
          ],
        ),
      ),
    );
  }
}
