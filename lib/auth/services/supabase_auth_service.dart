import 'package:supabase_flutter/supabase_flutter.dart' hide AuthException;
import '../models/user_role.dart';
import '../models/user_session.dart';
import 'auth_exception.dart';
import 'auth_service.dart';

/// Supabase-backed [AuthService]. Replaces [DemoAuthService] behind the same
/// abstraction — no screen changed to make this swap (LoginScreen, RoleGate,
/// ProfileScreen, AdminDashboardScreen, ProducerDashboardScreen all only
/// ever depended on [AuthService]/[UserSession]/[UserRole]).
///
/// The three demo accounts still work exactly as before, but now backed by
/// real Supabase Auth users instead of a hardcoded in-memory list — see
/// SUPABASE_SETUP.md for how to create them once in your Supabase project
/// (Supabase Auth requires an email address; the demo IDs are mapped to
/// `<id>@livescreen.local` addresses below).
///
/// Role is read from the `profiles` table (not decided client-side), per
/// the requirement that the backend — not just the Flutter enum — knows a
/// user's role.
class SupabaseAuthService extends AuthService {
  final SupabaseClient _client = Supabase.instance.client;

  UserSession? _cachedSession;

  static const Map<String, String> _demoEmails = {
    'user_demo': 'user_demo@livescreen.local',
    'theatre_demo': 'theatre_demo@livescreen.local',
    'producer_demo': 'producer_demo@livescreen.local',
  };

  @override
  UserSession? get currentSession => _cachedSession;

  @override
  Future<UserSession> login(String userId, String password) async {
    // Accepts either a known demo ID or a real email address, so this
    // keeps working once real (non-demo) accounts exist.
    final email = _demoEmails[userId] ?? userId;

    AuthResponse response;
    try {
      response = await _client.auth.signInWithPassword(email: email, password: password);
    } catch (_) {
      // Covers wrong password, unknown email, and any network/Supabase
      // error alike — never crashes, always a clear login-screen message.
      throw const AuthException('Incorrect ID or password.');
    }

    final authUser = response.user;
    if (authUser == null) {
      throw const AuthException('Incorrect ID or password.');
    }

    Map<String, dynamic>? profileRow;
    try {
      profileRow = await _client.from('profiles').select().eq('id', authUser.id).maybeSingle();
    } catch (_) {
      profileRow = null;
    }

    final role = _parseRole(profileRow?['role'] as String?);
    if (role == null) {
      await _client.auth.signOut();
      throw const AuthException(
        'Signed in, but this account has no role assigned in the database. '
        'See SUPABASE_SETUP.md.',
      );
    }

    final session = UserSession(userId: userId, role: role);
    _cachedSession = session;
    notifyListeners();
    return session;
  }

  @override
  Future<void> logout() async {
    await _client.auth.signOut();
    _cachedSession = null;
    notifyListeners();
  }

  UserRole? _parseRole(String? value) {
    switch (value) {
      case 'user':
        return UserRole.user;
      case 'theatre_admin':
        return UserRole.theatreAdmin;
      case 'producer':
        return UserRole.producer;
      default:
        return null;
    }
  }
}
