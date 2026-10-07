import 'package:flutter/material.dart';
import '../../shared/widgets/admin/admin_sidebar.dart';
import '../../shared/widgets/admin/admin_top_bar.dart';
import '../../shared/widgets/admin/admin_status_badge.dart';
import '../../shared/models/show_model.dart';
import '../../shared/services/show_repository.dart';
import '../models/theatre_configuration.dart';
import '../models/movie_content.dart';
import '../services/theatre_repository.dart';
import '../services/movie_repository.dart';
import '../services/selected_theatre.dart';
import 'theatre_list_screen.dart';
import 'theatre_screens_screen.dart';
import 'theatre_bookings_screen.dart';
import 'theatre_analytics_screen.dart';
import 'theatre_snacks_screen.dart';
import 'admin_dashboard_screen.dart';

/// Redesigned 'Shows Schedule' Screen for Theatre Admin.
/// Implements the master dark cinematic design language (Black, Gold & Burgundy).
class TheatreShowsScreen extends StatefulWidget {
  const TheatreShowsScreen({super.key});

  @override
  State<TheatreShowsScreen> createState() => _TheatreShowsScreenState();
}

class _TheatreShowsScreenState extends State<TheatreShowsScreen> {
  late Future<List<TheatreConfiguration>> _theatresFuture;
  TheatreConfiguration? _selectedTheatre;
  List<ShowModel> _shows = [];
  bool _loadingShows = false;
  List<MovieContent> _movieCatalog = [];

  @override
  void initState() {
    super.initState();
    _loadTheatres();
    movieRepository.getPublishedMovies().then((catalog) {
      if (mounted) setState(() => _movieCatalog = catalog);
    });
  }

  String _movieTitleFor(String? movieId) {
    if (movieId == null) return '—';
    for (final m in _movieCatalog) {
      if (m.id == movieId) return m.title.isEmpty ? '(Untitled Movie)' : m.title;
    }
    return 'Movie';
  }

  Future<void> _loadTheatres() async {
    _theatresFuture = theatreRepository.getMyTheatres();
    final theatres = await _theatresFuture;
    if (mounted) {
      final current = selectedTheatreContext.resolve(theatres);
      setState(() {
        _selectedTheatre = current;
      });
      if (current != null) _loadShows(current.id);
    }
  }

  void _onTheatreSwitched(TheatreConfiguration theatre) {
    selectedTheatreContext.select(theatre.id);
    setState(() => _selectedTheatre = theatre);
    _loadShows(theatre.id);
  }

