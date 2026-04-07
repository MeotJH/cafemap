import 'package:flutter/widgets.dart';

import 'naver_map_view.dart';

// ???? ?? ?????? ?? ??? ????.
Widget buildNaverMapViewImpl({
  required BuildContext context,
  required double lat,
  required double lng,
  required double zoom,
  required List<MapMarkerData> markers,
  String? selectedMarkerId,
  ValueChanged<String>? onMarkerTap,
  ValueChanged<dynamic>? onMapReady,
}) {
  return const SizedBox.shrink();
}
