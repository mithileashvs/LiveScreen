import 'package:flutter/material.dart';
import '../models/user_role.dart';
import '../services/auth_service.dart';
import '../screens/login_screen.dart';
import '../../screens/user_dashboard_screen.dart';
import '../../admin/screens/admin_dashboard_screen.dart';
import '../../producer/screens/producer_dashboard_screen.dart';

/// PART 13: the ONE place that maps a role to its home screen. LoginScreen
/// and [RoleGate] both call this instead of each hardcoding their own
/// switch — so there's exactly one definition of "where does this role go".
///
/// UserRole.user now opens UserDashboardScreen (the redesigned premium
/// ticket-booking dashboard) instead of the old MainNavScreen bottom-nav
/// layout. MainNavScreen and its four tabs (HomeScreen, ExploreScreen,
/// TicketsScreen, ProfileScreen) are untouched — TicketsScreen and
/// ProfileScreen are simply reused from within the new dashboard instead
/// of being duplicated; HomeScreen/ExploreScreen/MainNavScreen itself are
/// just no longer the User role's entry point.
class RoleRouter {
  static Widget homeFor(UserRole role) {
    switch (role) {
      case UserRole.user:
        return const UserDashboardScreen();
      case UserRole.theatreAdmin:
        return const AdminDashboardScreen();
      case UserRole.producer:
        return const ProducerDashboardScreen();
    }
  }
}

/// PART 14: a defensive check placed at every entry point into a
/// role-specific screen (e.g. the Profile tab's Admin Studio link).
/// LoginScreen already routes correctly on first login — this exists for
/// the case where something still tries to navigate straight to a
/// protected screen (no session, or the wrong role), and redirects
/// instead of exposing it.
class RoleGate extends StatelessWidget {
  final UserRole requiredRole;
  final WidgetBuilder builder;

  const RoleGate({super.key, required this.requiredRole, required this.builder});

  @override
  Widget build(BuildContext context) {
    final session = authService.currentSession;

    if (session == null) {
      return const LoginScreen();
    }
    if (session.role != requiredRole) {
      return RoleRouter.homeFor(session.role);
    }
    return builder(context);
  }
}
