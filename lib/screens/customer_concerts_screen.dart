import 'package:flutter/material.dart';
import '../data/demo_data.dart';
import '../models/event.dart';
import '../theme/customer_theme.dart';
import 'event_details_screen.dart';

/// Dedicated Concerts Page for LiveScreen Customers.
///
/// Strict Rule: CONCERTS ONLY.
/// Does not show Movies, Events, or Sports.
/// Structure is data-ready for future concert tours & live music performances.
class CustomerConcertsScreen extends StatefulWidget {
  const CustomerConcertsScreen({super.key});

  @override
  State<CustomerConcertsScreen> createState() => _CustomerConcertsScreenState();
}

class _CustomerConcertsScreenState extends State<CustomerConcertsScreen> {
  String _selectedFilter = 'All Concerts';

  static const List<String> _filters = [
    'All Concerts',
    'Rock',
    'Pop',
    'Classical',
    'Electronic',
    'Indie',
    'Acoustic',
  ];

  List<EventModel> get _concerts {
    final list = DemoData.events.where((e) => e.category == 'Concerts').toList();
    if (_selectedFilter == 'All Concerts') return list;
    return list.where((e) =>
        e.genre.toLowerCase().contains(_selectedFilter.toLowerCase()) ||
        e.title.toLowerCase().contains(_selectedFilter.toLowerCase())).toList();
  }

  @override
  Widget build(BuildContext context) {
    final concerts = _concerts;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              RichText(
                text: const TextSpan(
                  children: [
                    TextSpan(
                      text: 'Live Music & ',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: CustomerColors.textPrimary,
                        letterSpacing: -0.4,
                      ),
                    ),
                    TextSpan(
                      text: 'Concerts',
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
                '${concerts.length} Tours Listed',
                style: const TextStyle(
                  color: CustomerColors.textMuted,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Filters
          SizedBox(
            height: 38,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _filters.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final filter = _filters[index];
                final isSelected = filter == _selectedFilter;
                return GestureDetector(
                  onTap: () => setState(() => _selectedFilter = filter),
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
                      filter,
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

          if (concerts.isEmpty)
            _buildEmptyState()
          else
            LayoutBuilder(
              builder: (context, constraints) {
                const minCardWidth = 280.0;
                final crossAxisCount = (constraints.maxWidth / (minCardWidth + 18)).floor().clamp(1, 4);
                final cardWidth = (constraints.maxWidth - (crossAxisCount - 1) * 18) / crossAxisCount;

                return Wrap(
                  spacing: 18,
                  runSpacing: 20,
                  children: [
                    for (final item in concerts)
                      _CustomerConcertCard(
                        event: item,
                        width: cardWidth,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => EventDetailsScreen(event: item),
                            ),
                          );
                        },
                      ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
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
              Icons.music_note_outlined,
              size: 32,
              color: CustomerColors.gold,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No Live Concerts in This Category',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: CustomerColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Major artist tour dates and arena concert announcements will be scheduled here.\nCheck back soon for the latest musical events.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: CustomerColors.textSecondary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _CustomerConcertCard extends StatefulWidget {
  final EventModel event;
  final double width;
  final VoidCallback onTap;

  const _CustomerConcertCard({
    required this.event,
    required this.width,
    required this.onTap,
  });

  @override
  State<_CustomerConcertCard> createState() => _CustomerConcertCardState();
}

class _CustomerConcertCardState extends State<_CustomerConcertCard> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: widget.width,
          transform: _hovering
              ? Matrix4.translationValues(0.0, -4.0, 0.0)
              : Matrix4.identity(),
          decoration: BoxDecoration(
            color: CustomerColors.surfaceCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _hovering ? CustomerColors.gold : CustomerColors.borderSubtle,
              width: _hovering ? 1.4 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: _hovering
                    ? CustomerColors.gold.withValues(alpha: 0.16)
                    : Colors.black.withValues(alpha: 0.25),
                blurRadius: _hovering ? 14 : 8,
                offset: Offset(0, _hovering ? 6 : 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Visual banner
              Container(
                height: 140,
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF26121E),
                      Color(0xFF140B10),
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    const Center(
                      child: Icon(
                        Icons.mic_external_on_rounded,
                        size: 46,
                        color: Color(0x66E11D48),
                      ),
                    ),
                    Positioned(
                      top: 10,
                      left: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: CustomerColors.background.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: CustomerColors.borderSubtle),
                        ),
                        child: Text(
                          widget.event.genre.toUpperCase(),
                          style: const TextStyle(
                            color: Color(0xFFF43F5E),
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: CustomerColors.surfaceCard.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star_rounded, size: 14, color: CustomerColors.gold),
                            const SizedBox(width: 3),
                            Text(
                              widget.event.rating.toStringAsFixed(1),
                              style: const TextStyle(
                                color: CustomerColors.textPrimary,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.event.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: CustomerColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.event.description,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: CustomerColors.textSecondary,
                        height: 1.35,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          widget.event.duration.isNotEmpty ? widget.event.duration : 'Live Concert',
                          style: const TextStyle(
                            fontSize: 12,
                            color: CustomerColors.textMuted,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: CustomerColors.burgundy,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: CustomerColors.goldLight.withValues(alpha: 0.5),
                              width: 0.8,
                            ),
                          ),
                          child: const Text(
                            'Book Tickets',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
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
    );
  }
}
