import 'package:flutter/material.dart';
import '../../shared/widgets/admin/admin_sidebar.dart';
import '../../shared/widgets/admin/admin_top_bar.dart';
import '../screens/platform_admin_dashboard_screen.dart';
import '../screens/theatre_verification_screen.dart';
import '../screens/producer_verification_screen.dart';
import '../screens/movie_approval_screen.dart';
import '../screens/platform_verifications_screen.dart';
import '../screens/platform_bookings_screen.dart';
import '../screens/platform_users_screen.dart';
import '../screens/platform_analytics_screen.dart';
import '../screens/activity_log_screen.dart';
import '../screens/platform_admin_profile_screen.dart';
import '../screens/platform_admin_settings_screen.dart';
import '../screens/platform_admin_help_screen.dart';

/// Central theme palette for Platform Admin.
/// Strictly follows master cinematic LiveScreen visual design (Black, Burgundy, Gold & Warm Off-White).
class PlatformAdminColors {
  static const Color background = Color(0xFF050507);
  static const Color card = Color(0xFF09090C);
  static const Color cardSurface = Color(0xFF0D0D12);
  static const Color cardAlt = Color(0xFF101015);

  static const Color gold = Color(0xFFD4AF37);
  static const Color goldAccent = Color(0xFFC9A227);
  static const Color goldMuted = Color(0xFFB8941F);

  static const Color burgundy = Color(0xFF5A0F1B);
  static const Color burgundyDark = Color(0xFF54162B);
  static const Color burgundyAccent = Color(0xFF8F1025);
  static const Color burgundyBright = Color(0xFFA3152C);

  static const Color textWhite = Color(0xFFF3EEE5);
  static const Color textMuted = Color(0xFF9CA3AF);
  static const Color textDim = Color(0xFF71717A);

  static const Color borderSubtle = Color(0x33D4AF37);
  static const Color borderCard = Color(0xFF1E1E26);
  static const Color borderDark = Color(0xFF16161C);

  static const Color success = Color(0xFF10B981);
  static const Color error = Color(0xFFEF4444);
}

/// Standard 9 main navigation items for Platform Admin sidebar.
const List<AdminNavItemData> kPlatformAdminNavItems = [
  AdminNavItemData(key: 'dashboard', label: 'Dashboard', icon: Icons.grid_view_rounded),
  AdminNavItemData(key: 'theatres', label: 'Theatre Management', icon: Icons.domain_outlined),
  AdminNavItemData(key: 'producers', label: 'Producer Management', icon: Icons.groups_outlined),
  AdminNavItemData(key: 'movies', label: 'Movie & Content', icon: Icons.movie_outlined),
  AdminNavItemData(key: 'verifications', label: 'Verifications', icon: Icons.verified_user_outlined),
  AdminNavItemData(key: 'bookings', label: 'Bookings', icon: Icons.confirmation_number_outlined),
  AdminNavItemData(key: 'users', label: 'Users', icon: Icons.people_outline_rounded),
  AdminNavItemData(key: 'analytics', label: 'Analytics', icon: Icons.bar_chart_rounded),
  AdminNavItemData(key: 'audit_logs', label: 'Audit Logs', icon: Icons.receipt_long_outlined),
];

