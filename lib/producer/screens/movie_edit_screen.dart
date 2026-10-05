import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../admin/models/movie_content.dart';
import '../../admin/services/movie_repository.dart';
import '../../shared/platform/video_upload_stub.dart'
    if (dart.library.html) '../../shared/platform/video_upload_web.dart';
import '../../shared/services/trailer_url.dart';

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
  late final TextEditingController _trailerUrl;
  String _immersiveTrailerUrl = '';
  String? _uploadedFileName;
  bool _uploadingImmersive = false;
  late final TextEditingController _thumbnail;
  late final TextEditingController _duration;
  late final TextEditingController _language;
  late final TextEditingController _genre;
  late String _approvalStatus;
  bool _saving = false;
  bool _submitting = false;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final m = widget.existing;
    _title = TextEditingController(text: m?.title ?? '');
    _description = TextEditingController(text: m?.description ?? '');
    _trailerUrl = TextEditingController(text: m?.trailerUrl ?? m?.trailerPath ?? '');
    _immersiveTrailerUrl = m?.immersiveTrailerUrl ?? '';
    _thumbnail = TextEditingController(text: m?.thumbnail ?? '');
    _duration = TextEditingController(text: (m?.durationSeconds ?? 0).toString());
    _language = TextEditingController(text: m?.language ?? 'English');
    _genre = TextEditingController(text: m?.genre ?? 'Drama');
    _approvalStatus = m?.approvalStatus ?? 'draft';
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _trailerUrl.dispose();
    _thumbnail.dispose();
    _duration.dispose();
    _language.dispose();
    _genre.dispose();
    super.dispose();
  }

  Future<void> _handleUploadImmersive() async {
    setState(() => _uploadingImmersive = true);
    try {
      final producerId = widget.existing?.producerId ??
          Supabase.instance.client.auth.currentUser?.id ??
          'producer';
      final result = await pickAndUploadImmersiveTrailer(producerId: producerId);
      if (!mounted) return;

      if (result == null) {
        setState(() => _uploadingImmersive = false);
        return;
      }

      if (!result.isSuccess) {
        setState(() => _uploadingImmersive = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.errorMessage ?? 'Upload failed.'),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }

      setState(() {
        _uploadingImmersive = false;
        _immersiveTrailerUrl = result.storageUrl ?? '';
        _uploadedFileName = result.fileName;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Uploaded ${result.fileName ?? "immersive trailer"}.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _uploadingImmersive = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Upload failed: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _save() async {
    if (_title.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title is required.')),
      );
      return;
    }

    final trailerError = TrailerSource.validateProducerYouTubeUrl(
      _trailerUrl.text,
      allowEmpty: true,
    );
    if (trailerError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(trailerError),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _saving = true);

    // status/approvalStatus are never set from here — Platform Admin owns
    // approval/publish, this screen only ever edits the movie's own fields.
    final movie = MovieContent(
      id: widget.existing?.id ?? '',
      title: _title.text.trim(),
      description: _description.text.trim(),
      trailerUrl: _trailerUrl.text.trim(),
      immersiveTrailerUrl: _immersiveTrailerUrl.trim(),
      thumbnail: _thumbnail.text.trim(),
      durationSeconds: int.tryParse(_duration.text) ?? 0,
      language: _language.text.trim().isNotEmpty ? _language.text.trim() : 'English',
      genre: _genre.text.trim().isNotEmpty ? _genre.text.trim() : 'Drama',
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

  Future<void> _submitForReview() async {
    if (!_isEditing) return;
    setState(() => _submitting = true);
    try {
      await movieRepository.submitForReview(widget.existing!.id);
      if (!mounted) return;
      setState(() {
        _approvalStatus = 'submitted';
        _submitting = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Submitted for Platform Admin review.')),
      );
    } catch (e) {
      setState(() => _submitting = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not submit: $e')),
      );
    }
  }

  Future<void> _withdraw() async {
    if (!_isEditing) return;
    setState(() => _submitting = true);
    try {
      await movieRepository.withdrawFromReview(widget.existing!.id);
      if (!mounted) return;
      setState(() {
        _approvalStatus = 'draft';
        _submitting = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Withdrawn back to draft.')),
      );
    } catch (e) {
      setState(() => _submitting = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not withdraw: $e')),
      );
    }
  }

  String _approvalLabel(String status) {
    switch (status) {
      case 'submitted':
        return 'Submitted — waiting for Platform Admin review.';
      case 'under_review':
        return 'Under review by Platform Admin.';
      case 'approved':
        return 'Approved by Platform Admin. Platform Admin can publish it '
            'from the Movie Approval screen.';
      case 'rejected':
        return 'Rejected by Platform Admin.';
      default:
        return 'Draft — only you can see this movie. Submit it for '
            'Platform Admin review when it is ready.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070709),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F0F12),
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFFD4AF37)),
        title: Text(
          _isEditing ? 'Edit Movie' : 'New Movie',
          style: const TextStyle(color: Color(0xFFFFFFFF), fontWeight: FontWeight.w700),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _field(_title, 'Title'),
          _field(_description, 'Description', maxLines: 3),
          Row(
            children: [
              Expanded(child: _field(_language, 'Language')),
              const SizedBox(width: 14),
              Expanded(child: _field(_genre, 'Genre')),
            ],
          ),
          _field(
            _trailerUrl,
            'YouTube Trailer',
            hintText: 'https://www.youtube.com/watch?v=VIDEO_ID or https://youtu.be/VIDEO_ID',
            helperText: 'Used for normal trailer playback.',
          ),
          _buildImmersiveTrailerSection(),
          _field(_thumbnail, 'Thumbnail Path / URL'),
          _field(_duration, 'Duration (seconds)', keyboardType: TextInputType.number),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF14141A),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF1E1E26)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Approval Status', style: TextStyle(color: Color(0xFFFFFFFF), fontWeight: FontWeight.w700, fontSize: 15)),
                const SizedBox(height: 4),
                Text(_approvalLabel(_approvalStatus), style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 12.5)),
                if (_isEditing && _approvalStatus == 'draft') ...[
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFD4AF37),
                      side: const BorderSide(color: Color(0xFFD4AF37)),
                    ),
                    onPressed: _submitting ? null : _submitForReview,
                    icon: const Icon(Icons.send, size: 18),
                    label: const Text('Submit for Review'),
                  ),
                ],
                if (_isEditing && _approvalStatus == 'submitted') ...[
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFEF4444),
                      side: const BorderSide(color: Color(0xFFEF4444)),
                    ),
                    onPressed: _submitting ? null : _withdraw,
                    icon: const Icon(Icons.undo, size: 18),
                    label: const Text('Withdraw'),
                  ),
                ],
                if (!_isEditing) ...[
                  const SizedBox(height: 8),
                  const Text(
                    'Save this movie first, then submit it for review.',
                    style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD4AF37),
              foregroundColor: Colors.black,
              minimumSize: const Size(double.infinity, 44),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
            ),
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

  Widget _field(
    TextEditingController controller,
    String label, {
    int maxLines = 1,
    TextInputType? keyboardType,
    String? hintText,
    String? helperText,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        style: const TextStyle(color: Color(0xFFF7F5F0), fontSize: 13.5),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
          hintText: hintText,
          hintStyle: const TextStyle(color: Color(0xFF71717A), fontSize: 13),
          helperText: helperText,
          helperStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 11.5),
          filled: true,
          fillColor: const Color(0xFF14141A),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF22222A))),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF22222A))),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFD4AF37))),
        ),
      ),
    );
  }

  Widget _buildImmersiveTrailerSection() {
    final hasExisting = _immersiveTrailerUrl.isNotEmpty;
    final displayName = _uploadedFileName != null
        ? '✓ $_uploadedFileName uploaded'
        : (hasExisting ? '✓ Existing immersive trailer' : null);

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF14141A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF1E1E26)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Immersive 3D Trailer',
              style: TextStyle(
                color: Color(0xFFFFFFFF),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Used to play the trailer directly on the cinema screen in the 3D seat experience.',
              style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12),
            ),
            const SizedBox(height: 12),
            if (displayName != null) ...[
              Row(
                children: [
                  const Icon(Icons.check_circle, color: Color(0xFF10B981), size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      displayName,
                      style: const TextStyle(
                        color: Color(0xFF10B981),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
            Row(
              children: [
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFD4AF37),
                    side: const BorderSide(color: Color(0xFFD4AF37)),
                  ),
                  onPressed: _uploadingImmersive ? null : _handleUploadImmersive,
                  icon: _uploadingImmersive
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Icon(
                          hasExisting ? Icons.refresh : Icons.cloud_upload_outlined,
                          size: 18,
                        ),
                  label: Text(_uploadingImmersive
                      ? 'Uploading...'
                      : (hasExisting ? 'Replace Video' : 'Upload MP4 / WebM')),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
