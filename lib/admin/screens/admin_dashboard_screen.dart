import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../auth/services/auth_service.dart';
import '../../auth/screens/login_screen.dart';
import 'theatre_list_screen.dart';

/// PART 1: entry point into the Admin Studio.
///
/// The spec sketches Theatres / Theatre Configuration / Seating / Speakers /
/// Screen / Room-Acoustics / Movie / Preview & Publish as sibling sections.
/// In practice, every one of those except "Theatres" itself is a property
/// of ONE theatre being edited — so here they're implemented as tabs inside
/// [TheatreEditorScreen] for a specific theatre, rather than as separate
/// top-level destinations an admin would have to first pick a theatre for
/// anyway. This dashboard keeps "Theatres" as the one true top-level
/// section; everything else is reached by opening a theatre.
class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Theatre Admin Studio'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Log out',
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Manage Your Venues', style: AppTextStyles.heading),
            const SizedBox(height: 6),
            const Text(
              'Configure real theatres — room, screen, seating, speakers, '
              'and acoustics — then preview any seat before publishing.',
              style: AppTextStyles.body,
            ),
            const SizedBox(height: 24),
            _DashboardCard(
              icon: Icons.theaters,
              title: 'Theatres',
              subtitle: 'Create, edit, and publish theatre configurations',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const TheatreListScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _DashboardCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.accent),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTextStyles.subheading),
                    const SizedBox(height: 2),
                    Text(subtitle, style: AppTextStyles.caption),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}
