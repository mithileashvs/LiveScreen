import 'package:supabase_flutter/supabase_flutter.dart' hide AuthException;
import '../../admin/services/selected_theatre.dart';
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
    // Second/third Theatre Admin demo accounts — see
    // supabase/migrations/0005_dev_theatre_admin_demo_seed.sql, which
    // grants TA-0002/TA-0003 verified ownership of 'tavi'/'MiVa Screens'.
    'theatre_demo_2': 'theatre_demo_2@livescreen.local',
    'theatre_demo_3': 'theatre_demo_3@livescreen.local',
    'producer_demo': 'producer_demo@livescreen.local',
    'platform_admin_demo': 'platform_admin_demo@livescreen.local',
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
  Future<UserSession> signUp({
    required String email,
    required String password,
    required UserRole role,
    required String displayName,
  }) async {
    final roleString = _roleToString(role);

    AuthResponse response;
    try {
      response = await _client.auth.signUp(
        email: email,
        password: password,
        // Read by the handle_new_user() trigger (0001/0002 migrations) to
        // set profiles.role/display_name server-side on insert — the same
        // mechanism the four existing demo accounts rely on. Nothing about
        // role assignment happens client-side beyond this signup call.
        data: {'role': roleString, 'display_name': displayName},
      );
    } catch (e) {
      throw AuthException(_signUpErrorMessage(e));
    }

    final authUser = response.user;
    if (authUser == null) {
      throw const AuthException('Could not create the account. Please try again.');
    }

    // Supabase Auth signUp() does not always return an active session
    // (e.g. if email confirmation is required on this project) — if so,
    // fall through to a normal login with the credentials just created,
    // rather than leaving the caller without a session.
    if (response.session == null) {
      return login(email, password);
    }

    final session = UserSession(userId: email, role: role);
    _cachedSession = session;
    notifyListeners();
    return session;
  }

  String _roleToString(UserRole role) {
    switch (role) {
      case UserRole.user:
        return 'user';
      case UserRole.theatreAdmin:
        return 'theatre_admin';
      case UserRole.producer:
        return 'producer';
      case UserRole.platformAdmin:
        return 'platform_admin';
    }
  }

  String _signUpErrorMessage(Object error) {
    final message = error.toString().toLowerCase();
    if (message.contains('already registered') || message.contains('already exists')) {
      return 'An account with this email already exists.';
    }
    if (message.contains('password')) {
      return 'Password does not meet the minimum requirements.';
    }
    return 'Could not create the account. Please check your details and try again.';
  }

  @override
  Future<void> logout() async {
    await _client.auth.signOut();
    _cachedSession = null;
    selectedTheatreContext.clear();
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
      case 'platform_admin':
        return UserRole.platformAdmin;
      default:
        return null;
    }
  }
}
