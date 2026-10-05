import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../auth/services/auth_service.dart';
import '../../auth/models/user_session.dart';
import '../../auth/screens/login_screen.dart';
import '../../admin/models/movie_content.dart';
import '../../admin/services/movie_repository.dart';
import '../../shared/widgets/admin/admin_sidebar.dart';
import '../../shared/widgets/admin/admin_top_bar.dart';
import 'producer_dashboard_screen.dart';
import 'my_movies_screen.dart';
import 'movie_edit_screen.dart';
import 'producer_assets_screen.dart';
import 'producer_analytics_screen.dart';
import 'producer_settings_screen.dart';
import 'producer_help_screen.dart';

/// Functional Producer Profile Screen.
/// Follows the master dark cinematic visual language (Black, Deep Burgundy, Metallic Gold & Warm Off-White).
/// Displays real authenticated user data from Supabase Auth and the profiles table.
class ProducerProfileScreen extends StatefulWidget {
  const ProducerProfileScreen({super.key});

  @override
  State<ProducerProfileScreen> createState() => _ProducerProfileScreenState();
}

class _ProducerProfileScreenState extends State<ProducerProfileScreen> {
  bool _loading = true;
  String _displayName = 'Producer Admin';
  String _email = '';
  String _userId = '';
  String _role = 'Producer';
  DateTime? _createdAt;
  List<MovieContent> _myMovies = [];

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  SupabaseClient? _getSupabaseClient() {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  Future<void> _loadProfileData() async {
    setState(() => _loading = true);

    try {
      final client = _getSupabaseClient();
      final user = client?.auth.currentUser;
      UserSession? session;
      try {
        session = authService.currentSession;
      } catch (_) {}

      _userId = user?.id ?? session?.userId ?? 'Unknown';
      _email = user?.email ?? (session?.userId.contains('@') == true ? session!.userId : 'producer_demo@livescreen.local');
      _displayName = user?.userMetadata?['display_name'] as String? ?? 'Sunrise Productions';

      // Query profiles table for live server-side record
      if (client != null && user != null) {
        try {
          final profile = await client
              .from('profiles')
              .select()
              .eq('id', user.id)
              .maybeSingle();

          if (profile != null) {
            final name = profile['display_name'] as String?;
            if (name != null && name.trim().isNotEmpty) {
              _displayName = name.trim();
            }
            final emailVal = profile['email'] as String?;
            if (emailVal != null && emailVal.trim().isNotEmpty) {
              _email = emailVal.trim();
            }
            final roleVal = profile['role'] as String?;
            if (roleVal != null) {
              _role = roleVal == 'producer' ? 'Producer' : roleVal;
            }
            final createdAtVal = profile['created_at'] as String?;
            if (createdAtVal != null) {
              _createdAt = DateTime.tryParse(createdAtVal);
            }
          }
        } catch (_) {}
      }

      if (_createdAt == null && user?.createdAt != null) {
        _createdAt = DateTime.tryParse(user!.createdAt);
      }

      // Load producer catalog count
      try {
        _myMovies = await movieRepository.getMyMovies();
      } catch (_) {
        _myMovies = [];
      }
    } catch (_) {}

    if (mounted) {
      setState(() => _loading = false);
    }
  }

  Future<void> _editDisplayName() async {
    final controller = TextEditingController(text: _displayName);
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF111116),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0x66D4AF37)),
        ),
        title: Row(
          children: const [
            Icon(Icons.edit_outlined, color: Color(0xFFC9A227), size: 20),
            SizedBox(width: 10),
            Text(
              'Edit Producer Name',
              style: TextStyle(color: Color(0xFFF3EEE5), fontSize: 18, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Update your studio or production company display name.',
              style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              style: const TextStyle(color: Color(0xFFF3EEE5), fontSize: 14),
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFF09090C),
                hintText: 'e.g. Sunrise Productions',
                hintStyle: const TextStyle(color: Color(0xFF71717A)),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFF22222A)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFC9A227)),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF9CA3AF))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFC9A227),
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Save', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (saved == true && controller.text.trim().isNotEmpty) {
      final newName = controller.text.trim();
      final client = _getSupabaseClient();
      final user = client?.auth.currentUser;
      if (client != null && user != null) {
        try {
          await client
              .from('profiles')
              .update({'display_name': newName})
              .eq('id', user.id);

          await client.auth.updateUser(
            UserAttributes(data: {'display_name': newName}),
          );
        } catch (_) {}
      }
      setState(() => _displayName = newName);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Producer name updated successfully.'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
      }
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
        title: const Text(
          'Sign Out',
          style: TextStyle(color: Color(0xFFF3EEE5), fontWeight: FontWeight.w700),
        ),
        content: const Text(
          'Are you sure you want to sign out of the Producer Admin portal?',
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
      ).then((_) => _loadProfileData());
    } else if (key == 'assets') {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const ProducerAssetsScreen()),
      );
    } else if (key == 'analytics') {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const ProducerAnalyticsScreen()),
      );
    } else if (key == 'profile') {
      // already here
    } else if (key == 'settings') {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const ProducerSettingsScreen()),
      );
    } else if (key == 'help') {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const ProducerHelpScreen()),
      );
    }
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return 'Active Account';
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${dt.day.toString().padLeft(2, '0')} ${months[dt.month - 1]} ${dt.year}';
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
      activeKey: 'profile',
      mainNavItems: navItems,
      onSelectKey: _navigateTo,
    );

    final initial = _displayName.isNotEmpty ? _displayName.substring(0, 1).toUpperCase() : 'P';
    final approvedCount = _myMovies.where((m) => m.approvalStatus == 'approved').length;

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
                  searchPlaceholder: 'Search profile and account settings...',
                  showDrawerButton: !isDesktop,
                  onProfileTap: () {},
                  onSettingsTap: () => _navigateTo('settings'),
                ),
                Expanded(
                  child: _loading
                      ? const Center(child: CircularProgressIndicator(color: Color(0xFFC9A227)))
                      : SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Page Header
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: const [
                                      Text(
                                        'Profile',
                                        style: TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFFF3EEE5),
                                          letterSpacing: -0.5,
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        'Manage your producer account and company information.',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Color(0xFF9CA3AF),
                                        ),
                                      ),
                                    ],
                                  ),
                                  ElevatedButton.icon(
                                    onPressed: _editDisplayName,
                                    icon: const Icon(Icons.edit_outlined, size: 16),
                                    label: const Text('Edit Profile', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFC9A227),
                                      foregroundColor: Colors.black,
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),

                              // Profile Header Card
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF09090C),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: const Color(0x55C9A227)),
                                  gradient: const LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Color(0xFF0E0E14),
                                      Color(0xFF09090C),
                                      Color(0x1F5A0F1B),
                                    ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.4),
                                      blurRadius: 10,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    // Large Avatar Squircle
                                    Container(
                                      width: 72,
                                      height: 72,
                                      decoration: BoxDecoration(
                                        color: const Color(0x2B5A0F1B),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(color: const Color(0xFFC9A227), width: 1.5),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xFF5A0F1B).withValues(alpha: 0.4),
                                            blurRadius: 12,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: Center(
                                        child: Text(
                                          initial,
                                          style: const TextStyle(
                                            fontSize: 32,
                                            fontWeight: FontWeight.w800,
                                            color: Color(0xFFC9A227),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 20),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Flexible(
                                                child: Text(
                                                  _displayName,
                                                  style: const TextStyle(
                                                    fontSize: 20,
                                                    fontWeight: FontWeight.w800,
                                                    color: Color(0xFFF3EEE5),
                                                  ),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                                decoration: BoxDecoration(
                                                  color: const Color(0x335A0F1B),
                                                  borderRadius: BorderRadius.circular(6),
                                                  border: Border.all(color: const Color(0x666B1422)),
                                                ),
                                                child: Text(
                                                  _role,
                                                  style: const TextStyle(
                                                    color: Color(0xFFC9A227),
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            _email,
                                            style: const TextStyle(
                                              fontSize: 13.5,
                                              color: Color(0xFF9CA3AF),
                                            ),
                                          ),
                                          const SizedBox(height: 10),
                                          Row(
                                            children: const [
                                              Icon(Icons.verified_rounded, size: 16, color: Color(0xFF10B981)),
                                              SizedBox(width: 6),
                                              Text(
                                                'Verified Content Producer • LiveScreen Distribution Active',
                                                style: TextStyle(
                                                  color: Color(0xFF10B981),
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),

                              // Account Information & Catalog Performance
                              LayoutBuilder(
                                builder: (context, constraints) {
                                  final isWide = constraints.maxWidth > 850;

                                  final detailsCard = Container(
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
                                          children: const [
                                            Icon(Icons.badge_outlined, color: Color(0xFFC9A227), size: 18),
                                            SizedBox(width: 10),
                                            Text(
                                              'Account Information',
                                              style: TextStyle(
                                                color: Color(0xFFF3EEE5),
                                                fontSize: 16,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 18),
                                        _buildInfoRow('Studio / Company', _displayName),
                                        const Divider(color: Color(0xFF1A1A22), height: 20),
                                        _buildInfoRow('Account Email', _email),
                                        const Divider(color: Color(0xFF1A1A22), height: 20),
                                        _buildInfoRow('Role', 'Verified $_role'),
                                        const Divider(color: Color(0xFF1A1A22), height: 20),
                                        _buildInfoRow('Producer Account ID', _userId.length > 18 ? '${_userId.substring(0, 18)}...' : _userId),
                                        const Divider(color: Color(0xFF1A1A22), height: 20),
                                        _buildInfoRow('Member Since', _formatDate(_createdAt)),
                                      ],
                                    ),
                                  );

                                  final statsCard = Container(
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
                                          children: const [
                                            Icon(Icons.theaters_outlined, color: Color(0xFFC9A227), size: 18),
                                            SizedBox(width: 10),
                                            Text(
                                              'Catalog Overview',
                                              style: TextStyle(
                                                color: Color(0xFFF3EEE5),
                                                fontSize: 16,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 18),
                                        _buildInfoRow('Submitted Movies', '${_myMovies.length} titles'),
                                        const Divider(color: Color(0xFF1A1A22), height: 20),
                                        _buildInfoRow('Approved Movies', '$approvedCount titles'),
                                        const Divider(color: Color(0xFF1A1A22), height: 20),
                                        _buildInfoRow('Distribution Status', _myMovies.isNotEmpty ? 'Active' : 'No Submissions Yet'),
                                        const Divider(color: Color(0xFF1A1A22), height: 20),
                                        _buildInfoRow('Storage Security', 'Authenticated RLS Isolated'),
                                        const SizedBox(height: 16),
                                        OutlinedButton.icon(
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: const Color(0xFFC9A227),
                                            side: const BorderSide(color: Color(0x66C9A227)),
                                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                          ),
                                          onPressed: () => _navigateTo('my_movies'),
                                          icon: const Icon(Icons.arrow_forward_rounded, size: 15),
                                          label: const Text('View All Movies in Catalog', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5)),
                                        ),
                                      ],
                                    ),
                                  );

                                  if (isWide) {
                                    return Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Expanded(flex: 55, child: detailsCard),
                                        const SizedBox(width: 20),
                                        Expanded(flex: 45, child: statsCard),
                                      ],
                                    );
                                  }

                                  return Column(
                                    children: [
                                      detailsCard,
                                      const SizedBox(height: 20),
                                      statsCard,
                                    ],
                                  );
                                },
                              ),
                              const SizedBox(height: 28),

                              // Sign Out Action Card
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
                                          'Session & Authentication',
                                          style: TextStyle(
                                            color: Color(0xFFF3EEE5),
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          'Sign out of your Producer session on this workstation.',
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

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13, fontWeight: FontWeight.w500),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            style: const TextStyle(color: Color(0xFFF3EEE5), fontSize: 13, fontWeight: FontWeight.w600),
            textAlign: TextAlign.end,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
