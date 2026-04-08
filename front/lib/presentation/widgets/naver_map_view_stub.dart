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
  ValueChanged<MapViewportData>? onCameraIdle,
}) {
  return const SizedBox.shrink();
}
