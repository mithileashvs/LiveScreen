import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/event.dart';
import '../models/venue.dart';
import '../models/seat.dart';
import 'digital_ticket_screen.dart';

enum PaymentMethod { upi, card, netBanking }

/// Checkout payment screen matching the LiveScreen visual system.
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

    await Future.delayed(const Duration(milliseconds: 1200));

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
      appBar: AppBar(
        title: const Text('Payment', style: AppTextStyles.heading),
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
                  // Amount due card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
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
                        const Text('Amount to Pay', style: AppTextStyles.body),
                        const SizedBox(height: 6),
                        Text(
                          '₹${widget.total.toInt()}',
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            color: AppColors.navy,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  const Text('Payment Method', style: AppTextStyles.subheading),
                  const SizedBox(height: 14),

                  _paymentOption(
                    method: PaymentMethod.upi,
                    icon: Icons.qr_code_rounded,
                    title: 'UPI',
                    subtitle: 'Google Pay, PhonePe, Paytm, BHIM',
                  ),
                  const SizedBox(height: 12),
                  _paymentOption(
                    method: PaymentMethod.card,
                    icon: Icons.credit_card_rounded,
                    title: 'Credit / Debit Card',
                    subtitle: 'Visa, Mastercard, RuPay',
                  ),
                  const SizedBox(height: 12),
                  _paymentOption(
                    method: PaymentMethod.netBanking,
                    icon: Icons.account_balance_rounded,
                    title: 'Net Banking',
                    subtitle: 'All major Indian banks supported',
                  ),
                ],
              ),
            ),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isProcessing ? null : _payNow,
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
                child: _isProcessing
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: AppColors.navy,
                        ),
                      )
                    : Text('Pay ₹${widget.total.toInt()} →'),
              ),
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
    return InkWell(
      onTap: () => setState(() => _selectedMethod = method),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.accent : AppColors.border,
            width: selected ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: selected ? 0.03 : 0.01),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.navy.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: selected ? AppColors.navy : AppColors.textSecondary,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.subheading.copyWith(
                      fontSize: 15,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                    ),
                  ),
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

