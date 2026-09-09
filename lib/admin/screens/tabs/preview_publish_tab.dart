import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../../../screens/unity_experience_screen.dart';
import '../../models/seat_config.dart';
import '../../models/theatre_configuration.dart';
import '../../services/theatre_repository.dart';
import '../../services/theatre_unity_bridge.dart';
import '../../services/theatre_validation.dart';
import '../../../shared/models/show_model.dart';
import '../../../shared/services/show_repository.dart';

/// PART 11/12: seat preview reuses the existing user-facing
/// [UnityExperienceScreen] unchanged — this is the actual integration
/// point the spec asks for, not a new preview system. Publishing runs the
/// same validation a real backend would eventually enforce.
class PreviewPublishTab extends StatefulWidget {
  final TheatreConfiguration config;
  final VoidCallback onChanged;

  const PreviewPublishTab({super.key, required this.config, required this.onChanged});

  @override
  State<PreviewPublishTab> createState() => _PreviewPublishTabState();
}

class _PreviewPublishTabState extends State<PreviewPublishTab> {
  SeatConfig? _selectedSeat;
  bool _publishing = false;
  late Future<List<ShowModel>> _showsFuture;

  @override
  void initState() {
    super.initState();
    _showsFuture = showRepository.getShowsForTheatre(widget.config.id);
  }

  Future<void> _addShow() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (time == null || !mounted) return;

    final startTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);

    try {
      await showRepository.createShow(
        theatreId: widget.config.id,
        movieId: null, // this theatre's single configured movie is used directly at booking time
        startTime: startTime,
      );
      if (!mounted) return;
      setState(() => _showsFuture = showRepository.getShowsForTheatre(widget.config.id));
      _showMessage('Show added.');
    } catch (e) {
      if (!mounted) return;
      _showMessage('Could not add show: $e');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _saveDraft() async {
    await theatreRepository.saveTheatre(widget.config);
    widget.onChanged();
    if (!mounted) return;
    _showMessage('Draft saved.');
  }

  Future<void> _publish() async {
    setState(() => _publishing = true);
    final errors = await theatreRepository.publishTheatre(widget.config.id);
    setState(() => _publishing = false);
    widget.onChanged();

    if (!mounted) return;

    if (errors.isEmpty) {
      _showMessage('Theatre published.');
    } else {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text('Cannot publish yet', style: AppTextStyles.subheading),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [for (final e in errors) Text('• $e', style: AppTextStyles.body)],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('OK')),
          ],
        ),
      );
    }
  }

  void _preview() {
    final seat = _selectedSeat;
    if (seat == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => UnityExperienceScreen(
          seatLabel: TheatreUnityBridge.seatIdForPreview(seat.id),
          theatre: widget.config,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final config = widget.config;
    final validationErrors = TheatreValidation.validateForPublish(config);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text('Preview a Seat', style: AppTextStyles.subheading),
        const SizedBox(height: 10),
        if (config.seats.isEmpty)
          const Text(
            'Configure seating first — there are no seats to preview yet.',
            style: AppTextStyles.caption,
          )
        else ...[
          DropdownButtonFormField<SeatConfig>(
            value: _selectedSeat,
            hint: const Text('Choose a seat', style: AppTextStyles.body),
            items: [
              for (final seat in config.seats)
                DropdownMenuItem(value: seat, child: Text(seat.id, style: AppTextStyles.body)),
            ],
            onChanged: (seat) => setState(() => _selectedSeat = seat),
            decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _selectedSeat == null ? null : _preview,
            icon: const Icon(Icons.visibility),
            label: const Text('Preview This Seat'),
          ),
        ],
        const SizedBox(height: 28),
        Row(
          children: [
            const Expanded(child: Text('Showtimes', style: AppTextStyles.subheading)),
            TextButton.icon(
              onPressed: _addShow,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Show'),
            ),
          ],
        ),
        const SizedBox(height: 6),
        FutureBuilder<List<ShowModel>>(
          future: _showsFuture,
          builder: (context, snapshot) {
            final shows = snapshot.data ?? [];
            if (snapshot.connectionState != ConnectionState.done) {
              return const SizedBox.shrink();
            }
            if (shows.isEmpty) {
              return const Text(
                'No showtimes yet. Users can still book seats directly against '
                'this theatre once published.',
                style: AppTextStyles.caption,
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final show in shows)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text('• ${show.startTime.toLocal()}', style: AppTextStyles.body),
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: 28),
        const Text('Publish Checklist', style: AppTextStyles.subheading),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
          ),
          child: validationErrors.isEmpty
              ? const Row(
                  children: [
                    Icon(Icons.check_circle, color: AppColors.success, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text('This theatre is ready to publish.', style: AppTextStyles.body),
                    ),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final error in validationErrors)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.error_outline, color: AppColors.error, size: 18),
                            const SizedBox(width: 8),
                            Expanded(child: Text(error, style: AppTextStyles.body)),
                          ],
                        ),
                      ),
                  ],
                ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _saveDraft,
                child: const Text('Save Draft'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: _publishing ? null : _publish,
                child: _publishing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                      )
                    : const Text('Publish Theatre'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
