import 'package:flutter/material.dart';
import '../admin/models/movie_content.dart';
import '../admin/services/movie_repository.dart';
import '../shared/services/trailer_url.dart';
import '../shared/widgets/trailer_player.dart';
import '../theme/customer_theme.dart';
import '../widgets/customer_widgets.dart';
import 'movie_showtimes_screen.dart';

/// Movie Details / About Movie Screen.
///
/// Designed with inspiration from Reference Image 2:
/// - Hero header with poster, "In Cinemas" tag, rating pill, formats
/// - Primary Action: "Book tickets" (solid burgundy CTA)
/// - Secondary Action: "Watch Trailer" (integrated trailer player)
/// - About section with synopsis and detailed metadata table
/// - Cast & Crew preview sections
/// - Top reviews
/// - "You might also like" recommendations from verified published movies
class MovieDetailsScreen extends StatefulWidget {
  final MovieContent movie;

  const MovieDetailsScreen({super.key, required this.movie});

  @override
  State<MovieDetailsScreen> createState() => _MovieDetailsScreenState();
}

class _MovieDetailsScreenState extends State<MovieDetailsScreen> {
  List<MovieContent> _recommendedMovies = [];
  bool _isLoadingRecommended = true;

  @override
  void initState() {
    super.initState();
    _loadRecommendations();
  }

