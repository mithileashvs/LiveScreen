import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../shared/widgets/admin/admin_sidebar.dart';
import '../../shared/widgets/admin/admin_top_bar.dart';
import '../../shared/widgets/admin/admin_stat_card.dart';
import '../../shared/widgets/admin/admin_status_badge.dart';
import '../../admin/models/movie_content.dart';
import '../../admin/services/movie_repository.dart';
import '../../shared/platform/video_upload_stub.dart'
    if (dart.library.html) '../../shared/platform/video_upload_web.dart';
import 'producer_dashboard_screen.dart';
import 'my_movies_screen.dart';
import 'movie_edit_screen.dart';
import 'producer_analytics_screen.dart';
import 'producer_profile_screen.dart';
import 'producer_settings_screen.dart';
import 'producer_help_screen.dart';

/// 'Trailers & Assets' Screen for Producer Admin.
/// Implements the master dark cinematic design language (Black, Gold & Burgundy).
/// Allows producers to inspect and manage web trailers, immersive 3D trailer
/// assets, and poster art across all movies in their catalog.
class ProducerAssetsScreen extends StatefulWidget {
  const ProducerAssetsScreen({super.key});

  @override
  State<ProducerAssetsScreen> createState() => _ProducerAssetsScreenState();
}

class _ProducerAssetsScreenState extends State<ProducerAssetsScreen> {
  List<MovieContent> _movies = [];
  bool _loading = true;
  String? _uploadingMovieId;

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

