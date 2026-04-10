// 웹 전용 파일 선택 구현이라 `dart:html` 사용 lint를 예외 처리한다.
// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter

import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';

// 웹 이미지 선택 결과를 전달하는 값 객체다.
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

// 브라우저 파일 선택기를 열어 리뷰 이미지를 읽는다.
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

// 브라우저 FileReader를 사용해 업로드 대상 이미지를 바이트로 읽는다.
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
