import '../models/theatre_configuration.dart';
import 'theatre_validation.dart';
import 'supabase_theatre_repository.dart';

/// PART 16 (original)/shared-database task: every screen in the Admin
/// Studio (and now the user-facing theatre catalog) talks to
/// [TheatreRepository], never to a concrete storage mechanism. This is what
/// made swapping the in-memory mock for a real Supabase-backed
/// implementation a one-file change (see [SupabaseTheatreRepository]) with
/// zero changes to any screen.
/// Summary of relational records associated with a theatre.
class TheatreDependencySummary {
  final int showCount;
  final int bookingCount;

  const TheatreDependencySummary({
    this.showCount = 0,
    this.bookingCount = 0,
  });

  bool get hasDependencies => showCount > 0 || bookingCount > 0;
}

/// Thrown when an attempt to permanently delete a theatre is blocked
/// due to existing shows or bookings.
class TheatreHasDependenciesException implements Exception {
  final String theatreId;
  final int showCount;
  final int bookingCount;

  const TheatreHasDependenciesException({
    required this.theatreId,
    required this.showCount,
    required this.bookingCount,
  });

  String get message =>
      'Cannot delete theatre because it has associated records ($showCount show(s), $bookingCount booking(s)). '
      'Deactivate the theatre instead to preserve historical show and booking data.';

  @override
  String toString() => message;
}

abstract class TheatreRepository {
  Future<TheatreConfiguration> createTheatre(TheatreBasicInfo basicInfo);
  Future<void> saveTheatre(TheatreConfiguration config);
  Future<TheatreConfiguration?> loadTheatre(String id);

  /// Checks dependencies before deleting. If associated shows or bookings
  /// exist, throws [TheatreHasDependenciesException].
  Future<void> deleteTheatre(String id);

  /// Queries the count of shows and bookings linked to [id].
  Future<TheatreDependencySummary> getTheatreDependencies(String id);

  /// Safely archives a theatre, setting status to [TheatreStatus.archived]
  /// and stopping public discovery and new bookings while preserving data.
  Future<void> deactivateTheatre(String id);

  /// Restores an archived theatre to [TheatreStatus.published].
  Future<void> reactivateTheatre(String id);

  /// Theatre Admin's own theatres (draft, published, or archived) —
  /// filtered server-side by ownership, not fetched-then-filtered client-side.
  Future<List<TheatreConfiguration>> getMyTheatres();

  /// Every theatre visible to a User: published only. A draft theatre must
  /// never appear here, regardless of who owns it.
  Future<List<TheatreConfiguration>> getPublishedTheatres();

  /// Runs publish validation and, only if it passes, flips the theatre's
  /// status to Published and persists it. Returns the validation errors
  /// (empty on success) so the UI can show exactly what's missing.
  Future<List<String>> publishTheatre(String id);
}

/// Deliberately in-memory — kept as a reference/offline fallback
/// implementation now that [SupabaseTheatreRepository] is what the app
/// actually uses. Useful for running the Admin Studio UI without a
/// Supabase project configured.
class InMemoryTheatreRepository implements TheatreRepository {
  final Map<String, TheatreConfiguration> _theatres = {};
  final Map<String, int> _mockShowCounts = {};
  final Map<String, int> _mockBookingCounts = {};
  int _nextId = 1;

  void setMockDependencies(String id, {int showCount = 0, int bookingCount = 0}) {
    _mockShowCounts[id] = showCount;
    _mockBookingCounts[id] = bookingCount;
  }

  @override
  Future<TheatreConfiguration> createTheatre(TheatreBasicInfo basicInfo) async {
    final id = 'theatre_${_nextId++}';
    final config = TheatreConfiguration(id: id, basicInfo: basicInfo);
    _theatres[id] = config;
    return config;
  }

  @override
  Future<void> saveTheatre(TheatreConfiguration config) async {
    _theatres[config.id] = config;
  }

  @override
  Future<TheatreConfiguration?> loadTheatre(String id) async {
    return _theatres[id];
  }

  @override
  Future<List<TheatreConfiguration>> getMyTheatres() async {
    return _theatres.values.toList(growable: false);
  }

  @override
  Future<List<TheatreConfiguration>> getPublishedTheatres() async {
    return _theatres.values.where((t) => t.status == TheatreStatus.published).toList();
  }

  @override
  Future<TheatreDependencySummary> getTheatreDependencies(String id) async {
    return TheatreDependencySummary(
      showCount: _mockShowCounts[id] ?? 0,
      bookingCount: _mockBookingCounts[id] ?? 0,
    );
  }

  @override
  Future<void> deactivateTheatre(String id) async {
    final config = _theatres[id];
    if (config != null) {
      config.status = TheatreStatus.archived;
      _theatres[id] = config;
    }
  }

  @override
  Future<void> reactivateTheatre(String id) async {
    final config = _theatres[id];
    if (config != null) {
      config.status = TheatreStatus.published;
      _theatres[id] = config;
    }
  }

  @override
  Future<void> deleteTheatre(String id) async {
    final deps = await getTheatreDependencies(id);
    if (deps.hasDependencies) {
      throw TheatreHasDependenciesException(
        theatreId: id,
        showCount: deps.showCount,
        bookingCount: deps.bookingCount,
      );
    }
    _theatres.remove(id);
  }

  @override
  Future<List<String>> publishTheatre(String id) async {
    final config = _theatres[id];
    if (config == null) {
      return ['Theatre not found.'];
    }

    final errors = TheatreValidation.validateForPublish(config);
    if (errors.isEmpty) {
      config.status = TheatreStatus.published;
      _theatres[id] = config;
    }
    return errors;
  }
}

/// A single shared instance every screen reads from. Backed by Supabase now
/// — InMemoryTheatreRepository above is kept only as a fallback reference.
final TheatreRepository theatreRepository = SupabaseTheatreRepository();