  Future<void> _loadRecommendations() async {
    try {
      final all = await movieRepository.getPublishedMovies();
      if (mounted) {
        setState(() {
          _recommendedMovies = all.where((m) => m.id != widget.movie.id).take(6).toList();
          _isLoadingRecommended = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingRecommended = false);
    }
  }

  void _bookTickets() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MovieShowtimesScreen(movie: widget.movie),
      ),
    );
  }

  void _watchTrailer() {
    final effectiveUrl = widget.movie.trailerUrl.isNotEmpty
        ? widget.movie.trailerUrl
        : widget.movie.trailerPath;
    final source = TrailerSource.parse(effectiveUrl);

    if (source.isPlayable) {
      TrailerScreen.open(
        context,
        movieTitle: widget.movie.title,
        rawTrailerPath: effectiveUrl,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            source.problem ?? 'Trailer is not available for this movie right now.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final movie = widget.movie;
    final hasPoster = movie.thumbnail.trim().isNotEmpty;
    final durationFormatted = movie.durationSeconds > 0
        ? '${movie.durationSeconds ~/ 3600 > 0 ? '${movie.durationSeconds ~/ 3600}h ' : ''}${(movie.durationSeconds % 3600) ~/ 60}m'
        : '2h 15m';

    return Scaffold(
      backgroundColor: CustomerColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Navigation: Back button
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(
                          Icons.arrow_back_rounded,
                          color: CustomerColors.gold,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Back to Movies',
                          style: TextStyle(
                            color: CustomerColors.gold,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Hero Presentation (Poster + Info + CTAs)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: CustomerColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: CustomerColors.borderSubtle),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF14151C),
                      Color(0xFF0C0D12),
                    ],
                  ),
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isDesktop = constraints.maxWidth >= 720;

                    final posterWidget = Container(
                      width: isDesktop ? 220 : 170,
                      height: (isDesktop ? 220 : 170) * 1.48,
                      decoration: BoxDecoration(
                        color: CustomerColors.surfaceCard,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: CustomerColors.borderGold, width: 1.2),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black87,
                            blurRadius: 18,
                            offset: Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(13),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            if (hasPoster)
                              Image.network(
                                movie.thumbnail.trim(),
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => _fallbackPoster(movie.title),
                              )
                            else
                              _fallbackPoster(movie.title),
                            Positioned(
                              left: 0,
                              right: 0,
                              bottom: 0,
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 6),
                                color: Colors.black.withValues(alpha: 0.85),
                                child: const Center(
                                  child: Text(
                                    'In Cinemas',
                                    style: TextStyle(
                                      color: CustomerColors.gold,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );

                    final infoWidget = Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title
                        Text(
                          movie.title.isNotEmpty ? movie.title : 'LiveScreen Feature',
                          style: TextStyle(
                            fontSize: isDesktop ? 32 : 24,
                            fontWeight: FontWeight.w800,
                            color: CustomerColors.textPrimary,
                            letterSpacing: -0.5,
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Rating badge pill
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: CustomerColors.surfaceCard,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: CustomerColors.borderGoldSubtle),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.star_rounded, size: 18, color: CustomerColors.gold),
                              SizedBox(width: 6),
                              Text(
                                '8.8/10',
                                style: TextStyle(
                                  color: CustomerColors.textPrimary,
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              SizedBox(width: 8),
                              Text(
                                '(12.4K+ Votes)',
                                style: TextStyle(
                                  color: CustomerColors.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 14),

                        // Metadata line
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              durationFormatted,
                              style: const TextStyle(color: CustomerColors.textSecondary, fontSize: 13),
                            ),
                            const Text('•', style: TextStyle(color: CustomerColors.textMuted)),
                            const Text(
                              'Action, Drama',
                              style: TextStyle(color: CustomerColors.textSecondary, fontSize: 13),
                            ),
                            const Text('•', style: TextStyle(color: CustomerColors.textMuted)),
                            const Text(
                              'UA16+',
                              style: TextStyle(color: CustomerColors.textSecondary, fontSize: 13),
                            ),
                            const Text('•', style: TextStyle(color: CustomerColors.textMuted)),
                            const Text(
                              'Standard Audio & Visuals',
                              style: TextStyle(color: CustomerColors.textSecondary, fontSize: 13),
                            ),
                          ],
                        ),

                        const SizedBox(height: 14),

                        // Format tags
                        Wrap(
                          spacing: 8,
                          children: [
                            _formatTag('2D'),
                            _formatTag('IMAX'),
                            _formatTag('Dolby Atmos'),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // CTA Buttons (Book tickets + Watch Trailer)
                        Wrap(
                          spacing: 14,
                          runSpacing: 10,
                          children: [
                            ElevatedButton.icon(
                              onPressed: _bookTickets,
                              icon: const Icon(Icons.confirmation_number_outlined, size: 18),
                              label: const Text('Book tickets'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: CustomerColors.burgundy,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                side: const BorderSide(color: CustomerColors.gold, width: 1.2),
                                padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                textStyle: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            OutlinedButton.icon(
                              onPressed: _watchTrailer,
                              icon: const Icon(Icons.play_circle_outline_rounded, size: 18),
                              label: const Text('Watch Trailer'),
                              style: OutlinedButton.styleFrom(
                                backgroundColor: CustomerColors.surfaceCard,
                                foregroundColor: CustomerColors.gold,
                                side: const BorderSide(color: CustomerColors.gold, width: 1.2),
                                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                textStyle: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    );

                    if (isDesktop) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          posterWidget,
                          const SizedBox(width: 28),
                          Expanded(child: infoWidget),
                        ],
                      );
                    } else {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(child: posterWidget),
                          const SizedBox(height: 20),
                          infoWidget,
                        ],
                      );
                    }
                  },
                ),
              ),

              const SizedBox(height: 24),

              // About the movie section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'About the movie',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: CustomerColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      movie.description.isNotEmpty
                          ? movie.description
                          : 'Experience this cinema release presented with immersive visuals and premium theatre soundscapes.',
                      style: const TextStyle(
                        fontSize: 14,
                        color: CustomerColors.textSecondary,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Metadata details grid
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: CustomerColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: CustomerColors.borderSubtle),
                      ),
                      child: Wrap(
                        spacing: 36,
                        runSpacing: 16,
                        children: [
                          _metaItem('Duration', durationFormatted),
                          _metaItem('Status', 'Verified & Published'),
                          _metaItem('Release', 'Now Showing'),
                          _metaItem('Format', '2D / 3D Theatre'),
                          _metaItem('Languages', 'English, Tamil, Hindi'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Cast & Crew Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Cast & Crew',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: CustomerColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      height: 110,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          _personCard('Lead Actor', 'Cast'),
                          _personCard('Supporting Lead', 'Cast'),
                          _personCard('Director', 'Crew'),
                          _personCard('Music Director', 'Crew'),
                          _personCard('Cinematographer', 'Crew'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Top Reviews Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Top Reviews',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: CustomerColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 14),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isDesktop = constraints.maxWidth >= 600;
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _reviewCard(
                                author: 'Rahul S.',
                                date: 'Yesterday',
                                rating: '10/10',
                                comment:
                                    'An absolute cinematic masterpiece with outstanding sound design and visuals.',
                                likes: 42,
                              ),
                            ),
                            if (isDesktop) ...[
                              const SizedBox(width: 16),
                              Expanded(
                                child: _reviewCard(
                                  author: 'Priya K.',
                                  date: '2 days ago',
                                  rating: '9/10',
                                  comment:
                                      'Gripping storytelling from start to finish. Highly recommended on a big screen!',
                                  likes: 28,
                                ),
                              ),
                            ],
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 36),

              // You might also like recommendations
              if (!_isLoadingRecommended && _recommendedMovies.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'You Might Also Like',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: CustomerColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        height: 280,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _recommendedMovies.length,
                          separatorBuilder: (_, _) => const SizedBox(width: 16),
                          itemBuilder: (context, index) {
                            final rec = _recommendedMovies[index];
                            return CustomerMovieCard(
                              title: rec.title.isNotEmpty ? rec.title : '(Untitled)',
                              posterUrl: rec.thumbnail.isNotEmpty ? rec.thumbnail : null,
                              genre: rec.durationSeconds > 0
                                  ? '${rec.durationSeconds ~/ 60}m • Cinema'
                                  : 'Cinema Release',
                              width: 175,
                              onTap: () {
                                Navigator.of(context).pushReplacement(
                                  MaterialPageRoute(
                                    builder: (_) => MovieDetailsScreen(movie: rec),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _formatTag(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: CustomerColors.surfaceElevated,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: CustomerColors.borderGoldSubtle),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: CustomerColors.goldLight,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _metaItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: CustomerColors.textMuted,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: CustomerColors.textPrimary,
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _personCard(String name, String role) {
    return Container(
      width: 90,
      margin: const EdgeInsets.only(right: 14),
      child: Column(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: CustomerColors.surfaceHighlight,
            child: const Icon(Icons.person, color: CustomerColors.textSecondary, size: 28),
          ),
          const SizedBox(height: 6),
          Text(
            name,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: CustomerColors.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          Text(
            role,
            style: const TextStyle(
              fontSize: 10,
              color: CustomerColors.textMuted,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _reviewCard({
    required String author,
    required String date,
    required String rating,
    required String comment,
    required int likes,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CustomerColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: CustomerColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: CustomerColors.surfaceCard,
                child: Text(
                  author[0],
                  style: const TextStyle(color: CustomerColors.gold, fontSize: 12),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      author,
                      style: const TextStyle(
                        color: CustomerColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      date,
                      style: const TextStyle(
                        color: CustomerColors.textMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: CustomerColors.surfaceCard,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star_rounded, size: 14, color: CustomerColors.gold),
                    const SizedBox(width: 3),
                    Text(
                      rating,
                      style: const TextStyle(
                        color: CustomerColors.textPrimary,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            comment,
            style: const TextStyle(
              color: CustomerColors.textSecondary,
              fontSize: 12.5,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.thumb_up_outlined, size: 14, color: CustomerColors.textMuted),
              const SizedBox(width: 4),
              Text(
                '$likes',
                style: const TextStyle(color: CustomerColors.textMuted, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _fallbackPoster(String title) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF222633),
            Color(0xFF13151D),
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.movie_creation_outlined,
              size: 44,
              color: CustomerColors.gold.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 8),
            Text(
              title.isNotEmpty ? title : 'LiveScreen',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: CustomerColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
