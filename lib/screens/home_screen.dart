import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../data/demo_data.dart';
import '../widgets/category_chip.dart';
import '../widgets/featured_event_card.dart';
import '../widgets/venue_card.dart';
import '../admin/models/theatre_configuration.dart';
import '../admin/services/theatre_repository.dart';
import 'event_details_screen.dart';
import 'theatre_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _selectedCategory = 'Movies';
  late Future<List<TheatreConfiguration>> _theatresFuture;

  @override
  void initState() {
    super.initState();
    // Published theatres come straight from the same database a Theatre
    // Admin publishes through — no separate hardcoded user-side list.
    _theatresFuture = theatreRepository.getPublishedTheatres();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 16),
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  RichText(
                    text: const TextSpan(
                      children: [
                        TextSpan(text: 'Live', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                        TextSpan(text: 'Screen', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.accent)),
                      ],
                    ),
                  ),
                  const CircleAvatar(
                    radius: 18,
                    backgroundColor: AppColors.surfaceElevated,
                    child: Icon(Icons.person, color: AppColors.textSecondary, size: 20),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Search bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.search, color: AppColors.textMuted, size: 20),
                    SizedBox(width: 10),
                    Text('Search movies, concerts, sports & events', style: AppTextStyles.caption),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Categories
            SizedBox(
              height: 42,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  CategoryChip(emoji: '🎬', label: 'Movies', selected: _selectedCategory == 'Movies', onTap: () => setState(() => _selectedCategory = 'Movies')),
                  CategoryChip(emoji: '🎤', label: 'Concerts', selected: _selectedCategory == 'Concerts', onTap: () => setState(() => _selectedCategory = 'Concerts')),
                  CategoryChip(emoji: '🏏', label: 'Sports', selected: _selectedCategory == 'Sports', onTap: () => setState(() => _selectedCategory = 'Sports')),
                  CategoryChip(emoji: '🎭', label: 'Theatre', selected: _selectedCategory == 'Theatre', onTap: () => setState(() => _selectedCategory = 'Theatre')),
                  CategoryChip(emoji: '😂', label: 'Comedy', selected: _selectedCategory == 'Comedy', onTap: () => setState(() => _selectedCategory = 'Comedy')),
                  CategoryChip(emoji: '🎪', label: 'Events', selected: _selectedCategory == 'Events', onTap: () => setState(() => _selectedCategory = 'Events')),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Live Theatres — published theatres from the shared database
            // (Theatre Admin's Preview & Publish). See PART: cross-role
            // persistence — this is the section that must show a theatre
            // right after a Theatre Admin publishes it.
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text('Live Theatres', style: AppTextStyles.heading.copyWith(fontSize: 18)),
            ),
            const SizedBox(height: 14),
            FutureBuilder<List<TheatreConfiguration>>(
              future: _theatresFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Text('Loading theatres...', style: AppTextStyles.caption),
                  );
                }
                if (snapshot.hasError) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Text('Unable to load theatres. Try again.',
                        style: AppTextStyles.caption),
                  );
                }
                final theatres = snapshot.data ?? [];
                if (theatres.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Text('No published theatres yet.', style: AppTextStyles.caption),
                  );
                }
                return SizedBox(
                  height: 100,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: theatres.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      final theatre = theatres[index];
                      return GestureDetector(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => TheatreDetailScreen(theatreId: theatre.id),
                            ),
                          );
                        },
                        child: Container(
                          width: 200,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                theatre.basicInfo.name,
                                style: AppTextStyles.subheading,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                theatre.content?.title.isNotEmpty == true
                                    ? theatre.content!.title
                                    : '${theatre.seats.length} seats',
                                style: AppTextStyles.caption,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
            const SizedBox(height: 28),

            // Featured Events
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text('Featured Events', style: AppTextStyles.heading.copyWith(fontSize: 18)),
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 210,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: DemoData.events.map((event) {
                  return FeaturedEventCard(
                    event: event,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => EventDetailsScreen(event: event)),
                      );
                    },
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 28),

            // Popular Venues
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text('Popular Venues', style: AppTextStyles.heading.copyWith(fontSize: 18)),
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 110,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: DemoData.venues.map((venue) {
                  return VenueCard(
                    venue: venue,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('${venue.name} tapped')),
                      );
                    },
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
