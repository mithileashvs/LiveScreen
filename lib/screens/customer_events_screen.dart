import 'package:flutter/material.dart';
import '../data/demo_data.dart';
import '../models/event.dart';
import '../theme/customer_theme.dart';
import 'event_details_screen.dart';

/// Dedicated Events Page for LiveScreen Customers.
///
/// Strict Rule: EVENTS ONLY.
/// Does not show Movies, Sports, or Concerts.
/// Structure is data-ready for future event content.
class CustomerEventsScreen extends StatefulWidget {
  const CustomerEventsScreen({super.key});

  @override
  State<CustomerEventsScreen> createState() => _CustomerEventsScreenState();
}

class _CustomerEventsScreenState extends State<CustomerEventsScreen> {
  String _selectedFilter = 'All Events';

  static const List<String> _filters = [
    'All Events',
    'Festivals',
    'Workshops',
    'Exhibitions',
    'Comedy',
    'Theatre',
  ];

  List<EventModel> get _events {
    // Only load items categorized under Events or Theatre/Comedy
    final list = DemoData.events.where((e) =>
        e.category == 'Events' || e.category == 'Theatre' || e.category == 'Comedy').toList();
    if (_selectedFilter == 'All Events') return list;
    return list.where((e) =>
        e.genre.toLowerCase().contains(_selectedFilter.toLowerCase()) ||
        e.category.toLowerCase().contains(_selectedFilter.toLowerCase())).toList();
  }

  @override
  Widget build(BuildContext context) {
    final events = _events;

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
                      text: 'Live & Cultural ',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: CustomerColors.textPrimary,
                        letterSpacing: -0.4,
                      ),
                    ),
                    TextSpan(
                      text: 'Events',
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
                '${events.length} Events Listed',
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

          if (events.isEmpty)
            _buildEmptyState()
          else
            LayoutBuilder(
              builder: (context, constraints) {
                const minCardWidth = 260.0;
                final crossAxisCount = (constraints.maxWidth / (minCardWidth + 18)).floor().clamp(1, 4);
                final cardWidth = (constraints.maxWidth - (crossAxisCount - 1) * 18) / crossAxisCount;

                return Wrap(
                  spacing: 18,
                  runSpacing: 20,
                  children: [
                    for (final event in events)
                      _CustomerCategoryEventCard(
                        event: event,
                        width: cardWidth,
                        categoryColor: CustomerColors.gold,
                        categoryIcon: Icons.confirmation_number_outlined,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => EventDetailsScreen(event: event),
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
              Icons.event_seat_outlined,
              size: 32,
              color: CustomerColors.gold,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No Events Scheduled in This Category',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: CustomerColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'New live theatre and special festival events are announced regularly.\nCheck back soon for the latest schedule.',
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

class _CustomerCategoryEventCard extends StatefulWidget {
  final EventModel event;
  final double width;
  final Color categoryColor;
  final IconData categoryIcon;
  final VoidCallback onTap;

  const _CustomerCategoryEventCard({
    required this.event,
    required this.width,
    required this.categoryColor,
    required this.categoryIcon,
    required this.onTap,
  });

  @override
  State<_CustomerCategoryEventCard> createState() => _CustomerCategoryEventCardState();
}

class _CustomerCategoryEventCardState extends State<_CustomerCategoryEventCard> {
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
              color: _hovering ? widget.categoryColor : CustomerColors.borderSubtle,
              width: _hovering ? 1.4 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: _hovering
                    ? widget.categoryColor.withValues(alpha: 0.16)
                    : Colors.black.withValues(alpha: 0.25),
                blurRadius: _hovering ? 14 : 8,
                offset: Offset(0, _hovering ? 6 : 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top visual banner
              Container(
                height: 140,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      CustomerColors.surfaceElevated,
                      CustomerColors.surfaceHighlight,
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Icon(
                        widget.categoryIcon,
                        size: 44,
                        color: widget.categoryColor.withValues(alpha: 0.5),
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
                          style: TextStyle(
                            color: widget.categoryColor,
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

              // Bottom Info
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
                          widget.event.duration.isNotEmpty ? widget.event.duration : 'Live',
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
                            'View Details',
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
