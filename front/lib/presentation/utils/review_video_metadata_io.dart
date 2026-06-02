import 'dart:io';

import 'package:video_player/video_player.dart';

class ReviewVideoMetadata {
  final int? durationMs;

  const ReviewVideoMetadata({required this.durationMs});
}

Future<ReviewVideoMetadata> loadReviewVideoMetadata({
  String? filePath,
  Object? bytes,
  String? contentType,
}) async {
  if (filePath == null || filePath.isEmpty) {
    return const ReviewVideoMetadata(durationMs: null);
  }
  VideoPlayerController? controller;
  try {
    controller = VideoPlayerController.file(File(filePath));
    await controller.initialize();
    return ReviewVideoMetadata(
      durationMs: controller.value.duration.inMilliseconds,
    );
  } catch (_) {
    return const ReviewVideoMetadata(durationMs: null);
  } finally {
    if (controller != null) {
      await controller.dispose();
    }
  }
}
