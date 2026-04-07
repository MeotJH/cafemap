import 'package:front/data/remote/menu_api.dart';
import 'package:front/domain/entities/brand.dart';
import 'package:front/domain/entities/menu.dart';
import 'package:front/domain/repositories/menu_repository.dart';

// ?? API ??? ?? ??? ????.
class RemoteMenuRepository implements MenuRepository {
  final MenuApi _api;

  RemoteMenuRepository(this._api);

  @override
  Future<List<Brand>> fetchBrands() {
    return _api.fetchBrands();
  }

  @override
  Future<List<Menu>> fetchMenus(String brandId, {String? query}) {
    return _api.fetchMenus(brandId, query: query);
  }
}
