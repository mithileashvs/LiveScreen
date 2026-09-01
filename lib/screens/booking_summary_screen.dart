import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/event.dart';
import '../models/venue.dart';
import '../models/seat.dart';
import 'mock_payment_screen.dart';

/// Shows a summary of the booking (event, venue, seat, price breakdown)
/// before the user proceeds to payment.
class BookingSummaryScreen extends StatelessWidget {
  final EventModel event;
  final VenueModel venue;
  final String screenName;
  final String date;
  final String time;
  final SeatModel seat;

  const BookingSummaryScreen({
    super.key,
    required this.event,
    required this.venue,
    required this.screenName,
    required this.date,
    required this.time,
    required this.seat,
  });

  static const double convenienceFee = 20;

  @override
  Widget build(BuildContext context) {
    final double total = seat.price + convenienceFee;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Booking Summary')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Expanded(
              child: ListView(
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                    ),
                    child: Column(
                      children: [
                        _row('Event', event.title),
                        _row('Venue', venue.name),
                        _row('Screen', screenName),
                        _row('Date', date),
                        _row('Time', time),
                        _row('Seat', seat.label),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                    ),
                    child: Column(
                      children: [
                        _row('Ticket', '₹${seat.price.toInt()}'),
                        _row('Convenience fee', '₹${convenienceFee.toInt()}'),
                        const Divider(color: Colors.white24, height: 24),
                        _row('Total', '₹${total.toInt()}', emphasize: true),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => MockPaymentScreen(
                      event: event,
                      venue: venue,
                      screenName: screenName,
                      date: date,
                      time: time,
                      seat: seat,
                      total: total,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 54)),
              child: const Text('Continue to Payment'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value, {bool emphasize = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: emphasize ? AppTextStyles.subheading : AppTextStyles.body),
          Text(
            value,
            style: emphasize
                ? AppTextStyles.subheading.copyWith(color: AppColors.accent, fontSize: 18)
                : AppTextStyles.subheading.copyWith(fontSize: 14),
          ),
        ],
      ),
    );
  }
}
