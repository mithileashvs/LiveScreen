import 'package:flutter/foundation.dart';
import '../models/user_role.dart';
import '../models/user_session.dart';
import 'auth_exception.dart';
import 'supabase_auth_service.dart';

/// PART 11: the single place the rest of the app asks "who's logged in?"
/// or "log this person in/out". Everything else (LoginScreen, RoleGate,
/// the Profile screen's admin entry point) depends on this abstraction,
/// never on how authentication is actually performed — so swapping in
/// Firebase/Supabase/a real backend later means writing one new
/// implementation of this class, not touching any screen.
abstract class AuthService extends ChangeNotifier {
  /// Null when nobody is logged in.
  UserSession? get currentSession;

  bool get isLoggedIn => currentSession != null;

  /// Throws [AuthException] on invalid credentials — never crashes, and
  /// never leaves [currentSession] partially updated on failure.
  Future<UserSession> login(String userId, String password);

  Future<void> logout();
}

class _DemoAccount {
  final String userId;
  final String password;
  final UserRole role;
  const _DemoAccount(this.userId, this.password, this.role);
}

/// PART 10/11: temporary local/demo authentication. Three hardcoded
/// accounts, no network calls, no persistence beyond the current app
/// session — deliberately the simplest thing that satisfies the current
/// requirement without gesturing at infrastructure (Firebase/Supabase/etc.)
/// the project doesn't have yet.
class DemoAuthService extends AuthService {
  static const _accounts = [
    _DemoAccount('user_demo', 'User@123', UserRole.user),
    _DemoAccount('theatre_demo', 'Theatre@123', UserRole.theatreAdmin),
    _DemoAccount('producer_demo', 'Producer@123', UserRole.producer),
  ];

  UserSession? _currentSession;

  @override
  UserSession? get currentSession => _currentSession;

  @override
  Future<UserSession> login(String userId, String password) async {
    // A small delay so the login screen's loading state has something
    // real to show, rather than resolving instantly every time.
    await Future.delayed(const Duration(milliseconds: 400));

    for (final account in _accounts) {
      if (account.userId == userId && account.password == password) {
        final session = UserSession(userId: account.userId, role: account.role);
        _currentSession = session;
        notifyListeners();
        return session;
      }
    }

    throw const AuthException('Incorrect ID or password.');
  }

  @override
  Future<void> logout() async {
    _currentSession = null;
    notifyListeners();
  }
}

/// A single shared instance, mirroring the same pattern already used for
/// [theatreRepository] elsewhere in the app.
///
/// Backed by Supabase now (see SupabaseAuthService) — DemoAuthService above
/// is kept in this file as a reference/fallback implementation (e.g. for
/// running the UI without a Supabase project configured yet) but is no
/// longer what the app actually uses.
final AuthService authService = SupabaseAuthService();