  Future<void> _handleUploadImmersive(MovieContent movie) async {
    setState(() => _uploadingMovieId = movie.id);
    try {
      final producerId = movie.producerId ??
          Supabase.instance.client.auth.currentUser?.id ??
          'producer';
      final result = await pickAndUploadImmersiveTrailer(producerId: producerId);
      if (!mounted) return;

      if (result == null) {
        setState(() => _uploadingMovieId = null);
        return;
      }

      if (!result.isSuccess) {
        setState(() => _uploadingMovieId = null);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.errorMessage ?? 'Upload failed.'),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }

      movie.immersiveTrailerUrl = result.storageUrl ?? '';
      await movieRepository.updateMovie(movie);
      if (!mounted) return;

      setState(() => _uploadingMovieId = null);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Uploaded ${result.fileName ?? "immersive trailer"}.'),
          backgroundColor: const Color(0xFF10B981),
        ),
      );
      _loadMovies();
    } catch (e) {
      if (!mounted) return;
      setState(() => _uploadingMovieId = null);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upload error: $e'), backgroundColor: Colors.redAccent),
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
      ).then((_) => _loadMovies());
    } else if (key == 'assets') {
      // already here
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
      activeKey: 'assets',
      mainNavItems: navItems,
      onSelectKey: _navigateTo,
      onProfile: () => _navigateTo('profile'),
      onSettings: () => _navigateTo('settings'),
      onHelpSupport: () => _navigateTo('help'),
    );

    final webTrailersCount = _movies.where((m) => m.trailerUrl.isNotEmpty).length;
    final immersiveCount = _movies.where((m) => m.immersiveTrailerUrl.isNotEmpty).length;
    final posterCount = _movies.where((m) => m.thumbnail.isNotEmpty).length;

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
                  searchPlaceholder: 'Search media assets, trailers, posters...',
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
                              // Page Header
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: const [
                                  Text(
                                    'Trailers & Assets',
                                    style: TextStyle(
                                      fontSize: 26,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFFFFFFFF),
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Manage video trailers, 3D immersive cinema assets, and posters across your catalog.',
                                    style: TextStyle(fontSize: 13.5, color: Color(0xFF9CA3AF)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),

                              // Quick KPI Cards
                              Row(
                                children: [
                                  Expanded(
                                    child: AdminStatCard(
                                      icon: Icons.ondemand_video_rounded,
                                      iconColor: const Color(0xFFD4AF37),
                                      value: '$webTrailersCount',
                                      label: 'Web Trailers Linked',
                                      trendText: 'YouTube streams',
                                      isTrendPositive: webTrailersCount > 0,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: AdminStatCard(
                                      icon: Icons.view_in_ar_rounded,
                                      iconColor: const Color(0xFF10B981),
                                      iconBgColor: const Color(0x2210B981),
                                      value: '$immersiveCount',
                                      label: '3D Venue Assets',
                                      trendText: 'Unity screen player ready',
                                      isTrendPositive: immersiveCount > 0,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: AdminStatCard(
                                      icon: Icons.image_outlined,
                                      iconColor: const Color(0xFF8B1024),
                                      iconBgColor: const Color(0x338B1024),
                                      value: '$posterCount',
                                      label: 'Posters Uploaded',
                                      trendText: 'Key art configured',
                                      isTrendPositive: posterCount > 0,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 28),

                              // Asset List
                              if (_movies.isEmpty)
                                Container(
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
                                      const Icon(Icons.video_collection_outlined, size: 48, color: Color(0xFF71717A)),
                                      const SizedBox(height: 14),
                                      const Text('No Movies in Catalog', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFFFFFFFF))),
                                      const SizedBox(height: 6),
                                      const Text(
                                        'Create a movie to start managing trailers and media assets.',
                                        style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 18),
                                      ElevatedButton.icon(
                                        onPressed: () => _navigateTo('submit_movie'),
                                        icon: const Icon(Icons.add_rounded, size: 18),
                                        label: const Text('Submit New Movie', style: TextStyle(fontWeight: FontWeight.w700)),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFFD4AF37),
                                          foregroundColor: Colors.black,
                                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              else
                                ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: _movies.length,
                                  separatorBuilder: (_, _) => const SizedBox(height: 14),
                                  itemBuilder: (context, index) {
                                    final movie = _movies[index];
                                    final isUploading = _uploadingMovieId == movie.id;
                                    return _buildMovieAssetCard(movie, isUploading);
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

  Widget _buildMovieAssetCard(MovieContent movie, bool isUploading) {
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
          // Movie Header
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: movie.thumbnail.isNotEmpty
                    ? Image.network(
                        movie.thumbnail,
                        width: 44,
                        height: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => _posterFallback(),
                      )
                    : _posterFallback(),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      movie.title.isEmpty ? '(Untitled Movie)' : movie.title,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFFFFFFFF)),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${movie.language} • ${movie.genre} • ${movie.durationSeconds ~/ 60} mins',
                      style: const TextStyle(fontSize: 12.5, color: Color(0xFF9CA3AF)),
                    ),
                  ],
                ),
              ),
              AdminStatusBadge(status: movie.approvalStatus, showDot: true),
              const SizedBox(width: 12),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFD4AF37),
                  side: const BorderSide(color: Color(0xFFD4AF37), width: 1),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => MovieEditScreen(existing: movie)),
                  ).then((_) => _loadMovies());
                },
                child: const Text('Edit Details', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFF1A1A22)),
          const SizedBox(height: 16),

          // Asset Channels Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Web Trailer Channel
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF14141A),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF1E1E26)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.play_circle_outline_rounded,
                            size: 18,
                            color: movie.trailerUrl.isNotEmpty ? const Color(0xFFD4AF37) : const Color(0xFF71717A),
                          ),
                          const SizedBox(width: 8),
                          const Text('YouTube Web Trailer', style: TextStyle(color: Color(0xFFFFFFFF), fontWeight: FontWeight.w600, fontSize: 13)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        movie.trailerUrl.isNotEmpty ? movie.trailerUrl : 'No YouTube trailer URL linked yet.',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: movie.trailerUrl.isNotEmpty ? const Color(0xFF9CA3AF) : const Color(0xFF71717A),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // 3D Immersive Venue Asset Channel
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF14141A),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF1E1E26)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.view_in_ar_rounded,
                            size: 18,
                            color: movie.immersiveTrailerUrl.isNotEmpty ? const Color(0xFF10B981) : const Color(0xFF71717A),
                          ),
                          const SizedBox(width: 8),
                          const Text('3D Venue Screen Video', style: TextStyle(color: Color(0xFFFFFFFF), fontWeight: FontWeight.w600, fontSize: 13)),
                          const Spacer(),
                          if (isUploading)
                            const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFD4AF37)))
                          else
                            InkWell(
                              onTap: () => _handleUploadImmersive(movie),
                              child: Row(
                                children: [
                                  Icon(
                                    movie.immersiveTrailerUrl.isNotEmpty ? Icons.refresh_rounded : Icons.cloud_upload_outlined,
                                    size: 14,
                                    color: const Color(0xFFD4AF37),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    movie.immersiveTrailerUrl.isNotEmpty ? 'Replace' : 'Upload',
                                    style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 11.5, fontWeight: FontWeight.w700),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        movie.immersiveTrailerUrl.isNotEmpty
                            ? 'Asset synchronized with Unity screen player.'
                            : 'No MP4/WebM uploaded. Playback will show standby screen.',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: movie.immersiveTrailerUrl.isNotEmpty ? const Color(0xFF10B981) : const Color(0xFF71717A),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _posterFallback() {
    return Container(
      width: 44,
      height: 60,
      decoration: BoxDecoration(
        color: const Color(0xFF1C180E),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0x33D4AF37)),
      ),
      child: const Center(
        child: Icon(Icons.movie_creation_outlined, color: Color(0xFFD4AF37), size: 22),
      ),
    );
  }
}
