import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/show_model.dart';

abstract class ShowRepository {
  Future<ShowModel> createShow({
    required String theatreId,
    String? movieId,
    required DateTime startTime,
    DateTime? endTime,
  });

  /// Every scheduled show for one theatre, in start-time order. Used by
  /// both the Admin Studio (managing a theatre's own shows) and the User
  /// catalog (browsing a published theatre's shows) — RLS on the `shows`
  /// table decides what each caller is actually allowed to see.
  Future<List<ShowModel>> getShowsForTheatre(String theatreId);
}

class SupabaseShowRepository implements ShowRepository {
  SupabaseClient get _client => Supabase.instance.client;

  @override
  Future<ShowModel> createShow({
    required String theatreId,
    String? movieId,
    required DateTime startTime,
    DateTime? endTime,
  }) async {
    final row = await _client
        .from('shows')
        .insert({
          'theatre_id': theatreId,
          'movie_id': movieId,
          'start_time': startTime.toIso8601String(),
          'end_time': endTime?.toIso8601String(),
          'status': 'scheduled',
        })
        .select()
        .single();
    return ShowModel.fromRow(row);
  }

  @override
  Future<List<ShowModel>> getShowsForTheatre(String theatreId) async {
    final rows = await _client
        .from('shows')
        .select()
        .eq('theatre_id', theatreId)
        .order('start_time');
    return rows.map((r) => ShowModel.fromRow(r as Map<String, dynamic>)).toList();
  }
}

final ShowRepository showRepository = SupabaseShowRepository();
