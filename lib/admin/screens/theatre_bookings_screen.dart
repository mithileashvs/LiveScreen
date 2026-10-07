import 'package:flutter/material.dart';
import '../../shared/widgets/admin/admin_sidebar.dart';
import '../../shared/widgets/admin/admin_top_bar.dart';
import '../../shared/widgets/admin/admin_status_badge.dart';
import '../../shared/widgets/admin/admin_stat_card.dart';
import '../../shared/models/booking_model.dart';
import '../../shared/services/booking_repository.dart';
import 'admin_dashboard_screen.dart';
import 'theatre_list_screen.dart';
import 'theatre_screens_screen.dart';
import 'theatre_shows_screen.dart';
import 'theatre_analytics_screen.dart';
import 'theatre_snacks_screen.dart';

/// Redesigned 'Theatre Bookings' Screen for Theatre Admin.
/// Implements the master dark cinematic design language (Black, Gold & Burgundy).
class TheatreBookingsScreen extends StatefulWidget {
  const TheatreBookingsScreen({super.key});

  @override
  State<TheatreBookingsScreen> createState() => _TheatreBookingsScreenState();
}

class _TheatreBookingsScreenState extends State<TheatreBookingsScreen> {
  late Future<List<BookingModel>> _bookingsFuture;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    setState(() {
      _bookingsFuture = bookingRepository.getMyBookings();
    });
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
      // already here
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
      activeKey: 'bookings',
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
                  searchPlaceholder: 'Search booking ID, customer, seat...',
                  showDrawerButton: !isDesktop,
                  onProfileTap: () => _navigateTo('my_theatre'),
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
                              'Theatre Bookings',
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFFFFFFFF),
                                letterSpacing: -0.5,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Real-time confirmed ticket reservations, seats, and customer check-in records.',
                              style: TextStyle(fontSize: 13.5, color: Color(0xFF9CA3AF)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        FutureBuilder<List<BookingModel>>(
                          future: _bookingsFuture,
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(48),
                                  child: CircularProgressIndicator(color: Color(0xFFD4AF37)),
                                ),
                              );
                            }

                            final bookings = snapshot.data!;
                            final confirmedCount = bookings.where((b) => b.status.toLowerCase() == 'confirmed').length;
                            final estimatedRevenue = bookings.length * 190;

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Quick KPI Metrics Row
                                Row(
                                  children: [
                                    Expanded(
                                      child: AdminStatCard(
                                        icon: Icons.confirmation_number_outlined,
                                        value: '${bookings.length}',
                                        label: 'Total Bookings',
                                        trendText: bookings.isNotEmpty ? '${bookings.length} reservations' : 'No reservations',
                                        isTrendPositive: bookings.isNotEmpty,
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: AdminStatCard(
                                        icon: Icons.check_circle_outline_rounded,
                                        iconColor: const Color(0xFF10B981),
                                        iconBgColor: const Color(0x2210B981),
                                        value: '$confirmedCount',
                                        label: 'Confirmed Tickets',
                                        trendText: '$confirmedCount active',
                                        isTrendPositive: confirmedCount > 0,
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: AdminStatCard(
                                        icon: Icons.currency_rupee_rounded,
                                        iconColor: const Color(0xFFD4AF37),
                                        value: '₹$estimatedRevenue',
                                        label: 'Estimated Ticket Gross',
                                        trendText: 'Calculated gross',
                                        isTrendPositive: estimatedRevenue > 0,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 24),

                                if (bookings.isEmpty)
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
                                      children: const [
                                        Icon(Icons.confirmation_number_outlined, size: 48, color: Color(0xFF71717A)),
                                        SizedBox(height: 14),
                                        Text('No Bookings Yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFFFFFFFF))),
                                        SizedBox(height: 6),
                                        Text(
                                          'When audience members reserve tickets, live records will display here in real time.',
                                          style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                  )
                                else
                                  Container(
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF0F0F12),
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(color: const Color(0xFF1E1E26)),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(14),
                                      child: Table(
                                        columnWidths: const {
                                          0: FlexColumnWidth(2.2),
                                          1: FlexColumnWidth(2),
                                          2: FlexColumnWidth(1.8),
                                          3: FlexColumnWidth(2),
                                        },
                                        children: [
                                          TableRow(
                                            decoration: const BoxDecoration(
                                              color: Color(0xFF14141A),
                                              border: Border(bottom: BorderSide(color: Color(0xFF1E1E26))),
                                            ),
                                            children: const [
                                              Padding(
                                                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                                                child: Text('Booking ID', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: Color(0xFF71717A))),
                                              ),
                                              Padding(
                                                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                                child: Text('Seat Reserved', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: Color(0xFF71717A))),
                                              ),
                                              Padding(
                                                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                                child: Text('Status', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: Color(0xFF71717A))),
                                              ),
                                              Padding(
                                                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                                child: Text('Time', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: Color(0xFF71717A))),
                                              ),
                                            ],
                                          ),
                                          for (final b in bookings)
                                            TableRow(
                                              decoration: const BoxDecoration(
                                                border: Border(bottom: BorderSide(color: Color(0xFF1A1A22), width: 0.8)),
                                              ),
                                              children: [
                                                Padding(
                                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                                  child: Row(
                                                    children: [
                                                      const Icon(Icons.tag_rounded, size: 14, color: Color(0xFFD4AF37)),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        b.id.length > 8 ? b.id.substring(0, 8).toUpperCase() : b.id.toUpperCase(),
                                                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFFD4AF37)),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                Padding(
                                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                                  child: Row(
                                                    children: [
                                                      const Icon(Icons.event_seat_outlined, size: 15, color: Color(0xFF9CA3AF)),
                                                      const SizedBox(width: 6),
                                                      Text(
                                                        b.seatId,
                                                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5, color: Color(0xFFF7F5F0)),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                Padding(
                                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                                  child: AdminStatusBadge(status: b.status, showDot: true),
                                                ),
                                                Padding(
                                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                                  child: Text(
                                                    b.createdAt != null
                                                        ? '${b.createdAt!.day}/${b.createdAt!.month} at ${b.createdAt!.hour.toString().padLeft(2, '0')}:${b.createdAt!.minute.toString().padLeft(2, '0')}'
                                                        : 'Confirmed',
                                                    style: const TextStyle(fontSize: 12.5, color: Color(0xFF9CA3AF)),
                                                  ),
                                                ),
                                              ],
                                            ),
                                        ],
                                      ),
                                    ),
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
}
