import 'package:flutter/material.dart';
import '../data/demo_data.dart';
import '../models/event.dart';
import '../theme/app_theme.dart';
import '../widgets/movie_card.dart';
import '../auth/services/auth_service.dart';
import '../auth/screens/login_screen.dart';
import '../admin/models/theatre_configuration.dart';
import '../admin/services/theatre_repository.dart';
import 'event_details_screen.dart';
import 'coming_soon_screen.dart';
import 'tickets_screen.dart';
import 'profile_screen.dart';
import 'theatre_detail_screen.dart';

/// The redesigned USER-role home, replacing MainNavScreen's bottom-nav
/// layout for this role. A desktop-first sidebar + top-bar layout, per the
/// reference design — MainNavScreen and its four tabs (HomeScreen,
/// ExploreScreen, TicketsScreen, ProfileScreen) are left completely intact
/// and untouched; TicketsScreen/ProfileScreen are simply reused from here
/// instead of being duplicated.
class UserDashboardScreen extends StatefulWidget {
  const UserDashboardScreen({super.key});

  @override
  State<UserDashboardScreen> createState() => _UserDashboardScreenState();
}

class _UserDashboardScreenState extends State<UserDashboardScreen> {
  static const List<String> _navCategories = ['Home', 'Movies', 'Concerts', 'Sports', 'Theatre', 'Events'];
  static const List<String> _filterCategories = ['All', 'Movies', 'Concerts', 'Sports', 'Theatre', 'Comedy', 'Events'];
  static const List<String> _locations = ['Chennai', 'Bengaluru', 'Mumbai', 'Delhi', 'Hyderabad'];

  String _selectedNav = 'Movies';
  String _selectedFilter = 'Movies';
  String _selectedLocation = 'Chennai';
  String _searchQuery = '';
  int _nowShowingPage = 0;
  int _heroIndex = 0;

  late final PageController _heroController;
  late Future<List<TheatreConfiguration>> _theatresFuture;

  @override
  void initState() {
    super.initState();
    _heroController = PageController();
    _theatresFuture = theatreRepository.getPublishedTheatres();
  }

  @override
  void dispose() {
    _heroController.dispose();
    super.dispose();
  }

  List<EventModel> get _visibleEvents {
    if (_searchQuery.trim().isNotEmpty) {
      final query = _searchQuery.trim().toLowerCase();
      return DemoData.events.where((e) => e.title.toLowerCase().contains(query)).toList();
    }
    if (_selectedFilter == 'All') return DemoData.events;
    return DemoData.events.where((e) => e.category == _selectedFilter).toList();
  }

  void _selectNav(String nav) {
    setState(() {
      _selectedNav = nav;
      _nowShowingPage = 0;
      if (nav == 'Home') {
        _selectedFilter = 'All';
      } else {
        _selectedFilter = nav;
      }
    });
  }

  void _selectFilter(String filter) {
    setState(() {
      _selectedFilter = filter;
      _selectedNav = _navCategories.contains(filter) ? filter : 'Home';
      _nowShowingPage = 0;
    });
  }

