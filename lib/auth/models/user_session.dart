import 'user_role.dart';

/// The identity of whoever is currently logged in (PART 11). Immutable and
/// tiny on purpose — this is the one thing the rest of the app is allowed
/// to know about "who's logged in", regardless of what eventually produces
/// it (demo credentials today, a real backend later).
class UserSession {
  final String userId;
  final UserRole role;

  const UserSession({required this.userId, required this.role});
}
