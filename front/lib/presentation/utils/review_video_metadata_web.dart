// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter

import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';

class ReviewVideoMetadata {
  final int? durationMs;

  const ReviewVideoMetadata({required this.durationMs});
}

Future<ReviewVideoMetadata> loadReviewVideoMetadata({
  String? filePath,
  Uint8List? bytes,
  String? contentType,
}) async {
  if (bytes == null || bytes.isEmpty) {
    return const ReviewVideoMetadata(durationMs: null);
  }
  final blob = html.Blob(<Object>[bytes], contentType);
  final objectUrl = html.Url.createObjectUrlFromBlob(blob);
  final video = html.VideoElement()
    ..preload = 'metadata'
    ..src = objectUrl;

  final completer = Completer<ReviewVideoMetadata>();

  void complete(ReviewVideoMetadata value) {
    if (!completer.isCompleted) {
      completer.complete(value);
    }
  }

  video.onLoadedMetadata.listen((_) {
    final duration = video.duration;
    if (duration.isNaN || !duration.isFinite) {
      complete(const ReviewVideoMetadata(durationMs: null));
      return;
    }
    complete(ReviewVideoMetadata(durationMs: (duration * 1000).round()));
  });
  video.onError.listen((_) {
    complete(const ReviewVideoMetadata(durationMs: null));
  });

  try {
    final metadata = await completer.future.timeout(
      const Duration(seconds: 5),
      onTimeout: () => const ReviewVideoMetadata(durationMs: null),
    );
    return metadata;
  } finally {
    video.pause();
    video.removeAttribute('src');
    video.load();
    html.Url.revokeObjectUrl(objectUrl);
  }
}
