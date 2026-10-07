import 'package:flutter/material.dart';
import '../admin/models/movie_content.dart';
import '../admin/models/theatre_configuration.dart';
import '../admin/services/movie_repository.dart';
import '../admin/services/theatre_repository.dart';
import '../auth/screens/login_screen.dart';
import '../auth/services/auth_service.dart';
import '../data/demo_data.dart';
import '../models/event.dart';
import '../theme/customer_theme.dart';
import '../widgets/customer_widgets.dart';
import 'customer_concerts_screen.dart';
import 'customer_events_screen.dart';
import 'customer_help_screen.dart';
import 'customer_movies_screen.dart';
import 'customer_sports_screen.dart';
import 'event_details_screen.dart';
import 'movie_details_screen.dart';
import 'profile_screen.dart';
import 'theatre_detail_screen.dart';
import 'tickets_screen.dart';

/// The Customer Dashboard for LiveScreen.
///
/// Implements the unified customer theme (black, metallic gold, burgundy) and
/// strict category page isolation:
/// - HOME: Single vertically scrollable discovery page containing previews for
///   Movies, Events, Sports, and Concerts. Scrolling does not change pages.
/// - MOVIES: Dedicated page showing MOVIES ONLY (Platform Admin verified & published).
/// - EVENTS: Dedicated page showing EVENTS ONLY.
/// - SPORTS: Dedicated page showing SPORTS ONLY.
/// - CONCERTS: Dedicated page showing CONCERTS ONLY.
class UserDashboardScreen extends StatefulWidget {
  const UserDashboardScreen({super.key});

  @override
  State<UserDashboardScreen> createState() => _UserDashboardScreenState();
}

class _UserDashboardScreenState extends State<UserDashboardScreen> {
  String _selectedNav = 'Home';
  String _selectedLocation = 'Mumbai, India';
  String _searchQuery = '';

  List<MovieContent> _publishedMovies = [];
  bool _isLoadingMovies = true;

  late final PageController _heroController;
  int _currentHeroIndex = 0;

  static const List<String> _locations = [
    'Mumbai, India',
    'Chennai, India',
    'Bengaluru, India',
    'Delhi, India',
    'Hyderabad, India',
  ];

  @override
  void initState() {
    super.initState();
    _heroController = PageController();
    _loadPublishedMovies();
  }

  Future<void> _loadPublishedMovies() async {
    try {
      final movies = await movieRepository.getPublishedMovies();
      if (mounted) {
        setState(() {
          _publishedMovies = movies;
          _isLoadingMovies = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingMovies = false);
    }
  }

  @override
  void dispose() {
    _heroController.dispose();
    super.dispose();
  }

  void _selectNav(String nav) {
    if (nav == 'My Bookings') {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const TicketsScreen()));
      return;
    }
    if (nav == 'Settings') {
      _showSettingsDialog();
      return;
    }

    setState(() {
      _selectedNav = nav;
    });
  }

