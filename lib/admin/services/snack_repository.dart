import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/theatre_snack.dart';

/// Repository for Theatre-specific Concession / Snack Catalog operations.
/// Strictly scopes snack catalogs by `theatre_id`.
abstract class SnackRepository {
  /// Fetches snacks for a specific theatre.
  /// If [onlyAvailable] is true, only returns items where is_available == true.
  Future<List<TheatreSnack>> getSnacksForTheatre(String theatreId, {bool onlyAvailable = false});

  /// Adds a new snack to a theatre's catalog.
  Future<TheatreSnack> createSnack(TheatreSnack snack);

  /// Updates an existing snack item.
  Future<void> updateSnack(TheatreSnack snack);

  /// Deletes a snack item from a theatre's catalog.
  Future<void> deleteSnack(String snackId, String theatreId);

  /// Toggles whether a snack is available for customer ordering.
  Future<void> toggleAvailability(String snackId, String theatreId, bool isAvailable);
}

class SupabaseSnackRepository implements SnackRepository {
  SupabaseClient get _client => Supabase.instance.client;

  @override
  Future<List<TheatreSnack>> getSnacksForTheatre(String theatreId, {bool onlyAvailable = false}) async {
    if (theatreId.isEmpty) return [];

    try {
      var query = _client.from('theatre_snacks').select().eq('theatre_id', theatreId);
      if (onlyAvailable) {
        query = query.eq('is_available', true);
      }
      final res = await query.order('category', ascending: true).order('name', ascending: true);
      return (res as List)
          .map((row) => TheatreSnack.fromMap(row as Map<String, dynamic>))
          .toList();
    } catch (_) {
      // Return empty list if table not migrated or network error
      return [];
    }
  }

  @override
  Future<TheatreSnack> createSnack(TheatreSnack snack) async {
    final payload = snack.toMap(forInsert: true);
    final res = await _client.from('theatre_snacks').insert(payload).select().single();
    return TheatreSnack.fromMap(res);
  }

  @override
  Future<void> updateSnack(TheatreSnack snack) async {
    final payload = snack.toMap();
    await _client
        .from('theatre_snacks')
        .update(payload)
        .eq('id', snack.id)
        .eq('theatre_id', snack.theatreId);
  }

  @override
  Future<void> deleteSnack(String snackId, String theatreId) async {
    await _client
        .from('theatre_snacks')
        .delete()
        .eq('id', snackId)
        .eq('theatre_id', theatreId);
  }

  @override
  Future<void> toggleAvailability(String snackId, String theatreId, bool isAvailable) async {
    await _client
        .from('theatre_snacks')
        .update({'is_available': isAvailable})
        .eq('id', snackId)
        .eq('theatre_id', theatreId);
  }
}

final SnackRepository snackRepository = SupabaseSnackRepository();