  void _openEvent(EventModel event) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => EventDetailsScreen(event: event)));
  }

  Future<void> _logout() async {
    await authService.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  void _showComingSoonSnack(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature is coming soon.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          _Sidebar(
            selectedNav: _selectedNav,
            onSelectNav: _selectNav,
            onMyBookings: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const TicketsScreen())),
            onWatchlist: () => _showComingSoonSnack('Watchlist'),
            onOffers: () => _showComingSoonSnack('Offers'),
            onTry3DVenue: () => _openExploreTheatres(),
          ),
          Expanded(
            child: Column(
              children: [
                _TopBar(
                  selectedLocation: _selectedLocation,
                  locations: _locations,
                  onLocationChanged: (loc) => setState(() => _selectedLocation = loc),
                  onSearchChanged: (q) => setState(() {
                    _searchQuery = q;
                    _nowShowingPage = 0;
                  }),
                  onProfileMenuSelected: _handleProfileMenuSelection,
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(bottom: 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        _CategoryFilterBar(
                          categories: _filterCategories,
                          selected: _selectedFilter,
                          onSelect: _selectFilter,
                        ),
                        const SizedBox(height: 20),
                        if (_searchQuery.trim().isEmpty) _buildHero(),
                        const SizedBox(height: 28),
                        _buildNowShowing(),
                        const SizedBox(height: 28),
                        _buildTheatrePromo(),
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

  void _openExploreTheatres() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const _ExploreTheatresScreen()),
    );
  }

  void _handleProfileMenuSelection(String value) {
    if (value == 'profile') {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ProfileScreen()));
    } else if (value == 'logout') {
      _logout();
    }
  }

  Widget _buildHero() {
    final heroEvents = DemoData.events.take(5).toList();
    if (heroEvents.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: SizedBox(
        height: 260,
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: PageView.builder(
                controller: _heroController,
                itemCount: heroEvents.length,
                onPageChanged: (i) => setState(() => _heroIndex = i),
                itemBuilder: (context, index) => _HeroSlide(
                  event: heroEvents[index],
                  onBookTickets: () => _openEvent(heroEvents[index]),
                  onWatchTrailer: () => _showComingSoonSnack('Trailers'),
                ),
              ),
            ),
            Positioned(
              bottom: 16,
              right: 24,
              child: Row(
                children: [
                  for (int i = 0; i < heroEvents.length; i++)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: i == _heroIndex ? 20 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: i == _heroIndex ? AppColors.accent : Colors.white.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(3),
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

  Widget _buildNowShowing() {
    final events = _visibleEvents;
    final title = _searchQuery.trim().isNotEmpty
        ? 'Results for "${_searchQuery.trim()}"'
        : (_selectedFilter == 'All' ? 'Now Showing' : _selectedFilter);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(title, style: AppTextStyles.heading),
              const Spacer(),
              if (_searchQuery.trim().isEmpty)
                TextButton.icon(
                  onPressed: () => Navigator.of(context)
                      .push(MaterialPageRoute(builder: (_) => const ComingSoonScreen())),
                  icon: const Text('See Coming Soon', style: TextStyle(color: AppColors.accent)),
                  label: const Icon(Icons.arrow_forward_rounded, size: 16, color: AppColors.accent),
                ),
            ],
          ),
          const SizedBox(height: 14),
          if (events.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Text('Nothing here yet.', style: AppTextStyles.body),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                const cardWidth = 190.0;
                const spacing = 18.0;
                final perPage = ((constraints.maxWidth + spacing) / (cardWidth + spacing))
                    .floor()
                    .clamp(1, 8);
                final totalPages = (events.length / perPage).ceil();
                final page = _nowShowingPage.clamp(0, totalPages - 1);
                final start = page * perPage;
                final pageItems = events.skip(start).take(perPage).toList();

                return Row(
                  children: [
                    _CarouselArrow(
                      icon: Icons.chevron_left_rounded,
                      enabled: page > 0,
                      onTap: () => setState(() => _nowShowingPage = page - 1),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Row(
                        children: [
                          for (int i = 0; i < pageItems.length; i++) ...[
                            MovieCard(
                              event: pageItems[i],
                              width: cardWidth,
                              onTap: () => _openEvent(pageItems[i]),
                            ),
                            if (i != pageItems.length - 1) const SizedBox(width: spacing),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    _CarouselArrow(
                      icon: Icons.chevron_right_rounded,
                      enabled: page < totalPages - 1,
                      onTap: () => setState(() => _nowShowingPage = page + 1),
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildTheatrePromo() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [AppColors.surfaceElevated, AppColors.surface],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Different Screens.', style: AppTextStyles.heading),
                  Text('Same Emotions.', style: AppTextStyles.heading),
                  const SizedBox(height: 8),
                  const Text(
                    'Discover unforgettable experiences near you.',
                    style: AppTextStyles.body,
                  ),
                ],
              ),
            ),
            ElevatedButton.icon(
              onPressed: _openExploreTheatres,
              icon: const Text('Explore Theatres'),
              label: const Icon(Icons.arrow_forward_rounded, size: 18, color: Colors.black),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroSlide extends StatelessWidget {
  final EventModel event;
  final VoidCallback onBookTickets;
  final VoidCallback onWatchTrailer;

  const _HeroSlide({required this.event, required this.onBookTickets, required this.onWatchTrailer});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            AppColors.background,
            AppColors.surfaceElevated.withValues(alpha: 0.9),
          ],
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            event.category == 'Movies' ? 'NOW IN THEATRES' : event.category.toUpperCase(),
            style: AppTextStyles.caption.copyWith(color: AppColors.accent, letterSpacing: 2),
          ),
          const SizedBox(height: 10),
          Text(
            event.title.toUpperCase(),
            style: AppTextStyles.displayLarge.copyWith(fontSize: 40, height: 1.05),
          ),
          const SizedBox(height: 10),
          Text(
            event.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.body.copyWith(fontSize: 15),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: onBookTickets,
                icon: const Text('Book Tickets'),
                label: const Icon(Icons.arrow_forward_rounded, size: 18, color: Colors.black),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: onWatchTrailer,
                icon: const Icon(Icons.play_circle_outline_rounded),
                label: const Text('Watch Trailer'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CarouselArrow extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  const _CarouselArrow({required this.icon, required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.25,
      child: IconButton(
        onPressed: enabled ? onTap : null,
        icon: Icon(icon),
        style: IconButton.styleFrom(
          backgroundColor: AppColors.surface,
          side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
      ),
    );
  }
}

class _CategoryFilterBar extends StatelessWidget {
  final List<String> categories;
  final String selected;
  final ValueChanged<String> onSelect;

  const _CategoryFilterBar({required this.categories, required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = category == selected;
          return GestureDetector(
            onTap: () => onSelect(category),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.accent : Colors.transparent,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isSelected ? AppColors.accent : Colors.white.withValues(alpha: 0.15),
                ),
              ),
              child: Text(
                category,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.black : AppColors.textSecondary,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final String selectedLocation;
  final List<String> locations;
  final ValueChanged<String> onLocationChanged;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onProfileMenuSelected;

  const _TopBar({
    required this.selectedLocation,
    required this.locations,
    required this.onLocationChanged,
    required this.onSearchChanged,
    required this.onProfileMenuSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 4),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 46,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search_rounded, color: AppColors.textMuted, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      onChanged: onSearchChanged,
                      style: AppTextStyles.body.copyWith(color: AppColors.textPrimary),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        isDense: true,
                        hintText: 'Search movies, theatres, or experiences...',
                        hintStyle: AppTextStyles.body,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
          PopupMenuButton<String>(
            color: AppColors.surfaceElevated,
            onSelected: onLocationChanged,
            itemBuilder: (context) => [
              for (final loc in locations) PopupMenuItem(value: loc, child: Text(loc)),
            ],
            child: Container(
              height: 46,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.location_on_outlined, size: 18, color: AppColors.accent),
                  const SizedBox(width: 6),
                  Text(selectedLocation, style: AppTextStyles.body.copyWith(color: AppColors.textPrimary)),
                  const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textMuted),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Stack(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                ),
                child: const Icon(Icons.notifications_outlined, color: AppColors.textPrimary),
              ),
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(color: AppColors.error, shape: BoxShape.circle),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          PopupMenuButton<String>(
            color: AppColors.surfaceElevated,
            onSelected: onProfileMenuSelected,
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'profile', child: Text('Profile')),
              PopupMenuItem(value: 'logout', child: Text('Log Out')),
            ],
            child: CircleAvatar(
              radius: 23,
              backgroundColor: AppColors.accent,
              child: Text(
                (authService.currentSession?.userId ?? 'U').substring(0, 1).toUpperCase(),
                style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Sidebar extends StatelessWidget {
  final String selectedNav;
  final ValueChanged<String> onSelectNav;
  final VoidCallback onMyBookings;
  final VoidCallback onWatchlist;
  final VoidCallback onOffers;
  final VoidCallback onTry3DVenue;

  const _Sidebar({
    required this.selectedNav,
    required this.onSelectNav,
    required this.onMyBookings,
    required this.onWatchlist,
    required this.onOffers,
    required this.onTry3DVenue,
  });

  static const _navIcons = {
    'Home': Icons.home_rounded,
    'Movies': Icons.local_movies_rounded,
    'Concerts': Icons.mic_rounded,
    'Sports': Icons.sports_cricket_rounded,
    'Theatre': Icons.theater_comedy_rounded,
    'Events': Icons.event_rounded,
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 232,
      color: AppColors.background,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: RichText(
              text: const TextSpan(
                children: [
                  TextSpan(
                    text: 'Live',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                  ),
                  TextSpan(
                    text: 'Screen',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.accent),
                  ),
                ],
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(8, 2, 8, 0),
            child: Text(
              'ANY SCREEN. A BIGGER TOGETHER.',
              style: TextStyle(fontSize: 9, color: AppColors.textMuted, letterSpacing: 0.6),
            ),
          ),
          const SizedBox(height: 28),
          for (final nav in _navIcons.keys)
            _NavItem(
              icon: _navIcons[nav]!,
              label: nav,
              selected: selectedNav == nav,
              onTap: () => onSelectNav(nav),
            ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Divider(color: AppColors.surfaceElevated, height: 1),
          ),
          _NavItem(icon: Icons.confirmation_number_outlined, label: 'My Bookings', onTap: onMyBookings),
          _NavItem(icon: Icons.bookmark_border_rounded, label: 'Watchlist', onTap: onWatchlist),
          _NavItem(icon: Icons.local_offer_outlined, label: 'Offers', onTap: onOffers),
          const Spacer(),
          GestureDetector(
            onTap: onTry3DVenue,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Experience it', style: AppTextStyles.subheading),
                  const Text('before you book.', style: AppTextStyles.subheading),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Text('Try 3D Venue', style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.w600, fontSize: 13)),
                      SizedBox(width: 4),
                      Icon(Icons.arrow_forward_rounded, size: 14, color: AppColors.accent),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Text('LiveScreen\nv1.0', style: AppTextStyles.caption),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({required this.icon, required this.label, required this.onTap, this.selected = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: selected ? AppColors.accent.withValues(alpha: 0.15) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                Icon(icon, size: 20, color: selected ? AppColors.accent : AppColors.textSecondary),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected ? AppColors.accent : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A small published-theatres listing, reached via "Explore Theatres" /
/// "Try 3D Venue". Reuses theatreRepository/TheatreDetailScreen exactly as
/// built for the database-connected flow — no separate/duplicate theatre
/// data source.
class _ExploreTheatresScreen extends StatelessWidget {
  const _ExploreTheatresScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Explore Theatres')),
      body: FutureBuilder<List<TheatreConfiguration>>(
        future: theatreRepository.getPublishedTheatres(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator(color: AppColors.accent));
          }
          final theatres = snapshot.data ?? [];
          if (theatres.isEmpty) {
            return const Center(
              child: Text('No published theatres yet.', style: AppTextStyles.body),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: theatres.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final theatre = theatres[index];
              return Material(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => TheatreDetailScreen(theatreId: theatre.id)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(theatre.basicInfo.name, style: AppTextStyles.subheading),
                              const SizedBox(height: 4),
                              Text('${theatre.seats.length} seats', style: AppTextStyles.caption),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