/// Navigates between Platform Admin sections with fixed-sidebar continuity.
void navigatePlatformAdmin(BuildContext context, String currentKey, String targetKey) {
  if (currentKey == targetKey) return;

  Widget nextScreen;
  switch (targetKey) {
    case 'dashboard':
      nextScreen = const PlatformAdminDashboardScreen();
      break;
    case 'theatres':
      nextScreen = const TheatreVerificationScreen();
      break;
    case 'producers':
      nextScreen = const ProducerVerificationScreen();
      break;
    case 'movies':
      nextScreen = const MovieApprovalScreen();
      break;
    case 'verifications':
      nextScreen = const PlatformVerificationsScreen();
      break;
    case 'bookings':
      nextScreen = const PlatformBookingsScreen();
      break;
    case 'users':
      nextScreen = const PlatformUsersScreen();
      break;
    case 'analytics':
      nextScreen = const PlatformAnalyticsScreen();
      break;
    case 'audit_logs':
      nextScreen = const ActivityLogScreen();
      break;
    case 'profile':
      nextScreen = const PlatformAdminProfileScreen();
      break;
    case 'settings':
      nextScreen = const PlatformAdminSettingsScreen();
      break;
    case 'help':
      nextScreen = const PlatformAdminHelpScreen();
      break;
    default:
      return;
  }

  Navigator.of(context).pushReplacement(
    PageRouteBuilder(
      pageBuilder: (_, _, _) => nextScreen,
      transitionDuration: Duration.zero,
    ),
  );
}

/// Unified, responsive master scaffold for all Platform Admin screens.
/// Guarantees:
/// - Fixed, non-scrollable left sidebar on desktop
/// - Standard dark top bar
/// - Consistent page header (warm-white title, muted subtitle, optional header actions)
/// - Only main content scrolls vertically
/// - Zero white/navy elements
class PlatformAdminScaffold extends StatelessWidget {
  final String activeKey;
  final String? activeSecondaryKey;
  final String pageTitle;
  final String pageSubtitle;
  final Widget? headerAction;
  final Widget body;
  final ValueChanged<String>? onSearchChanged;
  final String searchPlaceholder;
  final bool scrollable;

  const PlatformAdminScaffold({
    super.key,
    required this.activeKey,
    this.activeSecondaryKey,
    required this.pageTitle,
    required this.pageSubtitle,
    this.headerAction,
    required this.body,
    this.onSearchChanged,
    this.searchPlaceholder = 'Search users, theatres, producers, movies...',
    this.scrollable = true,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 900;

    final sidebar = AdminSidebar(
      activeKey: activeKey,
      activeSecondaryKey: activeSecondaryKey,
      mainNavItems: kPlatformAdminNavItems,
      onSelectKey: (k) => navigatePlatformAdmin(context, activeKey, k),
      onProfile: () => navigatePlatformAdmin(context, activeKey, 'profile'),
      onSettings: () => navigatePlatformAdmin(context, activeKey, 'settings'),
      onHelpSupport: () => navigatePlatformAdmin(context, activeKey, 'help'),
    );

    return Scaffold(
      backgroundColor: PlatformAdminColors.background,
      drawer: isDesktop ? null : Drawer(backgroundColor: const Color(0xFF070709), child: sidebar),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (isDesktop)
            SizedBox(
              width: 240,
              child: sidebar,
            ),
          Expanded(
            child: Column(
              children: [
                // Top Header
                AdminTopBar(
                  tagTitle: 'PLATFORM ADMIN',
                  tagTitleColor: PlatformAdminColors.textWhite,
                  profileRole: 'Platform Admin',
                  profileSubtitle: 'LiveScreen',
                  showTheatreSelector: false,
                  selectedLocation: 'Chennai',
                  searchPlaceholder: searchPlaceholder,
                  showDrawerButton: !isDesktop,
                  onSearchChanged: onSearchChanged,
                  onProfileTap: () => navigatePlatformAdmin(context, activeKey, 'profile'),
                  onSettingsTap: () => navigatePlatformAdmin(context, activeKey, 'settings'),
                ),
                Expanded(
                  child: scrollable
                      ? SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildHeader(),
                              const SizedBox(height: 22),
                              body,
                            ],
                          ),
                        )
                      : Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildHeader(),
                              const SizedBox(height: 22),
                              Expanded(child: body),
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

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                pageTitle,
                style: const TextStyle(
                  color: PlatformAdminColors.textWhite,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                pageSubtitle,
                style: const TextStyle(
                  color: PlatformAdminColors.textMuted,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        if (headerAction != null) ...[
          const SizedBox(width: 14),
          headerAction!,
        ],
      ],
    );
  }
}
