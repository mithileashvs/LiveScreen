import 'package:flutter/material.dart';
import '../../shared/widgets/admin/admin_sidebar.dart';
import '../../shared/widgets/admin/admin_top_bar.dart';
import '../../shared/widgets/admin/admin_status_badge.dart';
import '../../admin/models/movie_content.dart';
import '../../admin/services/movie_repository.dart';
import 'producer_dashboard_screen.dart';
import 'my_movies_screen.dart';
import 'producer_assets_screen.dart';
import 'producer_analytics_screen.dart';
import 'movie_edit_screen.dart';
import 'producer_profile_screen.dart';
import 'producer_settings_screen.dart';
import 'producer_help_screen.dart';

/// Redesigned 'Content Submissions' Screen for Producer Admin.
/// Implements the master dark cinematic design language (Black, Gold & Burgundy).
/// Tracks movie submission lifecycle, review notes, and verification statuses.
class ProducerSubmissionsScreen extends StatefulWidget {
  const ProducerSubmissionsScreen({super.key});

  @override
  State<ProducerSubmissionsScreen> createState() => _ProducerSubmissionsScreenState();
}

class _ProducerSubmissionsScreenState extends State<ProducerSubmissionsScreen> {
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
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const ProducerAnalyticsScreen()),
      );
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
      activeKey: 'my_movies',
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
                  searchPlaceholder: 'Search submissions, review status...',
                  showDrawerButton: !isDesktop,
                  onProfileTap: () => _navigateTo('profile'),
                  onSettingsTap: () => _navigateTo('settings'),
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
                              'Content Submissions',
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFFFFFFFF),
                                letterSpacing: -0.5,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Track movies submitted for Platform Admin review and verification.',
                              style: TextStyle(fontSize: 13.5, color: Color(0xFF9CA3AF)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        FutureBuilder<List<MovieContent>>(
                          future: _moviesFuture,
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(48),
                                  child: CircularProgressIndicator(color: Color(0xFFD4AF37)),
                                ),
                              );
                            }

                            final allMovies = snapshot.data!;
                            final submittedMovies = allMovies
                                .where((m) => m.approvalStatus != 'draft')
                                .toList();

                            if (submittedMovies.isEmpty) {
                              return Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(48),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0F0F12),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: const Color(0xFF1E1E26)),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.assignment_outlined, size: 48, color: Color(0xFF71717A)),
                                    const SizedBox(height: 14),
                                    const Text('No Active Submissions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFFFFFFFF))),
                                    const SizedBox(height: 6),
                                    const Text(
                                      'Draft movies can be submitted for Platform Admin review from your movies list.',
                                      style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 18),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFFD4AF37),
                                        foregroundColor: Colors.black,
                                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      ),
                                      onPressed: () => _navigateTo('my_movies'),
                                      child: const Text('View Movies', style: TextStyle(fontWeight: FontWeight.w700)),
                                    ),
                                  ],
                                ),
                              );
                            }

                            return Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFF0F0F12),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: const Color(0xFF1E1E26)),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: Table(
                                  columnWidths: const {
                                    0: FlexColumnWidth(1.4),
                                    1: FlexColumnWidth(3),
                                    2: FlexColumnWidth(1.8),
                                    3: FlexColumnWidth(2.5),
                                    4: FlexColumnWidth(1.4),
                                  },
                                  children: [
                                    TableRow(
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF14141A),
                                        border: Border(bottom: BorderSide(color: Color(0xFF1E1E26))),
                                      ),
                                      children: const [
                                        Padding(
                                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                          child: Text('Date', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: Color(0xFF71717A))),
                                        ),
                                        Padding(
                                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                          child: Text('Movie', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: Color(0xFF71717A))),
                                        ),
                                        Padding(
                                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                          child: Text('Review Status', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: Color(0xFF71717A))),
                                        ),
                                        Padding(
                                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                          child: Text('Notes / Reason', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: Color(0xFF71717A))),
                                        ),
                                        Padding(
                                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                          child: Text('Action', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: Color(0xFF71717A))),
                                        ),
                                      ],
                                    ),
                                    for (final movie in submittedMovies)
                                      TableRow(
                                        decoration: const BoxDecoration(
                                          border: Border(bottom: BorderSide(color: Color(0xFF1A1A22), width: 0.8)),
                                        ),
                                        children: [
                                          // Date
                                          Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                            child: Text(
                                              movie.createdAt != null ? _formatDate(movie.createdAt!) : '—',
                                              style: const TextStyle(fontSize: 12.5, color: Color(0xFF9CA3AF)),
                                            ),
                                          ),

                                          // Movie
                                          Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
                                                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: Color(0xFFFFFFFF)),
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                      const SizedBox(height: 2),
                                                      Text(
                                                        '${movie.language} • ${movie.genre}',
                                                        style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),

                                          // Status
                                          Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                            child: Align(
                                              alignment: Alignment.centerLeft,
                                              child: AdminStatusBadge(
                                                status: movie.approvalStatus == 'submitted'
                                                    ? 'Pending'
                                                    : (movie.approvalStatus == 'under_review' ? 'In Review' : movie.approvalStatus),
                                                showDot: true,
                                              ),
                                            ),
                                          ),

                                          // Notes / Reason
                                          Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                            child: Text(
                                              movie.reviewReason?.isNotEmpty == true ? movie.reviewReason! : 'Awaiting reviewer feedback.',
                                              style: TextStyle(
                                                fontSize: 12.5,
                                                color: movie.reviewReason?.isNotEmpty == true ? const Color(0xFFEF4444) : const Color(0xFF71717A),
                                              ),
                                            ),
                                          ),

                                          // Action
                                          Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                            child: OutlinedButton(
                                              style: OutlinedButton.styleFrom(
                                                foregroundColor: const Color(0xFFD4AF37),
                                                side: const BorderSide(color: Color(0xFFD4AF37)),
                                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                                minimumSize: const Size(60, 30),
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                              ),
                                              onPressed: () async {
                                                await Navigator.of(context).push(
                                                  MaterialPageRoute(builder: (_) => MovieEditScreen(existing: movie)),
                                                );
                                                _refresh();
                                              },
                                              child: const Text('Edit', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700)),
                                            ),
                                          ),
                                        ],
                                      ),
                                  ],
                                ),
                              ),
                            );
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

  Widget _posterFallback() {
    return Container(
      width: 32,
      height: 44,
      decoration: BoxDecoration(
        color: const Color(0xFF1C180E),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0x33D4AF37)),
      ),
      child: const Center(
        child: Icon(Icons.movie_creation_outlined, color: Color(0xFFD4AF37), size: 16),
      ),
    );
  }
}
