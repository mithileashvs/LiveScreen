import 'package:flutter/material.dart';
import '../data/demo_data.dart';
import '../theme/app_theme.dart';
import '../widgets/movie_card.dart';
import 'event_details_screen.dart';

/// Dedicated Coming Soon page matching the LiveScreen visual system.
class ComingSoonScreen extends StatelessWidget {
  const ComingSoonScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final movies = DemoData.events.where((e) => e.category == 'Movies').toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Coming Soon', style: AppTextStyles.heading),
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
            const Text(
              'Upcoming Releases',
              style: AppTextStyles.heading,
            ),
            const SizedBox(height: 6),
            const Text(
              'Be the first to experience these titles on the biggest screens.',
              style: AppTextStyles.body,
            ),
            const SizedBox(height: 24),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 190,
                mainAxisSpacing: 20,
                crossAxisSpacing: 18,
                childAspectRatio: 182 / 310,
              ),
              itemCount: movies.length,
              itemBuilder: (context, index) {
                final movie = movies[index];
                return MovieCard(
                  event: movie,
                  width: double.infinity,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => EventDetailsScreen(event: movie),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
