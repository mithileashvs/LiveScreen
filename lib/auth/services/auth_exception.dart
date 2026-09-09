/// Thrown by [AuthService.login] on invalid credentials. A plain,
/// catchable exception rather than an assertion or a crash (PART 12:
/// "Invalid credentials must NOT crash the application").
class AuthException implements Exception {
  final String message;
  const AuthException(this.message);

  @override
  String toString() => message;
}
