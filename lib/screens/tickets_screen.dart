import 'package:flutter/material.dart';
import '../theme/customer_theme.dart';
import 'unity_experience_screen.dart';

/// My Bookings screen for LiveScreen Customers.
///
/// Designed with the black/gold/burgundy cinematic theme.
/// Features "Upcoming" and "Past" sections, ticket cards, and 3D Seat Experience.
class TicketsScreen extends StatelessWidget {
  const TicketsScreen({super.key});

  static final List<Map<String, String>> _upcomingBookings = [
    {
      'movie': 'Demo Movie',
      'theatre': 'LiveScreen Cinemas',
      'screen': 'Screen 1',
      'date': 'Today, 12 Sep',
      'time': '7:30 PM',
      'seats': 'F10, F11',
      'seatPrimary': 'F10',
      'status': 'CONFIRMED',
    },
  ];

  static final List<Map<String, String>> _pastBookings = [
    {
      'movie': 'Midnight Horizon',
      'theatre': 'LiveScreen Cinemas',
      'screen': 'Screen 2',
      'date': '28 Aug 2026',
      'time': '4:00 PM',
      'seats': 'D8',
      'seatPrimary': 'D8',
      'status': 'COMPLETED',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: CustomerColors.background,
        appBar: AppBar(
          title: const Text(
            'My Bookings',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: CustomerColors.textPrimary,
            ),
          ),
          backgroundColor: CustomerColors.surface,
          foregroundColor: CustomerColors.textPrimary,
          elevation: 0,
          bottom: const TabBar(
            labelColor: CustomerColors.gold,
            unselectedLabelColor: CustomerColors.textSecondary,
            indicatorColor: CustomerColors.gold,
            indicatorWeight: 3,
            labelStyle: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
            unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
            tabs: [
              Tab(text: 'Upcoming'),
              Tab(text: 'Past'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildBookingList(context, _upcomingBookings, isUpcoming: true),
            _buildBookingList(context, _pastBookings, isUpcoming: false),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingList(
    BuildContext context,
    List<Map<String, String>> bookings, {
    required bool isUpcoming,
  }) {
    if (bookings.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: CustomerColors.surfaceElevated,
                  shape: BoxShape.circle,
                  border: Border.all(color: CustomerColors.borderGold),
                ),
                child: const Icon(
                  Icons.confirmation_number_outlined,
                  size: 36,
                  color: CustomerColors.gold,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                isUpcoming ? 'No upcoming bookings' : 'No past bookings',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: CustomerColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                isUpcoming
                    ? 'Explore movies and book your favourite seat.'
                    : 'Your completed bookings will appear here.',
                style: const TextStyle(color: CustomerColors.textSecondary, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(24),
      itemCount: bookings.length,
      separatorBuilder: (_, _) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final b = bookings[index];
        final isConfirmed = b['status'] == 'CONFIRMED';

        return Container(
          decoration: BoxDecoration(
            color: CustomerColors.surfaceCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: CustomerColors.borderSubtle),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      b['movie']!,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: CustomerColors.textPrimary,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isConfirmed
                            ? CustomerColors.gold.withValues(alpha: 0.18)
                            : CustomerColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isConfirmed
                              ? CustomerColors.gold
                              : CustomerColors.borderSubtle,
                        ),
                      ),
                      child: Text(
                        b['status']!,
                        style: TextStyle(
                          color: isConfirmed
                              ? CustomerColors.gold
                              : CustomerColors.textSecondary,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${b['theatre']} • ${b['screen']}',
                  style: const TextStyle(
                    color: CustomerColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 14),
                const Divider(color: CustomerColors.borderSubtle, height: 1),
                const SizedBox(height: 14),
                Row(
                  children: [
                    _infoColumn('DATE & TIME', '${b['date']} • ${b['time']}'),
                    const SizedBox(width: 32),
                    _infoColumn('SEATS', b['seats']!),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    if (isUpcoming) ...[
                      OutlinedButton.icon(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => UnityExperienceScreen(
                                seatLabel: b['seatPrimary']!,
                                theatre: null,
                                movie: null,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(
                          Icons.view_in_ar_rounded,
                          size: 16,
                          color: CustomerColors.gold,
                        ),
                        label: const Text('Experience Seat'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: CustomerColors.gold,
                          side: const BorderSide(color: CustomerColors.borderGold),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    ElevatedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Digital ticket for ${b['movie']} is verified.',
                            ),
                            backgroundColor: CustomerColors.surface,
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: CustomerColors.burgundy,
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: CustomerColors.gold, width: 0.9),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('View Ticket'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _infoColumn(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: CustomerColors.textMuted,
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: const TextStyle(
            color: CustomerColors.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
