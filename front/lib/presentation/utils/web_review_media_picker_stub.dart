import 'dart:typed_data';

class WebPickedReviewMedia {
  final String fileName;
  final String mimeType;
  final Uint8List bytes;

  const WebPickedReviewMedia({
    required this.fileName,
    required this.mimeType,
    required this.bytes,
  });
}

Future<List<WebPickedReviewMedia>> pickWebReviewMedia({
  required bool multiple,
}) async {
  return const [];
}
