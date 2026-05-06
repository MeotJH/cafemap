import 'package:flutter/widgets.dart';

import 'naver_map_view_stub.dart'
    if (dart.library.html) 'naver_map_view_web.dart'
    if (dart.library.io) 'naver_map_view_mobile.dart';

// ???? ??? ?? ??? ???? ?????.
Widget buildNaverMapView({
  Key? key,
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
  return KeyedSubtree(
    key: key,
    child: buildNaverMapViewImpl(
      context: context,
      lat: lat,
      lng: lng,
      zoom: zoom,
      markers: markers,
      selectedMarkerId: selectedMarkerId,
      onMarkerTap: onMarkerTap,
      onMapReady: onMapReady,
      onCameraIdle: onCameraIdle,
    ),
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
  final String? badgeText;

  const MapMarkerData({
    required this.id,
    required this.lat,
    required this.lng,
    required this.caption,
    this.description,
    this.iconUrl,
    this.useDefaultMarker = false,
    this.badgeText,
  });
}

class MapViewportData {
  final double lat;
  final double lng;
  final double zoom;
  final double? southLat;
  final double? westLng;
  final double? northLat;
  final double? eastLng;

  const MapViewportData({
    required this.lat,
    required this.lng,
    required this.zoom,
    this.southLat,
    this.westLng,
    this.northLat,
    this.eastLng,
  });

  bool get hasBounds =>
      southLat != null &&
      westLng != null &&
      northLat != null &&
      eastLng != null;
}
