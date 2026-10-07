import 'package:flutter/material.dart';
import '../data/demo_data.dart';
import '../models/event.dart';
import '../theme/customer_theme.dart';
import 'event_details_screen.dart';

/// Dedicated Sports Page for LiveScreen Customers.
///
/// Strict Rule: SPORTS ONLY.
/// Does not show Movies, Events, or Concerts.
/// Structure is data-ready for future sports tournament & match content.
class CustomerSportsScreen extends StatefulWidget {
  const CustomerSportsScreen({super.key});

  @override
  State<CustomerSportsScreen> createState() => _CustomerSportsScreenState();
}

class _CustomerSportsScreenState extends State<CustomerSportsScreen> {
  String _selectedFilter = 'All Sports';

  static const List<String> _filters = [
    'All Sports',
    'Cricket',
    'Football',
    'Tennis',
    'Motorsports',
    'Esports',
  ];

  List<EventModel> get _sports {
    final list = DemoData.events.where((e) => e.category == 'Sports').toList();
    if (_selectedFilter == 'All Sports') return list;
    return list.where((e) =>
        e.genre.toLowerCase().contains(_selectedFilter.toLowerCase()) ||
        e.title.toLowerCase().contains(_selectedFilter.toLowerCase())).toList();
  }

  @override
  Widget build(BuildContext context) {
    final sports = _sports;

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
                      text: 'Stadium & Arena ',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: CustomerColors.textPrimary,
                        letterSpacing: -0.4,
                      ),
                    ),
                    TextSpan(
                      text: 'Sports',
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
                '${sports.length} Matches Scheduled',
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

          if (sports.isEmpty)
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
                    for (final item in sports)
                      _CustomerSportsCard(
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
              Icons.sports_cricket_outlined,
              size: 32,
              color: CustomerColors.gold,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No Matches Currently Scheduled',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: CustomerColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Live stadium fixtures and championship matches will be scheduled soon.\nStay tuned for official updates.',
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

class _CustomerSportsCard extends StatefulWidget {
  final EventModel event;
  final double width;
  final VoidCallback onTap;

  const _CustomerSportsCard({
    required this.event,
    required this.width,
    required this.onTap,
  });

  @override
  State<_CustomerSportsCard> createState() => _CustomerSportsCardState();
}

class _CustomerSportsCardState extends State<_CustomerSportsCard> {
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
              // Visual header banner
              Container(
                height: 140,
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF16231A),
                      Color(0xFF0F1A12),
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    const Center(
                      child: Icon(
                        Icons.sports_soccer_outlined,
                        size: 46,
                        color: Color(0x6610B981),
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
                            color: Color(0xFF10B981),
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.6,
                          ),
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
                          widget.event.duration.isNotEmpty ? widget.event.duration : 'Match',
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
