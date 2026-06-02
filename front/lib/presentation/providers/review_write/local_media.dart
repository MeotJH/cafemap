import 'dart:typed_data';

/// 업로드 전에만 존재하는 로컬 미디어 모델.
///
/// presigned 업로드가 끝난 뒤 사용하는 [ReviewMediaItem]과 분리한 이유는,
/// 이 객체가 원본 바이트와 같은 클라이언트 전용 정보를 들고 있기 때문이다.
class ReviewWriteLocalMedia {
  final String fileName;
  final String contentType;
  final Uint8List bytes;
  final int? durationMs;

  const ReviewWriteLocalMedia({
    required this.fileName,
    required this.contentType,
    required this.bytes,
    this.durationMs,
  });

  String get type =>
      contentType.toLowerCase().startsWith('video/') ? 'video' : 'image';
}
