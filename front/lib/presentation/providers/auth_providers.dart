import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:front/domain/entities/auth_context.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthController {
  final FirebaseAuth _auth;
  static Future<void>? _googleInitFuture;

  AuthController(this._auth);

  Future<void> _ensureGoogleInitialized() {
    return _googleInitFuture ??=
        GoogleSignIn.instance.initialize();
  }

  Future<void> signInWithGoogle() async {
    if (kIsWeb) {
      final provider = GoogleAuthProvider();
      await _auth.signInWithPopup(provider);
      return;
    }

    await _ensureGoogleInitialized();
    final googleUser = await GoogleSignIn.instance.authenticate();

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      idToken: googleAuth.idToken,
    );
    await _auth.signInWithCredential(credential);
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
    );
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
