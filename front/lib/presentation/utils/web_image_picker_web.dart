import 'dart:async';
import 'dart:html' as html;
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
  final input = html.FileUploadInputElement()
    ..accept = 'image/*'
    ..multiple = multiple;
  input.click();
  await input.onChange.first;

  final files = input.files;
  if (files == null || files.isEmpty) return const [];

  final results = <WebPickedImage>[];
  for (final file in files) {
    final bytes = await _readBytes(file);
    if (bytes == null || bytes.isEmpty) continue;
    results.add(
      WebPickedImage(
        fileName: file.name,
        mimeType: file.type.isNotEmpty ? file.type : 'image/jpeg',
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

