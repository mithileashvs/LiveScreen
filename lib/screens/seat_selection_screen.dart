import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/event.dart';
import '../models/venue.dart';
import '../models/seat.dart';
import '../data/demo_data.dart';
import 'unity_experience_screen.dart';
import 'booking_summary_screen.dart';

/// Interactive cinema seat map matching the LiveScreen visual system.
/// Immersive cinema palette: Deep Navy, Gold, White, Neutral Grey (No purple).
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
        return AppColors.seatPremium; // Deep Navy #0B1F3A
      case SeatType.recliner:
        return AppColors.seatRecliner;
      case SeatType.available:
      case SeatType.selected:
        return AppColors.seatAvailable;
    }
  }

  Border? _borderFor(SeatModel seat) {
    if (seat == _selectedSeat) {
      return Border.all(color: AppColors.accentSoft, width: 1.5);
    }
    if (seat.type == SeatType.available) {
      return Border.all(color: AppColors.border, width: 1);
    }
    return null;
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
      appBar: AppBar(
        title: const Text('Select Your Seat', style: AppTextStyles.heading),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.border, height: 1),
        ),
      ),
      body: Column(
        children: [
          // Screen Indicator
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Column(
              children: [
                Container(
                  width: 280,
                  height: 6,
                  decoration: BoxDecoration(
                    color: AppColors.navy,
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.navy.withValues(alpha: 0.25),
                        blurRadius: 10,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'SCREEN',
                  style: AppTextStyles.caption.copyWith(
                    letterSpacing: 4,
                    fontWeight: FontWeight.w700,
                    color: AppColors.navy,
                  ),
                ),
              ],
            ),
          ),
          // Seat Map Grid
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                const horizontalPadding = 16.0;
                final viewportWidth = constraints.maxWidth - (horizontalPadding * 2);
                return SingleChildScrollView(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: horizontalPadding),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minWidth: viewportWidth),
                      child: Column(
                        children: rows.map((row) {
                          final rowSeats = _seats.where((s) => s.row == row).toList();
                          final aisleGaps = DemoData.aisleGapsAfterSeatNumber();
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 5),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 22,
                                  child: Text(
                                    row,
                                    style: AppTextStyles.caption.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                for (final seat in rowSeats) ...[
                                  GestureDetector(
                                    onTap: () => _onSeatTap(seat),
                                    child: Container(
                                      width: 26,
                                      height: 26,
                                      margin: const EdgeInsets.symmetric(horizontal: 2.5),
                                      decoration: BoxDecoration(
                                        color: _colorFor(seat),
                                        borderRadius: BorderRadius.circular(6),
                                        border: _borderFor(seat),
                                        boxShadow: seat == _selectedSeat
                                            ? [
                                                BoxShadow(
                                                  color: AppColors.accent.withValues(alpha: 0.4),
                                                  blurRadius: 6,
                                                  spreadRadius: 1,
                                                ),
                                              ]
                                            : null,
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
          // Legend
          Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
            color: AppColors.surface,
            child: Wrap(
              spacing: 18,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                _legendItem(AppColors.seatAvailable, 'Available', hasBorder: true),
                _legendItem(AppColors.seatSelected, 'Selected'),
                _legendItem(AppColors.seatBooked, 'Occupied'),
                _legendItem(AppColors.seatPremium, 'Premium (Navy)'),
                _legendItem(AppColors.seatRecliner, 'Recliner'),
              ],
            ),
          ),
          // Bottom selection action bar
          if (_selectedSeat != null)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: const Border(top: BorderSide(color: AppColors.border)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 12,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Seat ${_selectedSeat!.label}  •  1 Ticket',
                              style: AppTextStyles.subheading.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '₹${_selectedSeat!.price.toInt()}',
                              style: const TextStyle(
                                color: AppColors.accentSoft,
                                fontWeight: FontWeight.w700,
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        // Experience This Seat (Unity Integration)
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => UnityExperienceScreen(
                                    seatLabel: _selectedSeat!.label,
                                    // DEMO-ONLY PATH. This screen's seats
                                    // come from DemoData.generateSeats(),
                                    // not from any saved theatre, so there
                                    // is no TheatreConfiguration to send.
                                    // Explicitly null: Unity shows its
                                    // generic auditorium plus a visible
                                    // "Demo venue" badge. The real booking
                                    // path is TheatreSeatSelectionScreen,
                                    // which passes a real theatre.
                                    theatre: null,
                                    // Same demo-data reasoning: widget.event
                                    // is an EventModel (DemoData), not a
                                    // MovieContent — there's nothing real
                                    // to send.
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
                            label: const Text('Experience This Seat'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.navy,
                              side: const BorderSide(color: AppColors.navy, width: 1.2),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        // Proceed to Booking
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
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.accent,
                              foregroundColor: AppColors.navy,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              textStyle: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                            child: const Text('Proceed to Booking →'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _legendItem(Color color, String label, {bool hasBorder = false}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
            border: hasBorder ? Border.all(color: AppColors.border) : null,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