  void _openMovieDetails(MovieContent movie) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MovieDetailsScreen(movie: movie),
      ),
    );
  }

  void _openEventDetails(EventModel event) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EventDetailsScreen(event: event),
      ),
    );
  }

  Future<void> _logout() async {
    await authService.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: CustomerColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: CustomerColors.borderSubtle),
        ),
        title: const Text('Settings', style: TextStyle(color: CustomerColors.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('Language: English', style: TextStyle(color: CustomerColors.textSecondary, fontSize: 13.5)),
            SizedBox(height: 8),
            Text('Video Quality: High / Auto (4K HDR)', style: TextStyle(color: CustomerColors.textSecondary, fontSize: 13.5)),
            SizedBox(height: 8),
            Text('Notifications: Enabled', style: TextStyle(color: CustomerColors.textSecondary, fontSize: 13.5)),
            SizedBox(height: 8),
            Text('LiveScreen Version 2.0 (Cinema Redesign)', style: TextStyle(color: CustomerColors.gold, fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close', style: TextStyle(color: CustomerColors.gold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = authService.currentSession?.userId ?? 'Alex';

    return Scaffold(
      backgroundColor: CustomerColors.background,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth >= 1050;

          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Sidebar (Fixed on Desktop)
              if (isDesktop)
                CustomerSidebar(
                  selectedNav: _selectedNav,
                  onSelectNav: _selectNav,
                ),

              // 2. Main Content Area
              Expanded(
                child: Column(
                  children: [
                    // Top Bar
                    CustomerTopBar(
                      selectedLocation: _selectedLocation,
                      locations: _locations,
                      userName: currentUserId,
                      onLocationChanged: (loc) => setState(() => _selectedLocation = loc),
                      onSearchChanged: (q) => setState(() => _searchQuery = q.trim()),
                      onProfileMenuSelected: (val) {
                        if (val == 'profile') {
                          setState(() => _selectedNav = 'Profile');
                        } else if (val == 'logout') {
                          _logout();
                        }
                      },
                      showMenuButton: !isDesktop,
                      onMenuPressed: () => Scaffold.of(context).openDrawer(),
                    ),

                    // Active Page View
                    Expanded(
                      child: _buildCurrentView(),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      drawer: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth >= 1050) return const SizedBox.shrink();
          return Drawer(
            backgroundColor: CustomerColors.background,
            child: CustomerSidebar(
              selectedNav: _selectedNav,
              onSelectNav: (nav) {
                Navigator.of(context).pop();
                _selectNav(nav);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildCurrentView() {
    switch (_selectedNav) {
      case 'Movies':
        return CustomerMoviesScreen(
          onSelectMovie: _openMovieDetails,
        );
      case 'Events':
        return const CustomerEventsScreen();
      case 'Sports':
        return const CustomerSportsScreen();
      case 'Concerts':
        return const CustomerConcertsScreen();
      case 'Profile':
        return const ProfileScreen();
      case 'Help & Support':
        return const CustomerHelpScreen();
      case 'Home':
      default:
        return _buildHomeDiscoveryPage();
    }
  }

  // =========================================================================
  // HOME DISCOVERY PAGE (Vertically scrollable preview sections)
  // =========================================================================

  Widget _buildHomeDiscoveryPage() {
    final eventsList = DemoData.events.where((e) =>
        e.category == 'Events' || e.category == 'Theatre' || e.category == 'Comedy').toList();
    final sportsList = DemoData.events.where((e) => e.category == 'Sports').toList();
    final concertsList = DemoData.events.where((e) => e.category == 'Concerts').toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Cinematic Hero Banner (Reference Image 1)
          _buildHeroBanner(),

          const SizedBox(height: 32),

          // 2. Recommended Movies Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: CustomerSectionHeader(
              titlePrefix: 'Recommended',
              titleHighlight: 'Movies',
              onSeeAll: () => setState(() => _selectedNav = 'Movies'),
            ),
          ),
          const SizedBox(height: 16),
          _buildMoviesRow(),

          const SizedBox(height: 36),

          // 3. Featured Events Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: CustomerSectionHeader(
              titlePrefix: 'Upcoming',
              titleHighlight: 'Events',
              onSeeAll: () => setState(() => _selectedNav = 'Events'),
            ),
          ),
          const SizedBox(height: 16),
          _buildCategoryRow(
            items: eventsList,
            categoryIcon: Icons.confirmation_number_outlined,
            categoryColor: CustomerColors.gold,
          ),

          const SizedBox(height: 36),

          // 4. Stadium & Arena Sports Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: CustomerSectionHeader(
              titlePrefix: 'Stadium & Arena',
              titleHighlight: 'Sports',
              onSeeAll: () => setState(() => _selectedNav = 'Sports'),
            ),
          ),
          const SizedBox(height: 16),
          _buildCategoryRow(
            items: sportsList,
            categoryIcon: Icons.sports_cricket_outlined,
            categoryColor: CustomerColors.gold,
          ),

          const SizedBox(height: 36),

          // 5. Live Music & Concerts Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: CustomerSectionHeader(
              titlePrefix: 'Live Music &',
              titleHighlight: 'Concerts',
              onSeeAll: () => setState(() => _selectedNav = 'Concerts'),
            ),
          ),
          const SizedBox(height: 16),
          _buildCategoryRow(
            items: concertsList,
            categoryIcon: Icons.music_note_outlined,
            categoryColor: CustomerColors.gold,
          ),

          const SizedBox(height: 36),

          // 6. Interactive 3D Venue Feature Banner
          _build3DVenuePromoBanner(),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // =========================================================================
  // HERO BANNER (Reference Image 1)
  // =========================================================================

  Widget _buildHeroBanner() {
    final heroMovies = _publishedMovies.isNotEmpty
        ? _publishedMovies
        : [
            MovieContent(
              id: 'demo_hero',
              title: 'Cinematic Experience',
              description: 'Experience your favourite films with interactive 3D sightlines.',
            ),
          ];
    final heroCount = heroMovies.length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        height: 310,
        decoration: BoxDecoration(
          color: CustomerColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: CustomerColors.borderGold, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: CustomerColors.gold.withValues(alpha: 0.15),
              blurRadius: 24,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(19),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Interactive PageView for published movies
              PageView.builder(
                controller: _heroController,
                itemCount: heroCount,
                onPageChanged: (index) {
                  setState(() {
                    _currentHeroIndex = index;
                  });
                },
                itemBuilder: (context, index) {
                  final heroMovie = heroMovies[index];
                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      // Background Image / Artwork
                      if (heroMovie.thumbnail.isNotEmpty)
                        Image.network(
                          heroMovie.thumbnail,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => _heroFallbackBackground(),
                        )
                      else
                        _heroFallbackBackground(),

                      // Multi-stop horizontal gradient: provides contrast under left text
                      // while leaving center and right artwork vibrant and clearly visible
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            stops: const [0.0, 0.40, 0.70, 1.0],
                            colors: [
                              Colors.black.withValues(alpha: 0.88),
                              Colors.black.withValues(alpha: 0.48),
                              Colors.black.withValues(alpha: 0.12),
                              Colors.black.withValues(alpha: 0.02),
                            ],
                          ),
                        ),
                      ),

                      // Atmospheric burgundy cinematic tint in lower-left
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomLeft,
                            end: Alignment.topRight,
                            stops: const [0.0, 0.55, 1.0],
                            colors: [
                              CustomerColors.burgundyDark.withValues(alpha: 0.35),
                              Colors.transparent,
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),

                      // Content overlay
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 32),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: CustomerColors.gold.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: CustomerColors.gold),
                              ),
                              child: const Text(
                                'FEATURED PREMIERE',
                                style: TextStyle(
                                  color: CustomerColors.gold,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              heroMovie.title.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w900,
                                color: CustomerColors.textPrimary,
                                letterSpacing: 1.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 520),
                              child: Text(
                                heroMovie.description.isNotEmpty
                                    ? heroMovie.description
                                    : 'Experience this release with interactive 3D theatre sightlines and cinema acoustics.',
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  color: CustomerColors.textSecondary,
                                  height: 1.4,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(height: 22),
                            ElevatedButton(
                              onPressed: () {
                                if (_publishedMovies.isNotEmpty) {
                                  _openMovieDetails(heroMovie);
                                } else {
                                  setState(() => _selectedNav = 'Movies');
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: CustomerColors.burgundy,
                                foregroundColor: Colors.white,
                                side: const BorderSide(color: CustomerColors.gold, width: 1.2),
                                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(24),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Text('Explore Shows', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                                  SizedBox(width: 8),
                                  Icon(Icons.arrow_forward_rounded, size: 16),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),

              // Left & Right Carousel Arrows (Reference Image 1)
              Positioned(
                left: 14,
                top: 0,
                bottom: 0,
                child: Center(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: () {
                        if (heroCount > 1) {
                          final target = (_currentHeroIndex - 1 + heroCount) % heroCount;
                          _heroController.animateToPage(
                            target,
                            duration: const Duration(milliseconds: 320),
                            curve: Curves.easeInOut,
                          );
                        }
                      },
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.65),
                          shape: BoxShape.circle,
                          border: Border.all(color: CustomerColors.borderGoldSubtle),
                        ),
                        child: const Icon(Icons.chevron_left_rounded, color: CustomerColors.goldLight, size: 22),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                right: 14,
                top: 0,
                bottom: 0,
                child: Center(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: () {
                        if (heroCount > 1) {
                          final target = (_currentHeroIndex + 1) % heroCount;
                          _heroController.animateToPage(
                            target,
                            duration: const Duration(milliseconds: 320),
                            curve: Curves.easeInOut,
                          );
                        }
                      },
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.65),
                          shape: BoxShape.circle,
                          border: Border.all(color: CustomerColors.borderGoldSubtle),
                        ),
                        child: const Icon(Icons.chevron_right_rounded, color: CustomerColors.goldLight, size: 22),
                      ),
                    ),
                  ),
                ),
              ),

              // Bottom Carousel Dots (Reference Image 1)
              Positioned(
                bottom: 16,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    heroCount.clamp(1, 5),
                    (i) => GestureDetector(
                      onTap: () {
                        if (heroCount > 1) {
                          _heroController.animateToPage(
                            i,
                            duration: const Duration(milliseconds: 320),
                            curve: Curves.easeInOut,
                          );
                        }
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: i == _currentHeroIndex ? 24 : 6,
                        height: 5,
                        decoration: BoxDecoration(
                          color: i == _currentHeroIndex ? CustomerColors.gold : const Color(0xFF2A2B32),
                          borderRadius: BorderRadius.circular(3),
                          border: i == _currentHeroIndex
                              ? Border.all(color: CustomerColors.goldLight.withValues(alpha: 0.5), width: 0.5)
                              : null,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _heroFallbackBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF2E120A),
            Color(0xFF140804),
            Color(0xFF08080A),
          ],
        ),
      ),
    );
  }

  // =========================================================================
  // MOVIES ROW IN HOME
  // =========================================================================

  Widget _buildMoviesRow() {
    if (_isLoadingMovies) {
      return const SizedBox(
        height: 260,
        child: Center(child: CircularProgressIndicator(color: CustomerColors.gold)),
      );
    }

    final movies = _searchQuery.isNotEmpty
        ? _publishedMovies
            .where((m) =>
                m.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                m.description.toLowerCase().contains(_searchQuery.toLowerCase()))
            .toList()
        : _publishedMovies;

    if (movies.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: CustomerColors.surfaceCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: CustomerColors.borderSubtle),
          ),
          child: const Text(
            'No verified movies matching your search. Check back soon.',
            style: TextStyle(color: CustomerColors.textSecondary, fontSize: 13.5),
          ),
        ),
      );
    }

    return SizedBox(
      height: 370,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        itemCount: movies.length,
        separatorBuilder: (_, _) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          final movie = movies[index];
          return CustomerMovieCard(
            title: movie.title.isNotEmpty ? movie.title : '(Untitled)',
            posterUrl: movie.thumbnail.isNotEmpty ? movie.thumbnail : null,
            genre: movie.durationSeconds > 0
                ? '${movie.durationSeconds ~/ 60}m • Cinema'
                : 'Cinema Release',
            width: 195,
            onTap: () => _openMovieDetails(movie),
          );
        },
      ),
    );
  }

  // =========================================================================
  // CATEGORY ROWS IN HOME (Events, Sports, Concerts)
  // =========================================================================

  Widget _buildCategoryRow({
    required List<EventModel> items,
    required IconData categoryIcon,
    required Color categoryColor,
  }) {
    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: CustomerColors.surfaceCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: CustomerColors.borderSubtle),
          ),
          child: const Text(
            'New releases in this category are coming soon.',
            style: TextStyle(color: CustomerColors.textMuted, fontSize: 13),
          ),
        ),
      );
    }

    return SizedBox(
      height: 220,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          final item = items[index];
          return GestureDetector(
            onTap: () => _openEventDetails(item),
            child: Container(
              width: 260,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: CustomerColors.surfaceCard,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: CustomerColors.borderGoldSubtle),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    CustomerColors.surfaceCard,
                    CustomerColors.surfaceCard,
                    CustomerColors.burgundyDark.withValues(alpha: 0.15),
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: CustomerColors.surfaceElevated,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: CustomerColors.borderGoldSubtle),
                        ),
                        child: Icon(categoryIcon, color: categoryColor, size: 20),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.genre.toUpperCase(),
                              style: const TextStyle(
                                color: CustomerColors.goldLight,
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                            Text(
                              item.title,
                              style: const TextStyle(
                                color: CustomerColors.textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    item.description,
                    style: const TextStyle(color: CustomerColors.textSecondary, fontSize: 12, height: 1.35),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        item.duration.isNotEmpty ? item.duration : 'Live',
                        style: const TextStyle(color: CustomerColors.textMuted, fontSize: 12),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: CustomerColors.burgundy,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: CustomerColors.goldLight.withValues(alpha: 0.6),
                            width: 0.8,
                          ),
                        ),
                        child: const Text(
                          'View',
                          style: TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w700),
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
    );
  }

  // =========================================================================
  // 3D VENUE PROMO BANNER (Unity integration entry)
  // =========================================================================

  Widget _build3DVenuePromoBanner() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        decoration: BoxDecoration(
          color: CustomerColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: CustomerColors.borderGold, width: 1.2),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF260B12),
              Color(0xFF140F18),
              Color(0xFF0F1116),
            ],
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: CustomerColors.goldSubtle,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: CustomerColors.gold),
                    ),
                    child: const Text(
                      'INTERACTIVE 3D VENUE PREVIEWS',
                      style: TextStyle(
                        color: CustomerColors.gold,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Different Screens. Same Emotions.',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: CustomerColors.textPrimary,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Discover unforgettable experiences near you with interactive 3D venue sightlines before booking.',
                    style: TextStyle(
                      fontSize: 13,
                      color: CustomerColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const _ExploreTheatresScreen(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: CustomerColors.gold,
                      foregroundColor: CustomerColors.background,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                    child: const Text('Explore Theatres'),
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

class _ExploreTheatresScreen extends StatelessWidget {
  const _ExploreTheatresScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CustomerColors.background,
      appBar: AppBar(
        title: const Text('Explore Theatres', style: TextStyle(color: CustomerColors.textPrimary)),
        backgroundColor: CustomerColors.surface,
        iconTheme: const IconThemeData(color: CustomerColors.textPrimary),
      ),
      body: FutureBuilder<List<TheatreConfiguration>>(
        future: theatreRepository.getPublishedTheatres(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator(color: CustomerColors.gold));
          }
          final theatres = snapshot.data ?? [];
          if (theatres.isEmpty) {
            return const Center(
              child: Text(
                'No published theatres yet.',
                style: TextStyle(color: CustomerColors.textSecondary),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: theatres.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final theatre = theatres[index];
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: CustomerColors.surfaceCard,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: CustomerColors.borderSubtle),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: CustomerColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.theaters_outlined,
                        color: CustomerColors.gold,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            theatre.basicInfo.name,
                            style: const TextStyle(
                              color: CustomerColors.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${theatre.seats.length} seats • 3D Venue Sightlines Ready',
                            style: const TextStyle(
                              color: CustomerColors.textMuted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => TheatreDetailScreen(theatreId: theatre.id),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: CustomerColors.burgundy,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                      child: const Text('View Theatre'),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
