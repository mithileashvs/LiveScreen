import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/event.dart';
import '../models/venue.dart';
import '../data/demo_data.dart';
import 'venue_show_screen.dart';

/// Shown when the user taps on an event from the Home screen.
/// Displays event info, description, and lets them pick a venue + show.
class EventDetailsScreen extends StatelessWidget {
  final EventModel event;

  const EventDetailsScreen({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    final List<VenueModel> availableVenues = DemoData.venues
        .where((venue) => event.venueIds.contains(venue.id))
        .toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 20, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Container(
                    height: 220,
                    width: double.infinity,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppColors.surfaceElevated, AppColors.surface],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                    ),
                    child: Text(event.posterEmoji, style: const TextStyle(fontSize: 72)),
                  ),
                  const SizedBox(height: 20),
                  Text(event.title, style: AppTextStyles.displayLarge.copyWith(fontSize: 26)),
                  const SizedBox(height: 6),
                  Text(
                    '${event.genre} • ${event.duration}${event.language != 'N/A' ? ' • ${event.language}' : ''}',
                    style: AppTextStyles.body,
                  ),
                  const SizedBox(height: 18),
                  Text('About', style: AppTextStyles.subheading),
                  const SizedBox(height: 8),
                  Text(event.description, style: AppTextStyles.body),
                  const SizedBox(height: 24),
                  Text('Available At', style: AppTextStyles.subheading),
                  const SizedBox(height: 12),
                  ...availableVenues.map((venue) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
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
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(venue.name, style: AppTextStyles.subheading.copyWith(fontSize: 15)),
                                Text(venue.location, style: AppTextStyles.caption),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 10),
                  Text('Shows Today', style: AppTextStyles.subheading),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: DemoData.showTimesFor(event.id).map((time) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                        ),
                        child: Text(time, style: AppTextStyles.body.copyWith(color: AppColors.textPrimary)),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(20),
        child: ElevatedButton(
          onPressed: () {
            if (availableVenues.isNotEmpty) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => VenueShowScreen(
                    event: event,
                    venue: availableVenues.first,
                  ),
                ),
              );
            }
          },
          style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 54)),
          child: const Text('Select Show'),
        ),
      ),
    );
  }
}