  Future<void> _loadShows(String theatreId) async {
    setState(() => _loadingShows = true);
    try {
      final shows = await showRepository.getShowsForTheatre(theatreId);
      if (mounted) {
        setState(() {
          _shows = shows;
          _loadingShows = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingShows = false);
    }
  }

  Future<void> _publishShow(String showId, String theatreId) async {
    try {
      await showRepository.publishShow(showId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Show published — users can now book it.')),
      );
      _loadShows(theatreId);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not publish show: $e')),
      );
    }
  }

  void _navigateTo(String key) {
    if (key == 'dashboard') {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
      );
    } else if (key == 'my_theatre') {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const TheatreListScreen()),
      );
    } else if (key == 'screens') {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const TheatreScreensScreen()),
      );
    } else if (key == 'shows') {
      // already here
    } else if (key == 'snacks') {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const TheatreSnacksScreen()),
      );
    } else if (key == 'bookings') {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const TheatreBookingsScreen()),
      );
    } else if (key == 'analytics') {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const TheatreAnalyticsScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 900;

    const navItems = [
      AdminNavItemData(key: 'dashboard', label: 'Dashboard', icon: Icons.dashboard_rounded),
      AdminNavItemData(key: 'my_theatre', label: 'My Theatre', icon: Icons.theaters_outlined),
      AdminNavItemData(key: 'screens', label: 'Screens', icon: Icons.tv_rounded),
      AdminNavItemData(key: 'shows', label: 'Shows', icon: Icons.calendar_today_outlined),
      AdminNavItemData(key: 'bookings', label: 'Bookings', icon: Icons.confirmation_number_outlined),
      AdminNavItemData(key: 'analytics', label: 'Analytics', icon: Icons.bar_chart_rounded),
    ];

    final sidebar = AdminSidebar(
      activeKey: 'shows',
      mainNavItems: navItems,
      onSelectKey: _navigateTo,
    );

    return Scaffold(
      backgroundColor: const Color(0xFF070709),
      drawer: isDesktop ? null : Drawer(backgroundColor: const Color(0xFF070709), child: sidebar),
      body: Row(
        children: [
          if (isDesktop) sidebar,
          Expanded(
            child: Column(
              children: [
                AdminTopBar(
                  searchPlaceholder: 'Search shows, timings, movies...',
                  showDrawerButton: !isDesktop,
                  onTheatreChanged: _onTheatreSwitched,
                  onProfileTap: () => _navigateTo('my_theatre'),
                ),
                Expanded(
                  child: FutureBuilder<List<TheatreConfiguration>>(
                    future: _theatresFuture,
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37)));
                      }
                      final theatres = snapshot.data!;
                      if (theatres.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Container(
                              padding: const EdgeInsets.all(40),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0F0F12),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xFF1E1E26)),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.event_busy_rounded, size: 48, color: Color(0xFF71717A)),
                                  const SizedBox(height: 14),
                                  const Text('No Theatres Configured', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFFFFFFFF))),
                                  const SizedBox(height: 6),
                                  const Text('Set up a theatre first to schedule and manage movie shows.', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13)),
                                  const SizedBox(height: 18),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD4AF37), foregroundColor: Colors.black),
                                    onPressed: () => Navigator.of(context).push(
                                      MaterialPageRoute(builder: (_) => const TheatreListScreen()),
                                    ),
                                    child: const Text('Go to Theatres', style: TextStyle(fontWeight: FontWeight.w700)),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }

                      final currentTheatre = _selectedTheatre ?? theatres.first;

                      return SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Page Header
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Shows Schedule',
                                        style: TextStyle(
                                          fontSize: 26,
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFFFFFFFF),
                                          letterSpacing: -0.5,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${currentTheatre.basicInfo.name} • ${_shows.length} screenings configured',
                                        style: const TextStyle(fontSize: 13.5, color: Color(0xFF9CA3AF)),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 16),
                                ElevatedButton.icon(
                                  onPressed: () => _showScheduleDialog(theatres, currentTheatre),
                                  icon: const Icon(Icons.add_rounded, size: 16),
                                  label: const Text('Schedule Show', style: TextStyle(fontWeight: FontWeight.w700)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFD4AF37),
                                    foregroundColor: Colors.black,
                                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),

                            if (_loadingShows)
                              const Center(child: Padding(
                                padding: EdgeInsets.all(48),
                                child: CircularProgressIndicator(color: Color(0xFFD4AF37)),
                              ))
                            else if (_shows.isEmpty)
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(48),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0F0F12),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: const Color(0xFF1E1E26)),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.calendar_month_outlined, size: 48, color: Color(0xFF71717A)),
                                    const SizedBox(height: 14),
                                    const Text('No Shows Scheduled Yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFFFFFFFF))),
                                    const SizedBox(height: 6),
                                    const Text(
                                      'Schedule your first screening to begin accepting customer ticket bookings.',
                                      style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
                                    ),
                                    const SizedBox(height: 18),
                                    ElevatedButton.icon(
                                      onPressed: () => _showScheduleDialog(theatres, currentTheatre),
                                      icon: const Icon(Icons.add_rounded, size: 16),
                                      label: const Text('Schedule Show Now'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFFD4AF37),
                                        foregroundColor: Colors.black,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            else
                              Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0F0F12),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: const Color(0xFF1E1E26)),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(14),
                                  child: Table(
                                    columnWidths: const {
                                      0: FlexColumnWidth(2.8),
                                      1: FlexColumnWidth(2),
                                      2: FlexColumnWidth(1.8),
                                      3: FlexColumnWidth(1.5),
                                      4: FlexColumnWidth(1.5),
                                    },
                                    children: [
                                      TableRow(
                                        decoration: const BoxDecoration(
                                          color: Color(0xFF14141A),
                                          border: Border(bottom: BorderSide(color: Color(0xFF1E1E26))),
                                        ),
                                        children: const [
                                          Padding(
                                            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                                            child: Text('Movie', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: Color(0xFF71717A))),
                                          ),
                                          Padding(
                                            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                            child: Text('Start Time', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: Color(0xFF71717A))),
                                          ),
                                          Padding(
                                            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                            child: Text('Ticket Price', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: Color(0xFF71717A))),
                                          ),
                                          Padding(
                                            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                            child: Text('Status', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: Color(0xFF71717A))),
                                          ),
                                          Padding(
                                            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                            child: Text('Action', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: Color(0xFF71717A))),
                                          ),
                                        ],
                                      ),
                                      for (final show in _shows)
                                        TableRow(
                                          decoration: const BoxDecoration(
                                            border: Border(bottom: BorderSide(color: Color(0xFF1A1A22), width: 0.8)),
                                          ),
                                          children: [
                                            Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                              child: Row(
                                                children: [
                                                  Container(
                                                    width: 32,
                                                    height: 42,
                                                    decoration: BoxDecoration(
                                                      color: const Color(0xFF1C1C24),
                                                      borderRadius: BorderRadius.circular(4),
                                                      border: Border.all(color: const Color(0x33D4AF37)),
                                                    ),
                                                    child: const Center(
                                                      child: Icon(Icons.movie_outlined, size: 16, color: Color(0xFFD4AF37)),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Expanded(
                                                    child: Text(
                                                      _movieTitleFor(show.movieId),
                                                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5, color: Color(0xFFFFFFFF)),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                              child: Text(
                                                '${show.startTime.day}/${show.startTime.month} at ${show.startTime.hour.toString().padLeft(2, '0')}:${show.startTime.minute.toString().padLeft(2, '0')}',
                                                style: const TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
                                              ),
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                              child: Text(
                                                '₹${show.price.toStringAsFixed(0)}',
                                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFFD4AF37)),
                                              ),
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                              child: AdminStatusBadge(status: show.status, showDot: true),
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                              child: show.status == 'draft'
                                                  ? ElevatedButton(
                                                      style: ElevatedButton.styleFrom(
                                                        backgroundColor: const Color(0xFFD4AF37),
                                                        foregroundColor: Colors.black,
                                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                                        minimumSize: const Size(60, 28),
                                                      ),
                                                      onPressed: () => _publishShow(show.id, currentTheatre.id),
                                                      child: const Text('Publish', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                                                    )
                                                  : const Text(
                                                      'Live',
                                                      style: TextStyle(fontSize: 12.5, color: Color(0xFF10B981), fontWeight: FontWeight.w700),
                                                    ),
                                            ),
                                          ],
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showScheduleDialog(List<TheatreConfiguration> theatres, TheatreConfiguration currentTheatre) {
    if (_movieCatalog.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No approved movies are available yet — a movie must be approved '
            'by Platform Admin before it can be scheduled.',
          ),
        ),
      );
      return;
    }

    showDialog<_ScheduleShowResult>(
      context: context,
      builder: (ctx) => _ScheduleShowDialog(
        theatres: theatres,
        initialTheatreId: currentTheatre.id,
        catalog: _movieCatalog,
      ),
    ).then((input) {
      if (input == null || !mounted) return;

      if (!theatres.any((t) => t.id == input.theatre.id)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('That theatre is no longer in your authorized list.')),
        );
        return;
      }

      showRepository
          .createShow(
            theatreId: input.theatre.id,
            movieId: input.movie.id,
            startTime: input.startTime,
            price: input.price,
          )
          .then((_) => _loadShows(input.theatre.id))
          .catchError((e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Could not schedule show: $e')));
      });
    });
  }
}

