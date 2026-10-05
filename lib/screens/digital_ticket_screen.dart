import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/event.dart';
import '../models/venue.dart';
import '../models/seat.dart';
import 'unity_experience_screen.dart';

/// Shown after a successful checkout.
/// Displays the confirmed booking as a clean digital ticket with a QR placeholder.
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
              const SizedBox(height: 8),
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.success,
                  size: 36,
                ),
              ),
              const SizedBox(height: 12),
              const Text('Booking Confirmed!', style: AppTextStyles.heading),
              const SizedBox(height: 20),

              // Digital Ticket Card
              Expanded(
                child: SingleChildScrollView(
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.border),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Ticket Header
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 20,
                          ),
                          decoration: const BoxDecoration(
                            color: AppColors.navy,
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(19),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              RichText(
                                text: const TextSpan(
                                  children: [
                                    TextSpan(
                                      text: 'Live',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                    TextSpan(
                                      text: 'Screen',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.accent,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.accent,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'E-TICKET',
                                  style: TextStyle(
                                    color: AppColors.navy,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            children: [
                              Text(
                                event.title,
                                style: AppTextStyles.heading.copyWith(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '${event.genre} • ${event.duration}',
                                style: AppTextStyles.caption.copyWith(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 20),

                              // QR Box
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceSubtle,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: const Icon(
                                  Icons.qr_code_2_rounded,
                                  size: 130,
                                  color: AppColors.navy,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Scan at theatre entrance',
                                style: AppTextStyles.caption,
                              ),
                              const SizedBox(height: 20),

                              const Divider(color: AppColors.border, height: 1),
                              const SizedBox(height: 16),

                              _ticketRow('Theatre', venue.name),
                              _ticketRow('Screen', screenName),
                              _ticketRow('Seat', seat.label, highlight: true),
                              _ticketRow('Date', date),
                              _ticketRow('Showtime', time),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Bottom Actions
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => UnityExperienceScreen(
                              seatLabel: seat.label,
                              // DEMO-ONLY PATH. Reached exclusively from
                              // MockPaymentScreen, at the end of the
                              // DemoData chain (SeatSelectionScreen ->
                              // BookingSummaryScreen -> MockPaymentScreen
                              // -> here), which carries EventModel/
                              // VenueModel demo objects and never a
                              // TheatreConfiguration. Real bookings go
                              // through TheatreBookingConfirmScreen.
                              theatre: null,
                              movie: null,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(
                        Icons.view_in_ar_rounded,
                        size: 18,
                        color: AppColors.navy,
                      ),
                      label: const Text('Experience Seat (3D)'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.navy,
                        side: const BorderSide(color: AppColors.navy),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context)
                          .popUntil((route) => route.isFirst),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: AppColors.navy,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        textStyle: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      child: const Text('Done'),
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

  Widget _ticketRow(String label, String value, {bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.body),
          Text(
            value,
            style: TextStyle(
              fontSize: highlight ? 16 : 14,
              fontWeight: highlight ? FontWeight.w800 : FontWeight.w600,
              color: highlight ? AppColors.navy : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
