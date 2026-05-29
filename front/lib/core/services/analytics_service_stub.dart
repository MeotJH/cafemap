import 'analytics_service.dart';

class _NoopAnalyticsService implements AnalyticsService {
  @override
  Future<void> initialize({String? measurementId}) async {}

  @override
  void trackEvent(String name, [Map<String, Object?> params = const {}]) {}

  @override
  void trackPageView({
    required String path,
    String? location,
    String? title,
  }) {}
}

final AnalyticsService analyticsService = _NoopAnalyticsService();
