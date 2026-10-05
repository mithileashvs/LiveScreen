import 'package:flutter/material.dart';
import '../../shared/widgets/admin/admin_sidebar.dart';
import '../../shared/widgets/admin/admin_top_bar.dart';
import '../../shared/widgets/admin/admin_stat_card.dart';
import '../../admin/models/movie_content.dart';
import '../../admin/services/movie_repository.dart';
import 'producer_dashboard_screen.dart';
import 'my_movies_screen.dart';
import 'movie_edit_screen.dart';
import 'producer_assets_screen.dart';
import 'producer_profile_screen.dart';
import 'producer_settings_screen.dart';
import 'producer_help_screen.dart';

/// Redesigned 'Analytics & Performance' Screen for Producer Admin.
/// Implements the master dark cinematic design language (Black, Gold & Burgundy).
/// Calculates real-time metrics strictly from the producer's actual movie catalog:
/// - Approval rates and submission pipeline distributions
/// - Genre and language distribution breakdowns
/// - Asset compliance (web trailers, 3D cinema trailers, poster artwork)
class ProducerAnalyticsScreen extends StatefulWidget {
  const ProducerAnalyticsScreen({super.key});

  @override
  State<ProducerAnalyticsScreen> createState() => _ProducerAnalyticsScreenState();
}

