import 'package:flutter/material.dart';
import '../../shared/widgets/admin/admin_sidebar.dart';
import '../../shared/widgets/admin/admin_top_bar.dart';
import '../models/platform_admin_models.dart';
import '../services/platform_admin_repository.dart';
import 'theatre_verification_screen.dart';
import 'producer_verification_screen.dart';
import 'movie_approval_screen.dart';
import 'activity_log_screen.dart';
import 'platform_verifications_screen.dart';
import 'platform_bookings_screen.dart';
import 'platform_users_screen.dart';
import 'platform_analytics_screen.dart';
import 'platform_admin_profile_screen.dart';
import 'platform_admin_settings_screen.dart';
import 'platform_admin_help_screen.dart';

/// Redesigned LiveScreen Platform Admin Dashboard.
/// Strictly implements the master visual reference:
/// - Dark cinematic aesthetic: Near-black #050507, Deep Burgundy #54162B / #5A0F1B,
///   Metallic Gold #D4AF37 / #C9A227, Warm Off-White #F3EEE5.
/// - Fixed Sidebar with master navigation: Dashboard, Theatre Management, Producer Management,
///   Movie & Content, Verifications, Bookings, Users, Analytics, Audit Logs, Profile, Settings, Help & Support.
/// - Top Bar: "PLATFORM ADMIN", global search, location pill, notification bell, admin profile.
/// - Intro: "Good Morning!" with metallic gold emphasis and dynamic system date.
/// - 4 KPI Cards: Total Theatres, Total Producers, Total Movies, Total Users.
/// - Verification & Approvals: 3 clean cards for Theatre, Producer, Content pending requests.
/// - 2-Column Middle Row: Recent Submissions table (Left) + Platform Performance 2x2 grid (Right).
/// - Quick Admin Actions: 5 cards along the bottom.
/// - Pure LiveScreen real application data from platformAdminRepository. Zero fake data.
enum AdminCardAccent { gold, burgundy }

class _AdminCardColors {
  final Color borderColor;
  final Color hoverBorderColor;
  final Color bgColor;
  final Color hoverBgColor;
  final Color iconColor;
  final Color iconBgColor;
  final Color iconBorderColor;
  final Color shadowColor;

  const _AdminCardColors({
    required this.borderColor,
    required this.hoverBorderColor,
    required this.bgColor,
    required this.hoverBgColor,
    required this.iconColor,
    required this.iconBgColor,
    required this.iconBorderColor,
    required this.shadowColor,
  });

  static _AdminCardColors of(AdminCardAccent accent) {
    if (accent == AdminCardAccent.gold) {
      return const _AdminCardColors(
        borderColor: Color(0xFFB8941F),
        hoverBorderColor: Color(0xFFD4AF37),
        bgColor: Color(0xFF090806),
        hoverBgColor: Color(0xFF110D08),
        iconColor: Color(0xFFD4AF37),
        iconBgColor: Color(0x22D4AF37),
        iconBorderColor: Color(0x55D4AF37),
        shadowColor: Color(0x28B8941F),
      );
    } else {
      return const _AdminCardColors(
        borderColor: Color(0xFF8F1025),
        hoverBorderColor: Color(0xFFA3152C),
        bgColor: Color(0xFF0F060A),
        hoverBgColor: Color(0xFF16080E),
        iconColor: Color(0xFFD51F46),
        iconBgColor: Color(0x288F1025),
        iconBorderColor: Color(0x558F1025),
        shadowColor: Color(0x2D8F1025),
      );
    }
  }
}

class PlatformAdminDashboardScreen extends StatefulWidget {
  const PlatformAdminDashboardScreen({super.key});

  @override
  State<PlatformAdminDashboardScreen> createState() => _PlatformAdminDashboardScreenState();
}

