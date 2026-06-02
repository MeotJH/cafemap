import 'package:front/domain/entities/brand.dart';
import 'package:front/domain/entities/menu.dart';

// 메뉴 저장소 객체이다
abstract class MenuRepository {
  // 브랜드 목록을 가져온다.
  Future<List<Brand>> fetchBrands();

  // 메뉴 목록을 가져온다.
  Future<List<Menu>> fetchMenus(String brandId, {String? query});
}
