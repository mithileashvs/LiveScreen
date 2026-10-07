import 'package:flutter/material.dart';
import '../../shared/widgets/admin/admin_sidebar.dart';
import '../../shared/widgets/admin/admin_top_bar.dart';
import '../../shared/widgets/admin/admin_status_badge.dart';
import '../models/theatre_configuration.dart';
import '../services/theatre_repository.dart';
import '../services/selected_theatre.dart';
import 'theatre_editor_screen.dart';
import 'theatre_list_screen.dart';
import 'theatre_shows_screen.dart';
import 'theatre_bookings_screen.dart';
import 'theatre_analytics_screen.dart';
import 'theatre_snacks_screen.dart';
import 'admin_dashboard_screen.dart';

/// Redesigned 'Screens & Auditoriums' Screen for Theatre Admin.
/// Implements the master dark cinematic design language (Black, Gold & Burgundy).
class TheatreScreensScreen extends StatefulWidget {
  const TheatreScreensScreen({super.key});

  @override
  State<TheatreScreensScreen> createState() => _TheatreScreensScreenState();
}

class _TheatreScreensScreenState extends State<TheatreScreensScreen> {
  late Future<List<TheatreConfiguration>> _theatresFuture;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    setState(() {
      _theatresFuture = theatreRepository.getMyTheatres();
    });
  }

  void _onTheatreSwitched(TheatreConfiguration theatre) {
    selectedTheatreContext.select(theatre.id);
    setState(() {});
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
      // already here
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
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const TheatreAnalyticsScreen()),
      );
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
      activeKey: 'screens',
      mainNavItems: navItems,
      onSelectKey: _navigateTo,
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
                  searchPlaceholder: 'Search screens, formats, sound systems...',
                  showDrawerButton: !isDesktop,
                  onTheatreChanged: _onTheatreSwitched,
                  onProfileTap: () => _navigateTo('my_theatre'),
                ),
                Expanded(
                  child: FutureBuilder<List<TheatreConfiguration>>(
                    future: _theatresFuture,
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(
                          child: CircularProgressIndicator(color: Color(0xFFD4AF37)),
                        );
                      }
                      final theatres = snapshot.data!;
                      if (theatres.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Container(
                              padding: const EdgeInsets.all(40),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0F0F12),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xFF1E1E26)),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.tv_off_rounded, size: 48, color: Color(0xFF71717A)),
                                  const SizedBox(height: 14),
                                  const Text(
                                    'No Theatre Configured',
                                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFFFFFFFF)),
                                  ),
                                  const SizedBox(height: 6),
                                  const Text(
                                    'Set up a theatre first to configure its auditorium screens and audio setups.',
                                    style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
                                  ),
                                  const SizedBox(height: 18),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFD4AF37),
                                      foregroundColor: Colors.black,
                                    ),
                                    onPressed: () => Navigator.of(context).push(
                                      MaterialPageRoute(builder: (_) => const TheatreListScreen()),
                                    ),
                                    child: const Text('Go to Theatres', style: TextStyle(fontWeight: FontWeight.w700)),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }

                      final primaryTheatre = selectedTheatreContext.resolve(theatres)!;
                      final screenConfig = primaryTheatre.screen;

                      return SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Page Title & Header
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Screens & Auditoriums',
                                        style: TextStyle(
                                          fontSize: 26,
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFFFFFFFF),
                                          letterSpacing: -0.5,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${primaryTheatre.basicInfo.name} • ${primaryTheatre.basicInfo.hallName}',
                                        style: const TextStyle(
                                          fontSize: 13.5,
                                          color: Color(0xFF9CA3AF),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Row(
                                  children: [
                                    ElevatedButton.icon(
                                      onPressed: () => Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => TheatreEditorScreen(
                                            theatreId: primaryTheatre.id,
                                            initialIndex: 1, // Screen tab
                                          ),
                                        ),
                                      ).then((_) => _refresh()),
                                      icon: const Icon(Icons.tune_rounded, size: 16),
                                      label: const Text('Configure Screen', style: TextStyle(fontWeight: FontWeight.w700)),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFFD4AF37),
                                        foregroundColor: Colors.black,
                                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),

                            // Main Auditorium Screen Card
                            Container(
                              padding: const EdgeInsets.all(22),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0F0F12),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xFF1E1E26)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      // Screen Icon Squircle
                                      Container(
                                        width: 50,
                                        height: 50,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF1C180E),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: const Color(0x66D4AF37)),
                                        ),
                                        child: const Center(
                                          child: Icon(Icons.tv_rounded, color: Color(0xFFD4AF37), size: 24),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              primaryTheatre.basicInfo.hallName.isNotEmpty
                                                  ? primaryTheatre.basicInfo.hallName
                                                  : 'Main Auditorium (Screen 1)',
                                              style: const TextStyle(
                                                fontSize: 17,
                                                fontWeight: FontWeight.w700,
                                                color: Color(0xFFFFFFFF),
                                              ),
                                            ),
                                            const SizedBox(height: 3),
                                            Text(
                                              'Type: ${screenConfig.type.name.toUpperCase()} • Elevation: ${screenConfig.position.y.toStringAsFixed(1)}m • ${primaryTheatre.speakers.length} Speakers placed',
                                              style: const TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const AdminStatusBadge(status: 'Online', showDot: true),
                                    ],
                                  ),
                                  const SizedBox(height: 20),
                                  const Divider(height: 1, color: Color(0xFF1E1E26)),
                                  const SizedBox(height: 20),

                                  // Screen Metrics Row
                                  Wrap(
                                    spacing: 16,
                                    runSpacing: 14,
                                    children: [
                                      _ScreenMetricChip(label: 'Width', value: '${screenConfig.width.toStringAsFixed(1)}m'),
                                      _ScreenMetricChip(label: 'Height', value: '${screenConfig.height.toStringAsFixed(1)}m'),
                                      _ScreenMetricChip(
                                        label: 'Aspect Ratio',
                                        value: screenConfig.height > 0
                                            ? '${(screenConfig.width / screenConfig.height).toStringAsFixed(2)}:1'
                                            : '2.39:1',
                                      ),
                                      _ScreenMetricChip(label: 'Seating Capacity', value: '${primaryTheatre.seats.length} Seats'),
                                      _ScreenMetricChip(label: 'Sound System', value: '${primaryTheatre.speakers.length} Speakers'),
                                    ],
                                  ),
                                  const SizedBox(height: 22),

                                  // Actions Row
                                  Row(
                                    children: [
                                      OutlinedButton.icon(
                                        icon: const Icon(Icons.event_seat_outlined, size: 16),
                                        label: const Text('Edit Seating Layout'),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: const Color(0xFFD4AF37),
                                          side: const BorderSide(color: Color(0x66D4AF37)),
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                        ),
                                        onPressed: () => Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (_) => TheatreEditorScreen(
                                              theatreId: primaryTheatre.id,
                                              initialIndex: 2, // Seating tab
                                            ),
                                          ),
                                        ).then((_) => _refresh()),
                                      ),
                                      const SizedBox(width: 12),
                                      OutlinedButton.icon(
                                        icon: const Icon(Icons.volume_up_outlined, size: 16),
                                        label: const Text('Sound & Speakers'),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: const Color(0xFFF7F5F0),
                                          side: const BorderSide(color: Color(0xFF2E2E38)),
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                        ),
                                        onPressed: () => Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (_) => TheatreEditorScreen(
                                              theatreId: primaryTheatre.id,
                                              initialIndex: 3, // Speakers tab
                                            ),
                                          ),
                                        ).then((_) => _refresh()),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
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
}

class _ScreenMetricChip extends StatelessWidget {
  final String label;
  final String value;

  const _ScreenMetricChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF14141A),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF22222A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11.5, color: Color(0xFF71717A))),
          const SizedBox(height: 3),
          Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFFF7F5F0)),
          ),
        ],
      ),
    );
  }
}
