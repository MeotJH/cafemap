import 'package:go_router/go_router.dart';

import 'analytics_service_stub.dart'
    if (dart.library.html) 'analytics_service_web.dart' as impl;

abstract class AnalyticsService {
  Future<void> initialize({String? measurementId});
  void trackPageView({
    required String path,
    String? location,
    String? title,
  });
  void trackEvent(String name, [Map<String, Object?> params = const {}]);
}

AnalyticsService get analyticsService => impl.analyticsService;

void bindAnalyticsRouteTracking(GoRouter router) {
  String? lastTrackedLocation;

  void trackCurrentRoute() {
    final uri = router.routeInformationProvider.value.uri;
    final location = uri.toString().isEmpty ? '/' : uri.toString();
    if (location == lastTrackedLocation) {
      return;
    }
    lastTrackedLocation = location;
    analyticsService.trackPageView(
      path: uri.path.isEmpty ? '/' : uri.path,
      location: location,
      title: _pageTitleForPath(uri.path),
    );
  }

  router.routerDelegate.addListener(trackCurrentRoute);
  trackCurrentRoute();
}

String _pageTitleForPath(String path) {
  if (path == '/') return 'home';
  if (path.startsWith('/rankings/store/')) return 'ranking_store_detail';
  if (path.startsWith('/rankings/')) return 'ranking_detail';
  if (path == '/rankings') return 'rankings';
  if (path.startsWith('/map/store/')) return 'map_store_detail';
  if (path == '/map') return 'map';
  if (path == '/my') return 'my_record';
  if (path == '/auth') return 'auth';
  if (path == '/review/write') return 'review_write';
  if (path.startsWith('/review/select-store')) return 'review_store_select';
  if (path.startsWith('/review/') && path.endsWith('/edit')) return 'review_edit';
  if (path.startsWith('/review/')) return 'review_detail';
  if (path.startsWith('/cafes/')) return 'store_detail';
  return 'page';
}
