import 'package:flutter/material.dart';
import '../admin/models/theatre_configuration.dart';
import '../admin/models/movie_content.dart';
import '../admin/services/theatre_repository.dart';
import '../admin/services/movie_repository.dart';
import '../shared/models/show_model.dart';
import '../shared/services/show_repository.dart';
import 'theatre_seat_selection_screen.dart';

/// User-facing detail screen for one PUBLISHED theatre — reached from
/// "Explore Theatres" or movie details. Fully connected to Supabase repositories.
/// Styled with LiveScreen's premium cinematic theatre palette:
/// Black (#000000), Near Black (#080808), Charcoal (#151515),
/// Deep Burgundy (#700914), Warm Gold (#D4A84F), and Cream (#F2F0EA).
class TheatreDetailScreen extends StatefulWidget {
  final String theatreId;

  const TheatreDetailScreen({super.key, required this.theatreId});

  @override
  State<TheatreDetailScreen> createState() => _TheatreDetailScreenState();
}

class _TheatreDetailScreenState extends State<TheatreDetailScreen> {
  late Future<TheatreConfiguration?> _theatreFuture;
  Future<List<ShowModel>>? _showsFuture;
  final Map<String, MovieContent> _moviesById = {};

  @override
  void initState() {
    super.initState();
    _theatreFuture = theatreRepository.loadTheatre(widget.theatreId).then((config) {
      if (config != null) {
        setState(() {
          _showsFuture = showRepository.getShowsForTheatre(config.id).then((shows) async {
            final movieIds = shows.map((s) => s.movieId).whereType<String>().toSet();
            for (final id in movieIds) {
              if (_moviesById.containsKey(id)) continue;
              final movie = await movieRepository.getMovieById(id);
              if (movie != null) _moviesById[id] = movie;
            }
            if (mounted) setState(() {});
            return shows;
          });
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
      backgroundColor: const Color(0xFF080808),
      appBar: AppBar(
        title: const Text(
          'Theatre Details',
          style: TextStyle(
            fontFamily: 'Georgia',
            fontFamilyFallback: ['serif'],
            fontSize: 19,
            fontWeight: FontWeight.w600,
            color: Color(0xFFF2F0EA),
          ),
        ),
        backgroundColor: const Color(0xFF0C0C0C),
        foregroundColor: const Color(0xFFF2F0EA),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFF262626), height: 1),
        ),
      ),
      body: FutureBuilder<TheatreConfiguration?>(
        future: _theatreFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFD4A84F)),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Unable to load this theatre. Try again.\n${snapshot.error}',
                  style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final theatre = snapshot.data;
          if (theatre == null) {
            return const Center(
              child: Text(
                'This theatre is no longer available.',
                style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              // Theatre Hero Banner
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF0E0E0E),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xD9B8893C),
                    width: 1.2,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black87,
                      blurRadius: 20,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0x33D4A84F),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFFD4A84F), width: 0.8),
                          ),
                          child: const Text(
                            'LIVE VENUE',
                            style: TextStyle(
                              color: Color(0xFFD4A84F),
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                        const Spacer(),
                        const Icon(Icons.star_rounded, color: Color(0xFFD4A84F), size: 18),
                        const SizedBox(width: 4),
                        const Text(
                          '4.8',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      theatre.basicInfo.name,
                      style: const TextStyle(
                        fontFamily: 'Georgia',
                        fontFamilyFallback: ['serif'],
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFF2F0EA),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      theatre.basicInfo.hallName.isEmpty
                          ? 'Main Auditorium'
                          : theatre.basicInfo.hallName,
                      style: const TextStyle(
                        fontSize: 13.5,
                        color: Color(0xFF9CA3AF),
                      ),
                    ),
                    if (theatre.basicInfo.description.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      Text(
                        theatre.basicInfo.description,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFFCBD5E1),
                          height: 1.4,
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Icon(Icons.chair_outlined, color: Color(0xFFD4A84F), size: 16),
                        const SizedBox(width: 6),
                        Text(
                          '${theatre.seats.length} seats configured',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 20),
                        const Icon(Icons.volume_up_outlined, color: Color(0xFFD4A84F), size: 16),
                        const SizedBox(width: 6),
                        const Text(
                          'Dolby Atmos',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Showtimes Section
              if (_showsFuture != null)
                FutureBuilder<List<ShowModel>>(
                  future: _showsFuture,
                  builder: (context, showSnapshot) {
                    final allShows = showSnapshot.data ?? [];
                    final shows = allShows.where((s) => s.status == 'published').toList();
                    if (showSnapshot.connectionState != ConnectionState.done) {
                      return const SizedBox.shrink();
                    }
                    if (shows.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.only(bottom: 24),
                        child: Text(
                          'No published showtimes yet — check back soon.',
                          style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
                        ),
                      );
                    }

                    final byMovie = <String, List<ShowModel>>{};
                    for (final show in shows) {
                      byMovie.putIfAbsent(show.movieId ?? '', () => []).add(show);
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Now Showing',
                          style: TextStyle(
                            fontFamily: 'Georgia',
                            fontFamilyFallback: ['serif'],
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFF2F0EA),
                          ),
                        ),
                        const SizedBox(height: 14),
                        for (final entry in byMovie.entries) ...[
                          Text(
                            _moviesById[entry.key]?.title ?? 'Movie',
                            style: const TextStyle(
                              color: Color(0xFFD4A84F),
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              for (final show in entry.value)
                                InkWell(
                                  onTap: () => _selectSeat(theatre, showId: show.id),
                                  borderRadius: BorderRadius.circular(10),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF121212),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: const Color(0xFF262626)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.access_time_rounded,
                                          size: 15,
                                          color: Color(0xFFD4A84F),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          _formatShowTime(show.startTime),
                                          style: const TextStyle(
                                            color: Color(0xFFF2F0EA),
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          '₹${show.price.toStringAsFixed(0)}',
                                          style: const TextStyle(
                                            color: Color(0xFFD4A84F),
                                            fontWeight: FontWeight.w700,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 18),
                        ],
                        const SizedBox(height: 12),
                      ],
                    );
                  },
                ),

              // Experience Seat / Choose Seat CTAs
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _selectSeat(theatre),
                      icon: const Text('Select Your Seat'),
                      label: const Icon(Icons.arrow_forward_rounded, size: 16),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF700914), // deep burgundy
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        textStyle: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
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
