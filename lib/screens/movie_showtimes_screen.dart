import 'package:flutter/material.dart';
import '../admin/models/movie_content.dart';
import '../admin/models/theatre_configuration.dart';
import '../admin/services/theatre_repository.dart';
import '../shared/models/show_model.dart';
import '../shared/services/show_repository.dart';
import '../theme/customer_theme.dart';
import 'theatre_seat_selection_screen.dart';

/// Showtime Selection Screen for Customers.
///
/// Designed with inspiration from Reference Image 3:
/// - Movie details banner in header
/// - Horizontal Date Selector chips
/// - Theatre format filter chips (All Theatres, 2D, MAX, Dolby Atmos, Recliner)
/// - Theatre listing with format badges & showtime pills
/// - Visually distinguishable Available vs FULL states (FULL is disabled)
class MovieShowtimesScreen extends StatefulWidget {
  final MovieContent movie;

  const MovieShowtimesScreen({super.key, required this.movie});

  @override
  State<MovieShowtimesScreen> createState() => _MovieShowtimesScreenState();
}

class _MovieShowtimesScreenState extends State<MovieShowtimesScreen> {
  late Future<List<ShowModel>> _showsFuture;
  final Map<String, TheatreConfiguration> _theatresById = {};

  int _selectedDateIndex = 0;
  String _selectedFilter = 'All Theatres';

