import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';

import 'naver_map_view.dart';

// ???(Android/iOS)? ??? ?? ?? ????.
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
  NaverMapController? mapController;
  return NaverMap(
    options: NaverMapViewOptions(
      initialCameraPosition: NCameraPosition(
        target: NLatLng(lat, lng),
        zoom: zoom,
      ),
    ),
    onMapReady: (controller) async {
      mapController = controller;
      for (final marker in markers) {
        final nMarker = NMarker(
          id: marker.id,
          position: NLatLng(marker.lat, marker.lng),
        );
        if (!marker.useDefaultMarker) {
          // Keep the default marker icon so tap hit-area remains reliable.
          nMarker.setCaption(
            NOverlayCaption(
              text: marker.badgeText ?? '?',
              textSize: (marker.badgeText ?? '').length > 1 ? 12 : 18,
              color: Colors.black,
            ),
          );
        }
        nMarker.setOnTapListener((overlay) {
          onMarkerTap?.call(marker.id);
        });
        controller.addOverlay(nMarker);
      }
      onMapReady?.call(controller);
      final bounds = await controller.getContentBounds();
      onCameraIdle?.call(
        MapViewportData(
          lat: lat,
          lng: lng,
          zoom: zoom,
          southLat: bounds.southWest.latitude,
          westLng: bounds.southWest.longitude,
          northLat: bounds.northEast.latitude,
          eastLng: bounds.northEast.longitude,
        ),
      );
    },
    onCameraIdle: () async {
      final controller = mapController;
      if (controller == null) return;
      final position = await controller.getCameraPosition();
      final bounds = await controller.getContentBounds();
      onCameraIdle?.call(
        MapViewportData(
          lat: position.target.latitude,
          lng: position.target.longitude,
          zoom: position.zoom,
          southLat: bounds.southWest.latitude,
          westLng: bounds.southWest.longitude,
          northLat: bounds.northEast.latitude,
          eastLng: bounds.northEast.longitude,
        ),
      );
    },
  );
}
