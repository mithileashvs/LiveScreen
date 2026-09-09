import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../admin/models/movie_content.dart';
import '../../admin/services/movie_repository.dart';
import 'movie_edit_screen.dart';

/// Real CRUD for the Producer role (PART 10/Producer-connection task):
/// create/edit movies, backed by [movieRepository] — the same table a
/// theatre admin's Movie tab reads from.
class MyMoviesScreen extends StatefulWidget {
  const MyMoviesScreen({super.key});

  @override
  State<MyMoviesScreen> createState() => _MyMoviesScreenState();
}

class _MyMoviesScreenState extends State<MyMoviesScreen> {
  late Future<List<MovieContent>> _future;
  String? _error;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    setState(() {
      _error = null;
      _future = movieRepository.getMyMovies().catchError((e) {
        _error = e.toString();
        return <MovieContent>[];
      });
    });
  }

  Future<void> _openEditor([MovieContent? existing]) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => MovieEditScreen(existing: existing)),
    );
    if (saved == true) _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('My Movies')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(),
        icon: const Icon(Icons.add),
        label: const Text('New Movie'),
      ),
      body: FutureBuilder<List<MovieContent>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator(color: AppColors.accent));
          }

          if (_error != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, color: AppColors.error, size: 40),
                    const SizedBox(height: 12),
                    const Text('Unable to load movies. Try again.', style: AppTextStyles.body),
                    const SizedBox(height: 4),
                    Text(_error!, style: AppTextStyles.caption, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    OutlinedButton(onPressed: _refresh, child: const Text('Retry')),
                  ],
                ),
              ),
            );
          }

          final movies = snapshot.data ?? [];
          if (movies.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.movie_outlined, size: 48, color: AppColors.textMuted),
                    const SizedBox(height: 12),
                    const Text('No movies yet', style: AppTextStyles.subheading),
                    const SizedBox(height: 6),
                    const Text(
                      'Create a movie and publish it so theatre admins can pick it '
                      'for their theatres.',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.body,
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            itemCount: movies.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final movie = movies[index];
              final published = movie.status == 'published';
              return Material(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => _openEditor(movie),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                movie.title.isEmpty ? '(Untitled movie)' : movie.title,
                                style: AppTextStyles.subheading,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${movie.durationSeconds ~/ 60} min',
                                style: AppTextStyles.caption,
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: (published ? AppColors.success : AppColors.accent)
                                .withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: published ? AppColors.success : AppColors.accent,
                            ),
                          ),
                          child: Text(
                            published ? 'Published' : 'Draft',
                            style: AppTextStyles.caption.copyWith(
                              color: published ? AppColors.success : AppColors.accent,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
