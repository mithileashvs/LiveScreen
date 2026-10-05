import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../auth/services/auth_service.dart';
import '../../auth/models/user_session.dart';
import '../../auth/screens/login_screen.dart';
import '../theme/platform_admin_theme.dart';

/// Master Platform Admin Profile Page.
/// Renders real authenticated administrator data, governance privileges, and session management.
class PlatformAdminProfileScreen extends StatefulWidget {
  const PlatformAdminProfileScreen({super.key});

  @override
  State<PlatformAdminProfileScreen> createState() => _PlatformAdminProfileScreenState();
}

class _PlatformAdminProfileScreenState extends State<PlatformAdminProfileScreen> {
  bool _loading = true;
  String _displayName = 'Platform Administrator';
  String _email = '';
  String _userId = '';
  String _role = 'platform_admin';
  DateTime? _createdAt;

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
      _email = user?.email ?? (session?.userId.contains('@') == true ? session!.userId : 'platform_admin@livescreen.local');
      _displayName = user?.userMetadata?['display_name'] as String? ?? 'Platform Administrator';

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
              _role = roleVal;
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
    } catch (_) {}

    if (mounted) {
      setState(() => _loading = false);
    }
  }

  Future<void> _handleSignOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: PlatformAdminColors.cardSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: PlatformAdminColors.borderSubtle),
        ),
        title: const Text(
          'Sign Out',
          style: TextStyle(color: PlatformAdminColors.textWhite, fontSize: 18, fontWeight: FontWeight.w700),
        ),
        content: const Text(
          'Are you sure you want to end your current Platform Admin session?',
          style: TextStyle(color: PlatformAdminColors.textMuted, fontSize: 13.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel', style: TextStyle(color: PlatformAdminColors.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: PlatformAdminColors.burgundyAccent,
              foregroundColor: PlatformAdminColors.textWhite,
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

  String _formatDate(DateTime dt) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    return PlatformAdminScaffold(
      activeKey: 'dashboard',
      activeSecondaryKey: 'profile',
      pageTitle: 'Profile',
      pageSubtitle: 'Manage your administrator credentials and platform governance identity.',
      body: _loading
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: CircularProgressIndicator(color: PlatformAdminColors.gold),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Profile Header Hero Card
                _buildProfileHeroCard(),
                const SizedBox(height: 24),

                // 2. Account Details & System Privileges Grid
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth > 800;
                    if (isWide) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: _buildAccountDetailsCard()),
                          const SizedBox(width: 20),
                          Expanded(child: _buildSystemPrivilegesCard()),
                        ],
                      );
                    }
                    return Column(
                      children: [
                        _buildAccountDetailsCard(),
                        const SizedBox(height: 20),
                        _buildSystemPrivilegesCard(),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 24),

                // 3. Session Management & Sign Out
                _buildSessionCard(),
              ],
            ),
    );
  }

  Widget _buildProfileHeroCard() {
    final initial = _displayName.isNotEmpty ? _displayName[0].toUpperCase() : 'A';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: PlatformAdminColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: PlatformAdminColors.borderSubtle, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Avatar
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF14120C),
              border: Border.all(color: PlatformAdminColors.gold, width: 1.5),
            ),
            child: Center(
              child: Text(
                initial,
                style: const TextStyle(
                  color: PlatformAdminColors.gold,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
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
                          color: PlatformAdminColors.textWhite,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0x288F1025),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: PlatformAdminColors.burgundyAccent, width: 0.8),
                      ),
                      child: const Text(
                        'SUPER ADMIN',
                        style: TextStyle(
                          color: Color(0xFFFCA5A5),
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  _email,
                  style: const TextStyle(
                    color: PlatformAdminColors.textMuted,
                    fontSize: 13.5,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.shield_outlined, size: 14, color: PlatformAdminColors.gold),
                    const SizedBox(width: 5),
                    const Text(
                      'LiveScreen Platform Operations Tier',
                      style: TextStyle(
                        color: PlatformAdminColors.gold,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (_createdAt != null) ...[
                      const SizedBox(width: 12),
                      Text(
                        '•  Active since ${_formatDate(_createdAt!)}',
                        style: const TextStyle(
                          color: PlatformAdminColors.textDim,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountDetailsCard() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: PlatformAdminColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: PlatformAdminColors.borderDark, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.badge_outlined, color: PlatformAdminColors.gold, size: 18),
              SizedBox(width: 10),
              Text(
                'Account Information',
                style: TextStyle(color: PlatformAdminColors.textWhite, fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _buildInfoRow('Full Name', _displayName),
          const Divider(color: PlatformAdminColors.borderDark, height: 20),
          _buildInfoRow('Primary Email', _email),
          const Divider(color: PlatformAdminColors.borderDark, height: 20),
          _buildInfoRow('Account Role', _role == 'platform_admin' ? 'Platform Administrator' : _role),
          const Divider(color: PlatformAdminColors.borderDark, height: 20),
          _buildInfoRow('Security Status', 'Protected & Enforced via Supabase RLS'),
        ],
      ),
    );
  }

  Widget _buildSystemPrivilegesCard() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: PlatformAdminColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: PlatformAdminColors.borderDark, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.security_outlined, color: PlatformAdminColors.gold, size: 18),
              SizedBox(width: 10),
              Text(
                'Governance Privileges',
                style: TextStyle(color: PlatformAdminColors.textWhite, fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _buildPrivilegeItem(
            title: 'Venue & Operator Verifications',
            description: 'Authority to verify, reject, and suspend cinema venues and ownership bindings.',
            icon: Icons.domain_verification_rounded,
          ),
          const SizedBox(height: 14),
          _buildPrivilegeItem(
            title: 'Content & Producer Governance',
            description: 'Review submitted film assets and publish live content into public distribution.',
            icon: Icons.movie_filter_rounded,
          ),
          const SizedBox(height: 14),
          _buildPrivilegeItem(
            title: 'Audit Trail Visibility',
            description: 'Access complete immutable audit log stamping every administrative transition.',
            icon: Icons.history_edu_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildPrivilegeItem({required String title, required String description, required IconData icon}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: const Color(0xFF14120C),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0x44D4AF37), width: 0.8),
          ),
          child: Icon(icon, color: PlatformAdminColors.gold, size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: PlatformAdminColors.textWhite,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: const TextStyle(
                  color: PlatformAdminColors.textDim,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSessionCard() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: PlatformAdminColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: PlatformAdminColors.borderDark, width: 1.0),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Active Session',
                  style: TextStyle(color: PlatformAdminColors.textWhite, fontSize: 15, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 3),
                Text(
                  'Session Identifier: ${_userId.length > 16 ? '${_userId.substring(0, 16)}...' : _userId}',
                  style: const TextStyle(color: PlatformAdminColors.textDim, fontSize: 12.5),
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: PlatformAdminColors.burgundyAccent,
              foregroundColor: PlatformAdminColors.textWhite,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: _handleSignOut,
            icon: const Icon(Icons.logout_rounded, size: 16),
            label: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: PlatformAdminColors.textMuted, fontSize: 13)),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: PlatformAdminColors.textWhite, fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ),
      ],
    );
  }
}
