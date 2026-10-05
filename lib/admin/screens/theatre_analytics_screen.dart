import 'package:flutter/material.dart';
import '../../shared/widgets/admin/admin_sidebar.dart';
import '../../shared/widgets/admin/admin_top_bar.dart';
import '../../shared/widgets/admin/admin_stat_card.dart';
import '../../shared/widgets/admin/admin_section_header.dart';
import '../../shared/models/booking_model.dart';
import '../models/theatre_configuration.dart';
import '../../shared/services/booking_repository.dart';
import '../services/theatre_repository.dart';
import 'admin_dashboard_screen.dart';
import 'theatre_list_screen.dart';
import 'theatre_screens_screen.dart';
import 'theatre_shows_screen.dart';
import 'theatre_bookings_screen.dart';
import 'theatre_snacks_screen.dart';

/// Redesigned 'Venue Analytics' Screen for Theatre Admin.
/// Implements the master dark cinematic design language (Black, Gold & Burgundy).
class TheatreAnalyticsScreen extends StatefulWidget {
  const TheatreAnalyticsScreen({super.key});

  @override
  State<TheatreAnalyticsScreen> createState() => _TheatreAnalyticsScreenState();
}

class _TheatreAnalyticsScreenState extends State<TheatreAnalyticsScreen> {
  List<TheatreConfiguration> _theatres = [];
  List<BookingModel> _bookings = [];
  int _totalBookings = 0;
  int _totalSeats = 0;
  int _theatresCount = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final theatres = await theatreRepository.getMyTheatres();
      final bookings = await bookingRepository.getMyBookings();

      int seats = 0;
      for (final t in theatres) {
        seats += t.seats.length;
      }

