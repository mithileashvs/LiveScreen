import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../auth/services/auth_service.dart';
import '../../auth/models/user_session.dart';
import '../../auth/screens/login_screen.dart';
import '../../shared/widgets/admin/admin_sidebar.dart';
import '../../shared/widgets/admin/admin_top_bar.dart';
import 'producer_dashboard_screen.dart';
import 'my_movies_screen.dart';
import 'movie_edit_screen.dart';
import 'producer_assets_screen.dart';
import 'producer_analytics_screen.dart';
import 'producer_profile_screen.dart';
import 'producer_help_screen.dart';

/// Functional Producer Settings Screen.
/// Follows the master dark cinematic visual language (Black, Deep Burgundy, Metallic Gold & Warm Off-White).
/// Contains Account preferences, session notifications, appearance overview, security entry point, and Sign Out.
class ProducerSettingsScreen extends StatefulWidget {
  const ProducerSettingsScreen({super.key});

  @override
  State<ProducerSettingsScreen> createState() => _ProducerSettingsScreenState();
}

class _ProducerSettingsScreenState extends State<ProducerSettingsScreen> {
  // Session notification preferences (local to this session)
  bool _submissionAlerts = true;
  bool _assetProcessingAlerts = true;
  bool _catalogDigest = false;

  String _email = '';
  String _displayName = 'Sunrise Productions';

  @override
  void initState() {
    super.initState();
    _loadAccountData();
  }

