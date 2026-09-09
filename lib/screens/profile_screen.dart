import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../admin/screens/admin_dashboard_screen.dart';
import '../auth/models/user_role.dart';
import '../auth/services/auth_service.dart';
import '../auth/screens/login_screen.dart';
import '../auth/widgets/role_gate.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    await authService.logout();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    // PART 14: the Admin Studio entry point only appears for the
    // theatre_admin role — a plain user account never sees it, and even if
    // it somehow navigated here directly, RoleGate below would redirect it
    // back to its own home instead of exposing the Admin Studio.
    final isTheatreAdmin = authService.currentSession?.role == UserRole.theatreAdmin;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Profile')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Profile — coming soon', style: AppTextStyles.body),
            const SizedBox(height: 24),
            if (isTheatreAdmin) ...[
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => RoleGate(
                        requiredRole: UserRole.theatreAdmin,
                        builder: (_) => const AdminDashboardScreen(),
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.theaters_outlined),
                label: const Text('Theatre Admin Studio'),
              ),
              const SizedBox(height: 12),
            ],
            OutlinedButton.icon(
              onPressed: () => _logout(context),
              icon: const Icon(Icons.logout),
              label: const Text('Log Out'),
            ),
          ],
        ),
      ),
    );
  }
}
