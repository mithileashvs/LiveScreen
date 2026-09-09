import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../admin/models/theatre_configuration.dart';
import '../admin/models/seat_config.dart';
import '../shared/services/booking_repository.dart';

/// Deliberately minimal — per the task spec, this is NOT the full mock
/// payment flow the old EventModel-based booking screens have; it's "the
/// minimal persistent booking structure necessary for future development."
class TheatreBookingConfirmScreen extends StatefulWidget {
  final TheatreConfiguration theatre;
  final String? showId;
  final SeatConfig seat;

  const TheatreBookingConfirmScreen({
    super.key,
    required this.theatre,
    required this.seat,
    this.showId,
  });

  @override
  State<TheatreBookingConfirmScreen> createState() => _TheatreBookingConfirmScreenState();
}

class _TheatreBookingConfirmScreenState extends State<TheatreBookingConfirmScreen> {
  bool _submitting = false;
  bool _confirmed = false;
  String? _error;

  Future<void> _confirm() async {
    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      await bookingRepository.createBooking(
        theatreId: widget.theatre.id,
        showId: widget.showId,
        seatId: widget.seat.id,
      );
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _confirmed = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Confirm Booking')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: _confirmed ? _buildSuccess(context) : _buildConfirm(),
      ),
    );
  }

  Widget _buildConfirm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.theatre.basicInfo.name, style: AppTextStyles.subheading),
              const SizedBox(height: 8),
              if (widget.theatre.content?.title.isNotEmpty == true)
                Text(widget.theatre.content!.title, style: AppTextStyles.body),
              const SizedBox(height: 8),
              Text('Seat ${widget.seat.id}', style: AppTextStyles.body),
            ],
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 16),
          Text(_error!, style: const TextStyle(color: AppColors.error, fontSize: 13)),
        ],
        const Spacer(),
        ElevatedButton(
          onPressed: _submitting ? null : _confirm,
          child: _submitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                )
              : const Text('Confirm Booking'),
        ),
      ],
    );
  }

  Widget _buildSuccess(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.check_circle, color: AppColors.success, size: 64),
        const SizedBox(height: 16),
        const Text('Booking Confirmed', style: AppTextStyles.heading),
        const SizedBox(height: 8),
        Text('Seat ${widget.seat.id} at ${widget.theatre.basicInfo.name}',
            style: AppTextStyles.body, textAlign: TextAlign.center),
        const SizedBox(height: 32),
        ElevatedButton(
          onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
          child: const Text('Done'),
        ),
      ],
    );
  }
}
