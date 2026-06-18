import 'dart:typed_data';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class ReviewWriteMenuOptionsScrollBehavior extends MaterialScrollBehavior {
  const ReviewWriteMenuOptionsScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.trackpad,
    PointerDeviceKind.stylus,
    PointerDeviceKind.unknown,
  };
}

class ReviewWriteImageAddTile extends StatelessWidget {
  final int count;
  final int maxCount;
  final bool disabled;
  final VoidCallback onTap;

  const ReviewWriteImageAddTile({
    super.key,
    required this.count,
    required this.maxCount,
    required this.disabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: CustomPaint(
        painter: const _DashedBorderPainter(
          color: Color(0xFFCBD5E1),
          radius: 14,
        ),
        child: Container(
          width: 106,
          height: 106,
          decoration: BoxDecoration(
            color: const Color(0xFFFCFDFE),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.add_a_photo_outlined,
                color: Color(0xFF94A3B8),
                size: 30,
              ),
              const SizedBox(height: 6),
              Text(
                '$count/$maxCount',
                style: const TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ReviewWriteImagePreviewTile extends StatelessWidget {
  final Uint8List? bytes;
  final String? imageUrl;
  final String? contentType;
  final String durationLabel;
  final bool disabled;
  final VoidCallback onRemove;

  const ReviewWriteImagePreviewTile({
    super.key,
    this.bytes,
    this.imageUrl,
    this.contentType,
    this.durationLabel = '',
    required this.disabled,
    required this.onRemove,
  }) : assert(bytes != null || imageUrl != null);

  @override
  Widget build(BuildContext context) {
    final isVideo =
        (contentType ?? '').toLowerCase().startsWith('video/') ||
        (imageUrl ?? '').toLowerCase().endsWith('.mp4') ||
        (imageUrl ?? '').toLowerCase().endsWith('.mov') ||
        (imageUrl ?? '').toLowerCase().endsWith('.webm');
    final imageWidget = isVideo
        ? Container(
            width: 106,
            height: 106,
            color: const Color(0xFF0F172A),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.play_circle_fill_rounded,
                  size: 34,
                  color: Colors.white,
                ),
                SizedBox(height: 6),
                Text(
                  'VIDEO',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          )
        : bytes != null
        ? Image.memory(
            bytes!,
            width: 106,
            height: 106,
            fit: BoxFit.cover,
            gaplessPlayback: true,
          )
        : Image.network(
            imageUrl!,
            width: 106,
            height: 106,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: 106,
                height: 106,
                color: const Color(0xFFF8FAFC),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.broken_image_outlined,
                  color: Color(0xFF94A3B8),
                ),
              );
            },
          );
    return SizedBox(
      width: 106,
      height: 106,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: imageWidget,
          ),
          Positioned(
            top: 8,
            right: 8,
            child: GestureDetector(
              onTap: disabled ? null : onRemove,
              child: Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(
                  color: Color(0xFF1F2937),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, size: 16, color: Colors.white),
              ),
            ),
          ),
          if (isVideo && durationLabel.isNotEmpty)
            Positioned(
              left: 8,
              bottom: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.68),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  durationLabel,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double radius;

  const _DashedBorderPainter({required this.color, required this.radius});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    const dashWidth = 6.0;
    const dashSpace = 4.0;
    final path = Path()..addRRect(rect);
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = distance + dashWidth;
        canvas.drawPath(metric.extractPath(distance, next), paint);
        distance = next + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.radius != radius;
  }
}
