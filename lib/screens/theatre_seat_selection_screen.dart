import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../admin/models/theatre_configuration.dart';
import '../admin/models/seat_config.dart';
import 'unity_experience_screen.dart';
import 'theatre_booking_confirm_screen.dart';

/// The database-backed counterpart to the existing (untouched)
/// SeatSelectionScreen. Deliberately a separate, small screen rather than
/// retrofitting SeatSelectionScreen's EventModel/VenueModel-shaped
/// constructor — that screen and its existing generic-event flow are left
/// exactly as they were, avoiding any regression risk to already-working
/// code, at the cost of a little duplication in the seat-grid rendering.
///
/// Renders seats grouped by row/number (not by each seat's real X/Y/Z
/// metres, which would need canvas-style scaling like
/// VisualTheatreCanvas) — a simpler, uniform grid, same spirit as the
/// existing SeatSelectionScreen.
class TheatreSeatSelectionScreen extends StatefulWidget {
  final TheatreConfiguration theatre;
  final String? showId;

  const TheatreSeatSelectionScreen({super.key, required this.theatre, this.showId});

  @override
  State<TheatreSeatSelectionScreen> createState() => _TheatreSeatSelectionScreenState();
}

class _TheatreSeatSelectionScreenState extends State<TheatreSeatSelectionScreen> {
  SeatConfig? _selected;

  Color _colorFor(SeatConfig seat) {
    final isSelected = seat.id == _selected?.id;
    if (isSelected) return AppColors.accent;
    switch (seat.category) {
      case SeatCategory.premium:
        return AppColors.seatPremium;
      case SeatCategory.recliner:
        return AppColors.seatRecliner;
      case SeatCategory.standard:
        return AppColors.seatAvailable;
    }
  }

  @override
  Widget build(BuildContext context) {
    final seats = widget.theatre.seats;
    final rows = <String, List<SeatConfig>>{};
    for (final seat in seats) {
      rows.putIfAbsent(seat.row, () => []).add(seat);
    }
    final rowLabels = rows.keys.toList()..sort();
    for (final list in rows.values) {
      list.sort((a, b) => a.number.compareTo(b.number));
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Select Your Seat')),
      body: seats.isEmpty
          ? const Center(
              child: Text('This theatre has no configured seats yet.', style: AppTextStyles.body),
            )
          : Column(
              children: [
                const Padding(
                  padding: EdgeInsets.all(20),
                  child: Text('SCREEN', style: AppTextStyles.caption, textAlign: TextAlign.center),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: [
                          for (final rowLabel in rowLabels)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 5),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(
                                    width: 20,
                                    child: Text(rowLabel, style: AppTextStyles.caption),
                                  ),
                                  const SizedBox(width: 8),
                                  for (final seat in rows[rowLabel]!)
                                    GestureDetector(
                                      onTap: () => setState(() => _selected = seat),
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
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (_selected != null)
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: const BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Seat ${_selected!.id}', style: AppTextStyles.subheading),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => UnityExperienceScreen(
                                        seatLabel: _selected!.id,
                                        theatre: widget.theatre,
                                      ),
                                    ),
                                  );
                                },
                                child: const Text('Experience This Seat'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => TheatreBookingConfirmScreen(
                                        theatre: widget.theatre,
                                        showId: widget.showId,
                                        seat: _selected!,
                                      ),
                                    ),
                                  );
                                },
                                child: const Text('Book This Seat'),
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
}
