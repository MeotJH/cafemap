import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:front/domain/entities/brand.dart';
import 'package:front/domain/entities/menu.dart';

// 브랜드와 메뉴 조회 API 클라이언트다.
class MenuApi {
  MenuApi({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;

  String get _baseUrl => dotenv.env['API_BASE_URL'] ?? 'http://localhost:8080';

  Future<List<Brand>> fetchBrands() async {
    final response = await _dio.get('$_baseUrl/api/cafemap/brands');
    final data = response.data as List<dynamic>;
    return data
        .map((item) => _brandFromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<Menu>> fetchMenus(String brandId, {String? query}) async {
    final response = await _dio.get(
      '$_baseUrl/api/cafemap/brands/$brandId/menus',
      queryParameters: query == null || query.isEmpty ? null : {'query': query},
    );
    final data = response.data as List<dynamic>;
    return data
        .map((item) => _menuFromJson(item as Map<String, dynamic>))
        .toList();
  }
}

Brand _brandFromJson(Map<String, dynamic> json) {
  return Brand(
    id: json['id'] as String? ?? '',
    name: json['name'] as String? ?? '',
    logoUrl: json['logoUrl'] as String? ?? '',
  );
}

Menu _menuFromJson(Map<String, dynamic> json) {
  return Menu(
    id: json['id'] as String? ?? '',
    brandId: json['brandId'] as String? ?? '',
    name: json['name'] as String? ?? '',
    imageUrl: json['imageUrl'] as String? ?? '',
    category: json['category'] as String? ?? '',
  );
}

