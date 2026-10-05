import 'package:flutter/material.dart';
import '../models/event.dart';

/// A premium 2:3 portrait cinema movie card matching the LiveScreen visual system.
///
/// Surface: Dark Slate (#151B28).
/// Poster: ~72% height with real image support and sophisticated cinematic fallback.
/// Information: ~28% height with warm white typography, muted metadata, and metallic gold rating.
class MovieCard extends StatefulWidget {
  final EventModel event;
  final VoidCallback onTap;
  final double width;
  final double? height;
  final String? posterUrl;

  const MovieCard({
    super.key,
    required this.event,
    required this.onTap,
    this.width = 175,
    this.height,
    this.posterUrl,
  });

  @override
  State<MovieCard> createState() => _MovieCardState();
}

class _MovieCardState extends State<MovieCard> {
  bool _hovering = false;

  IconData _iconForCategory(String category) {
    switch (category) {
      case 'Concerts':
        return Icons.mic_rounded;
      case 'Sports':
        return Icons.sports_cricket_rounded;
      case 'Theatre':
        return Icons.theater_comedy_rounded;
      case 'Comedy':
        return Icons.sentiment_very_satisfied_rounded;
      case 'Events':
        return Icons.event_rounded;
      default:
        return Icons.movie_creation_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final icon = _iconForCategory(widget.event.category);
    final bool hasPosterUrl =
        widget.posterUrl != null && widget.posterUrl!.trim().isNotEmpty;
    final cardHeight = widget.height ?? (widget.width * 1.55); // ~2:3 portrait ratio

    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          width: widget.width,
          height: cardHeight,
          transform: _hovering
              ? Matrix4.translationValues(0.0, -4.0, 0.0)
              : Matrix4.identity(),
          decoration: BoxDecoration(
            color: const Color(0xFF151B28),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _hovering
                  ? const Color(0xFFE5A93C).withValues(alpha: 0.8)
                  : Colors.white.withValues(alpha: 0.07),
              width: _hovering ? 1.4 : 1.0,
            ),
            boxShadow: _hovering
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.45),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                    BoxShadow(
                      color: const Color(0xFFE5A93C).withValues(alpha: 0.16),
                      blurRadius: 12,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.22),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(13),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Poster area (~72% of card height)
                Expanded(
                  flex: 72,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (hasPosterUrl)
                        Image.network(
                          widget.posterUrl!.trim(),
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => _buildPosterFallback(icon),
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return _buildPosterFallback(icon, isLoading: true);
                          },
                        )
                      else
                        _buildPosterFallback(icon),

                      // Subtle category pill badge at top-left
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0A111E).withValues(alpha: 0.82),
                            borderRadius: BorderRadius.circular(5),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.12),
                            ),
                          ),
                          child: Text(
                            widget.event.genre.isNotEmpty
                                ? widget.event.genre.toUpperCase()
                                : widget.event.category.toUpperCase(),
                            style: const TextStyle(
                              color: Color(0xFFF7F5F0),
                              fontSize: 8.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Information area (~28% of card height)
                Container(
                  color: const Color(0xFF151B28),
                  padding: const EdgeInsets.fromLTRB(11, 9, 11, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Movie Title
                      Text(
                        widget.event.title,
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFF7F5F0),
                          letterSpacing: -0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),

                      // Genre • Duration
                      Text(
                        _formatMetadata(),
                        style: const TextStyle(
                          color: Color(0xFF7C8494),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w400,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 5),

                      // Rating (Metallic Gold Star + Score)
                      Row(
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            size: 15,
                            color: Color(0xFFE5A93C),
                          ),
                          const SizedBox(width: 3.5),
                          Text(
                            widget.event.rating.toStringAsFixed(1),
                            style: const TextStyle(
                              color: Color(0xFFF7F5F0),
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
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

  String _formatMetadata() {
    final parts = <String>[];
    if (widget.event.genre.isNotEmpty) parts.add(widget.event.genre);
    if (widget.event.duration.isNotEmpty) parts.add(widget.event.duration);
    if (parts.isEmpty) parts.add(widget.event.category);
    return parts.join(' • ');
  }

  Widget _buildPosterFallback(IconData icon, {bool isLoading = false}) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF1E283A),
            Color(0xFF0F1622),
          ],
        ),
      ),
      child: Center(
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFFE5A93C),
                ),
              )
            : Icon(
                icon,
                size: 38,
                color: Colors.white.withValues(alpha: 0.18),
              ),
      ),
    );
  }
}

/// A loading skeleton placeholder matching MovieCard's exact 2:3 proportions.
class MovieCardSkeleton extends StatelessWidget {
  final double width;

  const MovieCardSkeleton({super.key, this.width = 175});

  @override
  Widget build(BuildContext context) {
    final cardHeight = width * 1.55;

    return Container(
      width: width,
      height: cardHeight,
      decoration: BoxDecoration(
        color: const Color(0xFF151B28),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(13),
        child: Column(
          children: [
            Expanded(
              flex: 72,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF1B2435),
                      Color(0xFF121926),
                    ],
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.movie_creation_outlined,
                    size: 32,
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(11, 9, 11, 10),
              color: const Color(0xFF151B28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 12,
                    width: width * 0.7,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    height: 10,
                    width: width * 0.5,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 10,
                    width: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE5A93C).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

