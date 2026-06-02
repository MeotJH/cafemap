import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:video_player/video_player.dart';

class GalleryImageItem {
  final String? url;
  final String? viewerUrl;
  final Uint8List? bytes;

  const GalleryImageItem({this.url, this.viewerUrl, this.bytes})
    : assert(
        (url != null && url != '') || bytes != null,
        'Either url or bytes must be provided.',
      );

  const GalleryImageItem.url(String this.url, {this.viewerUrl}) : bytes = null;

  const GalleryImageItem.bytes(Uint8List this.bytes)
    : url = null,
      viewerUrl = null;

  bool get isSvgUrl => (url ?? '').toLowerCase().endsWith('.svg');
  bool get isViewerSvgUrl =>
      (viewerUrl ?? url ?? '').toLowerCase().endsWith('.svg');
  bool get isVideoUrl => _isVideoUrl(viewerUrl ?? url ?? '');
}

class StackedImageGallery extends StatelessWidget {
  final List<GalleryImageItem> images;
  final ValueChanged<int>? onImageTap;
  final int maxVisible;
  final double imageWidth;
  final double imageHeight;
  final double overlapOffset;
  final double verticalOffset;
  final BorderRadius borderRadius;
  final Widget? placeholder;

  const StackedImageGallery({
    super.key,
    required this.images,
    this.onImageTap,
    this.maxVisible = 2,
    this.imageWidth = 50,
    this.imageHeight = 48,
    this.overlapOffset = 22,
    this.verticalOffset = 6,
    this.borderRadius = const BorderRadius.all(Radius.circular(14)),
    this.placeholder,
  });

  @override
  Widget build(BuildContext context) {
    final visibleImages = images.take(maxVisible).toList(growable: false);
    if (visibleImages.isEmpty) {
      return const SizedBox.shrink();
    }

    final width = visibleImages.length == 1
        ? imageWidth
        : imageWidth + (overlapOffset * (visibleImages.length - 1));
    final height = imageHeight + (verticalOffset * (visibleImages.length - 1));

    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (var index = 0; index < visibleImages.length; index++)
            Positioned(
              left: index * overlapOffset,
              top: index * verticalOffset,
              child: _GalleryThumbnail(
                image: visibleImages[index],
                width: imageWidth,
                height: imageHeight,
                borderRadius: borderRadius,
                placeholder: placeholder,
                onTap: () {
                  final customTap = onImageTap;
                  if (customTap != null) {
                    customTap(index);
                    return;
                  }
                  showGalleryViewer(
                    context,
                    images: visibleImages,
                    initialIndex: index,
                    placeholder: placeholder,
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class GalleryImageStrip extends StatelessWidget {
  final List<GalleryImageItem> images;
  final double imageWidth;
  final double imageHeight;
  final double spacing;
  final BorderRadius borderRadius;
  final Widget? placeholder;
  final bool fadeOverflowEdges;
  final ScrollController? controller;
  final ValueChanged<int>? onImageTap;

  const GalleryImageStrip({
    super.key,
    required this.images,
    this.imageWidth = 120,
    this.imageHeight = 120,
    this.spacing = 10,
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
    this.placeholder,
    this.fadeOverflowEdges = true,
    this.controller,
    this.onImageTap,
  });

  @override
  Widget build(BuildContext context) {
    if (images.isEmpty) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final contentWidth =
            (images.length * imageWidth) + ((images.length - 1) * spacing);
        final shouldFade =
            fadeOverflowEdges &&
            constraints.hasBoundedWidth &&
            contentWidth > constraints.maxWidth;

        final strip = ScrollConfiguration(
          behavior: const _GalleryScrollerBehavior(),
          child: ListView.separated(
            controller: controller,
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: images.length,
            separatorBuilder: (_, _) => SizedBox(width: spacing),
            itemBuilder: (context, index) => _GalleryStripItem(
              image: images[index],
              width: imageWidth,
              height: imageHeight,
              borderRadius: borderRadius,
              placeholder: placeholder,
              onTap: () {
                final customTap = onImageTap;
                if (customTap != null) {
                  customTap(index);
                  return;
                }
                showGalleryViewer(
                  context,
                  images: images,
                  initialIndex: index,
                  placeholder: placeholder,
                );
              },
            ),
          ),
        );

        return SizedBox(
          height: imageHeight,
          child: shouldFade ? _HorizontalEdgeFade(child: strip) : strip,
        );
      },
    );
  }
}

class _HorizontalEdgeFade extends StatelessWidget {
  final Widget child;

  const _HorizontalEdgeFade({required this.child});

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.dstIn,
      shaderCallback: (bounds) {
        return const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Colors.transparent,
            Colors.black,
            Colors.black,
            Colors.transparent,
          ],
          stops: [0.0, 0.08, 0.92, 1.0],
        ).createShader(bounds);
      },
      child: child,
    );
  }
}

