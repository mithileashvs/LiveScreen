import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/show_model.dart';

abstract class ShowRepository {
  /// [movieId] is required — every show now schedules a specific catalog
  /// movie (the database also rejects any movie that isn't
  /// `approval_status = 'approved'`, see enforce_show_movie_approved in
  /// 0003_show_booking_workflow.sql). New shows start as 'draft' and are
  /// not visible/bookable until [publishShow] is called.
  Future<ShowModel> createShow({
    required String theatreId,
    required String movieId,
    required DateTime startTime,
    DateTime? endTime,
    required double price,
  });

  /// Moves a show from 'draft' to 'published' — the point at which it
  /// becomes discoverable/bookable by users (enforced by RLS, not just this
  /// method existing).
  Future<void> publishShow(String showId);

  /// Every show for one theatre, in start-time order, regardless of status
  /// — used by the Admin Studio to manage a theatre's own shows. RLS
  /// (`shows_select_own_theatre`) restricts this to theatres the caller
  /// owns; Platform Admin has no special-cased access here since it isn't
  /// part of Platform Admin's responsibilities (per the workflow spec:
  /// "Platform Admin does NOT create theatre shows").
  Future<List<ShowModel>> getShowsForTheatre(String theatreId);

  /// Every PUBLISHED show for one movie, across every PUBLISHED theatre —
  /// what the User-facing "movie -> available theatres/showtimes" screen
  /// needs. RLS (`shows_select_for_published_theatre`) already restricts
  /// this to published shows on published theatres; this method just adds
  /// the movie filter on top.
  Future<List<ShowModel>> getPublishedShowsForMovie(String movieId);

  /// Resolves a single show by id — needed wherever a screen only has a
  /// showId and must show what movie/price/time it actually refers to
  /// (e.g. the booking confirmation screen).
  Future<ShowModel?> getShowById(String showId);
}

class SupabaseShowRepository implements ShowRepository {
  SupabaseClient get _client => Supabase.instance.client;

  @override
  Future<ShowModel> createShow({
    required String theatreId,
    required String movieId,
    required DateTime startTime,
    DateTime? endTime,
    required double price,
  }) async {
    final row = await _client
        .from('shows')
        .insert({
          'theatre_id': theatreId,
          'movie_id': movieId,
          'start_time': startTime.toIso8601String(),
          'end_time': endTime?.toIso8601String(),
          'price': price,
          'status': 'draft',
        })
        .select()
        .single();
    return ShowModel.fromRow(row);
  }

  @override
  Future<void> publishShow(String showId) async {
    final updated = await _client
        .from('shows')
        .update({'status': 'published'})
        .eq('id', showId)
        .select();

    if (updated.isEmpty) {
      throw StateError('Could not publish show $showId.');
    }
  }

  @override
  Future<List<ShowModel>> getShowsForTheatre(String theatreId) async {
    final rows = await _client
        .from('shows')
        .select()
        .eq('theatre_id', theatreId)
        .order('start_time');
    return rows.map((r) => ShowModel.fromRow(r)).toList();
  }

  @override
  Future<List<ShowModel>> getPublishedShowsForMovie(String movieId) async {
    final rows = await _client
        .from('shows')
        .select()
        .eq('movie_id', movieId)
        .eq('status', 'published')
        .order('start_time');
    return rows.map((r) => ShowModel.fromRow(r)).toList();
  }

  @override
  Future<ShowModel?> getShowById(String showId) async {
    final rows = await _client.from('shows').select().eq('id', showId).limit(1);
    if (rows.isEmpty) return null;
    return ShowModel.fromRow(rows.first);
  }
}

final ShowRepository showRepository = SupabaseShowRepository();
