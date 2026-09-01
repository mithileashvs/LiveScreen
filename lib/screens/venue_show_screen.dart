import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/event.dart';
import '../models/venue.dart';
import '../data/demo_data.dart';
import 'seat_selection_screen.dart';

/// Lets the user pick a date and showtime for a given event + venue,
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
      appBar: AppBar(title: const Text('Choose Show')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.location_city, color: AppColors.electricBlue),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.venue.name, style: AppTextStyles.subheading),
                      Text(widget.event.title, style: AppTextStyles.caption),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text('Screen', style: AppTextStyles.subheading),
            const SizedBox(height: 10),
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
                    color: selected ? Colors.black : AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            Text('Date', style: AppTextStyles.subheading),
            const SizedBox(height: 10),
            SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _dates.length,
                separatorBuilder: (_, _) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final bool selected = _selectedDateIndex == index;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedDateIndex = index),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                      decoration: BoxDecoration(
                        color: selected ? AppColors.accent : AppColors.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        _dates[index],
                        style: TextStyle(
                          color: selected ? Colors.black : AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            Text('Showtimes', style: AppTextStyles.subheading),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: showTimes.map((time) {
                final bool selected = _selectedTime == time;
                return GestureDetector(
                  onTap: () => setState(() => _selectedTime = time),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    decoration: BoxDecoration(
                      color: selected ? AppColors.accent : AppColors.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                    ),
                    child: Text(
                      time,
                      style: TextStyle(
                        color: selected ? Colors.black : AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const Spacer(),
            ElevatedButton(
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
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 54)),
              child: const Text('Continue to Seats'),
            ),
          ],
        ),
      ),
    );
  }
}
