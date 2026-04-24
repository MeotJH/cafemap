import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:front/app/app.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:front/presentation/utils/naver_map_init.dart';
import 'package:front/presentation/providers/app_providers.dart';
import 'package:flutter/foundation.dart';

FirebaseOptions _firebaseOptionsFromEnv() {
  const requiredKeys = <String>[
    'FIREBASE_API_KEY',
    'FIREBASE_APP_ID',
    'FIREBASE_MESSAGING_SENDER_ID',
    'FIREBASE_PROJECT_ID',
  ];

  final missing = requiredKeys
      .where((key) => (dotenv.env[key] ?? '').trim().isEmpty)
      .toList();
  if (missing.isNotEmpty) {
    throw StateError(
      'Missing Firebase env keys: ${missing.join(', ')}. '
      'Add them to front/.env',
    );
  }

  return FirebaseOptions(
    apiKey: dotenv.env['FIREBASE_API_KEY']!,
    appId: dotenv.env['FIREBASE_APP_ID']!,
    messagingSenderId: dotenv.env['FIREBASE_MESSAGING_SENDER_ID']!,
    projectId: dotenv.env['FIREBASE_PROJECT_ID']!,
    authDomain: dotenv.env['FIREBASE_AUTH_DOMAIN'],
    storageBucket: dotenv.env['FIREBASE_STORAGE_BUCKET'],
  );
}

Future<void> _loadEnv() async {
  // Deploy copies the selected environment into `.env`; load one source of truth
  // so local `.env` values cannot be overridden by stale production values.
  await dotenv.load(fileName: '.env', isOptional: true);
  final apiBaseUrl = dotenv.env['API_BASE_URL'] ?? '';
  if (kDebugMode && apiBaseUrl.contains('.nip.io')) {
    dotenv.env['API_BASE_URL'] = 'http://localhost:8080';
  }
  debugPrint(
    'Env loaded: API_BASE_URL=${dotenv.env['API_BASE_URL']}, '
    'NAVER_MAP_CLIENT_ID=${dotenv.env['NAVER_MAP_CLIENT_ID']?.isNotEmpty == true ? 'set' : 'missing'}',
  );
}

// ? ?? ????. Riverpod ????? ???? ????.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    usePathUrlStrategy(); // ? ???? ??? ????.

    await _loadEnv();
    if (kIsWeb) {
      await Firebase.initializeApp(options: _firebaseOptionsFromEnv());
    } else {
      await Firebase.initializeApp();
    }

    final clientId = dotenv.env['NAVER_MAP_CLIENT_ID'];
    if (clientId == null || clientId.isEmpty) {
      throw StateError('NAVER_MAP_CLIENT_ID is missing in .env');
    }
    await initNaverMap(clientId);

    final container = ProviderContainer();

    runApp(
      UncontrolledProviderScope(
        container: container,
        child: const CafeMapApp(),
      ),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(container.read(currentLocationProvider.notifier).initialize());
    });
  } catch (error, stackTrace) {
    debugPrint('App bootstrap failed: $error');
    debugPrintStack(stackTrace: stackTrace);
    runApp(_BootstrapErrorApp(message: '$error'));
  }
}

class _BootstrapErrorApp extends StatelessWidget {
  final String message;

  const _BootstrapErrorApp({required this.message});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SelectableText('App startup failed:\n$message'),
          ),
        ),
      ),
    );
  }
}
