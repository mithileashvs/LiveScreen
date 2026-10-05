import 'package:flutter/material.dart';
import '../admin/models/movie_content.dart';
import '../admin/services/movie_repository.dart';
import '../theme/customer_theme.dart';
import '../widgets/customer_widgets.dart';
import 'movie_details_screen.dart';

/// Dedicated Movies Page for LiveScreen Customers.
///
/// Strict Rule: MOVIES ONLY.
/// Only displays movies that have been uploaded by Producers,
/// verified by Platform Admin, and published via [movieRepository.getPublishedMovies()].
class CustomerMoviesScreen extends StatefulWidget {
  final ValueChanged<MovieContent>? onSelectMovie;

  const CustomerMoviesScreen({super.key, this.onSelectMovie});

  @override
  State<CustomerMoviesScreen> createState() => _CustomerMoviesScreenState();
}

class _CustomerMoviesScreenState extends State<CustomerMoviesScreen> {
  List<MovieContent> _movies = [];
  bool _isLoading = true;
  String _selectedGenre = 'All';
  final String _searchFilter = '';

  static const List<String> _genres = [
    'All',
    'Action',
    'Drama',
    'Sci-Fi',
    'Thriller',
    'Comedy',
    'Romance',
  ];

  @override
  void initState() {
    super.initState();
    _loadPublishedMovies();
  }

  Future<void> _loadPublishedMovies() async {
    try {
      final movies = await movieRepository.getPublishedMovies();
      if (mounted) {
        setState(() {
          _movies = movies;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<MovieContent> get _filteredMovies {
    return _movies.where((m) {
      if (_searchFilter.isNotEmpty) {
        final q = _searchFilter.toLowerCase();
        final matches = m.title.toLowerCase().contains(q) ||
            m.description.toLowerCase().contains(q);
        if (!matches) return false;
      }
      if (_selectedGenre != 'All') {
        final matchesGenre = m.description.toLowerCase().contains(_selectedGenre.toLowerCase()) ||
            m.title.toLowerCase().contains(_selectedGenre.toLowerCase());
        if (!matchesGenre) return false;
      }
      return true;
    }).toList();
  }

  void _openDetails(MovieContent movie) {
    if (widget.onSelectMovie != null) {
      widget.onSelectMovie!(movie);
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MovieDetailsScreen(movie: movie),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final movies = _filteredMovies;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category Heading
          Row(
            children: [
              RichText(
                text: const TextSpan(
                  children: [
                    TextSpan(
                      text: 'Now Showing ',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: CustomerColors.textPrimary,
                        letterSpacing: -0.4,
                      ),
                    ),
                    TextSpan(
                      text: 'Movies',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: CustomerColors.gold,
                        letterSpacing: -0.4,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                '${movies.length} Movies Available',
                style: const TextStyle(
                  color: CustomerColors.textMuted,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Genre filter chips
          SizedBox(
            height: 38,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _genres.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final genre = _genres[index];
                final isSelected = genre == _selectedGenre;
                return GestureDetector(
                  onTap: () => setState(() => _selectedGenre = genre),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isSelected ? CustomerColors.burgundy : CustomerColors.surfaceCard,
                      borderRadius: BorderRadius.circular(19),
                      border: Border.all(
                        color: isSelected ? CustomerColors.gold : CustomerColors.borderGoldSubtle,
                        width: isSelected ? 1.2 : 1.0,
                      ),
                    ),
                    child: Text(
                      genre,
                      style: TextStyle(
                        color: isSelected ? CustomerColors.textPrimary : CustomerColors.textSecondary,
                        fontSize: 12.5,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 24),

          // Movies Grid / Content
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 60),
              child: Center(
                child: CircularProgressIndicator(color: CustomerColors.gold),
              ),
            )
          else if (movies.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 56, horizontal: 24),
              decoration: BoxDecoration(
                color: CustomerColors.surfaceCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: CustomerColors.borderSubtle),
              ),
              child: Column(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: CustomerColors.surfaceElevated,
                      shape: BoxShape.circle,
                      border: Border.all(color: CustomerColors.borderGold),
                    ),
                    child: const Icon(
                      Icons.movie_filter_outlined,
                      size: 32,
                      color: CustomerColors.gold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No Verified Movies Available',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: CustomerColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Only Platform Admin verified & published releases appear here.\nCheck back soon for new scheduled titles.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: CustomerColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                // Responsive grid: calculate card width to fit nicely
                const minCardWidth = 180.0;
                final crossAxisCount = (constraints.maxWidth / (minCardWidth + 18)).floor().clamp(2, 6);
                final cardWidth = (constraints.maxWidth - (crossAxisCount - 1) * 18) / crossAxisCount;

                return Wrap(
                  spacing: 18,
                  runSpacing: 22,
                  children: [
                    for (final movie in movies)
                      CustomerMovieCard(
                        title: movie.title.isEmpty ? '(Untitled)' : movie.title,
                        posterUrl: movie.thumbnail.isNotEmpty ? movie.thumbnail : null,
                        genre: movie.durationSeconds > 0
                            ? '${movie.durationSeconds ~/ 60}m • Cinema'
                            : 'Cinema Release',
                        onTap: () => _openDetails(movie),
                        width: cardWidth,
                      ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }
}
