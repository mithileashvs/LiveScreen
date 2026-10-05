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
      appBar: AppBar(
        title: const Text('Booking Summary', style: AppTextStyles.heading),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.border, height: 1),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Expanded(
              child: ListView(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Booking Details', style: AppTextStyles.subheading.copyWith(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 14),
                        const Divider(color: AppColors.border, height: 1),
                        const SizedBox(height: 14),
                        _row('Event', event.title),
                        _row('Venue', venue.name),
                        _row('Screen', screenName),
                        _row('Date', date),
                        _row('Time', time),
                        _row('Seat', seat.label),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Price Breakdown', style: AppTextStyles.subheading.copyWith(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 14),
                        const Divider(color: AppColors.border, height: 1),
                        const SizedBox(height: 14),
                        _row('Ticket Price', '₹${seat.price.toInt()}'),
                        _row('Convenience Fee', '₹${convenienceFee.toInt()}'),
                        const SizedBox(height: 10),
                        const Divider(color: AppColors.border, height: 1),
                        const SizedBox(height: 10),
                        _row('Total Payable', '₹${total.toInt()}', emphasize: true),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
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
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: AppColors.navy,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                child: const Text('Continue to Payment →'),
              ),
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
          Text(
            label,
            style: TextStyle(
              color: emphasize ? AppColors.textPrimary : AppColors.textSecondary,
              fontSize: emphasize ? 15 : 14,
              fontWeight: emphasize ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: emphasize ? AppColors.navy : AppColors.textPrimary,
              fontSize: emphasize ? 19 : 14,
              fontWeight: emphasize ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

