import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:front/data/mock/mock_data.dart';
import 'package:front/data/remote/ranking_api.dart';
import 'package:front/data/repositories/remote_ranking_repository.dart';
import 'package:front/data/remote/auth_api.dart';
import 'package:front/data/remote/review_api.dart';
import 'package:front/data/repositories/remote_review_repository.dart';
import 'package:front/data/remote/store_api.dart';
import 'package:front/data/repositories/remote_store_repository.dart';
import 'package:front/data/remote/menu_api.dart';
import 'package:front/data/remote/place_search_api.dart';
import 'package:front/data/repositories/remote_menu_repository.dart';
import 'package:front/data/repositories/remote_place_search_repository.dart';
import 'package:front/domain/repositories/ranking_repository.dart';
import 'package:front/domain/repositories/review_repository.dart';
import 'package:front/domain/repositories/store_repository.dart';
import 'package:front/domain/repositories/menu_repository.dart';
import 'package:front/domain/repositories/place_search_repository.dart';

class AppLocationState {
  final double latitude;
  final double longitude;
  final bool fromDevice;

  const AppLocationState({
    required this.latitude,
    required this.longitude,
    required this.fromDevice,
  });
}

class AppLocationController extends Notifier<AppLocationState> {
  static const double defaultLat = 37.5665;
  static const double defaultLng = 126.9780;

  @override
  AppLocationState build() {
    return const AppLocationState(
      latitude: defaultLat,
      longitude: defaultLng,
      fromDevice: false,
    );
  }

  Future<void> initialize() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (kDebugMode) {
          debugPrint(
            '[Location] serviceDisabled -> fallback=$defaultLat,$defaultLng',
          );
        }
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (kDebugMode) {
          debugPrint(
            '[Location] permissionDenied($permission) '
            '-> fallback=$defaultLat,$defaultLng',
          );
        }
        return;
      }

      final position = await Geolocator.getCurrentPosition();
      state = AppLocationState(
        latitude: position.latitude,
        longitude: position.longitude,
        fromDevice: true,
      );
    } catch (_) {
      if (kDebugMode) {
        debugPrint('[Location] exception -> fallback=$defaultLat,$defaultLng');
      }
      // ?? ???, ???? ??, ?? ?? ? ?? ??? ????.
    }
  }
}

final currentLocationProvider =
    NotifierProvider<AppLocationController, AppLocationState>(
  AppLocationController.new,
);

// ?? ??? ??? ???? Provider?.
final mockDataSourceProvider = Provider<MockDataSource>((ref) {
  return MockDataSource();
});

// ?? ??? Provider?.
final rankingRepositoryProvider = Provider<RankingRepository>((ref) {
  final api = ref.watch(rankingApiProvider);
  return RemoteRankingRepository(api);
});

// ?? ??? Provider?.
final storeRepositoryProvider = Provider<StoreRepository>((ref) {
  final api = ref.watch(storeApiProvider);
  return RemoteStoreRepository(api);
});

// ?? ??? Provider?.
final reviewRepositoryProvider = Provider<ReviewRepository>((ref) {
  final api = ref.watch(reviewApiProvider);
  return RemoteReviewRepository(api);
});

// ?? API ?????? ????.
final reviewApiProvider = Provider<ReviewApi>((ref) {
  return ReviewApi();
});

// ?? API ?????? ????.
final rankingApiProvider = Provider<RankingApi>((ref) {
  return RankingApi();
});

// ?? API ?????? ????.
final authApiProvider = Provider<AuthApi>((ref) {
  return AuthApi();
});

// ?? API ?????? ????.
final menuApiProvider = Provider<MenuApi>((ref) {
  return MenuApi();
});

// ?? API ?????? ????.
final storeApiProvider = Provider<StoreApi>((ref) {
  return StoreApi();
});

// ?? ?? API ?????? ????.
final placeSearchApiProvider = Provider<PlaceSearchApi>((ref) {
  return PlaceSearchApi();
});

// ?? ??? Provider?.
final menuRepositoryProvider = Provider<MenuRepository>((ref) {
  final api = ref.watch(menuApiProvider);
  return RemoteMenuRepository(api);
});

// ?? ?? ??? Provider?.
final placeSearchRepositoryProvider = Provider<PlaceSearchRepository>((ref) {
  final api = ref.watch(placeSearchApiProvider);
  return RemotePlaceSearchRepository(api);
});
