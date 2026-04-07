class AuthContext {
  final String idToken;
  final String uid;
  final String email;
  final String name;
  final String picture;

  const AuthContext({
    required this.idToken,
    required this.uid,
    required this.email,
    required this.name,
    required this.picture,
  });
}
