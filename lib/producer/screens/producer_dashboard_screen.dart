import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../auth/services/auth_service.dart';
import '../../auth/screens/login_screen.dart';
import 'my_movies_screen.dart';

/// PART 13: "a minimal clean producer dashboard consistent with the
/// existing application architecture" — placeholder sections only, no
/// functionality beyond navigation, since building out real producer
/// features isn't part of this task.
class ProducerDashboardScreen extends StatelessWidget {
  const ProducerDashboardScreen({super.key});

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
        title: const Text('Producer Dashboard'),
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
          children: const [
            Text('Producer Dashboard', style: AppTextStyles.heading),
            SizedBox(height: 6),
            Text(
              'Manage your movies, trailers, and content associated with '
              'LiveScreen theatres.',
              style: AppTextStyles.body,
            ),
            SizedBox(height: 24),
            _PlaceholderTile(icon: Icons.movie_outlined, title: 'Movies', screen: MyMoviesScreen()),
            _PlaceholderTile(
              icon: Icons.video_library_outlined,
              title: 'Trailers',
              subtitle: 'Trailer is a field on each movie — open Movies',
              screen: MyMoviesScreen(),
            ),
            _PlaceholderTile(
              icon: Icons.perm_media_outlined,
              title: 'Content',
              subtitle: 'Thumbnail/description are fields on each movie — open Movies',
              screen: MyMoviesScreen(),
            ),
            _PlaceholderTile(icon: Icons.person_outline, title: 'Profile'),
          ],
        ),
      ),
    );
  }
}

class _PlaceholderTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? screen;

  const _PlaceholderTile({required this.icon, required this.title, this.subtitle, this.screen});

  @override
  Widget build(BuildContext context) {
    final tappable = screen != null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: tappable
              ? () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen!))
              : null,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(icon, color: AppColors.textMuted),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: AppTextStyles.subheading),
                      if (subtitle != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(subtitle!, style: AppTextStyles.caption),
                        ),
                    ],
                  ),
                ),
                Text(tappable ? 'Open' : 'Coming soon', style: AppTextStyles.caption),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
