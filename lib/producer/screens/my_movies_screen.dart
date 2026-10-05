import 'package:flutter/material.dart';
import '../../shared/widgets/admin/admin_sidebar.dart';
import '../../shared/widgets/admin/admin_top_bar.dart';
import '../../shared/widgets/admin/admin_status_badge.dart';
import '../../admin/models/movie_content.dart';
import '../../admin/services/movie_repository.dart';
import 'producer_dashboard_screen.dart';
import 'movie_edit_screen.dart';
import 'producer_assets_screen.dart';
import 'producer_analytics_screen.dart';
import 'producer_submissions_screen.dart';
import 'producer_profile_screen.dart';
import 'producer_settings_screen.dart';
import 'producer_help_screen.dart';

/// Redesigned 'My Movies' Screen for Producer Admin.
/// Implements the master dark cinematic design language (Black, Gold & Burgundy).
/// Full catalog management with search, status filtering, editing, and submission lifecycle.
class MyMoviesScreen extends StatefulWidget {
  const MyMoviesScreen({super.key});

  @override
  State<MyMoviesScreen> createState() => _MyMoviesScreenState();
}

class _MyMoviesScreenState extends State<MyMoviesScreen> {
  late Future<List<MovieContent>> _future;
  String _selectedFilter = 'All';
  String _searchQuery = '';

