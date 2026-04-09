import 'dart:html' as html;

Future<bool> openExternalLink(String url, {String target = '_blank'}) async {
  final opened = html.window.open(url, target);
  return opened != null;
}
