import 'package:front/domain/entities/review.dart';

class StoreVisitMediaPage {
  final List<ReviewMediaItem> items;
  final bool hasMore;
  final String? nextCursor;

  const StoreVisitMediaPage({
    required this.items,
    required this.hasMore,
    required this.nextCursor,
  });
}
