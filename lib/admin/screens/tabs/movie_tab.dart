import 'package:flutter/material.dart';
import '../../models/movie_content.dart';
import '../../models/theatre_configuration.dart';
import '../../services/movie_repository.dart';

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
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final config = widget.config;
    final movie = config.content ?? MovieContent(id: '${config.id}_movie');

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text(
          'Movie / Trailer Assignment',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFFFFFFFF)),
        ),
        const SizedBox(height: 4),
        const Text(
          'Associate a trailer or teaser with this auditorium for customer 3D seat preview experiences.',
          style: TextStyle(fontSize: 12.5, color: Color(0xFF9CA3AF)),
        ),
        const SizedBox(height: 20),
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
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F0F12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0x55D4AF37)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Pick from Producer Catalog', style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: Color(0xFFFFFFFF))),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF14141A),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF22222A)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<MovieContent>(
                          value: null,
                          hint: const Text('Choose a verified producer title', style: TextStyle(color: Color(0xFF71717A))),
                          dropdownColor: const Color(0xFF14141A),
                          style: const TextStyle(color: Color(0xFFF7F5F0), fontSize: 13),
                          isExpanded: true,
                          items: [
                            for (final m in catalog)
                              DropdownMenuItem(value: m, child: Text(m.title.isEmpty ? '(Untitled)' : m.title)),
                          ],
                          onChanged: (m) {
                            if (m != null) _pickFromCatalog(m);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        if (movie.producerId != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Text(
              'Linked to Producer Catalog film. Modifications below are local to this theatre.',
              style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF0F0F12),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF1E1E26)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _field(
                key: 'movie-title-${movie.id}',
                label: 'Movie Title',
                initialValue: movie.title,
                onChanged: (v) => _update(movie, title: v),
              ),
              const SizedBox(height: 14),
              _field(
                key: 'movie-trailer-${movie.id}',
                label: 'Trailer Video Path / Stream URL',
                initialValue: movie.trailerPath,
                helperText: 'Local asset file path or secure HTTPS video stream URL',
                onChanged: (v) => _update(movie, trailerPath: v),
              ),
              const SizedBox(height: 14),
              _field(
                key: 'movie-thumbnail-${movie.id}',
                label: 'Movie Poster / Thumbnail URL',
                initialValue: movie.thumbnail,
                onChanged: (v) => _update(movie, thumbnail: v),
              ),
              const SizedBox(height: 14),
              _field(
                key: 'movie-duration-${movie.id}',
                label: 'Duration (seconds)',
                initialValue: movie.durationSeconds.toString(),
                keyboardType: TextInputType.number,
                onChanged: (v) {
                  final parsed = int.tryParse(v);
                  if (parsed != null) _update(movie, durationSeconds: parsed);
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _field({
    required String key,
    required String label,
    required String initialValue,
    required ValueChanged<String> onChanged,
    String? helperText,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 12)),
        const SizedBox(height: 6),
        TextFormField(
          key: ValueKey(key),
          initialValue: initialValue,
          keyboardType: keyboardType,
          style: const TextStyle(color: Color(0xFFF7F5F0), fontSize: 13.5),
          decoration: InputDecoration(
            helperText: helperText,
            helperStyle: const TextStyle(color: Color(0xFF71717A), fontSize: 11),
            filled: true,
            fillColor: const Color(0xFF14141A),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF22222A))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF22222A))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFD4AF37))),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
          onChanged: onChanged,
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
