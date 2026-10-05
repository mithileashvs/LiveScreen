import 'package:flutter/material.dart';
import '../../shared/widgets/admin/admin_sidebar.dart';
import '../../shared/widgets/admin/admin_top_bar.dart';
import '../../shared/widgets/admin/admin_stat_card.dart';
import '../../shared/widgets/admin/admin_status_badge.dart';
import '../../shared/widgets/admin/admin_section_header.dart';
import '../../admin/models/movie_content.dart';
import '../../admin/services/movie_repository.dart';
import 'my_movies_screen.dart';
import 'movie_edit_screen.dart';
import 'producer_submissions_screen.dart';
import 'producer_analytics_screen.dart';
import 'producer_assets_screen.dart';
import 'producer_profile_screen.dart';
import 'producer_settings_screen.dart';
import 'producer_help_screen.dart';

/// The Redesigned LiveScreen Producer Admin Dashboard.
/// Strictly reproduces the master visual design reference media_1790891530751.png:
/// - Dark cinematic aesthetic: Black #070709, Metallic Gold #D4AF37, Deep Burgundy #6E071A
/// - Sidebar: Dashboard (active pill), My Movies, Submit Movie, Trailers & Assets, Analytics,
///   Separator, Profile, Settings, Help & Support, and bottom 3-line branding.
/// - Top Bar: "PRODUCER ADMIN", search bar, notifications, and Producer Admin profile pill.
/// - Header: Dynamic greeting ("Good Morning!") with formatted date and overview subtext.
/// - 4 Overview KPI Cards: Total Submissions, Pending Review, Approved Movies, Rejected Movies.
/// - Quick Actions: Submit New Movie, Manage My Movies, Trailers & Assets, View Analytics.
/// - 2-Column lower layout:
///   - Left (~58%): Recent Submissions table (Date, Movie with poster, Details, Status)
///   - Right (~42%): My Movies list (Poster, Title/Genre, Status badge, Updated date, Gold Edit CTA)
/// - Powered by REAL LiveScreen database records via movieRepository. Zero fake data.
class ProducerDashboardScreen extends StatefulWidget {
  const ProducerDashboardScreen({super.key});

  @override
  State<ProducerDashboardScreen> createState() => _ProducerDashboardScreenState();
}

