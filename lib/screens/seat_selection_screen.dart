import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/event.dart';
import '../models/venue.dart';
import '../models/seat.dart';
import '../data/demo_data.dart';
import 'unity_experience_screen.dart';
import 'booking_summary_screen.dart';

/// Interactive seat map. The user taps a seat to see its details,
/// then can either experience it first or select it directly.
class SeatSelectionScreen extends StatefulWidget {
  final EventModel event;
  final VenueModel venue;
  final String screenName;
  final String date;
  final String time;

  const SeatSelectionScreen({
    super.key,
    required this.event,
    required this.venue,
    required this.screenName,
    required this.date,
    required this.time,
  });

  @override
  State<SeatSelectionScreen> createState() => _SeatSelectionScreenState();
}

class _SeatSelectionScreenState extends State<SeatSelectionScreen> {
  late List<SeatModel> _seats;
  SeatModel? _selectedSeat;

  @override
  void initState() {
    super.initState();
    _seats = DemoData.generateSeats();
  }

  Color _colorFor(SeatModel seat) {
    if (seat == _selectedSeat) return AppColors.seatSelected;
    switch (seat.type) {
      case SeatType.booked:
        return AppColors.seatBooked;
      case SeatType.premium:
        return AppColors.seatPremium;
      case SeatType.recliner:
        return AppColors.seatRecliner;
      case SeatType.available:
      case SeatType.selected:
        return AppColors.seatAvailable;
    }
  }

  void _onSeatTap(SeatModel seat) {
    if (seat.type == SeatType.booked) return;
    setState(() {
      _selectedSeat = (seat == _selectedSeat) ? null : seat;
    });
  }

  @override
  Widget build(BuildContext context) {
    final rows = _seats.map((s) => s.row).toSet().toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Select Your Seat')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              children: [
                Container(
                  width: 240,
                  height: 6,
                  decoration: BoxDecoration(
                    color: AppColors.electricBlue.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.electricBlue.withValues(alpha: 0.4),
                        blurRadius: 12,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text('SCREEN', style: AppTextStyles.caption.copyWith(letterSpacing: 3)),
              ],
            ),
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Rows are wider than most phone screens once the aisle gap
                // is included, so this whole seat map scrolls horizontally
                // when it needs to. But a plain horizontal SingleChildScrollView
                // always pins its content to the left when the content is
                // narrower than the viewport (e.g. on a wide window/tablet) —
                // it never centers on its own. Forcing a minWidth equal to the
                // viewport width, combined with Column's default center
                // cross-axis alignment below, makes the grid center itself
                // when it fits and scroll normally when it doesn't.
                const horizontalPadding = 16.0;
                final viewportWidth = constraints.maxWidth - (horizontalPadding * 2);
                return SingleChildScrollView(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: horizontalPadding),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minWidth: viewportWidth),
                      child: Column(
                        // Default CrossAxisAlignment.center: centers each row
                        // within the Column's width (which is at least the
                        // full viewport width thanks to the constraint above).
                        children: rows.map((row) {
                          final rowSeats = _seats.where((s) => s.row == row).toList();
                          // Seat numbers after which Unity draws an aisle gap —
                          // keeps the app's layout visually aligned with the 3D venue.
                          final aisleGaps = DemoData.aisleGapsAfterSeatNumber();
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 5),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 20,
                                  child: Text(row, style: AppTextStyles.caption),
                                ),
                                const SizedBox(width: 8),
                                for (final seat in rowSeats) ...[
                                  GestureDetector(
                                    onTap: () => _onSeatTap(seat),
                                    child: Container(
                                      width: 26,
                                      height: 26,
                                      margin: const EdgeInsets.symmetric(horizontal: 3),
                                      decoration: BoxDecoration(
                                        color: _colorFor(seat),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                    ),
                                  ),
                                  if (aisleGaps.contains(seat.number))
                                    const SizedBox(width: 24),
                                ],
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Wrap(
              spacing: 16,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                _legendDot(AppColors.seatAvailable, 'Available'),
                _legendDot(AppColors.seatSelected, 'Selected'),
                _legendDot(AppColors.seatBooked, 'Booked'),
                _legendDot(AppColors.seatPremium, 'Premium'),
                _legendDot(AppColors.seatRecliner, 'Recliner'),
              ],
            ),
          ),
          if (_selectedSeat != null)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.06))),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Seat ${_selectedSeat!.label}', style: AppTextStyles.subheading),
                          Text('₹${_selectedSeat!.price.toInt()}', style: AppTextStyles.body.copyWith(color: AppColors.accent, fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => UnityExperienceScreen(
                                  seatLabel: _selectedSeat!.label,
                                ),
                              ),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: const BorderSide(color: AppColors.accent),
                          ),
                          child: const Text('Experience This Seat', style: TextStyle(color: AppColors.accent)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => BookingSummaryScreen(
                                  event: widget.event,
                                  venue: widget.venue,
                                  screenName: widget.screenName,
                                  date: widget.date,
                                  time: widget.time,
                                  seat: _selectedSeat!,
                                ),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                          child: const Text('Select Seat'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 6),
        Text(label, style: AppTextStyles.caption),
      ],
    );
  }
}
