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
    onMapReady: (map) => onMapReady?.call(map),
  );
  return map;
}
