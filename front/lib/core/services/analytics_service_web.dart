// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter

import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;

import 'analytics_service.dart';

class _WebAnalyticsService implements AnalyticsService {
  bool _initialized = false;
  String _measurementId = '';

  @override
  Future<void> initialize({String? measurementId}) async {
    final normalized = (measurementId ?? '').trim();
    if (_initialized || normalized.isEmpty) {
      return;
    }

    _measurementId = normalized;
    await _injectGtagScript();
    _bootstrapGtag();
    _initialized = true;
  }

  @override
  void trackEvent(String name, [Map<String, Object?> params = const {}]) {
    if (!_initialized) {
      return;
    }
    _dispatchTrack(<String, Object?>{
      'type': 'event',
      'name': name,
      'params': _sanitizeParams(params),
    });
  }

  @override
  void trackPageView({
    required String path,
    String? location,
    String? title,
  }) {
    if (!_initialized) {
      return;
    }
    _dispatchTrack(<String, Object?>{
      'type': 'page_view',
      'params': <String, Object?>{
        'page_path': path,
        if ((location ?? '').isNotEmpty) 'page_location': location,
        if ((title ?? '').isNotEmpty) 'page_title': title,
      },
    });
  }

  Future<void> _injectGtagScript() {
    final completer = Completer<void>();
    final existing = html.document.querySelector(
      'script[data-ga4-loader="$_measurementId"]',
    );
    if (existing != null) {
      completer.complete();
      return completer.future;
    }

    final script = html.ScriptElement()
      ..async = true
      ..type = 'text/javascript'
      ..dataset['ga4Loader'] = _measurementId
      ..src = 'https://www.googletagmanager.com/gtag/js?id=$_measurementId';

    script.onLoad.first.then((_) => completer.complete());
    script.onError.first.then((_) => completer.complete());
    html.document.head?.append(script);
    return completer.future;
  }

  void _bootstrapGtag() {
    final bootstrap = html.ScriptElement()
      ..type = 'text/javascript'
      ..text = '''
window.dataLayer = window.dataLayer || [];
function gtag(){dataLayer.push(arguments);}
window.gtag = window.gtag || gtag;
gtag('js', new Date());
gtag('config', '$_measurementId', { send_page_view: false });
window.addEventListener('cafemap-ga4-track', function(event) {
  try {
    var payload = typeof event.detail === 'string'
      ? JSON.parse(event.detail)
      : (event.detail || {});
    if (!window.gtag || !payload || !payload.type) return;
    if (payload.type === 'page_view') {
      gtag('event', 'page_view', payload.params || {});
      return;
    }
    if (payload.type === 'event' && payload.name) {
      gtag('event', payload.name, payload.params || {});
    }
  } catch (_) {}
});
''';
    html.document.head?.append(bootstrap);
  }

  Map<String, Object?> _sanitizeParams(Map<String, Object?> params) {
    return {
      for (final entry in params.entries)
        if (entry.value != null) entry.key: entry.value,
    };
  }

  void _dispatchTrack(Map<String, Object?> payload) {
    html.window.dispatchEvent(
      html.CustomEvent(
        'cafemap-ga4-track',
        detail: jsonEncode(payload),
      ),
    );
  }
}

final AnalyticsService analyticsService = _WebAnalyticsService();
