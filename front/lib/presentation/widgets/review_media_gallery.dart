import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:front/domain/entities/review.dart';
import 'package:front/presentation/widgets/stacked_image_gallery.dart';

List<GalleryImageItem> reviewGalleryImagesFromMediaItems(
  List<ReviewMediaItem> mediaItems,
) {
  final items = <GalleryImageItem>[];
  final seenUrls = <String>{};

  for (final media in mediaItems) {
    final viewerUrl = media.url.trim();
    if (viewerUrl.isEmpty ||
        viewerUrl.toLowerCase().endsWith('.svg') ||
        !seenUrls.add(viewerUrl)) {
      continue;
    }

    final thumbnailUrl = media.isVideo
        ? (media.thumbnailUrl.trim().isNotEmpty
              ? media.thumbnailUrl.trim()
              : _thumbnailUrlFor(viewerUrl, width: 320, height: 220))
        : viewerUrl;
    items.add(GalleryImageItem.url(thumbnailUrl, viewerUrl: viewerUrl));
  }

  return [
    ...items.where((item) => item.isVideoUrl),
    ...items.where((item) => !item.isVideoUrl),
  ];
}

List<GalleryImageItem> reviewGalleryImagesFromReviews(List<Review> reviews) {
  final merged = <ReviewMediaItem>[];
  for (final review in reviews) {
    merged.addAll(review.mediaItems);
  }
  return reviewGalleryImagesFromMediaItems(merged);
}

class ReviewMediaSection extends StatelessWidget {
  final String title;
  final List<GalleryImageItem> images;
  final bool showTitle;
  final EdgeInsetsGeometry padding;

  const ReviewMediaSection({
    super.key,
    this.title = '방문 기록',
    required this.images,
    this.showTitle = true,
    this.padding = const EdgeInsets.fromLTRB(16, 18, 16, 20),
  });

  @override
  Widget build(BuildContext context) {
    if (images.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showTitle)
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
          if (showTitle) const SizedBox(height: 12),
          GalleryImageStrip(
            images: images,
            imageWidth: 104,
            imageHeight: 104,
            placeholder: const _ReviewPhotoPlaceholder(),
          ),
        ],
      ),
    );
  }
}

String _thumbnailUrlFor(
  String sourceUrl, {
  required int width,
  required int height,
}) {
  final baseUrl = (dotenv.env['API_BASE_URL'] ?? '').trim();
  if (baseUrl.isEmpty) return sourceUrl;
  final originalSourceUrl = _unwrapMediaProxySource(sourceUrl);
  final baseUri = Uri.parse(baseUrl);
  return baseUri
      .replace(
        path: '/api/cafemap/assets/thumbnail',
        queryParameters: {
          'src': originalSourceUrl,
          'w': width.toString(),
          'h': height.toString(),
        },
      )
      .toString();
}

String _unwrapMediaProxySource(String rawUrl) {
  final uri = Uri.tryParse(rawUrl.trim());
  if (uri == null) return rawUrl;
  final proxiedSource = uri.queryParameters['src']?.trim();
  if (proxiedSource == null || proxiedSource.isEmpty) {
    return rawUrl;
  }
  return proxiedSource;
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