typedef _ScheduleShowResult = ({TheatreConfiguration theatre, MovieContent movie, DateTime startTime, double price});

class _ScheduleShowDialog extends StatefulWidget {
  final List<TheatreConfiguration> theatres;
  final String initialTheatreId;
  final List<MovieContent> catalog;
  const _ScheduleShowDialog({
    required this.theatres,
    required this.initialTheatreId,
    required this.catalog,
  });

  @override
  State<_ScheduleShowDialog> createState() => _ScheduleShowDialogState();
}

class _ScreenOption {
  final String id;
  final String label;
  final int capacity;
  const _ScreenOption({required this.id, required this.label, required this.capacity});

  @override
  bool operator ==(Object other) => other is _ScreenOption && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

class _ScheduleShowDialogState extends State<_ScheduleShowDialog> {
  late TheatreConfiguration _theatre;
  _ScreenOption? _screen;
  MovieContent? _movie;
  DateTime? _date;
  TimeOfDay? _time;
  final _priceController = TextEditingController(text: '190');

  @override
  void initState() {
    super.initState();
    _theatre = widget.theatres.firstWhere(
      (t) => t.id == widget.initialTheatreId,
      orElse: () => widget.theatres.first,
    );
    _screensFor(_theatre).then((screens) {
      if (mounted) setState(() => _screen = screens.isEmpty ? null : screens.first);
    });
    if (widget.catalog.isNotEmpty) {
      _movie = widget.catalog.first;
    }
  }

  @override
  void dispose() {
    _priceController.dispose();
    super.dispose();
  }

  Future<List<_ScreenOption>> _screensFor(TheatreConfiguration theatre) async {
    return [
      _ScreenOption(
        id: theatre.id,
        label: theatre.basicInfo.hallName.isNotEmpty ? theatre.basicInfo.hallName : 'Main Auditorium',
        capacity: theatre.seats.length,
      ),
    ];
  }

