import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:front/domain/entities/review.dart';
import 'package:front/domain/entities/store_visit_media_page.dart';
import 'package:front/presentation/widgets/review_media_gallery.dart';
import 'package:front/presentation/widgets/stacked_image_gallery.dart';

typedef ReviewMediaPageLoader =
    Future<StoreVisitMediaPage> Function(String? cursor);

class LazyReviewMediaSection extends StatefulWidget {
  final List<ReviewMediaItem> initialItems;
  final bool initialHasMore;
  final String? initialNextCursor;
  final ReviewMediaPageLoader onLoadMore;
  final String title;

  const LazyReviewMediaSection({
    super.key,
    required this.initialItems,
    required this.initialHasMore,
    required this.initialNextCursor,
    required this.onLoadMore,
    this.title = '방문 기록',
  });

  @override
  State<LazyReviewMediaSection> createState() => _LazyReviewMediaSectionState();
}

class _LazyReviewMediaSectionState extends State<LazyReviewMediaSection> {
  late final ScrollController _scrollController;
  late final ValueNotifier<List<GalleryImageItem>> _galleryNotifier;
  late final ValueNotifier<bool> _hasMoreNotifier;
  late final ValueNotifier<bool> _isFetchingNotifier;

  late List<ReviewMediaItem> _items;
  late bool _hasMore;
  late String? _nextCursor;
  bool _isFetching = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_handleScroll);
    _galleryNotifier = ValueNotifier<List<GalleryImageItem>>(const []);
    _hasMoreNotifier = ValueNotifier<bool>(false);
    _isFetchingNotifier = ValueNotifier<bool>(false);
    _resetFromWidget();
  }

  @override
  void didUpdateWidget(covariant LazyReviewMediaSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!listEquals(oldWidget.initialItems, widget.initialItems) ||
        oldWidget.initialHasMore != widget.initialHasMore ||
        oldWidget.initialNextCursor != widget.initialNextCursor) {
      _resetFromWidget();
    }
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_handleScroll)
      ..dispose();
    _galleryNotifier.dispose();
    _hasMoreNotifier.dispose();
    _isFetchingNotifier.dispose();
    super.dispose();
  }

  void _resetFromWidget() {
    _items = List<ReviewMediaItem>.from(widget.initialItems);
    _hasMore = widget.initialHasMore;
    _nextCursor = widget.initialNextCursor;
    _isFetching = false;
    _syncNotifiers();
  }

  void _syncNotifiers() {
    _galleryNotifier.value = reviewGalleryImagesFromMediaItems(_items);
    _hasMoreNotifier.value = _hasMore;
    _isFetchingNotifier.value = _isFetching;
  }

  void _handleScroll() {
    if (!_scrollController.hasClients || !_hasMore || _isFetching) {
      return;
    }
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 240) {
      _fetchMore();
    }
  }

  Future<void> _fetchMore() async {
    if (_isFetching || !_hasMore) {
      return;
    }
    setState(() {
      _isFetching = true;
      _isFetchingNotifier.value = true;
    });

    try {
      final page = await widget.onLoadMore(_nextCursor);
      final merged = [..._items];
      final seenUrls = merged.map((item) => item.url.trim()).toSet();
      for (final item in page.items) {
        final url = item.url.trim();
        if (url.isEmpty || seenUrls.contains(url)) {
          continue;
        }
        seenUrls.add(url);
        merged.add(item);
      }
      if (!mounted) {
        return;
      }
      setState(() {
        _items = merged;
        _hasMore = page.hasMore;
        _nextCursor = page.nextCursor;
        _isFetching = false;
        _syncNotifiers();
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isFetching = false;
        _isFetchingNotifier.value = false;
      });
    }
  }

  void _openViewer(int initialIndex) {
    showDialog<void>(
      context: context,
      builder: (_) => _LazyGalleryViewerDialog(
        imagesListenable: _galleryNotifier,
        hasMoreListenable: _hasMoreNotifier,
        isFetchingListenable: _isFetchingNotifier,
        initialIndex: initialIndex,
        onLoadMore: _fetchMore,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final images = _galleryNotifier.value;
    if (images.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          GalleryImageStrip(
            images: images,
            controller: _scrollController,
            onImageTap: _openViewer,
            imageWidth: 104,
            imageHeight: 104,
            placeholder: const _ReviewPhotoPlaceholder(),
          ),
        ],
      ),
    );
  }
}

class _LazyGalleryViewerDialog extends StatefulWidget {
  final ValueListenable<List<GalleryImageItem>> imagesListenable;
  final ValueListenable<bool> hasMoreListenable;
  final ValueListenable<bool> isFetchingListenable;
  final int initialIndex;
  final Future<void> Function() onLoadMore;

  const _LazyGalleryViewerDialog({
    required this.imagesListenable,
    required this.hasMoreListenable,
    required this.isFetchingListenable,
    required this.initialIndex,
    required this.onLoadMore,
  });

  @override
  State<_LazyGalleryViewerDialog> createState() => _LazyGalleryViewerDialogState();
}

class _LazyGalleryViewerDialogState extends State<_LazyGalleryViewerDialog> {
  late final PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    final images = widget.imagesListenable.value;
    _currentIndex = widget.initialIndex.clamp(0, images.length - 1);
    _pageController = PageController(initialPage: _currentIndex);
    _maybeLoadMore(_currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _maybeLoadMore(int index) {
    final images = widget.imagesListenable.value;
    if (!widget.hasMoreListenable.value || widget.isFetchingListenable.value) {
      return;
    }
    if (index >= images.length - 3) {
      widget.onLoadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      backgroundColor: Colors.black,
      child: ValueListenableBuilder<List<GalleryImageItem>>(
        valueListenable: widget.imagesListenable,
        builder: (context, images, _) {
          if (images.isEmpty) {
            return const SizedBox.shrink();
          }
          if (_currentIndex >= images.length) {
            _currentIndex = images.length - 1;
          }

          return Stack(
            children: [
              PageView.builder(
                controller: _pageController,
                itemCount: images.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                  _maybeLoadMore(index);
                },
                itemBuilder: (context, index) {
                  final image = images[index];
                  return Center(
                    child: image.isVideoUrl
                        ? GalleryVideoPlayer(image: image)
                        : InteractiveViewer(
                            minScale: 1,
                            maxScale: 4,
                            panEnabled: false,
                            child: GalleryImageContent(
                              image: image,
                              fit: BoxFit.contain,
                              placeholder: const _ReviewPhotoPlaceholder(),
                              useViewerSource: true,
                            ),
                          ),
                  );
                },
              ),
              Positioned(
                top: 18,
                left: 20,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    child: Text(
                      '${_currentIndex + 1} / ${images.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 10,
                right: 10,
                child: IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, color: Colors.white),
                ),
              ),
              ValueListenableBuilder<bool>(
                valueListenable: widget.isFetchingListenable,
                builder: (context, isFetching, _) {
                  if (!isFetching) {
                    return const SizedBox.shrink();
                  }
                  return const Positioned(
                    right: 20,
                    bottom: 26,
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    ),
                  );
                },
              ),
              if (images.length > 1)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 28,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      images.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: index == _currentIndex ? 18 : 7,
                        height: 7,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        decoration: BoxDecoration(
                          color: index == _currentIndex
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.38),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _ReviewPhotoPlaceholder extends StatelessWidget {
  const _ReviewPhotoPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Color(0xFFF4EFEA),
      child: Center(
        child: Icon(Icons.image_outlined, size: 20, color: Color(0xFFC28D73)),
      ),
    );
  }
}