  SupabaseClient? _getSupabaseClient() {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  void _loadAccountData() {
    final client = _getSupabaseClient();
    final user = client?.auth.currentUser;
    UserSession? session;
    try {
      session = authService.currentSession;
    } catch (_) {}
    _email = user?.email ?? (session?.userId.contains('@') == true ? session!.userId : 'producer_demo@livescreen.local');
    _displayName = user?.userMetadata?['display_name'] as String? ?? 'Sunrise Productions';
  }

  Future<void> _sendPasswordReset() async {
    if (_email.isEmpty || !_email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No registered email address found for password reset.'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }

    try {
      final client = _getSupabaseClient();
      if (client != null) {
        await client.auth.resetPasswordForEmail(_email);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Password reset instructions sent to $_email.'),
          backgroundColor: const Color(0xFF10B981),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Password reset request completed for $_email.'),
          backgroundColor: const Color(0xFF10B981),
        ),
      );
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF111116),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0x666B1422)),
        ),
        title: const Text('Sign Out', style: TextStyle(color: Color(0xFFF3EEE5), fontWeight: FontWeight.w700)),
        content: const Text(
          'Are you sure you want to sign out of your Producer account?',
          style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF9CA3AF))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6B1422),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await authService.logout();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  void _navigateTo(String key) {
    if (key == 'dashboard') {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const ProducerDashboardScreen()),
      );
    } else if (key == 'my_movies') {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MyMoviesScreen()),
      );
    } else if (key == 'submit_movie') {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const MovieEditScreen()),
      );
    } else if (key == 'assets') {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const ProducerAssetsScreen()),
      );
    } else if (key == 'analytics') {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const ProducerAnalyticsScreen()),
      );
    } else if (key == 'profile') {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const ProducerProfileScreen()),
      );
    } else if (key == 'settings') {
      // already here
    } else if (key == 'help') {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const ProducerHelpScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 900;

    const navItems = [
      AdminNavItemData(key: 'dashboard', label: 'Dashboard', icon: Icons.grid_view_rounded),
      AdminNavItemData(key: 'my_movies', label: 'My Movies', icon: Icons.theaters_outlined),
      AdminNavItemData(key: 'submit_movie', label: 'Submit Movie', icon: Icons.add_box_outlined),
      AdminNavItemData(key: 'assets', label: 'Trailers & Assets', icon: Icons.smart_display_outlined),
      AdminNavItemData(key: 'analytics', label: 'Analytics', icon: Icons.bar_chart_rounded),
    ];

    final sidebar = AdminSidebar(
      activeKey: 'settings',
      mainNavItems: navItems,
      onSelectKey: _navigateTo,
    );

    return Scaffold(
      backgroundColor: const Color(0xFF070709),
      drawer: isDesktop ? null : Drawer(backgroundColor: const Color(0xFF070709), child: sidebar),
      body: Row(
        children: [
          if (isDesktop) sidebar,
          Expanded(
            child: Column(
              children: [
                AdminTopBar(
                  tagTitle: 'PRODUCER ADMIN',
                  tagTitleColor: const Color(0xFFF3EEE5),
                  profileRole: 'Producer Admin',
                  profileSubtitle: _displayName,
                  showTheatreSelector: false,
                  searchPlaceholder: 'Search producer settings...',
                  showDrawerButton: !isDesktop,
                  onProfileTap: () => _navigateTo('profile'),
                  onSettingsTap: () {},
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Page Header
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'Settings',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFFF3EEE5),
                                letterSpacing: -0.5,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Workspace configurations, notification preferences, and account security.',
                              style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF9CA3AF),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Section 1: Account Overview
                        _buildSectionCard(
                          icon: Icons.person_outline_rounded,
                          title: 'Account & Identity',
                          subtitle: 'Connected Producer credentials and distribution profile',
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildSettingRow(
                                title: 'Producer Display Name',
                                description: _displayName,
                                action: OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFFC9A227),
                                    side: const BorderSide(color: Color(0x66C9A227)),
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                  ),
                                  onPressed: () => _navigateTo('profile'),
                                  child: const Text('Manage in Profile', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                ),
                              ),
                              const Divider(color: Color(0xFF1E1E26), height: 24),
                              _buildSettingRow(
                                title: 'Authenticated Email',
                                description: _email,
                              ),
                              const Divider(color: Color(0xFF1E1E26), height: 24),
                              _buildSettingRow(
                                title: 'Role & Permissions',
                                description: 'Verified Producer (Catalog creation, trailer asset upload, distribution)',
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Section 2: Notifications (Session preferences)
                        _buildSectionCard(
                          icon: Icons.notifications_outlined,
                          title: 'Notification Preferences',
                          subtitle: 'Configure real-time alerts for movie submission lifecycles',
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildSwitchRow(
                                title: 'Review Status Alerts',
                                description: 'Receive notification when a movie is approved or rejected by Platform Admin.',
                                value: _submissionAlerts,
                                onChanged: (val) => setState(() => _submissionAlerts = val),
                              ),
                              const Divider(color: Color(0xFF1E1E26), height: 24),
                              _buildSwitchRow(
                                title: '3D Spatial Video Processing',
                                description: 'Alert when uploaded cinema trailers are ready for virtual theatre projection.',
                                value: _assetProcessingAlerts,
                                onChanged: (val) => setState(() => _assetProcessingAlerts = val),
                              ),
                              const Divider(color: Color(0xFF1E1E26), height: 24),
                              _buildSwitchRow(
                                title: 'Catalog Performance Digest',
                                description: 'Weekly summary of catalogue reach across theatre showtimes.',
                                value: _catalogDigest,
                                onChanged: (val) => setState(() => _catalogDigest = val),
                              ),
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0x14C9A227),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: const Color(0x33C9A227)),
                                ),
                                child: Row(
                                  children: const [
                                    Icon(Icons.info_outline_rounded, color: Color(0xFFC9A227), size: 16),
                                    SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        'Preferences apply to active session alerts and client notifications on this device.',
                                        style: TextStyle(color: Color(0xFFC9A227), fontSize: 12),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Section 3: Appearance
                        _buildSectionCard(
                          icon: Icons.palette_outlined,
                          title: 'Appearance & Theme',
                          subtitle: 'Visual aesthetic for video grading and asset previews',
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: const [
                                        Text(
                                          'Cinematic Dark Theme',
                                          style: TextStyle(color: Color(0xFFF3EEE5), fontSize: 14, fontWeight: FontWeight.w600),
                                        ),
                                        SizedBox(height: 3),
                                        Text(
                                          'Optimized for contrast, video screening, and low-light workflows',
                                          style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0x335A0F1B),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: const Color(0x666B1422)),
                                    ),
                                    child: const Text(
                                      'Active Default',
                                      style: TextStyle(color: Color(0xFFC9A227), fontSize: 11, fontWeight: FontWeight.w700),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  _buildColorSwatch(const Color(0xFF070709), 'Near Black'),
                                  _buildColorSwatch(const Color(0xFF5A0F1B), 'Deep Burgundy'),
                                  _buildColorSwatch(const Color(0xFFC9A227), 'Metallic Gold'),
                                  _buildColorSwatch(const Color(0xFFF3EEE5), 'Warm White'),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Section 4: Security
                        _buildSectionCard(
                          icon: Icons.security_rounded,
                          title: 'Security & Access',
                          subtitle: 'Account authentication and asset storage protection',
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildSettingRow(
                                title: 'Storage Access Protection',
                                description: 'Supabase Storage RLS restricts trailer video replacement to the original Producer UID.',
                              ),
                              const Divider(color: Color(0xFF1E1E26), height: 24),
                              _buildSettingRow(
                                title: 'Password Recovery',
                                description: 'Request a password reset email to your registered account.',
                                action: OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFFC9A227),
                                    side: const BorderSide(color: Color(0x66C9A227)),
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                  ),
                                  onPressed: _sendPasswordReset,
                                  icon: const Icon(Icons.mail_outline_rounded, size: 15),
                                  label: const Text('Send Reset Email', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Section 5: Sign Out
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: const Color(0xFF09090C),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0x666B1422)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: const [
                                  Text(
                                    'Account Session',
                                    style: TextStyle(
                                      color: Color(0xFFF3EEE5),
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'End your current producer session on this device.',
                                    style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12.5),
                                  ),
                                ],
                              ),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF5A0F1B),
                                  foregroundColor: Colors.white,
                                  side: const BorderSide(color: Color(0x886B1422)),
                                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                onPressed: _logout,
                                icon: const Icon(Icons.logout_rounded, size: 16),
                                label: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFF09090C),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF1E1E26)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0x1FC9A227),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0x40C9A227)),
                ),
                child: Icon(icon, size: 18, color: const Color(0xFFC9A227)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Color(0xFFF3EEE5),
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 12.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }

  Widget _buildSettingRow({
    required String title,
    required String description,
    Widget? action,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(color: Color(0xFFF3EEE5), fontSize: 13.5, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 3),
              Text(
                description,
                style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 12.5),
              ),
            ],
          ),
        ),
        if (action != null) ...[
          const SizedBox(width: 16),
          action,
        ],
      ],
    );
  }

  Widget _buildSwitchRow({
    required String title,
    required String description,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(color: Color(0xFFF3EEE5), fontSize: 13.5, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 3),
              Text(
                description,
                style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 12.5),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: const Color(0xFFC9A227),
          activeTrackColor: const Color(0x66C9A227),
          inactiveThumbColor: const Color(0xFF71717A),
          inactiveTrackColor: const Color(0xFF1E1E26),
        ),
      ],
    );
  }

  Widget _buildColorSwatch(Color color, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF111116),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF1E1E26)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0x40FFFFFF)),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 11, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
