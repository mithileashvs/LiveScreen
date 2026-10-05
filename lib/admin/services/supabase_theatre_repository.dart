import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/theatre_configuration.dart';
import 'theatre_repository.dart';
import 'theatre_validation.dart';

/// Supabase-backed [TheatreRepository]. Replaces [InMemoryTheatreRepository]
/// behind the same abstraction — every Admin Studio screen (Room, Screen,
/// Seating, Speakers, Acoustics, Movie, Preview & Publish, TheatreListScreen,
/// CreateTheatreScreen) keeps working unchanged, since none of them ever
/// depended on anything beyond [TheatreRepository]/[TheatreConfiguration].
///
/// Storage shape: the `theatres` table (see
/// supabase/migrations/0001_init.sql) keeps `owner_id`/`status`/timestamps
/// as real relational columns — exactly what ownership checks and
/// getMyTheatres()/getPublishedTheatres() need to filter on — and stores
/// the full nested Room/Screen/Seating/Speakers/Acoustics/Movie
/// configuration as a single `config` jsonb column, reusing
/// [TheatreConfiguration.toJson]/[TheatreConfiguration.fromJson] as-is
/// rather than exploding those already-well-designed nested models into
/// several more normalized child tables.
class SupabaseTheatreRepository implements TheatreRepository {
  SupabaseClient get _client => Supabase.instance.client;

  String _requireUserId() {
    final id = _client.auth.currentUser?.id;
    if (id == null) {
      throw StateError('No authenticated user — cannot perform this theatre operation.');
    }
    return id;
  }

  TheatreConfiguration _fromRow(Map<String, dynamic> row) {
    final configJson = Map<String, dynamic>.from(row['config'] as Map? ?? {});
    // The row's real id is always authoritative, in case the jsonb snapshot
    // is stale or was ever written before the id was known.
    configJson['id'] = row['id'];
    final config = TheatreConfiguration.fromJson(configJson);

    // verification_status/review_reason/owner_id are Platform-Admin-owned
    // database columns, never written as part of saveTheatre()'s jsonb
    // snapshot — always trust the row for these, never the jsonb.
    config.verificationStatus = row['verification_status'] as String? ?? 'pending';
    config.reviewReason = row['review_reason'] as String?;
    config.ownerId = row['owner_id'] as String?;
    return config;
  }

  Map<String, dynamic> _projectionColumns(TheatreConfiguration config) => {
        'name': config.basicInfo.name,
        'hall_name': config.basicInfo.hallName,
        'description': config.basicInfo.description,
        'status': config.status.name,
        'schema_version': config.schemaVersion,
        'config': config.toJson(),
      };

  @override
  Future<TheatreConfiguration> createTheatre(TheatreBasicInfo basicInfo) async {
    final ownerId = _requireUserId();

    // Two-step insert: Postgres generates the real UUID, then we write the
    // full jsonb snapshot back in (which needs to embed that id).
    final inserted = await _client
        .from('theatres')
        .insert({
          'owner_id': ownerId,
          'name': basicInfo.name,
          'hall_name': basicInfo.hallName,
          'description': basicInfo.description,
          'status': TheatreStatus.draft.name,
          'schema_version': kTheatreConfigSchemaVersion,
          'config': <String, dynamic>{},
        })
        .select()
        .single();

    final id = inserted['id'] as String;
    final config = TheatreConfiguration(id: id, basicInfo: basicInfo);
    await saveTheatre(config);
    return config;
  }

  @override
  Future<void> saveTheatre(TheatreConfiguration config) async {
    // Chaining .select() after .update() is what makes a silently-blocked
    // write LOUD instead of invisible: Postgres RLS blocks an UPDATE by
    // matching zero rows, not by throwing an error — without checking the
    // returned rows here, a save that never actually reached the database
    // (e.g. because the session's auth.uid() no longer matches this row's
    // owner_id) looks IDENTICAL to a successful one. This is exactly the
    // failure mode that left a theatre stuck on "draft" after Publish
    // reported success.
    final updatedRows =
        await _client.from('theatres').update(_projectionColumns(config)).eq('id', config.id).select();

    if (updatedRows.isEmpty) {
      throw StateError(
        'Save failed silently: no row was updated for theatre ${config.id}. '
        'This usually means the current session is no longer recognized as '
        'this theatre\'s owner (auth.uid() no longer matches owner_id) — '
        'try logging out and back in, then publishing again.',
      );
    }
  }