      if (mounted) {
        setState(() {
          _theatres = theatres;
          _bookings = bookings;
          _theatresCount = theatres.length;
          _totalSeats = seats;
          _totalBookings = bookings.length;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _navigateTo(String key) {
    if (key == 'dashboard') {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
      );
    } else if (key == 'my_theatre') {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const TheatreListScreen()),
      );
    } else if (key == 'screens') {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const TheatreScreensScreen()),
      );
    } else if (key == 'shows') {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const TheatreShowsScreen()),
      );
    } else if (key == 'bookings') {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const TheatreBookingsScreen()),
      );
    } else if (key == 'snacks') {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const TheatreSnacksScreen()),
      );
    } else if (key == 'analytics') {
      // already here
    }
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
      activeKey: 'analytics',
      mainNavItems: navItems,
      onSelectKey: _navigateTo,
    );

    final hasCapacity = _totalSeats > 0;
    final occupancyDouble = hasCapacity ? ((_totalBookings / _totalSeats) * 100).clamp(0, 100) : 0.0;
    final occupancyDisplay = '${occupancyDouble.toStringAsFixed(1)}%';

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
                  searchPlaceholder: 'Search metrics, reports, audit logs...',
                  showDrawerButton: !isDesktop,
                  onProfileTap: () => _navigateTo('my_theatre'),
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
                                    'Venue Analytics & Reports',
                                    style: TextStyle(
                                      fontSize: 26,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFFFFFFFF),
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Real performance metrics, admissions telemetry, and occupancy rates.',
                                    style: TextStyle(fontSize: 13.5, color: Color(0xFF9CA3AF)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),

                              // 4 Master KPI Cards using real data
                              LayoutBuilder(
                                builder: (context, constraints) {
                                  final cardWidth = (constraints.maxWidth - 36) / 4;
                                  final isWide = cardWidth > 180;

                                  final cards = [
                                    AdminStatCard(
                                      icon: Icons.confirmation_number_outlined,
                                      iconColor: const Color(0xFFD4AF37),
                                      value: '$_totalBookings',
                                      label: 'Total Admissions',
                                      trendText: _totalBookings == 0 ? 'No customer bookings' : '$_totalBookings confirmed',
                                      isTrendPositive: _totalBookings > 0,
                                    ),
                                    AdminStatCard(
                                      icon: Icons.event_seat_outlined,
                                      iconColor: const Color(0xFF8B1024),
                                      iconBgColor: const Color(0x338B1024),
                                      value: '$_totalSeats',
                                      label: 'Auditorium Capacity',
                                      trendText: _theatresCount == 0
                                          ? 'No venues'
                                          : 'Across $_theatresCount venue${_theatresCount == 1 ? "" : "s"}',
                                      isTrendPositive: _totalSeats > 0,
                                    ),
                                    AdminStatCard(
                                      icon: Icons.theaters_outlined,
                                      iconColor: const Color(0xFFD4AF37),
                                      value: '$_theatresCount',
                                      label: 'Configured Theatres',
                                      trendText: _theatresCount == 0 ? 'Add your first theatre' : 'Active venues',
                                      isTrendPositive: _theatresCount > 0,
                                    ),
                                    AdminStatCard(
                                      icon: Icons.access_time_rounded,
                                      iconColor: const Color(0xFFEF4444),
                                      iconBgColor: const Color(0x22EF4444),
                                      value: occupancyDisplay,
                                      label: 'Occupancy Rate',
                                      trendText: hasCapacity ? 'Admissions vs Capacity' : 'No seats configured',
                                      isTrendPositive: occupancyDouble > 0,
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
                              ),
                              const SizedBox(height: 28),

                              // Screen Performance Breakdown - Real Theatres
                              AdminSectionHeader(
                                title: 'Auditorium Utilization',
                                subtitle: 'Occupancy distribution across your configured theatres',
                              ),
                              const SizedBox(height: 14),

                              if (_theatres.isEmpty)
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(40),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0F0F12),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: const Color(0xFF1E1E26)),
                                  ),
                                  child: Center(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.theaters_outlined, size: 40, color: Color(0xFF71717A)),
                                        const SizedBox(height: 12),
                                        const Text(
                                          'No Theatres Configured Yet',
                                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFFFFFFFF)),
                                        ),
                                        const SizedBox(height: 4),
                                        const Text(
                                          'Auditorium utilization and capacity telemetry will display here once venues are added.',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12.5),
                                        ),
                                        const SizedBox(height: 16),
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(0xFFD4AF37),
                                            foregroundColor: Colors.black,
                                          ),
                                          onPressed: () => _navigateTo('my_theatre'),
                                          child: const Text('Manage Theatres', style: TextStyle(fontWeight: FontWeight.w700)),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              else
                                Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0F0F12),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: const Color(0xFF1E1E26)),
                                  ),
                                  child: Column(
                                    children: [
                                      for (int i = 0; i < _theatres.length; i++) ...[
                                        if (i > 0) const SizedBox(height: 16),
                                        _buildRealTheatreUtilizationRow(_theatres[i]),
                                      ],
                                    ],
                                  ),
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

  Widget _buildRealTheatreUtilizationRow(TheatreConfiguration theatre) {
    final hall = theatre.basicInfo.hallName.isNotEmpty ? theatre.basicInfo.hallName : 'Screen 1';
    final name = theatre.basicInfo.name.isNotEmpty ? '${theatre.basicInfo.name} ($hall)' : hall;
    final capacity = theatre.seats.length;
    final theatreBookings = _bookings.where((b) => b.theatreId == theatre.id).length;
    final percent = capacity > 0 ? ((theatreBookings / capacity) * 100).clamp(0, 100).round() : 0;
    final barColor = percent > 60
        ? const Color(0xFF10B981)
        : (percent > 0 ? const Color(0xFFD4AF37) : const Color(0xFF71717A));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: Color(0xFFF7F5F0)),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              capacity > 0 ? '$percent% Occupancy ($theatreBookings / $capacity seats)' : '0 seats mapped',
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: barColor),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: capacity > 0 ? (percent / 100.0) : 0.0,
            backgroundColor: const Color(0xFF1A1A22),
            valueColor: AlwaysStoppedAnimation<Color>(barColor),
            minHeight: 7,
          ),
        ),
      ],
    );
  }
}
