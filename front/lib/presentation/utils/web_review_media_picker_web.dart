// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter

import 'dart:async';
import 'dart:html' as html;
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
  final input = html.FileUploadInputElement()
    ..accept = 'image/*,video/*'
    ..multiple = multiple;
  input.click();
  await input.onChange.first;

  final files = input.files;
  if (files == null || files.isEmpty) return const [];

  final results = <WebPickedReviewMedia>[];
  for (final file in files) {
    final bytes = await _readBytes(file);
    if (bytes == null || bytes.isEmpty) continue;
    results.add(
      WebPickedReviewMedia(
        fileName: file.name,
        mimeType: file.type.isNotEmpty ? file.type : 'application/octet-stream',
        bytes: bytes,
      ),
    );
  }
  return results;
}

Future<Uint8List?> _readBytes(html.File file) {
  final completer = Completer<Uint8List?>();
  final reader = html.FileReader();

  reader.onError.listen((_) {
    if (!completer.isCompleted) completer.complete(null);
  });
  reader.onLoadEnd.listen((_) {
    final result = reader.result;
    if (result is ByteBuffer) {
      if (!completer.isCompleted) {
        completer.complete(Uint8List.view(result));
      }
      return;
    }
    if (result is Uint8List) {
      if (!completer.isCompleted) completer.complete(result);
      return;
    }
    if (!completer.isCompleted) completer.complete(null);
  });

  reader.readAsArrayBuffer(file);
  return completer.future;
}
