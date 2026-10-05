import 'package:flutter/material.dart';
import '../admin/screens/admin_dashboard_screen.dart';
import '../auth/models/user_role.dart';
import '../auth/services/auth_service.dart';
import '../auth/screens/login_screen.dart';
import '../auth/widgets/role_gate.dart';
import '../theme/customer_theme.dart';
import 'offers_screen.dart';
import 'watchlist_screen.dart';

/// Clean account and profile screen matching the LiveScreen visual system.
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
    final session = () {
      try {
        return authService.currentSession;
      } catch (_) {
        return null;
      }
    }();
    final isTheatreAdmin = session?.role == UserRole.theatreAdmin;
    final userId = session?.userId ?? 'Alex';

    return Scaffold(
      backgroundColor: CustomerColors.background,
      appBar: AppBar(
        title: const Text(
          'PROFILE',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: CustomerColors.textPrimary,
            letterSpacing: 1.5,
          ),
        ),
        backgroundColor: CustomerColors.surface,
        foregroundColor: CustomerColors.textPrimary,
        elevation: 0,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(color: CustomerColors.borderSubtle, height: 1),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Information Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: CustomerColors.surfaceCard,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: CustomerColors.borderGold, width: 1.2),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: CustomerColors.gold,
                    child: Text(
                      userId.substring(0, 1).toUpperCase(),
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: CustomerColors.background,
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userId,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: CustomerColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          session != null
                              ? '${session.role.name.toUpperCase()} ACCOUNT'
                              : 'LIVESCREEN MEMBER',
                          style: const TextStyle(
                            color: CustomerColors.gold,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // My Watchlist Action Card
            _actionCard(
              icon: Icons.bookmark_border_rounded,
              title: 'My Watchlist',
              subtitle: 'View saved movies, shows & 3D venue experiences',
              badge: 'Saved',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const WatchlistScreen()),
              ),
            ),
            const SizedBox(height: 14),

            // Offers & Discounts Action Card
            _actionCard(
              icon: Icons.local_offer_outlined,
              title: 'Offers & Discounts',
              subtitle: 'Explore active promo codes & cinema perks',
              badge: 'Exclusive',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const OffersScreen()),
              ),
            ),
            const SizedBox(height: 24),

            // Personal Details & Preferences
            _sectionCard(
              title: 'Personal Details & Preferences',
              children: [
                _tile(Icons.location_on_outlined, 'Location', 'Mumbai, India'),
                _tile(Icons.language_rounded, 'Preferred Language', 'English'),
                _tile(Icons.surround_sound_outlined, 'Audio Preference', 'Dolby Atmos / Spatial 3D'),
              ],
            ),
            const SizedBox(height: 20),

            // Notifications
            _sectionCard(
              title: 'Notifications',
              children: [
                _tile(Icons.notifications_outlined, 'Booking Reminders', 'Enabled'),
                _tile(Icons.local_offer_outlined, 'Promotions & Offers', 'Subscribed'),
              ],
            ),
            const SizedBox(height: 20),

            // Role Management (Admin Studio if authorized)
            if (isTheatreAdmin) ...[
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: CustomerColors.surfaceCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: CustomerColors.borderGold),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: CustomerColors.goldSubtle,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.admin_panel_settings, color: CustomerColors.gold),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Theatre Admin Studio',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: CustomerColors.textPrimary,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Manage venues, seating layouts & 3D acoustics',
                            style: TextStyle(color: CustomerColors.textSecondary, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
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
                      style: ElevatedButton.styleFrom(
                        backgroundColor: CustomerColors.burgundy,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Open Studio'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Sign Out Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: () => _logout(context),
                icon: const Icon(Icons.logout_rounded, color: CustomerColors.error, size: 20),
                label: const Text(
                  'Sign Out',
                  style: TextStyle(
                    color: CustomerColors.error,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: CustomerColors.borderBurgundy),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _sectionCard({required String title, required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: CustomerColors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CustomerColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: CustomerColors.gold,
              ),
            ),
          ),
          const Divider(color: CustomerColors.borderSubtle, height: 1),
          ...children,
        ],
      ),
    );
  }

  Widget _tile(IconData icon, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          Icon(icon, color: CustomerColors.gold, size: 20),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: CustomerColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: CustomerColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: CustomerColors.textMuted, size: 18),
        ],
      ),
    );
  }

  Widget _actionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required String badge,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: CustomerColors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CustomerColors.borderGoldSubtle),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: CustomerColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: CustomerColors.borderGold.withValues(alpha: 0.6)),
                  ),
                  child: Icon(icon, color: CustomerColors.gold, size: 22),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: CustomerColors.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: CustomerColors.burgundyDark.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: CustomerColors.borderBurgundy),
                            ),
                            child: Text(
                              badge,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: CustomerColors.goldLight,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: CustomerColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: CustomerColors.gold,
                  size: 15,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