class _ProducerAnalyticsScreenState extends State<ProducerAnalyticsScreen> {
  late Future<List<MovieContent>> _moviesFuture;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    setState(() {
      _moviesFuture = movieRepository.getMyMovies();
    });
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
      ).then((_) => _refresh());
    } else if (key == 'assets') {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const ProducerAssetsScreen()),
      );
    } else if (key == 'analytics') {
      // already here
    } else if (key == 'profile') {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const ProducerProfileScreen()),
      );
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
      activeKey: 'analytics',
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
                  searchPlaceholder: 'Search analytics and reports...',
                  showDrawerButton: !isDesktop,
                  onProfileTap: () => _navigateTo('profile'),
                  onSettingsTap: () => _navigateTo('settings'),
                ),
                Expanded(
                  child: FutureBuilder<List<MovieContent>>(
                    future: _moviesFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37)));
                      }
                      final movies = snapshot.data ?? [];
                      final total = movies.length;
                      final approved = movies.where((m) => m.approvalStatus == 'approved').length;
                      final inReview = movies.where((m) => m.approvalStatus == 'submitted' || m.approvalStatus == 'under_review').length;
                      final drafts = movies.where((m) => m.approvalStatus == 'draft').length;
                      final rejected = movies.where((m) => m.approvalStatus == 'rejected').length;
                      final published = movies.where((m) => m.status == 'published').length;

                      final approvalRate = total > 0 ? ((approved / total) * 100).toStringAsFixed(0) : '0';

                      // Genre distribution
                      final genreCounts = <String, int>{};
                      for (final m in movies) {
                        final g = m.genre.trim().isEmpty ? 'Drama' : m.genre.trim();
                        genreCounts[g] = (genreCounts[g] ?? 0) + 1;
                      }

                      // Language distribution
                      final langCounts = <String, int>{};
                      for (final m in movies) {
                        final l = m.language.trim().isEmpty ? 'English' : m.language.trim();
                        langCounts[l] = (langCounts[l] ?? 0) + 1;
                      }

                      // Asset readiness
                      final withWebTrailer = movies.where((m) => m.trailerUrl.isNotEmpty).length;
                      final with3dTrailer = movies.where((m) => m.immersiveTrailerUrl.isNotEmpty).length;
                      final withPoster = movies.where((m) => m.thumbnail.isNotEmpty).length;

                      return SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: const [
                                    Text(
                                      'Analytics & Performance',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 24,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'Real-time metrics calculated from your movie catalog and submission pipeline.',
                                      style: TextStyle(
                                        color: Color(0xFF9CA3AF),
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                                OutlinedButton.icon(
                                  onPressed: _refresh,
                                  icon: const Icon(Icons.refresh_rounded, size: 16, color: Color(0xFFD4AF37)),
                                  label: const Text('Refresh', style: TextStyle(color: Color(0xFFD4AF37), fontSize: 13, fontWeight: FontWeight.w600)),
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(color: Color(0x66D4AF37)),
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),

                            // 4 KPI Cards
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final cardWidth = (constraints.maxWidth - 36) / 4;
                                final isWide = cardWidth > 180;

                                if (!isWide) {
                                  return Column(
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: AdminStatCard(
                                              icon: Icons.movie_outlined,
                                              iconColor: const Color(0xFFD4AF37),
                                              value: '$total',
                                              label: 'Total Titles',
                                              trendText: '$total registered',
                                              isTrendPositive: true,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: AdminStatCard(
                                              icon: Icons.verified_rounded,
                                              iconColor: const Color(0xFF10B981),
                                              value: '$approvalRate%',
                                              label: 'Approval Rate',
                                              trendText: '$approved approved',
                                              isTrendPositive: true,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: AdminStatCard(
                                              icon: Icons.pending_actions_rounded,
                                              iconColor: const Color(0xFFF59E0B),
                                              value: '$inReview',
                                              label: 'Under Review',
                                              trendText: '$inReview awaiting decision',
                                              isTrendPositive: inReview == 0,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: AdminStatCard(
                                              icon: Icons.theaters_rounded,
                                              iconColor: const Color(0xFF3B82F6),
                                              value: '$published',
                                              label: 'Live in Theatres',
                                              trendText: '$published published',
                                              isTrendPositive: true,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  );
                                }

                                return Row(
                                  children: [
                                    Expanded(
                                      child: AdminStatCard(
                                        icon: Icons.movie_outlined,
                                        iconColor: const Color(0xFFD4AF37),
                                        value: '$total',
                                        label: 'Total Titles',
                                        trendText: '$total registered',
                                        isTrendPositive: true,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: AdminStatCard(
                                        icon: Icons.verified_rounded,
                                        iconColor: const Color(0xFF10B981),
                                        value: '$approvalRate%',
                                        label: 'Approval Rate',
                                        trendText: '$approved approved',
                                        isTrendPositive: true,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: AdminStatCard(
                                        icon: Icons.pending_actions_rounded,
                                        iconColor: const Color(0xFFF59E0B),
                                        value: '$inReview',
                                        label: 'Under Review',
                                        trendText: '$inReview awaiting decision',
                                        isTrendPositive: inReview == 0,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: AdminStatCard(
                                        icon: Icons.theaters_rounded,
                                        iconColor: const Color(0xFF3B82F6),
                                        value: '$published',
                                        label: 'Live in Theatres',
                                        trendText: '$published published',
                                        isTrendPositive: true,
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                            const SizedBox(height: 28),

                            if (movies.isEmpty) ...[
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0F0F12),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: const Color(0x33D4AF37)),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 64,
                                      height: 64,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: const Color(0x1AD4AF37),
                                        border: Border.all(color: const Color(0x44D4AF37)),
                                      ),
                                      child: const Icon(Icons.bar_chart_rounded, color: Color(0xFFD4AF37), size: 32),
                                    ),
                                    const SizedBox(height: 16),
                                    const Text(
                                      'No Movie Analytics Available Yet',
                                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
                                    ),
                                    const SizedBox(height: 6),
                                    const Text(
                                      'Submit your first movie to view catalog distribution, approval rates, and pipeline performance.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
                                    ),
                                    const SizedBox(height: 20),
                                    ElevatedButton.icon(
                                      onPressed: () => _navigateTo('submit_movie'),
                                      icon: const Icon(Icons.add_rounded, size: 18, color: Colors.black),
                                      label: const Text('Submit Movie', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700)),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFFD4AF37),
                                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ] else ...[
                              // Two-column layout on Desktop
                              LayoutBuilder(
                                builder: (context, constraints) {
                                  final isWide = constraints.maxWidth > 800;

                                  final leftColumn = _buildCard(
                                    title: 'Review Pipeline Status',
                                    subtitle: 'Distribution of movies across verification stages',
                                    icon: Icons.track_changes_rounded,
                                    child: Column(
                                      children: [
                                        _buildProgressRow('Approved', approved, total, const Color(0xFF10B981)),
                                        const SizedBox(height: 16),
                                        _buildProgressRow('In Review / Submitted', inReview, total, const Color(0xFFF59E0B)),
                                        const SizedBox(height: 16),
                                        _buildProgressRow('Draft (Unsubmitted)', drafts, total, const Color(0xFF6B7280)),
                                        const SizedBox(height: 16),
                                        _buildProgressRow('Rejected', rejected, total, const Color(0xFFEF4444)),
                                      ],
                                    ),
                                  );

                                  final rightColumn = _buildCard(
                                    title: 'Asset Readiness for 3D Cinema',
                                    subtitle: 'Completeness of trailers and promotional visual assets',
                                    icon: Icons.video_library_rounded,
                                    child: Column(
                                      children: [
                                        _buildProgressRow('Poster Artwork', withPoster, total, const Color(0xFFD4AF37)),
                                        const SizedBox(height: 16),
                                        _buildProgressRow('Web Trailer (Embed Stream)', withWebTrailer, total, const Color(0xFF3B82F6)),
                                        const SizedBox(height: 16),
                                        _buildProgressRow('3D Spatial Cinema Video', with3dTrailer, total, const Color(0xFF8B5CF6)),
                                        const SizedBox(height: 20),
                                        Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: const Color(0x14D4AF37),
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: const Color(0x33D4AF37)),
                                          ),
                                          child: Row(
                                            children: const [
                                              Icon(Icons.info_outline_rounded, color: Color(0xFFD4AF37), size: 16),
                                              SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  'Trailers uploaded to 3D Cinema play on virtual cinema screens during the interactive walkthrough.',
                                                  style: TextStyle(color: Color(0xFFD4AF37), fontSize: 12),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  );

                                  if (isWide) {
                                    return Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Expanded(child: leftColumn),
                                        const SizedBox(width: 20),
                                        Expanded(child: rightColumn),
                                      ],
                                    );
                                  }

                                  return Column(
                                    children: [
                                      leftColumn,
                                      const SizedBox(height: 20),
                                      rightColumn,
                                    ],
                                  );
                                },
                              ),
                              const SizedBox(height: 20),

                              // Bottom Row: Genres & Languages
                              LayoutBuilder(
                                builder: (context, constraints) {
                                  final isWide = constraints.maxWidth > 800;

                                  final genreCard = _buildCard(
                                    title: 'Genre Distribution',
                                    subtitle: 'Movie count by creative genre',
                                    icon: Icons.category_rounded,
                                    child: genreCounts.isEmpty
                                        ? const Center(child: Text('No genres found', style: TextStyle(color: Color(0xFF9CA3AF))))
                                        : Column(
                                            children: genreCounts.entries.map((entry) {
                                              return Padding(
                                                padding: const EdgeInsets.only(bottom: 12),
                                                child: _buildProgressRow(entry.key, entry.value, total, const Color(0xFFD4AF37)),
                                              );
                                            }).toList(),
                                          ),
                                  );

                                  final langCard = _buildCard(
                                    title: 'Language Distribution',
                                    subtitle: 'Distribution of audio tracks and releases',
                                    icon: Icons.language_rounded,
                                    child: langCounts.isEmpty
                                        ? const Center(child: Text('No languages recorded', style: TextStyle(color: Color(0xFF9CA3AF))))
                                        : Column(
                                            children: langCounts.entries.map((entry) {
                                              return Padding(
                                                padding: const EdgeInsets.only(bottom: 12),
                                                child: _buildProgressRow(entry.key, entry.value, total, const Color(0xFF10B981)),
                                              );
                                            }).toList(),
                                          ),
                                  );

                                  if (isWide) {
                                    return Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Expanded(child: genreCard),
                                        const SizedBox(width: 20),
                                        Expanded(child: langCard),
                                      ],
                                    );
                                  }

                                  return Column(
                                    children: [
                                      genreCard,
                                      const SizedBox(height: 20),
                                      langCard,
                                    ],
                                  );
                                },
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0F0F12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF1E1E26)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0x14D4AF37),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 18, color: const Color(0xFFD4AF37)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Color(0xFF9CA3AF),
                        fontSize: 12,
                      ),
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

  Widget _buildProgressRow(String label, int count, int total, Color color) {
    final pct = total > 0 ? (count / total) : 0.0;
    final pctText = '${(pct * 100).toStringAsFixed(0)}%';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFFF7F5F0),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            Row(
              children: [
                Text(
                  '$count titles',
                  style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 12),
                ),
                const SizedBox(width: 8),
                Text(
                  pctText,
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: pct,
            minHeight: 6,
            backgroundColor: const Color(0xFF1E1E26),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}
