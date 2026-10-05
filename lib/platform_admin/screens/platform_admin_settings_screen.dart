import 'package:flutter/material.dart';
import '../../auth/services/auth_service.dart';
import '../../auth/screens/login_screen.dart';
import '../theme/platform_admin_theme.dart';

/// Master Platform Admin Settings Page.
/// Implements Account preferences, notification alerts, appearance specs, security overview, and Sign Out.
class PlatformAdminSettingsScreen extends StatefulWidget {
  const PlatformAdminSettingsScreen({super.key});

  @override
  State<PlatformAdminSettingsScreen> createState() => _PlatformAdminSettingsScreenState();
}

class _PlatformAdminSettingsScreenState extends State<PlatformAdminSettingsScreen> {
  // Session administrative notification preferences
  bool _verificationAlerts = true;
  bool _contentSubmissionAlerts = true;
  bool _auditLoggingAlerts = true;
  bool _autoRefreshMetrics = true;

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

  @override
  Widget build(BuildContext context) {
    return PlatformAdminScaffold(
      activeKey: 'dashboard',
      activeSecondaryKey: 'settings',
      pageTitle: 'Settings',
      pageSubtitle: 'Configure platform administration preferences, notification feeds, and security parameters.',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Notification Preferences Card
          _buildNotificationCard(),
          const SizedBox(height: 20),

          // 2. Appearance & Display Card
          _buildAppearanceCard(),
          const SizedBox(height: 20),

          // 3. System Security & Enforcement Card
          _buildSecurityCard(),
          const SizedBox(height: 20),

          // 4. Session Termination Card
          _buildSignOutCard(),
        ],
      ),
    );
  }

  Widget _buildNotificationCard() {
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
              Icon(Icons.notifications_active_outlined, color: PlatformAdminColors.gold, size: 18),
              SizedBox(width: 10),
              Text(
                'Administrative Notifications',
                style: TextStyle(color: PlatformAdminColors.textWhite, fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Control which operational updates are highlighted during your active administrative session.',
            style: TextStyle(color: PlatformAdminColors.textMuted, fontSize: 12.5),
          ),
          const SizedBox(height: 16),
          _buildSwitchTile(
            title: 'Venue & Producer Verification Alerts',
            subtitle: 'Immediate alert banners when new theatre venues or producer accounts are submitted.',
            value: _verificationAlerts,
            onChanged: (v) => setState(() => _verificationAlerts = v),
          ),
          const Divider(color: PlatformAdminColors.borderDark, height: 20),
          _buildSwitchTile(
            title: 'Content & Movie Approval Alerts',
            subtitle: 'Alerts when film assets or trailers are queued for public publishing review.',
            value: _contentSubmissionAlerts,
            onChanged: (v) => setState(() => _contentSubmissionAlerts = v),
          ),
          const Divider(color: PlatformAdminColors.borderDark, height: 20),
          _buildSwitchTile(
            title: 'Audit Log Stamping Notifications',
            subtitle: 'Real-time notifications upon status transitions and review rejections.',
            value: _auditLoggingAlerts,
            onChanged: (v) => setState(() => _auditLoggingAlerts = v),
          ),
          const Divider(color: PlatformAdminColors.borderDark, height: 20),
          _buildSwitchTile(
            title: 'Auto-Refresh Dashboard Metrics',
            subtitle: 'Automatically poll platform counts upon navigating to the master dashboard.',
            value: _autoRefreshMetrics,
            onChanged: (v) => setState(() => _autoRefreshMetrics = v),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      children: [
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
                subtitle,
                style: const TextStyle(
                  color: PlatformAdminColors.textDim,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 14),
        Switch.adaptive(
          value: value,
          onChanged: onChanged,
          activeTrackColor: PlatformAdminColors.burgundyAccent,
          activeThumbColor: PlatformAdminColors.gold,
        ),
      ],
    );
  }

  Widget _buildAppearanceCard() {
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
              Icon(Icons.palette_outlined, color: PlatformAdminColors.gold, size: 18),
              SizedBox(width: 10),
              Text(
                'Appearance & Theme Specs',
                style: TextStyle(color: PlatformAdminColors.textWhite, fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF14120C),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: PlatformAdminColors.gold, width: 1.0),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.dark_mode_rounded, size: 14, color: PlatformAdminColors.gold),
                    SizedBox(width: 6),
                    Text(
                      'LiveScreen Dark Cinematic Master',
                      style: TextStyle(color: PlatformAdminColors.gold, fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Unified Black (#050507), Metallic Gold (#D4AF37), and Deep Burgundy (#5A0F1B).',
                  style: TextStyle(color: PlatformAdminColors.textDim, fontSize: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityCard() {
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
              Icon(Icons.lock_outline_rounded, color: PlatformAdminColors.gold, size: 18),
              SizedBox(width: 10),
              Text(
                'Security & Access Governance',
                style: TextStyle(color: PlatformAdminColors.textWhite, fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildSecurityRow('Authentication Provider', 'Supabase Auth (Encrypted JWT Token)'),
          const Divider(color: PlatformAdminColors.borderDark, height: 18),
          _buildSecurityRow('Row-Level Security (RLS)', 'Active — Platform Admin universal read & write override'),
          const Divider(color: PlatformAdminColors.borderDark, height: 18),
          _buildSecurityRow('Audit Protection', 'SQL triggers enforce status transition logging on all tables'),
        ],
      ),
    );
  }

  Widget _buildSecurityRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: PlatformAdminColors.textMuted, fontSize: 13)),
        Flexible(
          child: Text(
            value,
            style: const TextStyle(color: PlatformAdminColors.textWhite, fontWeight: FontWeight.w600, fontSize: 12.5),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }

  Widget _buildSignOutCard() {
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'End Platform Session',
                style: TextStyle(color: PlatformAdminColors.textWhite, fontSize: 15, fontWeight: FontWeight.w700),
              ),
              SizedBox(height: 3),
              Text(
                'Terminates authentication token on this device.',
                style: TextStyle(color: PlatformAdminColors.textDim, fontSize: 12.5),
              ),
            ],
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
}
