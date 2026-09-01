import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/event.dart';
import '../models/venue.dart';
import '../models/seat.dart';
import 'digital_ticket_screen.dart';

enum PaymentMethod { upi, card, netBanking }

/// A realistic-looking but fully mock checkout screen.
/// No real payment gateway is integrated in Phase 1 —
/// pressing "Pay" simply simulates a successful payment.
class MockPaymentScreen extends StatefulWidget {
  final EventModel event;
  final VenueModel venue;
  final String screenName;
  final String date;
  final String time;
  final SeatModel seat;
  final double total;

  const MockPaymentScreen({
    super.key,
    required this.event,
    required this.venue,
    required this.screenName,
    required this.date,
    required this.time,
    required this.seat,
    required this.total,
  });

  @override
  State<MockPaymentScreen> createState() => _MockPaymentScreenState();
}

class _MockPaymentScreenState extends State<MockPaymentScreen> {
  PaymentMethod _selectedMethod = PaymentMethod.upi;
  bool _isProcessing = false;

  void _payNow() async {
    setState(() => _isProcessing = true);

    // Simulate a short "processing" delay, like a real payment gateway would have.
    await Future.delayed(const Duration(milliseconds: 1400));

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => DigitalTicketScreen(
          event: widget.event,
          venue: widget.venue,
          screenName: widget.screenName,
          date: widget.date,
          time: widget.time,
          seat: widget.seat,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Payment')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Expanded(
              child: ListView(
                children: [
                  // Amount due
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppColors.surfaceElevated, AppColors.surface],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                    ),
                    child: Column(
                      children: [
                        Text('Amount to pay', style: AppTextStyles.body),
                        const SizedBox(height: 6),
                        Text(
                          '₹${widget.total.toInt()}',
                          style: AppTextStyles.displayLarge.copyWith(color: AppColors.accent),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  Text('Choose Payment Method', style: AppTextStyles.subheading),
                  const SizedBox(height: 14),

                  _paymentOption(
                    method: PaymentMethod.upi,
                    icon: Icons.qr_code_rounded,
                    title: 'UPI',
                    subtitle: 'Pay using any UPI app (mock)',
                  ),
                  const SizedBox(height: 12),
                  _paymentOption(
                    method: PaymentMethod.card,
                    icon: Icons.credit_card_rounded,
                    title: 'Credit / Debit Card',
                    subtitle: 'Visa, Mastercard, Rupay (mock)',
                  ),
                  const SizedBox(height: 12),
                  _paymentOption(
                    method: PaymentMethod.netBanking,
                    icon: Icons.account_balance_rounded,
                    title: 'Net Banking',
                    subtitle: 'All major banks supported (mock)',
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: _isProcessing ? null : _payNow,
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 54)),
              child: _isProcessing
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.black),
                    )
                  : Text('Pay ₹${widget.total.toInt()}'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _paymentOption({
    required PaymentMethod method,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final bool selected = _selectedMethod == method;
    return GestureDetector(
      onTap: () => setState(() => _selectedMethod = method),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.accent : Colors.white.withValues(alpha: 0.08),
            width: selected ? 1.6 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: selected ? AppColors.accent : AppColors.textSecondary),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.subheading.copyWith(fontSize: 15)),
                  Text(subtitle, style: AppTextStyles.caption),
                ],
              ),
            ),
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: selected ? AppColors.accent : AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}
