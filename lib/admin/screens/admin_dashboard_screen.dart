import 'package:flutter/material.dart';
import '../../shared/widgets/admin/admin_sidebar.dart';
import '../../shared/widgets/admin/admin_top_bar.dart';
import '../../shared/widgets/admin/admin_stat_card.dart';
import '../../shared/widgets/admin/admin_status_badge.dart';
import '../../shared/widgets/admin/admin_section_header.dart';
import '../services/selected_theatre.dart';
import '../../shared/models/show_model.dart';
import '../../shared/models/booking_model.dart';
import '../../shared/services/show_repository.dart';
import '../../shared/services/booking_repository.dart';
import '../../screens/unity_experience_screen.dart';
import '../models/theatre_configuration.dart';
import '../services/theatre_repository.dart';
import '../services/theatre_unity_bridge.dart';
import '../models/movie_content.dart';
import '../services/movie_repository.dart';
import 'theatre_editor_screen.dart';
import 'theatre_list_screen.dart';
import 'theatre_screens_screen.dart';
import 'theatre_shows_screen.dart';
import 'theatre_bookings_screen.dart';
import 'theatre_analytics_screen.dart';
import 'theatre_snacks_screen.dart';
import 'create_theatre_screen.dart';

/// The Redesigned LiveScreen Theatre Admin Dashboard.
/// Strictly reproduces media_1790658802815.png:
/// - Dark cinematic theme: Black #070709, Metallic Gold #D4AF37, Deep Burgundy #6E071A
/// - Unified sidebar with pill active state, gold icons, gold separator, bottom branding
/// - Dark top bar with THEATRE ADMIN tag, active theatre pill, search, location, notifications, profile
/// - Good Morning greeting with dynamic date
/// - 4 Overview KPI cards with trend indicators
/// - 2x4 Theatre Configuration Grid (Room, Screen, Seating, Speakers, Acoustics, Movie, Pricing, Preview)
/// - 2-Column lower layout: Recent Activity table (60%) + Today's Shows with occupancy bars (40%)
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  List<TheatreConfiguration> _theatres = [];
  TheatreConfiguration? _theatre;
  List<ShowModel> _shows = [];
  List<BookingModel> _bookings = [];
  List<MovieContent> _movieCatalog = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _loading = true);
    try {
      final theatres = await theatreRepository.getMyTheatres();
      final currentTheatre = selectedTheatreContext.resolve(theatres);
      final catalog = await movieRepository.getPublishedMovies().catchError((_) => <MovieContent>[]);

      if (currentTheatre != null) {
        final shows = await showRepository.getShowsForTheatre(currentTheatre.id);
        final bookings = await bookingRepository.getMyBookings();

        if (mounted) {
          setState(() {
            _theatres = theatres;
            _theatre = currentTheatre;
            _shows = shows;
            _bookings = bookings;
            _movieCatalog = catalog;
            _loading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _theatres = theatres;
            _theatre = theatres.isNotEmpty ? theatres.first : null;
            _shows = [];
            _bookings = [];
            _movieCatalog = catalog;
            _loading = false;
          });
        }
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _movieTitleFor(String? movieId) {
    if (movieId == null) return 'Live Screening';
    for (final m in _movieCatalog) {
      if (m.id == movieId) return m.title.isEmpty ? '(Untitled Movie)' : m.title;
    }
    return 'Live Screening';
  }

  void _onTheatreSwitched(TheatreConfiguration theatre) {
    selectedTheatreContext.select(theatre.id);
    _loadDashboardData();
  }

  void _openEditorAt(int tabIndex) {
    if (_theatre == null) {
      _createNewTheatre();
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TheatreEditorScreen(
          theatreId: _theatre!.id,
          initialIndex: tabIndex,
        ),
      ),
    ).then((_) => _loadDashboardData());
  }

  void _createNewTheatre() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CreateTheatreScreen()),
    ).then((_) => _loadDashboardData());
  }

  void _launchUnityVenueExperience() {
    if (_theatre == null) return;
    final seat = _theatre!.seats.isNotEmpty ? _theatre!.seats.first : null;
    final seatLabel = seat != null ? TheatreUnityBridge.seatIdForPreview(seat.id) : 'A1';

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => UnityExperienceScreen(
          seatLabel: seatLabel,
          theatre: _theatre,
          movie: null,
        ),
      ),
    );
  }

  void _navigateTo(String key) {
    if (key == 'dashboard') {
      // already on dashboard
    } else if (key == 'my_theatre') {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const TheatreListScreen()),
      ).then((_) => _loadDashboardData());
    } else if (key == 'screens') {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const TheatreScreensScreen()),
      ).then((_) => _loadDashboardData());
    } else if (key == 'shows') {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const TheatreShowsScreen()),
      ).then((_) => _loadDashboardData());
    } else if (key == 'bookings') {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const TheatreBookingsScreen()),
      ).then((_) => _loadDashboardData());
    } else if (key == 'snacks') {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const TheatreSnacksScreen()),
      ).then((_) => _loadDashboardData());
    } else if (key == 'analytics') {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const TheatreAnalyticsScreen()),
      ).then((_) => _loadDashboardData());
    } else if (key == 'profile') {
      _showProfileDialog();
    } else if (key == 'settings') {
      _showSettingsDialog();
    } else if (key == 'help') {
      _showHelpDialog();
    }
  }

  void _showProfileDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF111116),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0x66D4AF37)),
        ),
        title: Row(
          children: const [
            Icon(Icons.person_outline_rounded, color: Color(0xFFD4AF37)),
            SizedBox(width: 10),
            Text('Theatre Admin Profile', style: TextStyle(color: Color(0xFFFFFFFF), fontSize: 18, fontWeight: FontWeight.w700)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Administrator: Theatre Operations Admin', style: TextStyle(color: Color(0xFFF7F5F0), fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text('Venue: ${_theatre?.basicInfo.name ?? 'No Theatre Selected'}', style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13)),
            const SizedBox(height: 6),
            const Text('Role: Verified Theatre Owner & Manager', style: TextStyle(color: Color(0xFFD4AF37), fontSize: 13)),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF16161D),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0x33D4AF37)),
              ),
              child: const Text(
                'LiveScreen Multi-Venue Management System active. All venue configurations, seating geometries, and concession lists are encrypted and synchronized.',
                style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close', style: TextStyle(color: Color(0xFFD4AF37))),
          ),
        ],
      ),
    );
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF111116),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0x66D4AF37)),
        ),
        title: Row(
          children: const [
            Icon(Icons.settings_outlined, color: Color(0xFFD4AF37)),
            SizedBox(width: 10),
            Text('Venue & Admin Settings', style: TextStyle(color: Color(0xFFFFFFFF), fontSize: 18, fontWeight: FontWeight.w700)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.palette_outlined, color: Color(0xFFD4AF37)),
              title: const Text('Theme Mode', style: TextStyle(color: Color(0xFFF7F5F0), fontSize: 14)),
              subtitle: const Text('Cinematic Dark (Black, Gold & Burgundy)', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12)),
              trailing: const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 18),
            ),
            const Divider(color: Color(0xFF22222A)),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.notifications_active_outlined, color: Color(0xFFD4AF37)),
              title: const Text('Booking Alerts', style: TextStyle(color: Color(0xFFF7F5F0), fontSize: 14)),
              subtitle: const Text('Instant push notification on new ticket reservations', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12)),
              trailing: Switch(
                value: true,
                activeThumbColor: const Color(0xFFD4AF37),
                activeTrackColor: const Color(0xFFD4AF37).withValues(alpha: 0.5),
                onChanged: (_) {},
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Done', style: TextStyle(color: Color(0xFFD4AF37))),
          ),
        ],
      ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF111116),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0x66D4AF37)),
        ),
        title: Row(
          children: const [
            Icon(Icons.help_outline_rounded, color: Color(0xFFD4AF37)),
            SizedBox(width: 10),
            Text('LiveScreen Support', style: TextStyle(color: Color(0xFFFFFFFF), fontSize: 18, fontWeight: FontWeight.w700)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('Need help configuring your 3D venue layout or showtimes?', style: TextStyle(color: Color(0xFFF7F5F0), fontSize: 13.5)),
            SizedBox(height: 10),
            Text('• Email: partner-support@livescreen.io', style: TextStyle(color: Color(0xFFD4AF37), fontSize: 13)),
            SizedBox(height: 4),
            Text('• 24/7 Operations Desk: +91 (44) 4900-5800', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13)),
            SizedBox(height: 12),
            Text('Our cinema engineering team is available 24/7 for audio, projector, and seat geometry assistance.', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close', style: TextStyle(color: Color(0xFFD4AF37))),
          ),
        ],
      ),
    );
  }

  void _showPricingOffersDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF111116),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0x66D4AF37)),
        ),
        title: Row(
          children: const [
            Icon(Icons.local_offer_outlined, color: Color(0xFFD4AF37)),
            SizedBox(width: 10),
            Text('Pricing & Offers Management', style: TextStyle(color: Color(0xFFFFFFFF), fontSize: 18, fontWeight: FontWeight.w700)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Manage ticket base pricing tiers, weekday morning matinee discounts, and special festival promos.',
              style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
            ),
            const SizedBox(height: 14),
            _buildPricingRow('Executive / Standard Seating', '₹190.00'),
            const SizedBox(height: 8),
            _buildPricingRow('VIP Recliner Seating', '₹350.00'),
            const SizedBox(height: 8),
            _buildPricingRow('Matinee Discount (Before 12:00 PM)', '-20%'),
            const SizedBox(height: 14),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD4AF37),
                foregroundColor: Colors.black,
                minimumSize: const Size(double.infinity, 38),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                Navigator.of(ctx).pop();
                _navigateTo('snacks');
              },
              child: const Text('Manage Food & Concession Pricing →', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Done', style: TextStyle(color: Color(0xFFD4AF37))),
          ),
        ],
      ),
    );
  }

  Widget _buildPricingRow(String tier, String rate) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF16161D),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF22222A)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(tier, style: const TextStyle(color: Color(0xFFF7F5F0), fontSize: 13, fontWeight: FontWeight.w500)),
          Text(rate, style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 13, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 900;

    const navItems = [
      AdminNavItemData(key: 'dashboard', label: 'Dashboard', icon: Icons.dashboard_rounded),
      AdminNavItemData(key: 'my_theatre', label: 'My Theatre', icon: Icons.theaters_outlined),
      AdminNavItemData(key: 'screens', label: 'Screens', icon: Icons.tv_rounded),
      AdminNavItemData(key: 'shows', label: 'Shows', icon: Icons.calendar_today_outlined),
      AdminNavItemData(key: 'bookings', label: 'Bookings', icon: Icons.confirmation_number_outlined),
      AdminNavItemData(key: 'analytics', label: 'Analytics', icon: Icons.bar_chart_rounded),
    ];

    final sidebar = AdminSidebar(
      activeKey: 'dashboard',
      mainNavItems: navItems,
      onSelectKey: _navigateTo,
      onProfile: _showProfileDialog,
      onSettings: _showSettingsDialog,
      onHelpSupport: _showHelpDialog,
      onTry3DVenue: _theatre != null ? _launchUnityVenueExperience : null,
    );

    final theatreName = _theatre?.basicInfo.name.isNotEmpty == true
        ? _theatre!.basicInfo.name
        : (_theatres.isNotEmpty ? _theatres.first.basicInfo.name : 'LiveScreen Venue');
    final theatreCity = _theatre?.basicInfo.hallName.isNotEmpty == true
        ? _theatre!.basicInfo.hallName
        : '';

    return Scaffold(
      backgroundColor: const Color(0xFF070709),
      drawer: isDesktop ? null : Drawer(backgroundColor: const Color(0xFF070709), child: sidebar),
      body: Row(
        children: [
          if (isDesktop) sidebar,
          Expanded(
            child: Column(
              children: [
                // Top Bar matching reference image with active theatre pill
                AdminTopBar(
                  searchPlaceholder: 'Search shows, screens, bookings...',
                  showDrawerButton: !isDesktop,
                  activeTheatreName: theatreName,
                  activeTheatreCity: theatreCity,
                  theatres: _theatres,
                  onTheatreChanged: _onTheatreSwitched,
                  onProfileTap: _showProfileDialog,
                  onSettingsTap: _showSettingsDialog,
                  onNotificationTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('All screening audio systems and bookings operating smoothly.'),
                        backgroundColor: Color(0xFF16161D),
                      ),
                    );
                  },
                ),

                Expanded(
                  child: _loading
                      ? const Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37)))
                      : SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Top Greeting & Date matching reference
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: const [
                                        Text(
                                          'Good Morning!',
                                          style: TextStyle(
                                            fontSize: 26,
                                            fontWeight: FontWeight.w800,
                                            color: Color(0xFFFFFFFF),
                                            letterSpacing: -0.5,
                                          ),
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          "Here's what's happening at your theatre today.",
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
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF9CA3AF),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),

                              // 4 Overview Cards strictly matching reference image
                              _buildOverviewCards(),
                              const SizedBox(height: 28),

                              // Theatre Configuration Section (2x4 Grid)
                              AdminSectionHeader(
                                title: 'Theatre Configuration',
                                subtitle: 'Set up and manage your venue.',
                                actionLabel: 'View All',
                                onAction: () => _openEditorAt(0),
                              ),
                              const SizedBox(height: 14),
                              _buildConfigurationGrid(),
                              const SizedBox(height: 28),

                              // Lower Section: 2 Columns (Recent Activity 60% + Today's Shows 40%)
                              LayoutBuilder(
                                builder: (context, constraints) {
                                  final isWide = constraints.maxWidth > 850;
                                  if (!isWide) {
                                    return Column(
                                      children: [
                                        _buildRecentActivitySection(),
                                        const SizedBox(height: 28),
                                        _buildTodaysShowsSection(),
                                      ],
                                    );
                                  }

                                  return Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        flex: 6,
                                        child: _buildRecentActivitySection(),
                                      ),
                                      const SizedBox(width: 20),
                                      Expanded(
                                        flex: 4,
                                        child: _buildTodaysShowsSection(),
                                      ),
                                    ],
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

  String _getFormattedDate() {
    final now = DateTime.now();
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${weekdays[now.weekday - 1]}, ${now.day} ${months[now.month - 1]} ${now.year}';
  }

  Widget _buildOverviewCards() {
    final screensCount = _theatres.length;
    final showsCount = _shows.length;
    final bookingsCount = _bookings.length;
    final totalSeats = _theatres.fold<int>(0, (sum, t) => sum + t.seats.length);
    final occupancy = totalSeats > 0 ? ((bookingsCount / totalSeats) * 100).clamp(0, 100).round() : 0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = (constraints.maxWidth - 36) / 4;
        final isWide = cardWidth > 170;

        final cards = [
          AdminStatCard(
            icon: Icons.tv_rounded,
            iconColor: const Color(0xFFD4AF37),
            value: '$screensCount',
            label: 'Screens Active',
            trendText: screensCount > 0 ? '$screensCount configured' : 'None configured',
            isTrendPositive: screensCount > 0,
          ),
          AdminStatCard(
            icon: Icons.calendar_today_outlined,
            iconColor: const Color(0xFF8B1024),
            iconBgColor: const Color(0x338B1024),
            value: '$showsCount',
            label: 'Shows Today',
            trendText: showsCount > 0 ? '$showsCount scheduled' : 'No shows today',
            isTrendPositive: showsCount > 0,
          ),
          AdminStatCard(
            icon: Icons.people_outline_rounded,
            iconColor: const Color(0xFFD4AF37),
            value: '$bookingsCount',
            label: 'Bookings Today',
            trendText: bookingsCount > 0 ? '$bookingsCount confirmed' : 'No bookings yet',
            isTrendPositive: bookingsCount > 0,
          ),
          AdminStatCard(
            icon: Icons.access_time_rounded,
            iconColor: const Color(0xFFEF4444),
            iconBgColor: const Color(0x22EF4444),
            value: '$occupancy%',
            label: 'Occupancy Rate',
            trendText: occupancy > 0 ? '$occupancy% capacity' : '0% occupied',
            isTrendPositive: occupancy > 0,
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

  Widget _buildConfigurationGrid() {
    final items = [
      _ConfigGridItem(
        title: 'Room Setup',
        subtitle: 'Configure your theatre rooms and basic details.',
        icon: Icons.domain_rounded,
        onTap: () => _openEditorAt(0),
      ),
      _ConfigGridItem(
        title: 'Screen Configuration',
        subtitle: 'Manage screen details, formats and dimensions.',
        icon: Icons.tv_rounded,
        onTap: () => _openEditorAt(1),
      ),
      _ConfigGridItem(
        title: 'Seating Layout',
        subtitle: 'Design and manage seating arrangements.',
        icon: Icons.event_seat_outlined,
        onTap: () => _openEditorAt(2),
      ),
      _ConfigGridItem(
        title: 'Speakers & Audio',
        subtitle: 'Configure sound systems and audio settings.',
        icon: Icons.volume_up_outlined,
        onTap: () => _openEditorAt(3),
      ),
      _ConfigGridItem(
        title: 'Acoustics',
        subtitle: 'Set acoustic parameters for best experience.',
        icon: Icons.graphic_eq_rounded,
        onTap: () => _openEditorAt(4),
      ),
      _ConfigGridItem(
        title: 'Movie Management',
        subtitle: 'Add and manage movies and content.',
        icon: Icons.movie_outlined,
        onTap: () => _openEditorAt(5),
      ),
      _ConfigGridItem(
        title: 'Pricing & Offers',
        subtitle: 'Manage ticket pricing, discounts and offers.',
        icon: Icons.local_offer_outlined,
        onTap: _showPricingOffersDialog,
      ),
      _ConfigGridItem(
        title: 'Preview & Publish',
        subtitle: 'Preview your setup and make it live for booking.',
        icon: Icons.publish_outlined,
        onTap: () => _openEditorAt(6),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 800 ? 4 : 2;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 2.1,
          ),
          itemBuilder: (context, index) {
            final item = items[index];
            return _buildConfigCard(item);
          },
        );
      },
    );
  }

  Widget _buildConfigCard(_ConfigGridItem item) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F0F12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1E1E26), width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: item.onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                // Squircle gold icon box matching reference
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1C180E),
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(color: const Color(0x55D4AF37), width: 0.8),
                  ),
                  child: Icon(item.icon, size: 19, color: const Color(0xFFD4AF37)),
                ),
                const SizedBox(width: 12),

                // Title + Subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFFFFFFF),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF9CA3AF),
                          height: 1.25,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: Color(0xFF71717A),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecentActivitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AdminSectionHeader(
          title: 'Recent Activity',
          actionLabel: 'View All',
          onAction: () => _navigateTo('bookings'),
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
            child: Column(
              children: [
                // Table Header
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: const BoxDecoration(
                    color: Color(0xFF14141A),
                    border: Border(bottom: BorderSide(color: Color(0xFF1E1E26))),
                  ),
                  child: Row(
                    children: const [
                      SizedBox(
                        width: 75,
                        child: Text('Time', style: TextStyle(color: Color(0xFF71717A), fontSize: 11.5, fontWeight: FontWeight.w600)),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text('Activity', style: TextStyle(color: Color(0xFF71717A), fontSize: 11.5, fontWeight: FontWeight.w600)),
                      ),
                      Expanded(
                        flex: 4,
                        child: Text('Details', style: TextStyle(color: Color(0xFF71717A), fontSize: 11.5, fontWeight: FontWeight.w600)),
                      ),
                      SizedBox(
                        width: 80,
                        child: Text('Status', style: TextStyle(color: Color(0xFF71717A), fontSize: 11.5, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                ),

                if (_bookings.isEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.receipt_long_outlined, size: 36, color: Color(0xFF71717A)),
                        SizedBox(height: 12),
                        Text(
                          'No Recent Activity',
                          style: TextStyle(color: Color(0xFFF7F5F0), fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Customer bookings and reservations for your theatres will appear here in real time.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12),
                        ),
                      ],
                    ),
                  )
                else ...[
                  for (int i = 0; i < (_bookings.length > 5 ? 5 : _bookings.length); i++) ...[
                    Builder(
                      builder: (context) {
                        final b = _bookings.reversed.toList()[i];
                        final isConfirmed = b.status.toLowerCase() == 'confirmed';
                        final timeStr = b.createdAt != null
                            ? '${b.createdAt!.hour.toString().padLeft(2, '0')}:${b.createdAt!.minute.toString().padLeft(2, '0')}'
                            : 'Recent';
                        final actStr = isConfirmed ? 'New booking received' : 'Booking ${b.status}';
                        final dot = isConfirmed ? const Color(0xFF10B981) : const Color(0xFFEF4444);
                        final show = _shows.cast<ShowModel?>().firstWhere((s) => s?.id == b.showId, orElse: () => null);
                        final title = show != null ? _movieTitleFor(show.movieId) : 'Screen Reservation';
                        final details = '$title • Seat ${b.seatId}';
                        final status = b.status.isNotEmpty
                            ? '${b.status[0].toUpperCase()}${b.status.substring(1).toLowerCase()}'
                            : 'Confirmed';
                        final isLast = i == (_bookings.length > 5 ? 4 : _bookings.length - 1);
                        return _buildActivityRow(timeStr, actStr, dot, details, status, isLast: isLast);
                      },
                    ),
                  ],
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActivityRow(String time, String activity, Color dotColor, String details, String status, {bool isLast = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(
        border: isLast ? null : const Border(bottom: BorderSide(color: Color(0xFF1A1A22), width: 0.8)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 75,
            child: Text(
              time,
              style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 12),
            ),
          ),
          Expanded(
            flex: 3,
            child: Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    activity,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Color(0xFFF7F5F0), fontSize: 12.5, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 4,
            child: Text(
              details,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 12),
            ),
          ),
          SizedBox(
            width: 80,
            child: Align(
              alignment: Alignment.centerLeft,
              child: AdminStatusBadge(status: status),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodaysShowsSection() {
    final seatCount = _theatre?.seats.length ?? 0;
    final showsList = _shows.take(4).map((s) {
      final hallName = _theatre?.basicInfo.hallName.isNotEmpty == true ? _theatre!.basicInfo.hallName : 'Screen 1';
      final hour = s.startTime.hour;
      final minute = s.startTime.minute.toString().padLeft(2, '0');
      final period = hour >= 12 ? 'PM' : 'AM';
      final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
      final timeStr = '${displayHour.toString().padLeft(2, '0')}:$minute $period | $hallName';
      final bookedCount = _bookings.where((b) => b.showId == s.id && b.status.toLowerCase() != 'cancelled').length;
      final occ = seatCount > 0 ? ((bookedCount / seatCount) * 100).clamp(0, 100).round() : 0;
      final fillColor = occ >= 75 ? const Color(0xFFEF4444) : const Color(0xFFD4AF37);
      return _ShowItem(
        title: _movieTitleFor(s.movieId),
        timeScreen: timeStr,
        occupancy: occ,
        fillColor: fillColor,
      );
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AdminSectionHeader(
          title: "Today's Shows",
          actionLabel: 'View All',
          onAction: () => _navigateTo('shows'),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0F0F12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF1E1E26)),
          ),
          child: showsList.isEmpty
              ? Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.movie_creation_outlined, size: 36, color: Color(0xFF71717A)),
                      const SizedBox(height: 12),
                      const Text(
                        'No Shows Scheduled Today',
                        style: TextStyle(color: Color(0xFFF7F5F0), fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Screenings configured for this theatre will appear here with live seat occupancy.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12),
                      ),
                      const SizedBox(height: 14),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFD4AF37),
                          side: const BorderSide(color: Color(0xFFD4AF37), width: 1),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: () => _navigateTo('shows'),
                        icon: const Icon(Icons.add_rounded, size: 16),
                        label: const Text('Schedule Show', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    for (int i = 0; i < showsList.length; i++)
                      _buildShowTile(showsList[i], isLast: i == showsList.length - 1),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildShowTile(_ShowItem show, {bool isLast = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        border: isLast ? null : const Border(bottom: BorderSide(color: Color(0xFF1A1A22), width: 0.8)),
      ),
      child: Row(
        children: [
          // Movie Poster Placeholder with Film Icon
          Container(
            width: 36,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFF1C1C24),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0x33D4AF37)),
            ),
            child: const Center(
              child: Icon(Icons.movie_filter_rounded, size: 20, color: Color(0xFFD4AF37)),
            ),
          ),
          const SizedBox(width: 12),

          // Show Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  show.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFFFFFFF),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  show.timeScreen,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF9CA3AF),
                  ),
                ),
                const SizedBox(height: 6),

                // Occupancy Bar + Percentage
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(
                          value: show.occupancy / 100.0,
                          backgroundColor: const Color(0xFF22222A),
                          valueColor: AlwaysStoppedAnimation<Color>(show.fillColor),
                          minHeight: 5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${show.occupancy}%',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFFFFFFF),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Gold Outlined Manage Button
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFD4AF37),
              side: const BorderSide(color: Color(0xFFD4AF37), width: 1),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              minimumSize: const Size(60, 30),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
            onPressed: () => _navigateTo('shows'),
            child: const Text(
              'Manage',
              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConfigGridItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _ConfigGridItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });
}

class _ShowItem {
  final String title;
  final String timeScreen;
  final int occupancy;
  final Color fillColor;

  const _ShowItem({
    required this.title,
    required this.timeScreen,
    required this.occupancy,
    required this.fillColor,
  });
}
