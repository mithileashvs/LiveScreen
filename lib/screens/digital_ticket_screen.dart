import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/event.dart';
import '../models/venue.dart';
import '../models/seat.dart';
import 'main_nav_screen.dart';

/// Shown after a successful (mock) payment.
/// Displays the confirmed booking as a digital ticket with a QR placeholder.
class DigitalTicketScreen extends StatelessWidget {
  final EventModel event;
  final VenueModel venue;
  final String screenName;
  final String date;
  final String time;
  final SeatModel seat;

  const DigitalTicketScreen({
    super.key,
    required this.event,
    required this.venue,
    required this.screenName,
    required this.date,
    required this.time,
    required this.seat,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.success,
                ),
                child: const Icon(Icons.check_rounded, color: Colors.black, size: 40),
              ),
              const SizedBox(height: 18),
              Text('Booking Confirmed', style: AppTextStyles.heading),
              const SizedBox(height: 28),

              // Ticket card
              Expanded(
                child: SingleChildScrollView(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppColors.surfaceElevated, AppColors.surface],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                    ),
                    child: Column(
                      children: [
                        RichText(
                          text: const TextSpan(
                            children: [
                              TextSpan(text: 'Live', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                              TextSpan(text: 'Screen', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.accent)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(event.title, style: AppTextStyles.subheading.copyWith(fontSize: 20)),
                        const SizedBox(height: 20),

                        // QR placeholder
                        Container(
                          width: 160,
                          height: 160,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.qr_code_2_rounded, size: 140, color: Colors.black),
                        ),
                        const SizedBox(height: 24),

                        _dashedDivider(),
                        const SizedBox(height: 16),

                        _ticketRow('Venue', venue.name),
                        _ticketRow('Screen', screenName),
                        _ticketRow('Seat', seat.label),
                        _ticketRow('Date', date),
                        _ticketRow('Time', time),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Full ticket view coming soon')),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: const BorderSide(color: AppColors.accent),
                      ),
                      child: const Text('View Ticket', style: TextStyle(color: AppColors.accent)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (_) => const MainNavScreen()),
                          (route) => false,
                        );
                      },
                      style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                      child: const Text('Back to Home'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dashedDivider() {
    return SizedBox(
      height: 1,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final dashWidth = 6.0;
          final dashCount = (constraints.maxWidth / (dashWidth * 2)).floor();
          return Flex(
            direction: Axis.horizontal,
            children: List.generate(dashCount, (_) {
              return Expanded(
                child: Container(
                  color: Colors.white24,
                  height: 1,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                ),
              );
            }),
          );
        },
      ),
    );
  }

  Widget _ticketRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.body),
          Text(value, style: AppTextStyles.subheading.copyWith(fontSize: 14)),
        ],
      ),
    );
  }
}
