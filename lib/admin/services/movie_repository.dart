import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/movie_content.dart';

/// PART (Producer<->Theatre Admin connection): the one place both the
/// Producer dashboard and the Admin Studio's Movie tab read/write movie
/// data through — mirrors the same repository pattern already established
/// by [TheatreRepository], so a producer's movie and a theatre admin's
/// "pick from catalog" selection are always the same underlying record.
abstract class MovieRepository {
  Future<MovieContent> createMovie(MovieContent movie);
  Future<void> updateMovie(MovieContent movie);
  Future<void> deleteMovie(String id);

  /// The current producer's own movies, any status — for the Producer
  /// dashboard's "My Movies" screen.
  Future<List<MovieContent>> getMyMovies();

  /// Every movie currently in the public LiveScreen catalog — approved by
  /// Platform Admin. Used both by the Theatre Admin's Movie tab (trailer
  /// picker) and Theatre Admin's Show creation (movie-for-a-show picker).
  /// Filtered on `approval_status` alone: approval is what puts a movie in
  /// the catalog now (see 0003_show_booking_workflow.sql) — there is no
  /// separate "publish the movie" step to also check.
  Future<List<MovieContent>> getPublishedMovies();

  /// Producer-initiated: moves this movie's approval_status from 'draft' to
  /// 'submitted'. The database (0002_platform_admin_verification.sql) only
  /// allows a Producer to toggle between draft/submitted — it rejects any
  /// attempt to set under_review/approved/rejected directly.
  Future<void> submitForReview(String movieId);

  /// Producer-initiated: pulls a submitted movie back to 'draft' before
  /// Platform Admin has started reviewing it.
  Future<void> withdrawFromReview(String movieId);

  /// Resolves a single movie by id, subject to the caller's normal RLS
  /// visibility (their own movie at any status, or any approved movie).
  /// Needed now that a show's `movie_id` is the real source of truth for
  /// which movie is playing — e.g. the booking confirmation screen must
  /// show the movie a specific show actually references, not a theatre's
  /// old single attached-movie snapshot.
  Future<MovieContent?> getMovieById(String id);
}

class SupabaseMovieRepository implements MovieRepository {
  SupabaseClient get _client => Supabase.instance.client;

  String _requireUserId() {
    final id = _client.auth.currentUser?.id;
    if (id == null) {
      throw StateError('No authenticated user — cannot perform this movie operation.');
    }
    return id;
  }

  // 'status' (publish state) and 'approval_status' are deliberately never
  // written here — an ordinary producer edit (title/description/etc.) must
  // never reset either of them. Only submitForReview/withdrawFromReview
  // below touch approval_status, and only Platform Admin ever touches
  // status (see PlatformAdminRepository) — the database also refuses a
  // Producer's attempt to change either, per
  // 0002_platform_admin_verification.sql.
  Map<String, dynamic> _toRow(
    MovieContent movie, {
    required String producerId,
    bool includeDualColumns = true,
    bool includeMetadataColumns = true,
  }) {
    final row = <String, dynamic>{
      'producer_id': producerId,
      'title': movie.title,
      'description': movie.description,
      'trailer_path': movie.trailerUrl,
      'thumbnail': movie.thumbnail,
      'duration_seconds': movie.durationSeconds,
    };
    if (includeDualColumns) {
      row['trailer_url'] = movie.trailerUrl;
      row['immersive_trailer_url'] = movie.immersiveTrailerUrl;
    }
    if (includeMetadataColumns) {
      row['language'] = movie.language;
      row['genre'] = movie.genre;
    }
    return row;
  }

  MovieContent _fromRow(Map<String, dynamic> row) {
    return MovieContent(
      id: row['id'] as String,
      title: row['title'] as String? ?? '',
      description: row['description'] as String? ?? '',
      trailerUrl: (row['trailer_url'] ?? row['trailer_path']) as String? ?? '',
      immersiveTrailerUrl: row['immersive_trailer_url'] as String? ?? '',
      thumbnail: row['thumbnail'] as String? ?? '',
      durationSeconds: row['duration_seconds'] as int? ?? 0,
      producerId: row['producer_id'] as String?,
      status: row['status'] as String? ?? 'draft',
      approvalStatus: row['approval_status'] as String? ?? 'draft',
      reviewReason: row['review_reason'] as String?,
      language: row['language'] as String? ?? 'English',
      genre: row['genre'] as String? ?? 'Drama',
      createdAt: row['created_at'] != null ? DateTime.tryParse(row['created_at'].toString()) : null,
      updatedAt: row['updated_at'] != null ? DateTime.tryParse(row['updated_at'].toString()) : null,
    );
  }

