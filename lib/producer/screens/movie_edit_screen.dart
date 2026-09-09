import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../admin/models/movie_content.dart';
import '../../admin/services/movie_repository.dart';

/// Create/edit form for one producer-owned movie. Pass [existing] to edit,
/// or omit it to create a new one.
class MovieEditScreen extends StatefulWidget {
  final MovieContent? existing;

  const MovieEditScreen({super.key, this.existing});

  @override
  State<MovieEditScreen> createState() => _MovieEditScreenState();
}

class _MovieEditScreenState extends State<MovieEditScreen> {
  late final TextEditingController _title;
  late final TextEditingController _description;
  late final TextEditingController _trailerPath;
  late final TextEditingController _thumbnail;
  late final TextEditingController _duration;
  late bool _published;
  bool _saving = false;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final m = widget.existing;
    _title = TextEditingController(text: m?.title ?? '');
    _description = TextEditingController(text: m?.description ?? '');
    _trailerPath = TextEditingController(text: m?.trailerPath ?? '');
    _thumbnail = TextEditingController(text: m?.thumbnail ?? '');
    _duration = TextEditingController(text: (m?.durationSeconds ?? 0).toString());
    _published = m?.status == 'published';
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _trailerPath.dispose();
    _thumbnail.dispose();
    _duration.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_title.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title is required.')),
      );
      return;
    }

    setState(() => _saving = true);

    final movie = MovieContent(
      id: widget.existing?.id ?? '',
      title: _title.text.trim(),
      description: _description.text.trim(),
      trailerPath: _trailerPath.text.trim(),
      thumbnail: _thumbnail.text.trim(),
      durationSeconds: int.tryParse(_duration.text) ?? 0,
      status: _published ? 'published' : 'draft',
    );

    try {
      if (_isEditing) {
        await movieRepository.updateMovie(movie);
      } else {
        await movieRepository.createMovie(movie);
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      setState(() => _saving = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(_isEditing ? 'Edit Movie' : 'New Movie')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _field(_title, 'Title'),
          _field(_description, 'Description', maxLines: 3),
          _field(_trailerPath, 'Trailer Path / URL'),
          _field(_thumbnail, 'Thumbnail Path / URL'),
          _field(_duration, 'Duration (seconds)', keyboardType: TextInputType.number),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Published', style: AppTextStyles.subheading),
                      const SizedBox(height: 2),
                      Text(
                        _published
                            ? 'Visible to theatre admins in their Movie tab picker.'
                            : 'Draft — only you can see this movie.',
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _published,
                  activeColor: AppColors.accent,
                  onChanged: (v) => setState(() => _published = v),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                  )
                : const Text('Save'),
          ),
        ],
      ),
    );
  }

  Widget _field(TextEditingController controller, String label,
      {int maxLines = 1, TextInputType? keyboardType}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        style: AppTextStyles.body.copyWith(color: AppColors.textPrimary),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: AppTextStyles.caption,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}
