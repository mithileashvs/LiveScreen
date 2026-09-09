import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../admin/models/theatre_configuration.dart';
import '../admin/services/theatre_repository.dart';
import '../shared/models/show_model.dart';
import '../shared/services/show_repository.dart';
import 'theatre_seat_selection_screen.dart';

/// User-facing detail screen for one PUBLISHED theatre — reached from the
/// new "Live Theatres" section on HomeScreen. Everything here comes from
/// [theatreRepository]/[showRepository]; nothing is hardcoded.
class TheatreDetailScreen extends StatefulWidget {
  final String theatreId;

  const TheatreDetailScreen({super.key, required this.theatreId});

  @override
  State<TheatreDetailScreen> createState() => _TheatreDetailScreenState();
}

class _TheatreDetailScreenState extends State<TheatreDetailScreen> {
  late Future<TheatreConfiguration?> _theatreFuture;
  Future<List<ShowModel>>? _showsFuture;

  @override
  void initState() {
    super.initState();
    _theatreFuture = theatreRepository.loadTheatre(widget.theatreId).then((config) {
      if (config != null) {
        setState(() {
          _showsFuture = showRepository.getShowsForTheatre(config.id);
        });
      }
      return config;
    });
  }

  void _selectSeat(TheatreConfiguration theatre, {String? showId}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TheatreSeatSelectionScreen(theatre: theatre, showId: showId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Theatre')),
      body: FutureBuilder<TheatreConfiguration?>(
        future: _theatreFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator(color: AppColors.accent));
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Unable to load this theatre. Try again.\n${snapshot.error}',
                    style: AppTextStyles.body, textAlign: TextAlign.center),
              ),
            );
          }

          final theatre = snapshot.data;
          if (theatre == null) {
            return const Center(
              child: Text('This theatre is no longer available.', style: AppTextStyles.body),
            );
          }

          final movie = theatre.content;

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(theatre.basicInfo.name, style: AppTextStyles.heading),
              const SizedBox(height: 4),
              Text(
                theatre.basicInfo.hallName.isEmpty ? 'Auditorium' : theatre.basicInfo.hallName,
                style: AppTextStyles.caption,
              ),
              if (theatre.basicInfo.description.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(theatre.basicInfo.description, style: AppTextStyles.body),
              ],
              const SizedBox(height: 20),
              if (movie != null && movie.title.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.movie_outlined, color: AppColors.accent),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(movie.title, style: AppTextStyles.subheading),
                            if (movie.durationSeconds > 0)
                              Text('${movie.durationSeconds ~/ 60} min',
                                  style: AppTextStyles.caption),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
              Text('${theatre.seats.length} seats configured', style: AppTextStyles.caption),
              const SizedBox(height: 16),
              if (_showsFuture != null)
                FutureBuilder<List<ShowModel>>(
                  future: _showsFuture,
                  builder: (context, showSnapshot) {
                    final shows = showSnapshot.data ?? [];
                    if (showSnapshot.connectionState == ConnectionState.done && shows.isNotEmpty) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Showtimes', style: AppTextStyles.subheading),
                          const SizedBox(height: 10),
                          for (final show in shows)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: OutlinedButton(
                                onPressed: () => _selectSeat(theatre, showId: show.id),
                                child: Text(_formatShowTime(show.startTime)),
                              ),
                            ),
                          const SizedBox(height: 12),
                        ],
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ElevatedButton(
                onPressed: () => _selectSeat(theatre),
                child: const Text('Select Your Seat'),
              ),
            ],
          );
        },
      ),
    );
  }

  String _formatShowTime(DateTime dt) {
    final local = dt.toLocal();
    final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final minute = local.minute.toString().padLeft(2, '0');
    final period = local.hour >= 12 ? 'PM' : 'AM';
    return '${local.month}/${local.day} · $hour:$minute $period';
  }
}
