import 'package:flutter/widgets.dart';

import 'naver_map_view_stub.dart'
    if (dart.library.html) 'naver_map_view_web.dart'
    if (dart.library.io) 'naver_map_view_mobile.dart';

// ???? ??? ?? ??? ???? ?????.
Widget buildNaverMapView({
  required BuildContext context,
  required double lat,
  required double lng,
  required double zoom,
  required List<MapMarkerData> markers,
  String? selectedMarkerId,
  ValueChanged<String>? onMarkerTap,
  ValueChanged<dynamic>? onMapReady,
}) {
  return buildNaverMapViewImpl(
    context: context,
    lat: lat,
    lng: lng,
    zoom: zoom,
    markers: markers,
    selectedMarkerId: selectedMarkerId,
    onMarkerTap: onMarkerTap,
    onMapReady: onMapReady,
  );
}

// ??? ??? ?? ????.
class MapMarkerData {
  final String id;
  final double lat;
  final double lng;
  final String caption;
  final String? description;
  final String? iconUrl;
  final bool useDefaultMarker;

  const MapMarkerData({
    required this.id,
    required this.lat,
    required this.lng,
    required this.caption,
    this.description,
    this.iconUrl,
    this.useDefaultMarker = false,
  });
}