class _ProducerDashboardScreenState extends State<ProducerDashboardScreen> {
  List<MovieContent> _movies = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadMovies();
  }

  Future<void> _loadMovies() async {
    setState(() => _loading = true);
    try {
      final movies = await movieRepository.getMyMovies();
      if (mounted) {
        setState(() {
          _movies = movies;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openEditor([MovieContent? existing]) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => MovieEditScreen(existing: existing)),
    );
    if (saved == true) _loadMovies();
  }

  void _navigateTo(String key) {
    if (key == 'dashboard') {
      // already on dashboard
    } else if (key == 'my_movies') {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const MyMoviesScreen()),
      ).then((_) => _loadMovies());
    } else if (key == 'submit_movie') {
      _openEditor();
    } else if (key == 'assets') {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const ProducerAssetsScreen()),
      ).then((_) => _loadMovies());
    } else if (key == 'analytics') {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const ProducerAnalyticsScreen()),
      ).then((_) => _loadMovies());
    } else if (key == 'submissions') {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const ProducerSubmissionsScreen()),
      ).then((_) => _loadMovies());
    } else if (key == 'profile') {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const ProducerProfileScreen()),
      ).then((_) => _loadMovies());
    } else if (key == 'settings') {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const ProducerSettingsScreen()),
      ).then((_) => _loadMovies());
    } else if (key == 'help') {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const ProducerHelpScreen()),
      ).then((_) => _loadMovies());
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning!';
    if (hour < 17) return 'Good Afternoon!';
    return 'Good Evening!';
  }

  String _getFormattedDate() {
    final now = DateTime.now();
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${weekdays[now.weekday - 1]}, ${now.day} ${months[now.month - 1]} ${now.year}';
  }

  String _formatDate(DateTime dt) {
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
      activeKey: 'dashboard',
      mainNavItems: navItems,
      onSelectKey: _navigateTo,
      onProfile: () => _navigateTo('profile'),
      onSettings: () => _navigateTo('settings'),
      onHelpSupport: () => _navigateTo('help'),
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
                  profileSubtitle: 'Sunrise Productions',
                  showTheatreSelector: false,
                  searchPlaceholder: 'Search movies, submissions, trailers...',
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
                              // Top Greeting & Dynamic Date
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _getGreeting(),
                                          style: const TextStyle(
                                            fontSize: 26,
                                            fontWeight: FontWeight.w800,
                                            color: Color(0xFFFFFFFF),
                                            letterSpacing: -0.5,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        const Text(
                                          "Here's an overview of your movie submissions and content.",
                                          style: TextStyle(
                                            fontSize: 13.5,
                                            color: Color(0xFF9CA3AF),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    _getFormattedDate(),
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF9CA3AF),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),

                              // 4 Overview KPI Cards
                              _buildOverviewCards(),
                              const SizedBox(height: 28),

                              // Quick Actions (4 Cards)
                              _buildQuickActionsSection(),
                              const SizedBox(height: 28),

                              // Lower 2-Column Section (Recent Submissions + My Movies)
                              LayoutBuilder(
                                builder: (context, constraints) {
                                  if (constraints.maxWidth > 950) {
                                    return Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          flex: 58,
                                          child: _buildRecentSubmissionsSection(),
                                        ),
                                        const SizedBox(width: 18),
                                        Expanded(
                                          flex: 42,
                                          child: _buildMyMoviesSection(),
                                        ),
                                      ],
                                    );
                                  } else {
                                    return Column(
                                      children: [
                                        _buildRecentSubmissionsSection(),
                                        const SizedBox(height: 24),
                                        _buildMyMoviesSection(),
                                      ],
                                    );
                                  }
                                },
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

  Widget _buildOverviewCards() {
    final total = _movies.length;
    final pending = _movies.where((m) => m.approvalStatus == 'submitted' || m.approvalStatus == 'under_review').length;
    final approved = _movies.where((m) => m.approvalStatus == 'approved').length;
    final rejected = _movies.where((m) => m.approvalStatus == 'rejected').length;

    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = (constraints.maxWidth - 36) / 4;
        final isWide = cardWidth > 170;

        final cards = [
          AdminStatCard(
            icon: Icons.movie_outlined,
            iconColor: const Color(0xFFC9A227),
            iconBgColor: const Color(0x22C9A227),
            iconBorderColor: const Color(0x40C9A227),
            value: '$total',
            label: 'Total Submissions',
            trendArrow: total > 0 ? '↑ ' : '— ',
            trendText: total > 0 ? '+$total' : '0',
            trendSubtitle: total > 0 ? '$total total records' : 'No records',
            trendColor: const Color(0xFF10B981),
            borderColor: const Color(0x55C9A227),
            borderHoverColor: const Color(0x99D4AF37),
          ),
          AdminStatCard(
            icon: Icons.access_time_rounded,
            iconColor: const Color(0xFFE03E52),
            iconBgColor: const Color(0x2B6B1422),
            iconBorderColor: const Color(0x556B1422),
            value: '$pending',
            label: 'Pending Review',
            trendArrow: pending > 0 ? '↑ ' : '— ',
            trendText: pending > 0 ? '+$pending' : '0',
            trendSubtitle: pending > 0 ? '$pending in review' : '0 awaiting',
            trendColor: pending > 0 ? const Color(0xFFE03E52) : const Color(0xFF71717A),
            borderColor: const Color(0x666B1422),
            borderHoverColor: const Color(0xAA8B1024),
          ),
          AdminStatCard(
            icon: Icons.check_circle_outline_rounded,
            iconColor: const Color(0xFFC9A227),
            iconBgColor: const Color(0x22C9A227),
            iconBorderColor: const Color(0x40C9A227),
            value: '$approved',
            label: 'Approved Movies',
            trendArrow: approved > 0 ? '↑ ' : '— ',
            trendText: approved > 0 ? '+$approved' : '0',
            trendSubtitle: approved > 0 ? '$approved live in catalog' : 'None approved',
            trendColor: const Color(0xFF10B981),
            borderColor: const Color(0x55C9A227),
            borderHoverColor: const Color(0x99D4AF37),
          ),
          AdminStatCard(
            icon: Icons.cancel_outlined,
            iconColor: const Color(0xFFE03E52),
            iconBgColor: const Color(0x2B6B1422),
            iconBorderColor: const Color(0x556B1422),
            value: '$rejected',
            label: 'Rejected Movies',
            trendArrow: rejected > 0 ? '↑ ' : '— ',
            trendText: rejected > 0 ? '+$rejected' : '0',
            trendSubtitle: rejected > 0 ? '$rejected needs revision' : '0 rejected',
            trendColor: rejected > 0 ? const Color(0xFFE03E52) : const Color(0xFF71717A),
            borderColor: const Color(0x666B1422),
            borderHoverColor: const Color(0xAA8B1024),
          ),
        ];

        if (!isWide) {
          return Column(
            children: [
              Row(
                children: [
                  Expanded(child: cards[0]),
                  const SizedBox(width: 12),
                  Expanded(child: cards[1]),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: cards[2]),
                  const SizedBox(width: 12),
                  Expanded(child: cards[3]),
                ],
              ),
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: cards[0]),
            const SizedBox(width: 12),
            Expanded(child: cards[1]),
            const SizedBox(width: 12),
            Expanded(child: cards[2]),
            const SizedBox(width: 12),
            Expanded(child: cards[3]),
          ],
        );
      },
    );
  }

  Widget _buildQuickActionsSection() {
    final actions = [
      _QuickActionItem(
        title: 'Submit New Movie',
        subtitle: 'Add a new movie for platform review.',
        icon: Icons.add_box_outlined,
        onTap: () => _openEditor(),
      ),
      _QuickActionItem(
        title: 'Manage My Movies',
        subtitle: 'View and manage your submitted movies.',
        icon: Icons.theaters_outlined,
        onTap: () => _navigateTo('my_movies'),
      ),
      _QuickActionItem(
        title: 'Trailers & Assets',
        subtitle: 'Upload and manage trailers, posters and assets.',
        icon: Icons.smart_display_outlined,
        onTap: () => _navigateTo('assets'),
      ),
      _QuickActionItem(
        title: 'View Analytics',
        subtitle: 'Check your movie performance and reach.',
        icon: Icons.bar_chart_rounded,
        onTap: () => _navigateTo('analytics'),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFFF3EEE5),
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Manage your content and submissions.',
          style: TextStyle(
            fontSize: 13,
            color: Color(0xFF9CA3AF),
          ),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final crossAxisCount = constraints.maxWidth > 850 ? 4 : (constraints.maxWidth > 550 ? 2 : 1);
            if (crossAxisCount == 4) {
              return Row(
                children: [
                  for (int i = 0; i < actions.length; i++) ...[
                    if (i > 0) const SizedBox(width: 12),
                    Expanded(child: _QuickActionCardWidget(item: actions[i])),
                  ],
                ],
              );
            }
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: actions.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 2.4,
              ),
              itemBuilder: (context, index) => _QuickActionCardWidget(item: actions[index]),
            );
          },
        ),
      ],
    );
  }

  Widget _buildRecentSubmissionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AdminSectionHeader(
          title: 'Recent Submissions',
          actionLabel: 'View All →',
          onAction: () => _navigateTo('submissions'),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0F0F12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF1E1E26)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: _movies.isEmpty
                ? Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.movie_filter_outlined, size: 40, color: Color(0xFF71717A)),
                        const SizedBox(height: 12),
                        const Text(
                          'No Recent Submissions',
                          style: TextStyle(color: Color(0xFFFFFFFF), fontSize: 15, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Submit your movie for platform review to begin distribution.',
                          style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12.5),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFD4AF37),
                            side: const BorderSide(color: Color(0xFFD4AF37)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: () => _openEditor(),
                          icon: const Icon(Icons.add_rounded, size: 16),
                          label: const Text('Submit Movie', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                        ),
                      ],
                    ),
                  )
                : Column(
                    children: [
                      // Header Row
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: const BoxDecoration(
                          color: Color(0xFF14141A),
                          border: Border(bottom: BorderSide(color: Color(0xFF1E1E26))),
                        ),
                        child: Row(
                          children: const [
                            SizedBox(
                              width: 95,
                              child: Text('Date', style: TextStyle(color: Color(0xFF71717A), fontSize: 11.5, fontWeight: FontWeight.w600)),
                            ),
                            Expanded(
                              flex: 4,
                              child: Text('Movie', style: TextStyle(color: Color(0xFF71717A), fontSize: 11.5, fontWeight: FontWeight.w600)),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text('Details', style: TextStyle(color: Color(0xFF71717A), fontSize: 11.5, fontWeight: FontWeight.w600)),
                            ),
                            SizedBox(
                              width: 85,
                              child: Text('Status', style: TextStyle(color: Color(0xFF71717A), fontSize: 11.5, fontWeight: FontWeight.w600)),
                            ),
                          ],
                        ),
                      ),
                      for (int i = 0; i < (_movies.length > 4 ? 4 : _movies.length); i++)
                        _buildSubmissionRow(_movies[i], isLast: i == (_movies.length > 4 ? 3 : _movies.length - 1)),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmissionRow(MovieContent movie, {bool isLast = false}) {
    final dateStr = movie.createdAt != null ? _formatDate(movie.createdAt!) : 'Recently';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: isLast ? null : const Border(bottom: BorderSide(color: Color(0xFF1A1A22), width: 0.8)),
      ),
      child: Row(
        children: [
          // Date
          SizedBox(
            width: 95,
            child: Text(
              dateStr,
              style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 12),
            ),
          ),

          // Movie Poster & Title
          Expanded(
            flex: 4,
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: movie.thumbnail.isNotEmpty
                      ? Image.network(
                          movie.thumbnail,
                          width: 32,
                          height: 44,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => _posterFallback(),
                        )
                      : _posterFallback(),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        movie.title.isEmpty ? '(Untitled Movie)' : movie.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Color(0xFFFFFFFF), fontSize: 13, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${movie.language} • ${movie.genre}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Details
          Expanded(
            flex: 2,
            child: Text(
              movie.durationSeconds > 0 ? '${movie.durationSeconds ~/ 60} mins' : 'Feature Film',
              style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 12),
            ),
          ),

          // Status Badge
          SizedBox(
            width: 85,
            child: AdminStatusBadge(
              status: movie.approvalStatus == 'submitted'
                  ? 'Pending'
                  : (movie.approvalStatus == 'under_review' ? 'In Review' : movie.approvalStatus),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMyMoviesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AdminSectionHeader(
          title: 'My Movies',
          actionLabel: 'View All →',
          onAction: () => _navigateTo('my_movies'),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0F0F12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF1E1E26)),
          ),
          child: _movies.isEmpty
              ? Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.movie_creation_outlined, size: 40, color: Color(0xFF71717A)),
                      const SizedBox(height: 12),
                      const Text(
                        'No Movies Added Yet',
                        style: TextStyle(color: Color(0xFFFFFFFF), fontSize: 15, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Add titles to manage media assets and track status.',
                        style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12.5),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    for (int i = 0; i < (_movies.length > 4 ? 4 : _movies.length); i++)
                      _buildMyMovieTile(_movies[i], isLast: i == (_movies.length > 4 ? 3 : _movies.length - 1)),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildMyMovieTile(MovieContent movie, {bool isLast = false}) {
    final updatedStr = movie.updatedAt != null ? _formatDate(movie.updatedAt!) : (movie.createdAt != null ? _formatDate(movie.createdAt!) : 'Recently');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        border: isLast ? null : const Border(bottom: BorderSide(color: Color(0xFF1A1A22), width: 0.8)),
      ),
      child: Row(
        children: [
          // Poster
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: movie.thumbnail.isNotEmpty
                ? Image.network(
                    movie.thumbnail,
                    width: 34,
                    height: 48,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => _posterFallback(),
                  )
                : _posterFallback(),
          ),
          const SizedBox(width: 12),

          // Title & Language • Genre
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  movie.title.isEmpty ? '(Untitled Movie)' : movie.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFFFFFFFF)),
                ),
                const SizedBox(height: 2),
                Text(
                  '${movie.language} • ${movie.genre}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Status Badge
          AdminStatusBadge(
            status: movie.approvalStatus == 'submitted'
                ? 'Pending'
                : (movie.approvalStatus == 'under_review' ? 'In Review' : movie.approvalStatus),
          ),
          const SizedBox(width: 12),

          // Updated Date
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Updated', style: TextStyle(color: Color(0xFF71717A), fontSize: 10)),
              Text(updatedStr, style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 11, fontWeight: FontWeight.w500)),
            ],
          ),
          const SizedBox(width: 12),

          // Gold Outlined Edit Button
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFD4AF37),
              side: const BorderSide(color: Color(0xFFD4AF37), width: 1),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              minimumSize: const Size(54, 30),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
            onPressed: () => _openEditor(movie),
            child: const Text('Edit', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right_rounded, size: 16, color: Color(0xFF71717A)),
        ],
      ),
    );
  }

  Widget _posterFallback() {
    return Container(
      width: 34,
      height: 48,
      decoration: BoxDecoration(
        color: const Color(0xFF1C180E),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0x33D4AF37)),
      ),
      child: const Center(
        child: Icon(Icons.movie_creation_outlined, color: Color(0xFFD4AF37), size: 18),
      ),
    );
  }
}

class _QuickActionItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _QuickActionItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });
}

class _QuickActionCardWidget extends StatefulWidget {
  final _QuickActionItem item;

  const _QuickActionCardWidget({required this.item});

  @override
  State<_QuickActionCardWidget> createState() => _QuickActionCardWidgetState();
}

class _QuickActionCardWidgetState extends State<_QuickActionCardWidget> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        decoration: BoxDecoration(
          color: _hovered ? const Color(0x1F6B1422) : const Color(0xFF09090C),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _hovered ? const Color(0x666B1422) : const Color(0xFF1E1E26),
            width: 1,
          ),
          boxShadow: _hovered
              ? [
                  BoxShadow(
                    color: const Color(0x405A0F1B),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: widget.item.onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              child: Row(
                children: [
                  // Gold squircle icon
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0x1FC9A227),
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(color: const Color(0x40C9A227)),
                    ),
                    child: Icon(widget.item.icon, size: 19, color: const Color(0xFFC9A227)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          widget.item.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFF3EEE5),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.item.subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF9CA3AF),
                            height: 1.25,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 15,
                    color: _hovered ? const Color(0xFFF3EEE5) : const Color(0xFFC9A227),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

