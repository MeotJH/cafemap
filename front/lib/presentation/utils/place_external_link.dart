import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:front/presentation/utils/external_link.dart';

String? buildPlaceExternalLink({
  required String name,
  String address = '',
  String directLink = '',
}) {
  final trimmedDirectLink = directLink.trim();
  final directUri = Uri.tryParse(trimmedDirectLink);
  if (directUri != null &&
      (directUri.scheme == 'http' || directUri.scheme == 'https')) {
    return directUri.toString();
  }

  final query = [name.trim(), address.trim()]
      .where((item) => item.isNotEmpty)
      .join(' ');
  if (query.isEmpty) return null;

  return 'https://map.kakao.com/link/search/${Uri.encodeComponent(query)}';
}

bool hasPlaceExternalLink({
  required String name,
  String address = '',
  String directLink = '',
}) {
  return buildPlaceExternalLink(
        name: name,
        address: address,
        directLink: directLink,
      ) !=
      null;
}

Future<bool> openPlaceExternalLink({
  required String name,
  String address = '',
  String directLink = '',
}) async {
  final url = buildPlaceExternalLink(
    name: name,
    address: address,
    directLink: directLink,
  );
  if (url == null) return false;

  if (kIsWeb) {
    return openExternalLink(url, target: '_blank');
  }

  return launchUrl(
    Uri.parse(url),
    mode: LaunchMode.externalApplication,
    webOnlyWindowName: '_blank',
  );
}
