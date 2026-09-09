import '../models/theatre_configuration.dart';
import 'theatre_validation.dart';
import 'supabase_theatre_repository.dart';

/// PART 16 (original)/shared-database task: every screen in the Admin
/// Studio (and now the user-facing theatre catalog) talks to
/// [TheatreRepository], never to a concrete storage mechanism. This is what
/// made swapping the in-memory mock for a real Supabase-backed
/// implementation a one-file change (see [SupabaseTheatreRepository]) with
/// zero changes to any screen.
abstract class TheatreRepository {
  Future<TheatreConfiguration> createTheatre(TheatreBasicInfo basicInfo);
  Future<void> saveTheatre(TheatreConfiguration config);
  Future<TheatreConfiguration?> loadTheatre(String id);
  Future<void> deleteTheatre(String id);

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
  int _nextId = 1;

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
  Future<void> deleteTheatre(String id) async {
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
