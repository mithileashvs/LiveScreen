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

  /// Every producer's published movies — what a theatre admin's Movie tab
  /// picker shows. A draft movie must never appear here.
  Future<List<MovieContent>> getPublishedMovies();
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

  Map<String, dynamic> _toRow(MovieContent movie, {required String producerId}) => {
        'producer_id': producerId,
        'title': movie.title,
        'description': movie.description,
        'trailer_path': movie.trailerPath,
        'thumbnail': movie.thumbnail,
        'duration_seconds': movie.durationSeconds,
        'status': movie.status,
      };

  MovieContent _fromRow(Map<String, dynamic> row) {
    return MovieContent(
      id: row['id'] as String,
      title: row['title'] as String? ?? '',
      description: row['description'] as String? ?? '',
      trailerPath: row['trailer_path'] as String? ?? '',
      thumbnail: row['thumbnail'] as String? ?? '',
      durationSeconds: row['duration_seconds'] as int? ?? 0,
      producerId: row['producer_id'] as String?,
      status: row['status'] as String? ?? 'draft',
    );
  }

  @override
  Future<MovieContent> createMovie(MovieContent movie) async {
    final producerId = _requireUserId();
    final row = await _client
        .from('movies')
        .insert(_toRow(movie, producerId: producerId))
        .select()
        .single();
    return _fromRow(row);
  }

  @override
  Future<void> updateMovie(MovieContent movie) async {
    final producerId = _requireUserId();
    // Same reasoning as SupabaseTheatreRepository.saveTheatre: an
    // RLS-blocked UPDATE matches zero rows instead of throwing, so this
    // checks explicitly rather than assuming success.
    final updatedRows = await _client
        .from('movies')
        .update(_toRow(movie, producerId: producerId))
        .eq('id', movie.id)
        .select();

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
        .order('created_at');
    return rows.map((r) => _fromRow(r as Map<String, dynamic>)).toList();
  }

  @override
  Future<List<MovieContent>> getPublishedMovies() async {
    final rows =
        await _client.from('movies').select().eq('status', 'published').order('created_at');
    return rows.map((r) => _fromRow(r as Map<String, dynamic>)).toList();
  }
}

final MovieRepository movieRepository = SupabaseMovieRepository();