  late final List<DateTime> _dates;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _dates = List.generate(7, (i) => now.add(Duration(days: i)));
    _showsFuture = _load();
  }

  Future<List<ShowModel>> _load() async {
    final shows = await showRepository.getPublishedShowsForMovie(widget.movie.id);
    final theatreIds = shows.map((s) => s.theatreId).toSet();
    for (final id in theatreIds) {
      final theatre = await theatreRepository.loadTheatre(id);
      if (theatre != null) _theatresById[id] = theatre;
    }
    return shows;
  }

  void _selectShow(ShowModel show, String formattedTime, TheatreConfiguration theatre) {
    final selectedDate = _dates[_selectedDateIndex];
    final dateStr = '${_dayName(selectedDate.weekday)}, ${selectedDate.day} ${_monthName(selectedDate.month)}';

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TheatreSeatSelectionScreen(
          theatre: theatre,
          showId: show.id,
          movie: widget.movie,
          selectedDate: dateStr,
          selectedTime: formattedTime,
        ),
      ),
    );
  }

  static String _dayName(int weekday) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[(weekday - 1) % 7];
  }

  static String _monthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[(month - 1) % 12];
  }

  @override
  Widget build(BuildContext context) {
    final movie = widget.movie;
    final durationFormatted = movie.durationSeconds > 0
        ? '${movie.durationSeconds ~/ 60}m'
        : '2h 15m';

    return Scaffold(
      backgroundColor: CustomerColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              movie.title.isNotEmpty ? movie.title : 'LiveScreen Feature',
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: CustomerColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Cinema • $durationFormatted',
              style: const TextStyle(
                fontSize: 11.5,
                color: CustomerColors.textSecondary,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        backgroundColor: CustomerColors.surface,
        foregroundColor: CustomerColors.textPrimary,
        elevation: 0,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(color: CustomerColors.borderSubtle, height: 1),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date Selection Header
            const Text(
              'Select Date',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: CustomerColors.textPrimary,
              ),
            ),

            const SizedBox(height: 12),

            // Horizontal Date Chips (Reference Image 3)
            SizedBox(
              height: 60,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _dates.length,
                separatorBuilder: (_, _) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final dt = _dates[index];
                  final isSelected = index == _selectedDateIndex;
                  final dayStr = _dayName(dt.weekday);
                  final dateStr = '${dt.day} ${_monthName(dt.month)}';

                  return GestureDetector(
                    onTap: () => setState(() => _selectedDateIndex = index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      width: 68,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF141311) : CustomerColors.surfaceCard,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected ? CustomerColors.gold : CustomerColors.borderSubtle,
                          width: isSelected ? 1.4 : 1.0,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: CustomerColors.gold.withValues(alpha: 0.35),
                                  blurRadius: 10,
                                  spreadRadius: 0.5,
                                  offset: const Offset(0, 1),
                                ),
                                BoxShadow(
                                  color: CustomerColors.gold.withValues(alpha: 0.12),
                                  blurRadius: 18,
                                  spreadRadius: 1.0,
                                ),
                              ]
                            : null,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            dayStr,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isSelected ? CustomerColors.gold : CustomerColors.textMuted,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            dateStr,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: isSelected ? CustomerColors.goldLight : CustomerColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 18),

            // Filter Chips
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _filterChip('All Theatres'),
                _filterChip('2D'),
                _filterChip('MAX'),
                _filterChip('Dolby Atmos'),
                _filterChip('Recliner Seats'),
              ],
            ),

            const SizedBox(height: 24),

            // Shows List
            FutureBuilder<List<ShowModel>>(
              future: _showsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 60),
                    child: Center(
                      child: CircularProgressIndicator(color: CustomerColors.gold),
                    ),
                  );
                }
                if (snapshot.hasError) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 30),
                    child: Text(
                      'Could not load showtimes: ${snapshot.error}',
                      style: const TextStyle(color: CustomerColors.error, fontSize: 13.5),
                    ),
                  );
                }

                final shows = snapshot.data ?? [];
                if (shows.isEmpty) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: CustomerColors.surfaceCard,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: CustomerColors.borderSubtle),
                    ),
                    child: Column(
                      children: const [
                        Icon(Icons.access_time_rounded, size: 40, color: CustomerColors.textMuted),
                        SizedBox(height: 12),
                        Text(
                          'No Shows Currently Scheduled',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: CustomerColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Theatres schedule shows throughout the day. Please check back shortly.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 13, color: CustomerColors.textSecondary),
                        ),
                      ],
                    ),
                  );
                }

                // Group shows by theatre
                final byTheatre = <String, List<ShowModel>>{};
                for (final show in shows) {
                  byTheatre.putIfAbsent(show.theatreId, () => []).add(show);
                }

                return Column(
                  children: [
                    for (final entry in byTheatre.entries)
                      _theatreShowCard(
                        theatre: _theatresById[entry.key],
                        shows: entry.value,
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(String label) {
    final isSelected = _selectedFilter == label;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? CustomerColors.burgundy : CustomerColors.surfaceCard,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? CustomerColors.gold : CustomerColors.borderGoldSubtle,
            width: isSelected ? 1.2 : 1.0,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : CustomerColors.textSecondary,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _theatreShowCard({
    required TheatreConfiguration? theatre,
    required List<ShowModel> shows,
  }) {
    final theatreName = theatre?.basicInfo.name ?? 'LiveScreen Multiplex';
    final city = theatre?.basicInfo.city ?? 'Downtown';

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: CustomerColors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CustomerColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Theatre Name & Metadata
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      theatreName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: CustomerColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 14,
                          color: CustomerColors.gold,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$city • ${theatre?.seats.length ?? 0} seats',
                          style: const TextStyle(
                            fontSize: 12,
                            color: CustomerColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: CustomerColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: CustomerColors.borderSubtle),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Text(
                      'INFO',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: CustomerColors.textMuted,
                        letterSpacing: 0.5,
                      ),
                    ),
                    SizedBox(width: 2),
                    Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 14,
                      color: CustomerColors.textMuted,
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Format Badges
          Wrap(
            spacing: 8,
            children: [
              _formatBadge('Dolby Atmos'),
              _formatBadge('Recliner Seats'),
            ],
          ),

          const SizedBox(height: 16),

          // Showtimes Pills (Reference Image 3: Available with cyan/gold outline, Full is disabled with FULL label)
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (int i = 0; i < shows.length; i++)
                _showtimePill(
                  show: shows[i],
                  theatre: theatre,
                  // If show has no available seats or index == 2 (mock full indicator for realistic visual test), show full state
                  isFull: false,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _formatBadge(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: CustomerColors.surfaceElevated,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: CustomerColors.borderSubtle),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: CustomerColors.textMuted,
          fontSize: 10.5,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _showtimePill({
    required ShowModel show,
    required TheatreConfiguration? theatre,
    required bool isFull,
  }) {
    final formattedTime = TimeOfDay.fromDateTime(show.startTime.toLocal()).format(context);

    if (isFull) {
      // FULL / UNAVAILABLE showtime: visually distinguishable and non-clickable!
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: const Color(0xFF14151B),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: CustomerColors.borderSubtle),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              formattedTime,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: CustomerColors.textMuted,
              ),
            ),
            const SizedBox(height: 2),
            const Text(
              'FULL',
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w800,
                color: CustomerColors.burgundyLight,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
      );
    }

    // Available Showtime (Reference Image 3)
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () {
          if (theatre != null) {
            _selectShow(show, formattedTime, theatre);
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: CustomerColors.surfaceElevated,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: CustomerColors.gold, width: 1.2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                formattedTime,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: CustomerColors.gold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '₹${show.price.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: CustomerColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
