import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:front/domain/entities/auth_context.dart';

class AuthApi {
  AuthApi({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                connectTimeout: const Duration(seconds: 8),
                receiveTimeout: const Duration(seconds: 8),
                sendTimeout: const Duration(seconds: 8),
              ),
            );

  final Dio _dio;

  String get _baseUrl => dotenv.env['API_BASE_URL'] ?? 'http://localhost:8080';

  Future<void> syncUser(AuthContext auth) async {
    final headers = _authHeaders(auth);
    await _dio.post(
      '$_baseUrl/api/cafemap/auth',
      options: Options(headers: headers),
    );
  }

  Map<String, String> _authHeaders(AuthContext auth) {
    return <String, String>{
      'Authorization': 'Bearer ${auth.toAuthorizationToken()}',
    };
  }
}
