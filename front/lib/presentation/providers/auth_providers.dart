import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:front/domain/entities/auth_context.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthController {
  final FirebaseAuth _auth;
  static const String _defaultKakaoProviderId = 'oidc.kakao';
  static Future<void>? _googleInitFuture;

  AuthController(this._auth);

  String get _kakaoProviderId {
    final providerId = dotenv.env['KAKAO_FIREBASE_PROVIDER_ID']?.trim();
    if (providerId == null || providerId.isEmpty) {
      return _defaultKakaoProviderId;
    }
    return providerId;
  }

  Future<void> _ensureGoogleInitialized() {
    return _googleInitFuture ??= GoogleSignIn.instance.initialize();
  }

  Future<void> signInWithGoogle() async {
    if (kIsWeb) {
      final provider = GoogleAuthProvider();
      await _auth.signInWithPopup(provider);
      return;
    }

    await _ensureGoogleInitialized();
    final googleUser = await GoogleSignIn.instance.authenticate();

    final googleAuth = googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      idToken: googleAuth.idToken,
    );
    await _auth.signInWithCredential(credential);
  }

  Future<void> signInWithKakao() async {
    final provider = OAuthProvider(_kakaoProviderId);
    if (kIsWeb) {
      await _auth.signInWithPopup(provider);
      return;
    }
    await _auth.signInWithProvider(provider);
  }

  Future<void> signOut() async {
    await _auth.signOut();
    if (!kIsWeb) {
      await _ensureGoogleInitialized();
      await GoogleSignIn.instance.signOut();
    }
  }

  Future<AuthContext?> getAuthContext() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    final token = await user.getIdToken();
    if (token == null || token.isEmpty) return null;

    return AuthContext(
      idToken: token,
      uid: user.uid,
      email: user.email ?? '',
      name: user.displayName ?? '',
      picture: user.photoURL ?? '',
      provider: _providerForUser(user),
    );
  }

  String _providerForUser(User user) {
    final providerIds = user.providerData.map((info) => info.providerId);
    if (providerIds.any((providerId) {
      return providerId == _kakaoProviderId || providerId.contains('kakao');
    })) {
      return 'kakao';
    }
    if (providerIds.contains('google.com')) {
      return 'google';
    }
    return providerIds.isEmpty ? 'firebase' : providerIds.first;
  }

  User? get currentUser => _auth.currentUser;
}

final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

final authControllerProvider = Provider<AuthController>((ref) {
  final auth = ref.watch(firebaseAuthProvider);
  return AuthController(auth);
});

final authStateProvider = StreamProvider<User?>((ref) {
  final auth = ref.watch(firebaseAuthProvider);
  return auth.authStateChanges();
});

final kakaoLoginEnabledProvider = Provider<bool>((ref) {
  final raw = dotenv.env['KAKAO_LOGIN_ENABLED']?.trim().toLowerCase();
  return raw == '1' || raw == 'true' || raw == 'yes' || raw == 'on';
});
