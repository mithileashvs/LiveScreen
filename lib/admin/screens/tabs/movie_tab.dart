import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../../models/movie_content.dart';
import '../../models/theatre_configuration.dart';
import '../../services/movie_repository.dart';

/// PART 10 (original) / shared-database task: this tab can now either pick
/// from a Producer's published movie catalog (via [MovieRepository] — the
/// same table the Producer dashboard writes to, "do not create separate
/// disconnected movie data for Producer and Theatre Admin") or still type
/// one in by hand, same as before. Picking a catalog movie copies its
/// fields into `config.content` (keeping the theatre's own editable
/// snapshot, same as previously) and records which producer movie it came
/// from via `producerId`, so the link stays traceable.
class MovieTab extends StatefulWidget {
  final TheatreConfiguration config;
  final VoidCallback onChanged;

  const MovieTab({super.key, required this.config, required this.onChanged});

  @override
  State<MovieTab> createState() => _MovieTabState();
}

class _MovieTabState extends State<MovieTab> {
  late Future<List<MovieContent>> _catalogFuture;

  @override
  void initState() {
    super.initState();
    _catalogFuture = movieRepository.getPublishedMovies();
  }

  void _pickFromCatalog(MovieContent catalogMovie) {
    final current = widget.config.content;
    widget.config.content = MovieContent(
      id: current?.id ?? '${widget.config.id}_movie',
      title: catalogMovie.title,
      description: catalogMovie.description,
      trailerPath: catalogMovie.trailerPath,
      thumbnail: catalogMovie.thumbnail,
      durationSeconds: catalogMovie.durationSeconds,
      producerId: catalogMovie.producerId,
      status: catalogMovie.status,
    );
    widget.onChanged();
    setState(() {}); // refresh the manual-entry fields below to match
  }

  @override
  Widget build(BuildContext context) {
    final config = widget.config;
    final movie = config.content ?? MovieContent(id: '${config.id}_movie');

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text('Movie / Trailer', style: AppTextStyles.subheading),
        const SizedBox(height: 4),
        const Text(
          'Associate a trailer with this theatre for the seat-preview experience.',
          style: AppTextStyles.caption,
        ),
        const SizedBox(height: 16),
        FutureBuilder<List<MovieContent>>(
          future: _catalogFuture,
          builder: (context, snapshot) {
            final catalog = snapshot.data ?? [];
            if (snapshot.connectionState != ConnectionState.done || catalog.isEmpty) {
              return const SizedBox.shrink();
            }
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Pick from Producer Catalog', style: AppTextStyles.subheading),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<MovieContent>(
                      value: null,
                      hint: const Text('Choose a published movie', style: AppTextStyles.body),
                      items: [
                        for (final m in catalog)
                          DropdownMenuItem(value: m, child: Text(m.title, style: AppTextStyles.body)),
                      ],
                      onChanged: (m) {
                        if (m != null) _pickFromCatalog(m);
                      },
                      decoration:
                          const InputDecoration(border: OutlineInputBorder(), isDense: true),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        if (movie.producerId != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              'Linked to a producer catalog movie. Editing the fields below only '
              'changes this theatre\'s copy.',
              style: AppTextStyles.caption.copyWith(color: AppColors.accent),
            ),
          ),
        TextFormField(
          key: ValueKey('movie-title-${movie.id}'),
          initialValue: movie.title,
          style: AppTextStyles.body.copyWith(color: AppColors.textPrimary),
          decoration: const InputDecoration(
            labelText: 'Title',
            labelStyle: AppTextStyles.caption,
            border: OutlineInputBorder(),
          ),
          onChanged: (v) => _update(movie, title: v),
        ),
        const SizedBox(height: 14),
        TextFormField(
          key: ValueKey('movie-trailer-${movie.id}'),
          initialValue: movie.trailerPath,
          style: AppTextStyles.body.copyWith(color: AppColors.textPrimary),
          decoration: const InputDecoration(
            labelText: 'Trailer Path / URL',
            labelStyle: AppTextStyles.caption,
            helperText: 'Local file path today; a hosted URL once uploads are supported.',
            border: OutlineInputBorder(),
          ),
          onChanged: (v) => _update(movie, trailerPath: v),
        ),
        const SizedBox(height: 14),
        TextFormField(
          key: ValueKey('movie-thumbnail-${movie.id}'),
          initialValue: movie.thumbnail,
          style: AppTextStyles.body.copyWith(color: AppColors.textPrimary),
          decoration: const InputDecoration(
            labelText: 'Thumbnail Path / URL',
            labelStyle: AppTextStyles.caption,
            border: OutlineInputBorder(),
          ),
          onChanged: (v) => _update(movie, thumbnail: v),
        ),
        const SizedBox(height: 14),
        TextFormField(
          key: ValueKey('movie-duration-${movie.id}'),
          initialValue: movie.durationSeconds.toString(),
          keyboardType: TextInputType.number,
          style: AppTextStyles.body.copyWith(color: AppColors.textPrimary),
          decoration: const InputDecoration(
            labelText: 'Duration (seconds)',
            labelStyle: AppTextStyles.caption,
            border: OutlineInputBorder(),
          ),
          onChanged: (v) {
            final parsed = int.tryParse(v);
            if (parsed != null) _update(movie, durationSeconds: parsed);
          },
        ),
      ],
    );
  }

  void _update(
    MovieContent current, {
    String? title,
    String? trailerPath,
    String? thumbnail,
    int? durationSeconds,
  }) {
    widget.config.content = MovieContent(
      id: current.id,
      title: title ?? current.title,
      trailerPath: trailerPath ?? current.trailerPath,
      thumbnail: thumbnail ?? current.thumbnail,
      description: current.description,
      durationSeconds: durationSeconds ?? current.durationSeconds,
      producerId: current.producerId,
      status: current.status,
    );
    widget.onChanged();
  }
}