  @override
  Future<MovieContent> createMovie(MovieContent movie) async {
    final producerId = _requireUserId();
    Map<String, dynamic> row;
    try {
      row = await _client
          .from('movies')
          .insert(_toRow(movie, producerId: producerId, includeDualColumns: true, includeMetadataColumns: true))
          .select()
          .single();
    } on PostgrestException catch (e) {
      if (e.code == '42703' ||
          e.code == 'PGRST204' ||
          e.message.contains('language') ||
          e.message.contains('genre') ||
          e.message.contains('trailer_url') ||
          e.message.contains('immersive_trailer_url')) {
        row = await _client
            .from('movies')
            .insert(_toRow(movie, producerId: producerId, includeDualColumns: false, includeMetadataColumns: false))
            .select()
            .single();
      } else {
        rethrow;
      }
    }
    return _fromRow(row);
  }

  @override
  Future<void> updateMovie(MovieContent movie) async {
    final producerId = _requireUserId();
    List<Map<String, dynamic>> updatedRows;
    try {
      updatedRows = await _client
          .from('movies')
          .update(_toRow(movie, producerId: producerId, includeDualColumns: true, includeMetadataColumns: true))
          .eq('id', movie.id)
          .select();
    } on PostgrestException catch (e) {
      if (e.code == '42703' ||
          e.code == 'PGRST204' ||
          e.message.contains('language') ||
          e.message.contains('genre') ||
          e.message.contains('trailer_url') ||
          e.message.contains('immersive_trailer_url')) {
        updatedRows = await _client
            .from('movies')
            .update(_toRow(movie, producerId: producerId, includeDualColumns: false, includeMetadataColumns: false))
            .eq('id', movie.id)
            .select();
      } else {
        rethrow;
      }
    }

    if (updatedRows.isEmpty) {
      throw StateError(
        'Save failed silently: no row was updated for movie ${movie.id}. '
        'This usually means the current session is no longer recognized as '
        'this movie\'s producer — try logging out and back in.',
      );
    }
  }

  @override
  Future<void> deleteMovie(String id) async {
    await _client.from('movies').delete().eq('id', id);
  }

  @override
  Future<List<MovieContent>> getMyMovies() async {
    final producerId = _requireUserId();
    final rows = await _client
        .from('movies')
        .select()
        .eq('producer_id', producerId)
        .order('created_at', ascending: false);
    return rows.map((r) => _fromRow(r)).toList();
  }

  @override
  Future<List<MovieContent>> getPublishedMovies() async {
    final rows = await _client
        .from('movies')
        .select()
        .eq('status', 'published')
        .eq('approval_status', 'approved')
        .order('created_at');
    return rows.map((r) => _fromRow(r)).toList();
  }

  Future<void> _setApprovalStatus(String movieId, String approvalStatus) async {
    final updatedRows = await _client
        .from('movies')
        .update({'approval_status': approvalStatus})
        .eq('id', movieId)
        .select();

    if (updatedRows.isEmpty) {
      throw StateError(
        'Could not update movie $movieId — it may not belong to you, or the '
        'requested status change (currently $approvalStatus) is not allowed '
        'from its current state.',
      );
    }
  }

  @override
  Future<void> submitForReview(String movieId) => _setApprovalStatus(movieId, 'submitted');

  @override
  Future<void> withdrawFromReview(String movieId) => _setApprovalStatus(movieId, 'draft');

  @override
  Future<MovieContent?> getMovieById(String id) async {
    final rows = await _client.from('movies').select().eq('id', id).limit(1);
    if (rows.isEmpty) return null;
    return _fromRow(rows.first);
  }
}

final MovieRepository movieRepository = SupabaseMovieRepository();
