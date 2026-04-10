// 웹 전용 외부 링크 열기 구현이라 `dart:html` 사용 lint를 예외 처리한다.
// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter

import 'dart:html' as html;

// 웹 브라우저에서 새 탭 또는 지정한 타깃으로 외부 링크를 연다.
Future<bool> openExternalLink(String url, {String target = '_blank'}) async {
  html.window.open(url, target);
  return true;
}