class _GalleryScrollerBehavior extends MaterialScrollBehavior {
  const _GalleryScrollerBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.trackpad,
    PointerDeviceKind.stylus,
    PointerDeviceKind.unknown,
  };
}

void showGalleryViewer(
  BuildContext context, {
  required List<GalleryImageItem> images,
  int initialIndex = 0,
  Widget? placeholder,
}) {
  if (images.isEmpty) {
    return;
  }

  showDialog<void>(
    context: context,
    builder: (context) => _GalleryViewerDialog(
      images: images,
      initialIndex: initialIndex,
      placeholder: placeholder,
    ),
  );
}

class _GalleryThumbnail extends StatefulWidget {
  final GalleryImageItem image;
  final double width;
  final double height;
  final BorderRadius borderRadius;
  final Widget? placeholder;
  final VoidCallback onTap;

  const _GalleryThumbnail({
    required this.image,
    required this.width,
    required this.height,
    required this.borderRadius,
    required this.placeholder,
    required this.onTap,
  });

  @override
  State<_GalleryThumbnail> createState() => _GalleryThumbnailState();
}

class _GalleryThumbnailState extends State<_GalleryThumbnail> {
  bool _hasLoadError = false;

  void _markLoadError() {
    if (_hasLoadError) return;
    setState(() {
      _hasLoadError = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final cacheWidth = (widget.width * dpr).round();
    final cacheHeight = (widget.height * dpr).round();

    return GestureDetector(
      onTap: _hasLoadError ? null : widget.onTap,
      child: Container(
        width: widget.width,
        height: widget.height,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: const Color(0xFFF4EFEA),
          borderRadius: widget.borderRadius,
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: _GalleryImageContent(
          image: widget.image,
          fit: BoxFit.cover,
          placeholder: widget.placeholder,
          onLoadError: _markLoadError,
          cacheWidth: cacheWidth,
          cacheHeight: cacheHeight,
        ),
      ),
    );
  }
}

class _GalleryStripItem extends StatefulWidget {
  final GalleryImageItem image;
  final double width;
  final double height;
  final BorderRadius borderRadius;
  final Widget? placeholder;
  final VoidCallback onTap;

  const _GalleryStripItem({
    required this.image,
    required this.width,
    required this.height,
    required this.borderRadius,
    required this.placeholder,
    required this.onTap,
  });

  @override
  State<_GalleryStripItem> createState() => _GalleryStripItemState();
}

class _GalleryStripItemState extends State<_GalleryStripItem> {
  bool _hasLoadError = false;

  void _markLoadError() {
    if (_hasLoadError) return;
    setState(() {
      _hasLoadError = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final cacheWidth = (widget.width * dpr).round();
    final cacheHeight = (widget.height * dpr).round();

    return GestureDetector(
      onTap: _hasLoadError ? null : widget.onTap,
      child: ClipRRect(
        borderRadius: widget.borderRadius,
        child: SizedBox(
          width: widget.width,
          height: widget.height,
          child: _GalleryImageContent(
            image: widget.image,
            fit: BoxFit.cover,
            placeholder: widget.placeholder,
            onLoadError: _markLoadError,
            cacheWidth: cacheWidth,
            cacheHeight: cacheHeight,
          ),
        ),
      ),
    );
  }
}

class _GalleryViewerDialog extends StatefulWidget {
  final List<GalleryImageItem> images;
  final int initialIndex;
  final Widget? placeholder;

  const _GalleryViewerDialog({
    required this.images,
    required this.initialIndex,
    required this.placeholder,
  });

  @override
  State<_GalleryViewerDialog> createState() => _GalleryViewerDialogState();
}

class _GalleryViewerDialogState extends State<_GalleryViewerDialog> {
  late final PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(0, widget.images.length - 1);
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      backgroundColor: Colors.black,
      child: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: widget.images.length,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemBuilder: (context, index) {
              final image = widget.images[index];
              return Center(
                child: image.isVideoUrl
                    ? _GalleryVideoPlayer(image: image)
                    : InteractiveViewer(
                        minScale: 1,
                        maxScale: 4,
                        panEnabled: false,
                        child: _GalleryImageContent(
                          image: image,
                          fit: BoxFit.contain,
                          placeholder: widget.placeholder,
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
                  '${_currentIndex + 1} / ${widget.images.length}',
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
          if (widget.images.length > 1)
            Positioned(
              left: 0,
              right: 0,
              bottom: 28,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  widget.images.length,
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
      ),
    );
  }
}

class _GalleryImageContent extends StatelessWidget {
  final GalleryImageItem image;
  final BoxFit fit;
  final Widget? placeholder;
  final VoidCallback? onLoadError;
  final int? cacheWidth;
  final int? cacheHeight;
  final bool useViewerSource;

  const _GalleryImageContent({
    required this.image,
    required this.fit,
    required this.placeholder,
    this.onLoadError,
    this.cacheWidth,
    this.cacheHeight,
    this.useViewerSource = false,
  });

  @override
  Widget build(BuildContext context) {
    final fallback = placeholder ?? const _DefaultGalleryPlaceholder();

    if (image.bytes != null) {
      return Image.memory(
        image.bytes!,
        fit: fit,
        cacheWidth: cacheWidth,
        cacheHeight: cacheHeight,
        errorBuilder: (_, _, _) {
          onLoadError?.call();
          return fallback;
        },
      );
    }

    final url =
        ((useViewerSource ? image.viewerUrl : image.url) ?? image.url ?? '')
            .trim();
    if (url.isEmpty) {
      onLoadError?.call();
      return fallback;
    }

    final isSvgUrl = useViewerSource ? image.isViewerSvgUrl : image.isSvgUrl;
    if (isSvgUrl) {
      return Padding(
        padding: fit == BoxFit.cover
            ? const EdgeInsets.all(8)
            : EdgeInsets.zero,
        child: SvgPicture.network(
          url,
          fit: fit == BoxFit.cover ? BoxFit.contain : fit,
          placeholderBuilder: (_) => fallback,
        ),
      );
    }

    return CachedNetworkImage(
      imageUrl: url,
      fit: fit,
      memCacheWidth: cacheWidth,
      memCacheHeight: cacheHeight,
      maxWidthDiskCache: cacheWidth,
      maxHeightDiskCache: cacheHeight,
      fadeInDuration: Duration.zero,
      fadeOutDuration: Duration.zero,
      placeholder: (_, _) => fallback,
      errorWidget: (_, _, _) {
        onLoadError?.call();
        return fallback;
      },
    );
  }
}

class GalleryImageContent extends StatelessWidget {
  final GalleryImageItem image;
  final BoxFit fit;
  final Widget? placeholder;
  final bool useViewerSource;

  const GalleryImageContent({
    super.key,
    required this.image,
    required this.fit,
    this.placeholder,
    this.useViewerSource = false,
  });

  @override
  Widget build(BuildContext context) {
    return _GalleryImageContent(
      image: image,
      fit: fit,
      placeholder: placeholder,
      useViewerSource: useViewerSource,
    );
  }
}

class _GalleryVideoPlayer extends StatefulWidget {
  final GalleryImageItem image;

  const _GalleryVideoPlayer({required this.image});

  @override
  State<_GalleryVideoPlayer> createState() => _GalleryVideoPlayerState();
}

class GalleryVideoPlayer extends StatelessWidget {
  final GalleryImageItem image;

  const GalleryVideoPlayer({super.key, required this.image});

  @override
  Widget build(BuildContext context) {
    return _GalleryVideoPlayer(image: image);
  }
}

class _GalleryVideoPlayerState extends State<_GalleryVideoPlayer> {
  VideoPlayerController? _controller;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _initialize() async {
    final url = (widget.image.viewerUrl ?? widget.image.url ?? '').trim();
    if (url.isEmpty) {
      setState(() {
        _error = '영상을 재생할 수 없어요.';
      });
      return;
    }

    try {
      final controller = VideoPlayerController.networkUrl(Uri.parse(url));
      await controller.initialize();
      await controller.setLooping(true);
      await controller.play();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() {
        _controller = controller;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = '영상을 재생할 수 없어요.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (_error != null) {
      return Text(_error!, style: const TextStyle(color: Colors.white));
    }
    if (controller == null || !controller.value.isInitialized) {
      return const CircularProgressIndicator(color: Colors.white);
    }

    return SizedBox.expand(
      child: Stack(
        children: [
          Center(
            child: AspectRatio(
              aspectRatio: controller.value.aspectRatio == 0
                  ? 16 / 9
                  : controller.value.aspectRatio,
              child: VideoPlayer(controller),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 70,
            child: Center(
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF6B4D35),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () {
                  setState(() {
                    controller.value.isPlaying
                        ? controller.pause()
                        : controller.play();
                  });
                },
                icon: Icon(
                  controller.value.isPlaying
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded,
                ),
                label: Text(controller.value.isPlaying ? '일시정지' : '재생'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

bool _isVideoUrl(String rawUrl) {
  final url = rawUrl.trim().toLowerCase();
  if (url.isEmpty) return false;
  final path = Uri.tryParse(url)?.path.toLowerCase() ?? url;
  return path.endsWith('.mp4') ||
      path.endsWith('.mov') ||
      path.endsWith('.webm');
}

class _DefaultGalleryPlaceholder extends StatelessWidget {
  const _DefaultGalleryPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Color(0xFFF4EFEA),
      child: Center(
        child: Icon(
          Icons.local_cafe_rounded,
          size: 18,
          color: Color(0xFFC28D73),
        ),
      ),
    );
  }
}
