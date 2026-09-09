import 'package:flutter/material.dart';
import '../data/demo_data.dart';
import '../theme/app_theme.dart';
import '../widgets/movie_card.dart';
import 'event_details_screen.dart';

/// PART 11: a dedicated page, not a section stacked under "Now Showing".
/// Deliberately minimal for this phase — release dates, trailers, and
/// reminder notifications are explicitly future work per the spec.
class ComingSoonScreen extends StatelessWidget {
  const ComingSoonScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // No separate "coming soon" dataset exists yet — reusing the same movie
    // list here (rather than inventing a second one) keeps this page
    // functional without a duplicate data source; swapping in a real
    // release-date-based split is a filter to add later, not a rewrite.
    final movies = DemoData.events.where((e) => e.category == 'Movies').toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Coming Soon')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 210,
            mainAxisSpacing: 20,
            crossAxisSpacing: 20,
            childAspectRatio: 0.62,
          ),
          itemCount: movies.length,
          itemBuilder: (context, index) {
            final movie = movies[index];
            return MovieCard(
              event: movie,
              width: double.infinity,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => EventDetailsScreen(event: movie)),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