  @override
  Future<TheatreConfiguration?> loadTheatre(String id) async {
    final row = await _client.from('theatres').select().eq('id', id).maybeSingle();
    if (row == null) return null;
    return _fromRow(row);
  }

  @override
  Future<List<TheatreConfiguration>> getMyTheatres() async {
    final userId = _requireUserId();

    // Preferred path: every theatre this admin has a VERIFIED relationship
    // for, via theatre_admin_theatres — the actual source of truth for
    // "which theatres may I manage" (see
    // supabase/migrations/0006_theatre_admin_identity.sql). "My Theatres"/
    // the theatre switcher should only ever offer a theatre the admin can
    // actually configure, so pending/rejected relationships are excluded
    // here (TheatreAdminRepository.getMyTheatreRelationships() is the one
    // that surfaces those, e.g. for a "Pending verification" row).
    final adminRow = await _client.from('theatre_admins').select('id').eq('profile_id', userId).maybeSingle();

    if (adminRow != null) {
      final adminId = adminRow['id'] as String;

      // Step 1: resolve ONLY this admin's own verified relationship rows.
      // `theatre_admin_theatres_select_own` RLS already restricts every
      // row this query can see to ones whose admin_id belongs to the
      // caller's own profile_id — the .eq('admin_id', adminId) below is
      // redundant with that policy, not a substitute for it, and is kept
      // so this reads correctly even considered on its own.
      final relationshipRows = await _client
          .from('theatre_admin_theatres')
          .select('theatre_id')
          .eq('admin_id', adminId)
          .eq('verification_status', 'verified');

      final theatreIds = relationshipRows.map((r) => r['theatre_id'] as String).toSet().toList();
      if (theatreIds.isEmpty) return const [];

      // Step 2: fetch exactly those theatres, by id — a plain `IN (...)`
      // filter, not a PostgREST embed. `theatres_select_own`'s
      // is_authorized_theatre_admin(id) check still independently has to
      // agree for each row to come back at all, so a row here can never
      // exceed what step 1 already decided, even if that policy is later
      // widened for an unrelated reason.
      final rows = await _client.from('theatres').select().inFilter('id', theatreIds).order('created_at');
      return rows.map(_fromRow).toList();
    }

    // Fallback: an account with no theatre_admins row yet (shouldn't
    // normally happen post-migration, but covers any account the 0006
    // backfill didn't reach, or a fresh theatre_admin profile that hasn't
    // gone through registerAdmin() yet) — RLS (is_authorized_theatre_admin)
    // still allows this via the legacy owner_id branch, so this query
    // still only returns what this account is actually authorized for.
    final rows = await _client.from('theatres').select().eq('owner_id', userId).order('created_at');
    return rows.map(_fromRow).toList();
  }

  @override
  Future<List<TheatreConfiguration>> getPublishedTheatres() async {
    final rows = await _client
        .from('theatres')
        .select()
        .eq('status', TheatreStatus.published.name)
        .order('created_at');
    return rows.map(_fromRow).toList();
  }

  @override
  Future<TheatreDependencySummary> getTheatreDependencies(String id) async {
    try {
      final showRows = await _client.from('shows').select('id').eq('theatre_id', id);
      final bookingRows = await _client.from('bookings').select('id').eq('theatre_id', id);
      return TheatreDependencySummary(
        showCount: (showRows as List).length,
        bookingCount: (bookingRows as List).length,
      );
    } catch (_) {
      return const TheatreDependencySummary();
    }
  }

  @override
  Future<void> deactivateTheatre(String id) async {
    final config = await loadTheatre(id);
    if (config == null) {
      throw StateError('Theatre not found: $id');
    }
    config.status = TheatreStatus.archived;
    await saveTheatre(config);
  }

  @override
  Future<void> reactivateTheatre(String id) async {
    final config = await loadTheatre(id);
    if (config == null) {
      throw StateError('Theatre not found: $id');
    }
    config.status = TheatreStatus.published;
    await saveTheatre(config);
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
    await _client.from('theatres').delete().eq('id', id);
  }

  @override
  Future<List<String>> publishTheatre(String id) async {
    final config = await loadTheatre(id);
    if (config == null) {
      return ['Theatre not found.'];
    }

    final errors = TheatreValidation.validateForPublish(config);
    if (errors.isEmpty) {
      config.status = TheatreStatus.published;
      await saveTheatre(config);
    }
    return errors;
  }
}
