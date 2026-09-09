import 'package:flutter/material.dart';
import '../models/event.dart';
import '../theme/app_theme.dart';

/// A premium "Now Showing" movie card. Deliberately does NOT use real movie
/// poster artwork — LiveScreen has no image/asset pipeline for that yet,
/// and reproducing real studio poster art would be someone else's
/// copyrighted material. Instead each card gets a category-tinted gradient
/// with a large line icon, which reads as an intentional design choice
/// (similar to how many streaming apps render a fallback state) rather
/// than a missing image.
class MovieCard extends StatefulWidget {
  final EventModel event;
  final VoidCallback onTap;
  final double width;

  const MovieCard({
    super.key,
    required this.event,
    required this.onTap,
    this.width = 210,
  });

  @override
  State<MovieCard> createState() => _MovieCardState();
}

class _MovieCardState extends State<MovieCard> {
  bool _hovering = false;

  ({Color start, Color end, IconData icon}) _styleFor(String category) {
    switch (category) {
      case 'Concerts':
        return (start: const Color(0xFF3A1E4A), end: const Color(0xFF1A1024), icon: Icons.mic_rounded);
      case 'Sports':
        return (start: const Color(0xFF1E3A34), end: const Color(0xFF10201C), icon: Icons.sports_cricket_rounded);
      case 'Theatre':
        return (start: const Color(0xFF4A1E28), end: const Color(0xFF241014), icon: Icons.theater_comedy_rounded);
      case 'Comedy':
        return (start: const Color(0xFF4A3A1E), end: const Color(0xFF241C10), icon: Icons.sentiment_very_satisfied_rounded);
      case 'Events':
        return (start: const Color(0xFF1E2A4A), end: const Color(0xFF101424), icon: Icons.event_rounded);
      default: // Movies
        return (start: const Color(0xFF2A1E3A), end: const Color(0xFF14101F), icon: Icons.movie_creation_rounded);
    }
  }

  @override
  Widget build(BuildContext context) {
    final style = _styleFor(widget.event.category);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _hovering ? 1.03 : 1.0,
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            width: widget.width,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _hovering
                    ? AppColors.accent.withValues(alpha: 0.6)
                    : Colors.white.withValues(alpha: 0.08),
              ),
              boxShadow: _hovering
                  ? [
                      BoxShadow(
                        color: AppColors.accent.withValues(alpha: 0.18),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ]
                  : [],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Poster area — 2:3 cinema poster ratio.
                AspectRatio(
                  aspectRatio: 2 / 3,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [style.start, style.end],
                      ),
                    ),
                    child: Center(
                      child: Icon(style.icon, size: 56, color: Colors.white.withValues(alpha: 0.55)),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.event.title,
                        style: AppTextStyles.subheading,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${widget.event.genre} • ${widget.event.duration}',
                        style: AppTextStyles.caption,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.star_rounded, size: 15, color: AppColors.accent),
                          const SizedBox(width: 4),
                          Text(
                            widget.event.rating.toStringAsFixed(1),
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
