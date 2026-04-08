import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_naver_map_web/flutter_naver_map_web.dart';

import 'naver_map_view.dart';

// ?(Chrome ?)? ??? ?? ? ????.
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
  final clientId = dotenv.env['NAVER_MAP_CLIENT_ID'];
  if (clientId == null || clientId.isEmpty) {
    return const Center(child: Text('NAVER_MAP_CLIENT_ID is missing in .env'));
  }

  final places = markers
      .map(
        (marker) => Place(
          id: marker.id,
          name: marker.caption,
          latitude: marker.lat,
          longitude: marker.lng,
          description: marker.description,
          iconUrl: marker.iconUrl,
        ),
      )
      .toList();

  if (kDebugMode) {
    debugPrint(
      '[NaverMapWeb] places=${places.length} '
      'markers=${markers.length} '
      'sample=${places.isNotEmpty ? '${places.first.name}(${places.first.latitude},${places.first.longitude})' : 'none'}',
    );
  }

  final map = NaverMapWeb(
    clientId: clientId,
    initialLatitude: lat,
    initialLongitude: lng,
    initialZoom: zoom.round(),
    zoomControl: false,
    places: places,
    selectedPlaceId: selectedMarkerId,
    onMarkerClick: (place) => onMarkerTap?.call(place.id),
    onMapReady: (map) {
      _attachCameraIdleListener(
        map: map,
        onCameraIdle: onCameraIdle,
      );
      onMapReady?.call(map);
      final viewport = _viewportDataFromMap(map);
      if (viewport != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          onCameraIdle?.call(viewport);
        });
      }
    },
  );
  return map;
}

void _attachCameraIdleListener({
  required NaverMap map,
  ValueChanged<MapViewportData>? onCameraIdle,
}) {
  if (onCameraIdle == null) return;
  try {
    final globalThis = globalContext;
    final naver = globalThis.getProperty('naver'.toJS)! as JSObject;
    final maps = naver.getProperty('maps'.toJS)! as JSObject;
    final event = maps.getProperty('Event'.toJS)! as JSObject;
    final addListener = event.getProperty('addListener'.toJS)! as JSFunction;

    final listener = (() {
      final viewport = _viewportDataFromMap(map);
      if (viewport != null) {
        onCameraIdle(viewport);
      }
    }).toJS;

    addListener.callAsFunction(null, map as JSAny, 'idle'.toJS, listener);
  } catch (e) {
    if (kDebugMode) {
      debugPrint('Failed to attach web map idle listener: $e');
    }
  }
}

MapViewportData? _viewportDataFromMap(NaverMap map) {
  try {
    final center = map.getCenter() as JSObject;
    final latValue = center.callMethod('lat'.toJS);
    final lngValue = center.callMethod('lng'.toJS);
    final lat = (latValue.dartify() as num).toDouble();
    final lng = (lngValue.dartify() as num).toDouble();
    return MapViewportData(
      lat: lat,
      lng: lng,
      zoom: map.getZoom().toDouble(),
    );
  } catch (e) {
    if (kDebugMode) {
      debugPrint('Failed to read web map viewport: $e');
    }
    return null;
  }
}
