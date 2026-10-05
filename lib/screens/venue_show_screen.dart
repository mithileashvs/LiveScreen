import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/event.dart';
import '../models/venue.dart';
import '../data/demo_data.dart';
import 'seat_selection_screen.dart';

/// Lets the user pick a date, screen, and showtime for a given event + venue,
/// before moving on to seat selection.
class VenueShowScreen extends StatefulWidget {
  final EventModel event;
  final VenueModel venue;

  const VenueShowScreen({
    super.key,
    required this.event,
    required this.venue,
  });

  @override
  State<VenueShowScreen> createState() => _VenueShowScreenState();
}

class _VenueShowScreenState extends State<VenueShowScreen> {
  final List<String> _dates = ['Today', 'Tomorrow', 'Sat, 30 Aug'];
  int _selectedDateIndex = 0;
  String? _selectedTime;
  late String _selectedScreen;

  @override
  void initState() {
    super.initState();
    _selectedScreen = widget.venue.screens.first;
  }

  @override
  Widget build(BuildContext context) {
    final showTimes = DemoData.showTimesFor(widget.event.id);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Choose Show', style: AppTextStyles.heading),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.border, height: 1),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Venue and movie header card
            Container(
              width: double.infinity,
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
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.navy.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Icon(
                      Icons.theaters_outlined,
                      color: AppColors.navy,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.venue.name,
                          style: AppTextStyles.subheading.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.event.title,
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Screen selection
            const Text('Select Screen', style: AppTextStyles.subheading),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              children: widget.venue.screens.map((screen) {
                final bool selected = _selectedScreen == screen;
                return ChoiceChip(
                  label: Text(screen),
                  selected: selected,
                  onSelected: (_) => setState(() => _selectedScreen = screen),
                  backgroundColor: AppColors.surface,
                  selectedColor: AppColors.accent,
                  labelStyle: TextStyle(
                    color: selected ? AppColors.navy : AppColors.textPrimary,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                  side: BorderSide(
                    color: selected ? AppColors.accent : AppColors.border,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            // Date selection
            const Text('Select Date', style: AppTextStyles.subheading),
            const SizedBox(height: 12),
            SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _dates.length,
                separatorBuilder: (_, _) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final bool selected = _selectedDateIndex == index;
                  return InkWell(
                    onTap: () => setState(() => _selectedDateIndex = index),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: selected ? AppColors.accent : AppColors.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: selected ? AppColors.accent : AppColors.border,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: selected ? 0.04 : 0.01),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        _dates[index],
                        style: TextStyle(
                          color: selected ? AppColors.navy : AppColors.textPrimary,
                          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            // Showtimes selection
            const Text('Available Showtimes', style: AppTextStyles.subheading),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: showTimes.map((time) {
                final bool selected = _selectedTime == time;
                return InkWell(
                  onTap: () => setState(() => _selectedTime = time),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    decoration: BoxDecoration(
                      color: selected ? AppColors.accent : AppColors.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: selected ? AppColors.accent : AppColors.border,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: selected ? 0.04 : 0.01),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Text(
                      time,
                      style: TextStyle(
                        color: selected ? AppColors.navy : AppColors.textPrimary,
                        fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 48),
            // Submit button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _selectedTime == null
                    ? null
                    : () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => SeatSelectionScreen(
                              event: widget.event,
                              venue: widget.venue,
                              screenName: _selectedScreen,
                              date: _dates[_selectedDateIndex],
                              time: _selectedTime!,
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
                child: const Text('Continue to Seats'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
