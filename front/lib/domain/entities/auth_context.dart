import 'dart:convert';

class AuthContext {
  final String idToken;
  final String uid;
  final String email;
  final String name;
  final String picture;
  final String provider;

  const AuthContext({
    required this.idToken,
    required this.uid,
    required this.email,
    required this.name,
    required this.picture,
    required this.provider,
  });

  String toAuthorizationToken() {
    final payload = <String, String>{
      'uid': uid,
      'email': email,
      'name': name,
      'picture': picture,
      'provider': provider,
    };
    return 'cafemap-auth:${base64Url.encode(utf8.encode(jsonEncode(payload)))}';
  }
}