  static const List<String> _filters = ['All', 'Draft', 'Pending', 'Approved', 'Rejected'];

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    setState(() {
      _future = movieRepository.getMyMovies();
    });
  }

  Future<void> _openEditor([MovieContent? existing]) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => MovieEditScreen(existing: existing)),
    );
    if (saved == true) _refresh();
  }

  Future<void> _deleteMovie(MovieContent movie) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF111116),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0x66EF4444)),
        ),
        title: const Text('Delete Movie?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        content: Text(
          'Are you sure you want to delete "${movie.title}"? This action cannot be undone.',
          style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF9CA3AF))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await movieRepository.deleteMovie(movie.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Movie deleted successfully.')),
          );
          _refresh();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not delete movie: $e')),
          );
        }
      }
    }
  }

  void _navigateTo(String key) {
    if (key == 'dashboard') {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const ProducerDashboardScreen()),
      );
    } else if (key == 'my_movies') {
      // already here
    } else if (key == 'submit_movie') {
      _openEditor();
    } else if (key == 'assets') {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const ProducerAssetsScreen()),
      );
    } else if (key == 'analytics') {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const ProducerAnalyticsScreen()),
      );
    } else if (key == 'submissions') {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const ProducerSubmissionsScreen()),
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
                  searchPlaceholder: 'Search by title, genre, language...',
                  showDrawerButton: !isDesktop,
                  onSearchChanged: (val) => setState(() => _searchQuery = val),
                  onProfileTap: () => _navigateTo('profile'),
                  onSettingsTap: () => _navigateTo('settings'),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  'My Movies',
                                  style: TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFFFFFFFF),
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Browse, filter, and manage your full catalog of submitted productions.',
                                  style: TextStyle(fontSize: 13.5, color: Color(0xFF9CA3AF)),
                                ),
                              ],
                            ),
                            ElevatedButton.icon(
                              onPressed: () => _openEditor(),
                              icon: const Icon(Icons.add_rounded, size: 18),
                              label: const Text('New Movie', style: TextStyle(fontWeight: FontWeight.w700)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFD4AF37),
                                foregroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Filter Chips Row
                        SizedBox(
                          height: 38,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: _filters.length,
                            separatorBuilder: (_, _) => const SizedBox(width: 8),
                            itemBuilder: (context, index) {
                              final f = _filters[index];
                              final isSelected = f == _selectedFilter;
                              return FilterChip(
                                label: Text(f),
                                selected: isSelected,
                                onSelected: (_) => setState(() => _selectedFilter = f),
                                backgroundColor: const Color(0xFF14141A),
                                selectedColor: const Color(0xFF6E071A),
                                labelStyle: TextStyle(
                                  color: isSelected ? Colors.white : const Color(0xFFEDEAE2),
                                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                  fontSize: 12.5,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(19),
                                  side: BorderSide(
                                    color: isSelected ? const Color(0xFFD4AF37) : const Color(0xFF22222A),
                                    width: isSelected ? 1.2 : 0.8,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Movie List / Grid
                        FutureBuilder<List<MovieContent>>(
                          future: _future,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState != ConnectionState.done) {
                              return const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(48),
                                  child: CircularProgressIndicator(color: Color(0xFFD4AF37)),
                                ),
                              );
                            }

                            final all = snapshot.data ?? [];
                            var filtered = all;

                            // Apply status filter
                            if (_selectedFilter == 'Draft') {
                              filtered = filtered.where((m) => m.approvalStatus == 'draft').toList();
                            } else if (_selectedFilter == 'Pending') {
                              filtered = filtered.where((m) => m.approvalStatus == 'submitted' || m.approvalStatus == 'under_review').toList();
                            } else if (_selectedFilter == 'Approved') {
                              filtered = filtered.where((m) => m.approvalStatus == 'approved').toList();
                            } else if (_selectedFilter == 'Rejected') {
                              filtered = filtered.where((m) => m.approvalStatus == 'rejected').toList();
                            }

                            // Apply search query
                            if (_searchQuery.trim().isNotEmpty) {
                              final q = _searchQuery.trim().toLowerCase();
                              filtered = filtered.where((m) =>
                                  m.title.toLowerCase().contains(q) ||
                                  m.language.toLowerCase().contains(q) ||
                                  m.genre.toLowerCase().contains(q)).toList();
                            }

                            if (filtered.isEmpty) {
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
                                    const Icon(Icons.movie_outlined, size: 48, color: Color(0xFF71717A)),
                                    const SizedBox(height: 14),
                                    Text(
                                      all.isEmpty ? 'No movies yet' : 'No movies found in this filter',
                                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFFFFFFFF)),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      all.isEmpty
                                          ? 'Create a movie and publish it so theatre admins can pick it for their theatres.'
                                          : 'Try adjusting your search or switching to another filter status.',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
                                    ),
                                    if (all.isEmpty) ...[
                                      const SizedBox(height: 18),
                                      ElevatedButton.icon(
                                        onPressed: () => _openEditor(),
                                        icon: const Icon(Icons.add, size: 18),
                                        label: const Text('New Movie', style: TextStyle(fontWeight: FontWeight.w700)),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFFD4AF37),
                                          foregroundColor: Colors.black,
                                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              );
                            }

                            return ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: filtered.length,
                              separatorBuilder: (_, _) => const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final movie = filtered[index];
                                return _buildMovieCard(movie);
                              },
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

  Widget _buildMovieCard(MovieContent movie) {
    final updatedStr = movie.updatedAt != null
        ? _formatDate(movie.updatedAt!)
        : (movie.createdAt != null ? _formatDate(movie.createdAt!) : 'Recently');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F0F12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF1E1E26)),
      ),
      child: Row(
        children: [
          // Poster
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: movie.thumbnail.isNotEmpty
                ? Image.network(
                    movie.thumbnail,
                    width: 52,
                    height: 72,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => _posterFallback(),
                  )
                : _posterFallback(),
          ),
          const SizedBox(width: 16),

          // Title & Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        movie.title.isEmpty ? '(Untitled movie)' : movie.title,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFFFFFFFF)),
                      ),
                    ),
                    AdminStatusBadge(
                      status: movie.approvalStatus == 'submitted'
                          ? 'Pending'
                          : (movie.approvalStatus == 'under_review' ? 'In Review' : movie.approvalStatus),
                      showDot: true,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${movie.language} • ${movie.genre} • ${movie.durationSeconds ~/ 60} min',
                  style: const TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      movie.trailerUrl.isNotEmpty ? Icons.check_circle_outline : Icons.highlight_off,
                      size: 14,
                      color: movie.trailerUrl.isNotEmpty ? const Color(0xFF10B981) : const Color(0xFF71717A),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      movie.trailerUrl.isNotEmpty ? 'Web Trailer Linked' : 'No Web Trailer',
                      style: TextStyle(
                        fontSize: 11,
                        color: movie.trailerUrl.isNotEmpty ? const Color(0xFF10B981) : const Color(0xFF71717A),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(
                      movie.immersiveTrailerUrl.isNotEmpty ? Icons.view_in_ar : Icons.highlight_off,
                      size: 14,
                      color: movie.immersiveTrailerUrl.isNotEmpty ? const Color(0xFF10B981) : const Color(0xFF71717A),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      movie.immersiveTrailerUrl.isNotEmpty ? '3D Video Ready' : 'No 3D Video',
                      style: TextStyle(
                        fontSize: 11,
                        color: movie.immersiveTrailerUrl.isNotEmpty ? const Color(0xFF10B981) : const Color(0xFF71717A),
                      ),
                    ),
                    const Spacer(),
                    Text('Updated $updatedStr', style: const TextStyle(fontSize: 11, color: Color(0xFF71717A))),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),

          // Action Buttons
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFD4AF37),
                  side: const BorderSide(color: Color(0xFFD4AF37)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () => _openEditor(movie),
                child: const Text('Edit', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 20, color: Color(0xFF71717A)),
                tooltip: 'Delete Movie',
                onPressed: () => _deleteMovie(movie),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _posterFallback() {
    return Container(
      width: 52,
      height: 72,
      decoration: BoxDecoration(
        color: const Color(0xFF1C180E),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0x33D4AF37)),
      ),
      child: const Center(
        child: Icon(Icons.movie_creation_outlined, color: Color(0xFFD4AF37), size: 24),
      ),
    );
  }
}
