import 'naver_map_init_stub.dart'
    if (dart.library.html) 'naver_map_init_web.dart'
    if (dart.library.io) 'naver_map_init_mobile.dart';

// ???? ??? ?? SDK ???? ????.
Future<void> initNaverMap(String clientId) {
  return initNaverMapImpl(clientId);
}