  void _onTheatreChanged(TheatreConfiguration? theatre) {
    if (theatre == null || theatre.id == _theatre.id) return;
    setState(() {
      _theatre = theatre;
      _screen = null;
    });
    _screensFor(theatre).then((screens) {
      if (mounted) setState(() => _screen = screens.isEmpty ? null : screens.first);
    });
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFFD4AF37),
              onPrimary: Colors.black,
              surface: Color(0xFF14141A),
              onSurface: Color(0xFFF7F5F0),
            ),
          ),
          child: child!,
        );
      },
    );
    if (date != null) setState(() => _date = date);
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFFD4AF37),
              onPrimary: Colors.black,
              surface: Color(0xFF14141A),
              onSurface: Color(0xFFF7F5F0),
            ),
          ),
          child: child!,
        );
      },
    );
    if (time != null) setState(() => _time = time);
  }

  void _confirm() {
    final screen = _screen;
    final movie = _movie;
    final date = _date;
    final time = _time;
    final price = double.tryParse(_priceController.text);

    if (screen == null || movie == null || date == null || time == null || price == null || price < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choose a theatre, screen, movie, date, time, and a valid price.')),
      );
      return;
    }

    final startTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    Navigator.of(context).pop<_ScheduleShowResult>((
      theatre: _theatre,
      movie: movie,
      startTime: startTime,
      price: price,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF111116),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0x66D4AF37)),
      ),
      title: Row(
        children: const [
          Icon(Icons.calendar_month_outlined, color: Color(0xFFD4AF37)),
          SizedBox(width: 10),
          Text('Schedule New Show', style: TextStyle(color: Color(0xFFFFFFFF), fontSize: 18, fontWeight: FontWeight.w700)),
        ],
      ),
      content: SizedBox(
        width: 440,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.theatres.length > 1) ...[
                const Text('Theatre', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12)),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A22),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF2E2E38)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<TheatreConfiguration>(
                      value: _theatre,
                      isExpanded: true,
                      dropdownColor: const Color(0xFF14141A),
                      style: const TextStyle(color: Color(0xFFF7F5F0), fontSize: 13.5),
                      onChanged: _onTheatreChanged,
                      items: widget.theatres.map((t) {
                        final name = t.basicInfo.name.isNotEmpty ? t.basicInfo.name : 'Untitled Theatre';
                        return DropdownMenuItem<TheatreConfiguration>(
                          value: t,
                          child: Text(name),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
              ],
              const Text('Movie', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12)),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A22),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF2E2E38)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<MovieContent>(
                    value: _movie,
                    isExpanded: true,
                    dropdownColor: const Color(0xFF14141A),
                    style: const TextStyle(color: Color(0xFFF7F5F0), fontSize: 13.5),
                    onChanged: (m) => setState(() => _movie = m),
                    items: widget.catalog.map((m) {
                      return DropdownMenuItem<MovieContent>(
                        value: m,
                        child: Text(m.title.isEmpty ? '(Untitled)' : m.title),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Date', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12)),
                        const SizedBox(height: 6),
                        OutlinedButton.icon(
                          onPressed: _pickDate,
                          icon: const Icon(Icons.calendar_today_outlined, size: 16, color: Color(0xFFD4AF37)),
                          label: Text(
                            _date == null ? 'Pick Date' : '${_date!.day}/${_date!.month}/${_date!.year}',
                            style: const TextStyle(color: Color(0xFFF7F5F0), fontSize: 12),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFF2E2E38)),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Time', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12)),
                        const SizedBox(height: 6),
                        OutlinedButton.icon(
                          onPressed: _pickTime,
                          icon: const Icon(Icons.access_time_rounded, size: 16, color: Color(0xFFD4AF37)),
                          label: Text(
                            _time == null ? 'Pick Time' : _time!.format(context),
                            style: const TextStyle(color: Color(0xFFF7F5F0), fontSize: 12),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFF2E2E38)),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              const Text('Ticket Price (₹)', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12)),
              const SizedBox(height: 6),
              TextField(
                controller: _priceController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(color: Color(0xFFF7F5F0), fontSize: 13.5),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFF1A1A22),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF2E2E38))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF2E2E38))),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFD4AF37))),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel', style: TextStyle(color: Color(0xFF9CA3AF))),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFD4AF37),
            foregroundColor: Colors.black,
          ),
          onPressed: _confirm,
          child: const Text('Schedule Show', style: TextStyle(fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }
}
