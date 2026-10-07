import 'package:flutter/material.dart';
import '../../../screens/unity_experience_screen.dart';
import '../../models/seat_config.dart';
import '../../models/theatre_configuration.dart';
import '../../services/theatre_repository.dart';
import '../../services/theatre_unity_bridge.dart';
import '../../services/theatre_validation.dart';

/// Preview & Publish Tab for Theatre Studio.
/// Visual seat preview in Unity, publish validation checklist, and live publishing.
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

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: const Color(0xFF16161D)),
    );
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

    if (errors.isEmpty) {
      final fresh = await theatreRepository.loadTheatre(widget.config.id);
      if (fresh != null) {
        widget.config.status = fresh.status;
        widget.config.verificationStatus = fresh.verificationStatus;
        widget.config.reviewReason = fresh.reviewReason;
      }
    }

    setState(() => _publishing = false);
    widget.onChanged();

    if (!mounted) return;

    if (errors.isEmpty) {
      _showMessage('Theatre published successfully!');
    } else {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: const Color(0xFF111116),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFFEF4444)),
          ),
          title: const Text('Cannot Publish Yet', style: TextStyle(color: Color(0xFFFFFFFF), fontWeight: FontWeight.w700)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final e in errors)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text('• $e', style: const TextStyle(color: Color(0xFFF87171), fontSize: 13)),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK', style: TextStyle(color: Color(0xFFD4AF37))),
            ),
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
          movie: null,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final config = widget.config;
    final validationErrors = TheatreValidation.validateForPublish(config);

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text(
          'Preview a Seat in 3D Venue',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFFFFFFFF)),
        ),
        const SizedBox(height: 10),
        if (config.seats.isEmpty)
          const Text(
            'Configure seating first — there are no seats to preview yet.',
            style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
          )
        else ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: const Color(0xFF14141A),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF22222A)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<SeatConfig>(
                value: _selectedSeat,
                hint: const Text('Choose a seat to test point-of-view', style: TextStyle(color: Color(0xFF71717A))),
                dropdownColor: const Color(0xFF14141A),
                style: const TextStyle(color: Color(0xFFF7F5F0), fontSize: 13.5),
                isExpanded: true,
                items: [
                  for (final seat in config.seats)
                    DropdownMenuItem(value: seat, child: Text('Seat ${seat.id} (${seat.category.name.toUpperCase()})')),
                ],
                onChanged: (seat) => setState(() => _selectedSeat = seat),
              ),
            ),
          ),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            onPressed: _selectedSeat == null ? null : _preview,
            icon: const Icon(Icons.visibility_outlined, size: 18),
            label: const Text('Preview This Seat in 3D Venue', style: TextStyle(fontWeight: FontWeight.w700)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD4AF37),
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
        const SizedBox(height: 28),

        const Text(
          'Publish Checklist',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFFFFFFFF)),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFF0F0F12),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF1E1E26)),
          ),
          child: validationErrors.isEmpty
              ? Row(
                  children: const [
                    Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 22),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'This auditorium configuration is complete and ready to publish.',
                        style: TextStyle(color: Color(0xFFF7F5F0), fontSize: 13.5, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final error in validationErrors)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.error_outline_rounded, color: Color(0xFFEF4444), size: 18),
                            const SizedBox(width: 8),
                            Expanded(child: Text(error, style: const TextStyle(color: Color(0xFFF87171), fontSize: 13))),
                          ],
                        ),
                      ),
                  ],
                ),
        ),
        const SizedBox(height: 24),

        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _saveDraft,
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFF7F5F0),
                  side: const BorderSide(color: Color(0xFF2E2E38)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Save Draft', style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: ElevatedButton(
                onPressed: _publishing ? null : _publish,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD4AF37),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: _publishing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                      )
                    : const Text('Publish Theatre', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
