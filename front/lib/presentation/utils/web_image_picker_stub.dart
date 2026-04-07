import 'dart:typed_data';

class WebPickedImage {
  final String fileName;
  final String mimeType;
  final Uint8List bytes;

  const WebPickedImage({
    required this.fileName,
    required this.mimeType,
    required this.bytes,
  });
}

Future<List<WebPickedImage>> pickWebImages({required bool multiple}) async {
  return const [];
}

