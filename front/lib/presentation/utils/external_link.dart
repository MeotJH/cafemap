import 'external_link_stub.dart'
    if (dart.library.html) 'external_link_web.dart' as impl;

Future<bool> openExternalLink(String url, {String target = '_blank'}) {
  return impl.openExternalLink(url, target: target);
}
