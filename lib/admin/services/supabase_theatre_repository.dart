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
    return TheatreConfiguration.fromJson(configJson);
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
    final ownerId = _requireUserId();
    final rows = await _client
        .from('theatres')
        .select()
        .eq('owner_id', ownerId)
        .order('created_at');
    return rows.map((r) => _fromRow(r as Map<String, dynamic>)).toList();
  }

  @override
  Future<List<TheatreConfiguration>> getPublishedTheatres() async {
    final rows = await _client
        .from('theatres')
        .select()
        .eq('status', TheatreStatus.published.name)
        .order('created_at');
    return rows.map((r) => _fromRow(r as Map<String, dynamic>)).toList();
  }

  @override
  Future<void> deleteTheatre(String id) async {
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