class _PlatformAdminDashboardScreenState extends State<PlatformAdminDashboardScreen> {
  bool _loading = true;
  PlatformDashboardMetrics _metrics = const PlatformDashboardMetrics(
    totalTheatres: 0,
    totalProducers: 0,
    totalMovies: 0,
    totalUsers: 0,
    pendingTheatres: 0,
    pendingProducers: 0,
    pendingMovies: 0,
    totalBookings: 0,
    activeShows: 0,
    publishedTheatres: 0,
    liveMovies: 0,
  );
  List<PlatformRecentSubmission> _recentSubmissions = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        platformAdminRepository.getDashboardMetrics(),
        platformAdminRepository.getRecentSubmissions(limit: 5),
      ]);
      if (mounted) {
        setState(() {
          _metrics = results[0] as PlatformDashboardMetrics;
          _recentSubmissions = results[1] as List<PlatformRecentSubmission>;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _navigateTo(String key) {
    if (key == 'dashboard') {
      _loadData();
    } else if (key == 'theatres') {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const TheatreVerificationScreen()),
      ).then((_) => _loadData());
    } else if (key == 'producers') {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const ProducerVerificationScreen()),
      ).then((_) => _loadData());
    } else if (key == 'movies') {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const MovieApprovalScreen()),
      ).then((_) => _loadData());
    } else if (key == 'verifications') {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const PlatformVerificationsScreen()),
      ).then((_) => _loadData());
    } else if (key == 'bookings') {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const PlatformBookingsScreen()),
      ).then((_) => _loadData());
    } else if (key == 'users') {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const PlatformUsersScreen()),
      ).then((_) => _loadData());
    } else if (key == 'analytics') {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const PlatformAnalyticsScreen()),
      ).then((_) => _loadData());
    } else if (key == 'audit_logs') {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const ActivityLogScreen()),
      ).then((_) => _loadData());
    } else if (key == 'profile') {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const PlatformAdminProfileScreen()),
      ).then((_) => _loadData());
    } else if (key == 'settings') {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const PlatformAdminSettingsScreen()),
      ).then((_) => _loadData());
    } else if (key == 'help') {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const PlatformAdminHelpScreen()),
      ).then((_) => _loadData());
    }
  }

  void _openSubmissionAction(PlatformRecentSubmission submission) {
    if (submission.type == 'movie') {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const MovieApprovalScreen()),
      ).then((_) => _loadData());
    } else if (submission.type == 'theatre') {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const TheatreVerificationScreen()),
      ).then((_) => _loadData());
    } else if (submission.type == 'producer') {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const ProducerVerificationScreen()),
      ).then((_) => _loadData());
    }
  }

  String _formatDate(DateTime dt) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  String _formatDynamicCurrentDate() {
    final now = DateTime.now();
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${days[now.weekday - 1]}, ${now.day} ${months[now.month - 1]} ${now.year}';
  }

  String _getGreetingWord() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Morning!';
    if (hour < 17) return 'Afternoon!';
    return 'Evening!';
  }

  String _formatCount(int number) {
    if (number >= 1000) {
      final str = number.toString();
      final buffer = StringBuffer();
      int count = 0;
      for (int i = str.length - 1; i >= 0; i--) {
        buffer.write(str[i]);
        count++;
        if (count % 3 == 0 && i != 0) {
          buffer.write(',');
        }
      }
      return buffer.toString().split('').reversed.join('');
    }
    return number.toString();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 900;

    const navItems = [
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

    final sidebar = AdminSidebar(
      activeKey: 'dashboard',
      mainNavItems: navItems,
      onSelectKey: _navigateTo,
      onProfile: () => _navigateTo('profile'),
      onSettings: () => _navigateTo('settings'),
      onHelpSupport: () => _navigateTo('help'),
    );

    return Scaffold(
      backgroundColor: const Color(0xFF050507),
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
                // Top Header matching master visual reference
                AdminTopBar(
                  tagTitle: 'PLATFORM ADMIN',
                  tagTitleColor: const Color(0xFFF3EEE5),
                  profileRole: 'Platform Admin',
                  profileSubtitle: 'LiveScreen',
                  showTheatreSelector: false,
                  selectedLocation: 'Chennai',
                  searchPlaceholder: 'Search users, theatres, producers, movies...',
                  showDrawerButton: !isDesktop,
                  onProfileTap: () => _navigateTo('profile'),
                  onSettingsTap: () => _navigateTo('settings'),
                ),
                Expanded(
                  child: _loading
                      ? const Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37)))
                      : SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 1. Dashboard Greeting & Date Intro
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        RichText(
                                          text: TextSpan(
                                            children: [
                                              const TextSpan(
                                                text: 'Good ',
                                                style: TextStyle(
                                                  fontSize: 26,
                                                  fontWeight: FontWeight.w800,
                                                  color: Color(0xFFF3EEE5),
                                                  letterSpacing: -0.5,
                                                ),
                                              ),
                                              TextSpan(
                                                text: _getGreetingWord(),
                                                style: const TextStyle(
                                                  fontSize: 26,
                                                  fontWeight: FontWeight.w800,
                                                  color: Color(0xFFD4AF37),
                                                  letterSpacing: -0.5,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        const Text(
                                          'Monitor LiveScreen operations, approvals, and platform activity.',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Color(0xFF9CA3AF),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    _formatDynamicCurrentDate(),
                                    style: const TextStyle(
                                      color: Color(0xFF9CA3AF),
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 22),

                              // 2. Four KPI Cards
                              LayoutBuilder(
                                builder: (context, constraints) {
                                  final isWide = constraints.maxWidth > 900;
                                  final cardWidth = isWide
                                      ? (constraints.maxWidth - 3 * 16) / 4
                                      : (constraints.maxWidth - 16) / 2;

                                  final card1 = _FramedKpiCard(
                                    accent: AdminCardAccent.gold,
                                    icon: Icons.domain_outlined,
                                    title: 'Total Theatres',
                                    value: _formatCount(_metrics.totalTheatres),
                                    width: cardWidth,
                                  );

                                  final card2 = _FramedKpiCard(
                                    accent: AdminCardAccent.burgundy,
                                    icon: Icons.groups_outlined,
                                    title: 'Total Producers',
                                    value: _formatCount(_metrics.totalProducers),
                                    width: cardWidth,
                                  );

                                  final card3 = _FramedKpiCard(
                                    accent: AdminCardAccent.gold,
                                    icon: Icons.movie_outlined,
                                    title: 'Total Movies',
                                    value: _formatCount(_metrics.totalMovies),
                                    width: cardWidth,
                                  );

                                  final card4 = _FramedKpiCard(
                                    accent: AdminCardAccent.burgundy,
                                    icon: Icons.people_outline_rounded,
                                    title: 'Total Users',
                                    value: _formatCount(_metrics.totalUsers),
                                    width: cardWidth,
                                  );

                                  if (isWide) {
                                    return Row(
                                      children: [
                                        Expanded(child: card1),
                                        const SizedBox(width: 16),
                                        Expanded(child: card2),
                                        const SizedBox(width: 16),
                                        Expanded(child: card3),
                                        const SizedBox(width: 16),
                                        Expanded(child: card4),
                                      ],
                                    );
                                  }

                                  return Column(
                                    children: [
                                      Row(children: [Expanded(child: card1), const SizedBox(width: 16), Expanded(child: card2)]),
                                      const SizedBox(height: 16),
                                      Row(children: [Expanded(child: card3), const SizedBox(width: 16), Expanded(child: card4)]),
                                    ],
                                  );
                                },
                              ),
                              const SizedBox(height: 26),

                              // 3. Verification & Approvals
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Verification & Approvals',
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFFF3EEE5),
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  const Text(
                                    'Review pending requests across the LiveScreen platform.',
                                    style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12.5),
                                  ),
                                  const SizedBox(height: 14),
                                  LayoutBuilder(
                                    builder: (context, constraints) {
                                      final isWide = constraints.maxWidth > 850;

                                      final cardTheatres = _FramedVerificationCard(
                                        accent: AdminCardAccent.gold,
                                        icon: Icons.domain_outlined,
                                        title: 'Theatre Verifications',
                                        count: _metrics.pendingTheatres,
                                        description: 'Review and verify new theatre registrations.',
                                        onTap: () => _navigateTo('theatres'),
                                      );

                                      final cardProducers = _FramedVerificationCard(
                                        accent: AdminCardAccent.burgundy,
                                        icon: Icons.groups_outlined,
                                        title: 'Producer Verifications',
                                        count: _metrics.pendingProducers,
                                        description: 'Review and verify new producer registrations.',
                                        onTap: () => _navigateTo('producers'),
                                      );

                                      final cardContent = _FramedVerificationCard(
                                        accent: AdminCardAccent.gold,
                                        icon: Icons.movie_outlined,
                                        title: 'Content Approvals',
                                        count: _metrics.pendingMovies,
                                        description: 'Review submitted movies, trailers and content.',
                                        onTap: () => _navigateTo('movies'),
                                      );

                                      if (isWide) {
                                        return Row(
                                          children: [
                                            Expanded(child: cardTheatres),
                                            const SizedBox(width: 16),
                                            Expanded(child: cardProducers),
                                            const SizedBox(width: 16),
                                            Expanded(child: cardContent),
                                          ],
                                        );
                                      }

                                      return Column(
                                        children: [
                                          cardTheatres,
                                          const SizedBox(height: 14),
                                          cardProducers,
                                          const SizedBox(height: 14),
                                          cardContent,
                                        ],
                                      );
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 26),

                              // 4. Middle Row: Recent Submissions (Left) + Platform Performance (Right)
                              LayoutBuilder(
                                builder: (context, constraints) {
                                  final isWide = constraints.maxWidth > 1050;

                                  final submissionsWidget = _buildRecentSubmissionsModule();
                                  final performanceWidget = _buildPlatformPerformanceModule();

                                  if (isWide) {
                                    return Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Expanded(flex: 54, child: submissionsWidget),
                                        const SizedBox(width: 18),
                                        Expanded(flex: 46, child: performanceWidget),
                                      ],
                                    );
                                  }

                                  return Column(
                                    children: [
                                      submissionsWidget,
                                      const SizedBox(height: 24),
                                      performanceWidget,
                                    ],
                                  );
                                },
                              ),
                              const SizedBox(height: 28),

                              // 5. Quick Admin Actions
                              _buildQuickActionsModule(),
                              const SizedBox(height: 16),
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

// KPI and Verification cards rendered via framed widgets below


  // ---------------------------------------------------------------------------
  // Recent Submissions Module
  // ---------------------------------------------------------------------------
  Widget _buildRecentSubmissionsModule() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF09090C),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x33D4AF37), width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  'Recent Submissions',
                  style: TextStyle(
                    color: Color(0xFFF3EEE5),
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () => _navigateTo('audit_logs'),
                child: Row(
                  children: const [
                    Text(
                      'View All',
                      style: TextStyle(color: Color(0xFFC9A227), fontSize: 12.5, fontWeight: FontWeight.w600),
                    ),
                    SizedBox(width: 4),
                    Icon(Icons.arrow_forward_rounded, size: 14, color: Color(0xFFC9A227)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Table Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFF181820), width: 1)),
            ),
            child: Row(
              children: const [
                SizedBox(width: 32, child: Text('Type', style: TextStyle(color: Color(0xFF71717A), fontSize: 11, fontWeight: FontWeight.w600))),
                Expanded(flex: 40, child: Text('Name / Title', style: TextStyle(color: Color(0xFF71717A), fontSize: 11, fontWeight: FontWeight.w600))),
                Expanded(flex: 25, child: Text('Submitted', style: TextStyle(color: Color(0xFF71717A), fontSize: 11, fontWeight: FontWeight.w600))),
                Expanded(flex: 20, child: Text('Status', style: TextStyle(color: Color(0xFF71717A), fontSize: 11, fontWeight: FontWeight.w600))),
                SizedBox(width: 50, child: Text('Action', style: TextStyle(color: Color(0xFF71717A), fontSize: 11, fontWeight: FontWeight.w600))),
              ],
            ),
          ),

          // Table Rows or Empty State
          if (_recentSubmissions.isEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 36),
              child: Center(
                child: Column(
                  children: const [
                    Icon(Icons.inbox_outlined, color: Color(0xFF71717A), size: 30),
                    SizedBox(height: 8),
                    Text(
                      'No recent submissions.',
                      style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
            for (final item in _recentSubmissions) _buildSubmissionRow(item),
          ],
        ],
      ),
    );
  }

  Widget _buildSubmissionRow(PlatformRecentSubmission item) {
    IconData typeIcon;
    if (item.type == 'movie') {
      typeIcon = Icons.movie_outlined;
    } else if (item.type == 'theatre') {
      typeIcon = Icons.domain_outlined;
    } else {
      typeIcon = Icons.person_outline;
    }

    // Status pill
    Color statusBg;
    Color statusBorder;
    Color statusText;
    String statusLabel = item.status;

    final normStatus = item.status.toLowerCase();
    if (normStatus == 'approved' || normStatus == 'verified' || normStatus == 'published') {
      statusBg = const Color(0x2210B981);
      statusBorder = const Color(0x5510B981);
      statusText = const Color(0xFF10B981);
      statusLabel = normStatus == 'verified' ? 'Verified' : 'Approved';
    } else if (normStatus == 'rejected' || normStatus == 'suspended') {
      statusBg = const Color(0x2A6B1422);
      statusBorder = const Color(0x666B1422);
      statusText = const Color(0xFFEF4444);
      statusLabel = 'Rejected';
    } else {
      statusBg = const Color(0x2E5A0F1B);
      statusBorder = const Color(0x666B1422);
      statusText = const Color(0xFFFCA5A5);
      statusLabel = normStatus == 'under_review' ? 'In Review' : 'Pending';
    }

    final isPending = normStatus == 'pending' || normStatus == 'submitted' || normStatus == 'under_review';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFF14141B), width: 1)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Icon(typeIcon, size: 16, color: const Color(0xFFC9A227)),
          ),
          Expanded(
            flex: 40,
            child: Text(
              item.title,
              style: const TextStyle(
                color: Color(0xFFF3EEE5),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 25,
            child: Text(
              _formatDate(item.submittedAt),
              style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 12),
            ),
          ),
          Expanded(
            flex: 20,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: statusBorder),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(color: statusText, fontSize: 10.5, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
          SizedBox(
            width: 50,
            child: InkWell(
              onTap: () => _openSubmissionAction(item),
              child: Row(
                children: [
                  Text(
                    isPending ? 'Review' : 'View',
                    style: const TextStyle(color: Color(0xFFC9A227), fontSize: 11.5, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(width: 2),
                  const Icon(Icons.arrow_forward_rounded, size: 12, color: Color(0xFFC9A227)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Platform Performance Module
  // ---------------------------------------------------------------------------
  Widget _buildPlatformPerformanceModule() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF09090C),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x33D4AF37), width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
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
                      'Platform Performance',
                      style: TextStyle(
                        color: Color(0xFFF3EEE5),
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Latest platform activity and engagement.',
                      style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFF101014),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0x33D4AF37)),
                ),
                child: Row(
                  children: const [
                    Text('Last 7 Days', style: TextStyle(color: Color(0xFFF3EEE5), fontSize: 11.5, fontWeight: FontWeight.w500)),
                    SizedBox(width: 4),
                    Icon(Icons.keyboard_arrow_down_rounded, size: 14, color: Color(0xFFD4AF37)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // 2x2 Grid of Performance Metrics (Alternating Burgundy & Gold frames)
          Row(
            children: [
              Expanded(
                child: _FramedPerformanceMetricTile(
                  accent: AdminCardAccent.burgundy,
                  icon: Icons.confirmation_number_outlined,
                  title: 'Total Bookings',
                  value: _formatCount(_metrics.totalBookings),
                  waveColor: const Color(0xFFD51F46),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _FramedPerformanceMetricTile(
                  accent: AdminCardAccent.gold,
                  icon: Icons.calendar_today_outlined,
                  title: 'Active Shows',
                  value: _formatCount(_metrics.activeShows),
                  waveColor: const Color(0xFFD4AF37),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _FramedPerformanceMetricTile(
                  accent: AdminCardAccent.gold,
                  icon: Icons.domain_outlined,
                  title: 'Published Theatres',
                  value: _formatCount(_metrics.publishedTheatres),
                  waveColor: const Color(0xFFD4AF37),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _FramedPerformanceMetricTile(
                  accent: AdminCardAccent.burgundy,
                  icon: Icons.movie_outlined,
                  title: 'Live Movies',
                  value: _formatCount(_metrics.liveMovies),
                  waveColor: const Color(0xFFD51F46),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

// Performance metric tiles rendered via framed widgets below


  // ---------------------------------------------------------------------------
  // Quick Admin Actions Module
  // ---------------------------------------------------------------------------
  Widget _buildQuickActionsModule() {
    return Column(
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
                    'Quick Admin Actions',
                    style: TextStyle(
                      fontSize: 16.5,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFFF3EEE5),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Common platform management tasks.',
                    style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            InkWell(
              onTap: () => _navigateTo('audit_logs'),
              child: Row(
                children: const [
                  Text('View All', style: TextStyle(color: Color(0xFFC9A227), fontSize: 12.5, fontWeight: FontWeight.w600)),
                  SizedBox(width: 4),
                  Icon(Icons.arrow_forward_rounded, size: 14, color: Color(0xFFC9A227)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 950;

            final card1 = _FramedQuickActionCard(
              accent: AdminCardAccent.gold,
              icon: Icons.domain_outlined,
              title: 'Review Theatres',
              subtitle: 'Manage theatre registrations and verifications.',
              onTap: () => _navigateTo('theatres'),
            );

            final card2 = _FramedQuickActionCard(
              accent: AdminCardAccent.burgundy,
              icon: Icons.groups_outlined,
              title: 'Review Producers',
              subtitle: 'Manage producer registrations and verifications.',
              onTap: () => _navigateTo('producers'),
            );

            final card3 = _FramedQuickActionCard(
              accent: AdminCardAccent.gold,
              icon: Icons.movie_outlined,
              title: 'Review Content',
              subtitle: 'Approve movies, trailers and other content.',
              onTap: () => _navigateTo('movies'),
            );

            final card4 = _FramedQuickActionCard(
              accent: AdminCardAccent.burgundy,
              icon: Icons.people_outline_rounded,
              title: 'Manage Users',
              subtitle: 'View and manage platform users.',
              onTap: () => _navigateTo('users'),
            );

            final card5 = _FramedQuickActionCard(
              accent: AdminCardAccent.gold,
              icon: Icons.receipt_long_outlined,
              title: 'View Audit Logs',
              subtitle: 'Track platform activity and changes.',
              onTap: () => _navigateTo('audit_logs'),
            );

            if (isWide) {
              return Row(
                children: [
                  Expanded(child: card1),
                  const SizedBox(width: 12),
                  Expanded(child: card2),
                  const SizedBox(width: 12),
                  Expanded(child: card3),
                  const SizedBox(width: 12),
                  Expanded(child: card4),
                  const SizedBox(width: 12),
                  Expanded(child: card5),
                ],
              );
            }

            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(width: (constraints.maxWidth - 12) / 2, child: card1),
                SizedBox(width: (constraints.maxWidth - 12) / 2, child: card2),
                SizedBox(width: (constraints.maxWidth - 12) / 2, child: card3),
                SizedBox(width: (constraints.maxWidth - 12) / 2, child: card4),
                SizedBox(width: constraints.maxWidth, child: card5),
              ],
            );
          },
        ),
      ],
    );
  }

// Quick action cards rendered via framed widgets below

}

/// Subtle aesthetic decorative sine wave glow line
class _WavePainter extends CustomPainter {
  final Color color;

  _WavePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.85)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(0, size.height * 0.7);
    path.quadraticBezierTo(
      size.width * 0.25,
      size.height * 0.9,
      size.width * 0.5,
      size.height * 0.6,
    );
    path.quadraticBezierTo(
      size.width * 0.75,
      size.height * 0.3,
      size.width,
      size.height * 0.5,
    );

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}


// -----------------------------------------------------------------------------
// Framed Card Implementations (Metallic Gold & Deep Burgundy Frames with Hover)
// -----------------------------------------------------------------------------

class _FramedKpiCard extends StatefulWidget {
  final AdminCardAccent accent;
  final IconData icon;
  final String title;
  final String value;
  final double? width;

  const _FramedKpiCard({
    required this.accent,
    required this.icon,
    required this.title,
    required this.value,
    this.width,
  });

  @override
  State<_FramedKpiCard> createState() => _FramedKpiCardState();
}

class _FramedKpiCardState extends State<_FramedKpiCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = _AdminCardColors.of(widget.accent);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeInOut,
        width: widget.width,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: _hovered ? colors.hoverBgColor : colors.bgColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _hovered ? colors.hoverBorderColor : colors.borderColor,
            width: _hovered ? 1.1 : 0.9,
          ),
          boxShadow: [
            BoxShadow(
              color: _hovered ? colors.shadowColor : Colors.black.withValues(alpha: 0.4),
              blurRadius: _hovered ? 10 : 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: colors.iconBgColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colors.iconBorderColor, width: 0.8),
              ),
              child: Icon(widget.icon, color: colors.iconColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.title,
                    style: const TextStyle(
                      color: Color(0xFF9CA3AF),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.value,
                    style: const TextStyle(
                      color: Color(0xFFF3EEE5),
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FramedVerificationCard extends StatefulWidget {
  final AdminCardAccent accent;
  final IconData icon;
  final String title;
  final int count;
  final String description;
  final VoidCallback onTap;

  const _FramedVerificationCard({
    required this.accent,
    required this.icon,
    required this.title,
    required this.count,
    required this.description,
    required this.onTap,
  });

  @override
  State<_FramedVerificationCard> createState() => _FramedVerificationCardState();
}

class _FramedVerificationCardState extends State<_FramedVerificationCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = _AdminCardColors.of(widget.accent);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(14),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeInOut,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: _hovered ? colors.hoverBgColor : colors.bgColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _hovered ? colors.hoverBorderColor : colors.borderColor,
                width: _hovered ? 1.1 : 0.9,
              ),
              boxShadow: [
                BoxShadow(
                  color: _hovered ? colors.shadowColor : Colors.black.withValues(alpha: 0.4),
                  blurRadius: _hovered ? 10 : 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: colors.iconBgColor,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: colors.iconBorderColor, width: 0.8),
                      ),
                      child: Icon(widget.icon, color: colors.iconColor, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.title,
                            style: const TextStyle(
                              color: Color(0xFFF3EEE5),
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 3),
                          RichText(
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: '${widget.count} ',
                                  style: const TextStyle(
                                    color: Color(0xFFF3EEE5),
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const TextSpan(
                                  text: 'pending requests',
                                  style: TextStyle(
                                    color: Color(0xFF9CA3AF),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        widget.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF71717A),
                          fontSize: 11.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _hovered ? const Color(0xFFE2C044) : const Color(0xFFD4AF37),
                          width: 1.0,
                        ),
                      ),
                      child: const Icon(
                        Icons.arrow_forward_rounded,
                        size: 14,
                        color: Color(0xFFD4AF37),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FramedPerformanceMetricTile extends StatefulWidget {
  final AdminCardAccent accent;
  final IconData icon;
  final String title;
  final String value;
  final Color waveColor;

  const _FramedPerformanceMetricTile({
    required this.accent,
    required this.icon,
    required this.title,
    required this.value,
    required this.waveColor,
  });

  @override
  State<_FramedPerformanceMetricTile> createState() => _FramedPerformanceMetricTileState();
}

class _FramedPerformanceMetricTileState extends State<_FramedPerformanceMetricTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = _AdminCardColors.of(widget.accent);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _hovered ? colors.hoverBgColor : colors.bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _hovered ? colors.hoverBorderColor : colors.borderColor,
            width: _hovered ? 1.1 : 0.9,
          ),
          boxShadow: [
            BoxShadow(
              color: _hovered ? colors.shadowColor : Colors.black.withValues(alpha: 0.4),
              blurRadius: _hovered ? 10 : 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: colors.iconBgColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: colors.iconBorderColor, width: 0.8),
                  ),
                  child: Icon(widget.icon, color: colors.iconColor, size: 16),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.title,
                    style: const TextStyle(
                      color: Color(0xFF9CA3AF),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              widget.value,
              style: const TextStyle(
                color: Color(0xFFF3EEE5),
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            CustomPaint(
              size: const Size(double.infinity, 12),
              painter: _WavePainter(color: widget.waveColor),
            ),
          ],
        ),
      ),
    );
  }
}

class _FramedQuickActionCard extends StatefulWidget {
  final AdminCardAccent accent;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _FramedQuickActionCard({
    required this.accent,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  State<_FramedQuickActionCard> createState() => _FramedQuickActionCardState();
}

class _FramedQuickActionCardState extends State<_FramedQuickActionCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = _AdminCardColors.of(widget.accent);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeInOut,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _hovered ? colors.hoverBgColor : colors.bgColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _hovered ? colors.hoverBorderColor : colors.borderColor,
                width: _hovered ? 1.1 : 0.9,
              ),
              boxShadow: [
                BoxShadow(
                  color: _hovered ? colors.shadowColor : Colors.black.withValues(alpha: 0.4),
                  blurRadius: _hovered ? 10 : 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: colors.iconBgColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: colors.iconBorderColor, width: 0.8),
                      ),
                      child: Icon(widget.icon, color: colors.iconColor, size: 18),
                    ),
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _hovered ? const Color(0xFFE2C044) : const Color(0xFFD4AF37),
                          width: 1.0,
                        ),
                      ),
                      child: const Icon(
                        Icons.arrow_forward_rounded,
                        size: 12,
                        color: Color(0xFFD4AF37),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  widget.title,
                  style: const TextStyle(
                    color: Color(0xFFF3EEE5),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  widget.subtitle,
                  style: const TextStyle(
                    color: Color(0xFF71717A),
                    fontSize: 11,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
