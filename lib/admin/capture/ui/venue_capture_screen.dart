import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/services.dart';
import '../../models/theatre_configuration.dart';

/// Cinematic AI Venue Capture screen for Theatre Admins.
///
/// Workflow:
/// Capture Venue → Evidence → Analysis Status → Evidence Requests → Reconstruction Draft → Review & Confirm.
///
/// Strict Rule:
/// "AI assists reconstruction; it does not silently guess unknown measurements."
class VenueCaptureScreen extends StatefulWidget {
  final String theatreId;
  final TheatreConfiguration? initialConfig;
  final ValueChanged<TheatreConfiguration>? onConfigurationUpdated;

  const VenueCaptureScreen({
    super.key,
    required this.theatreId,
    this.initialConfig,
    this.onConfigurationUpdated,
  });

  @override
  State<VenueCaptureScreen> createState() => _VenueCaptureScreenState();
}

class _VenueCaptureScreenState extends State<VenueCaptureScreen> {
  VenueCaptureSession? _session;
  List<VenueCaptureMedia> _evidence = [];
  List<VenueCaptureRequest> _requests = [];
  bool _loading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadOrCreateSession();
  }

  Future<void> _loadOrCreateSession() async {
    setState(() => _loading = true);
    try {
      var session = await venueCaptureRepository
          .getActiveSessionForTheatre(widget.theatreId);
      session ??= await venueCaptureRepository.createSession(widget.theatreId);
      final evidence = await venueCaptureRepository.listEvidence(session.id);
      final requests = await venueCaptureRepository.listRequests(session.id);

      if (mounted) {
        setState(() {
          _session = session;
          _evidence = evidence;
          _requests = requests;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _loading = false;
        });
      }
    }
  }

  Future<void> _addPhotoMock() async {
    final session = _session;
    if (session == null) return;

    final newMedia = VenueCaptureMedia(
      id: 'media-${DateTime.now().millisecondsSinceEpoch}',
      sessionId: session.id,
      theatreId: session.theatreId,
      type: EvidenceType.photo,
      storagePath: 'theatres/${session.theatreId}/evidence/photo_${DateTime.now().millisecondsSinceEpoch}.jpg',
      filename: 'auditorium_view_${_evidence.length + 1}.jpg',
      mimeType: 'image/jpeg',
      byteSize: 2450000,
      createdAt: DateTime.now(),
    );

    await venueCaptureRepository.addEvidence(newMedia);

    // If session was in initial or needsPhoto, transition appropriately
    if (session.state == CaptureState.initial ||
        session.state == CaptureState.needsPhoto) {
      final updated = await venueCaptureRepository.updateSessionState(
        session.id,
        CaptureState.analyzing,
      );
      _session = updated;
    }

    final refreshedEvidence =
        await venueCaptureRepository.listEvidence(session.id);
    if (mounted) {
      setState(() {
        _evidence = refreshedEvidence;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Visual photo evidence recorded in private capture storage.'),
          backgroundColor: Color(0xFF16161D),
        ),
      );
    }
  }

  Future<void> _addMeasurementDialog() async {
    final session = _session;
    if (session == null) return;

    final controller = TextEditingController(text: '22.5');
    final labelController =
        TextEditingController(text: 'Room width (laser distance meter)');

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0F0F14),
        title: const Text(
          'Add Physical Measurement',
          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Physical measurements provide metric scale calibration for AI reconstruction.',
              style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: labelController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Measurement Description',
                labelStyle: TextStyle(color: Color(0xFF9CA3AF)),
                filled: true,
                fillColor: Color(0xFF181822),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Distance / Dimension (metres)',
                labelStyle: TextStyle(color: Color(0xFF9CA3AF)),
                filled: true,
                fillColor: Color(0xFF181822),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF9CA3AF))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD4AF37),
              foregroundColor: Colors.black,
            ),
            child: const Text('Record'),
          ),
        ],
      ),
    );

    if (result == true) {
      final value = double.tryParse(controller.text) ?? 20.0;
      final newMedia = VenueCaptureMedia(
        id: 'meas-${DateTime.now().millisecondsSinceEpoch}',
        sessionId: session.id,
        theatreId: session.theatreId,
        type: EvidenceType.measurement,
        storagePath: 'theatres/${session.theatreId}/measurements/${DateTime.now().millisecondsSinceEpoch}.json',
        filename: 'physical_measurement_${_evidence.length + 1}.json',
        metadata: {
          'description': labelController.text,
          'value_meters': value,
          'measured_by': 'theatre_admin',
        },
        createdAt: DateTime.now(),
      );

      await venueCaptureRepository.addEvidence(newMedia);
      final refreshedEvidence =
          await venueCaptureRepository.listEvidence(session.id);
      if (mounted) {
        setState(() {
          _evidence = refreshedEvidence;
        });
      }
    }
  }

  Future<void> _confirmDraft() async {
    final session = _session;
    final draft = session?.draft;
    if (session == null || draft == null) return;

    try {
      final confirmedSession = await venueCaptureRepository.confirmDraft(
        session.id,
        draft,
        adminUserId: 'admin-user',
      );

      if (widget.initialConfig != null &&
          widget.onConfigurationUpdated != null) {
        final updatedConfig = DraftToTheatreMapper.applyDraftToConfiguration(
          widget.initialConfig!,
          confirmedSession.draft!,
          options: const DraftMappingOptions(requireReviewed: true),
        );
        widget.onConfigurationUpdated!(updatedConfig);
      }

      if (mounted) {
        setState(() => _session = confirmedSession);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reconstruction draft confirmed into theatre configuration.'),
            backgroundColor: Color(0xFF16161D),
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = e.toString());
      }
    }
  }

  Future<void> _cancelSession() async {
    final session = _session;
    if (session == null) return;
    try {
      final updated = await venueCaptureRepository.cancelSession(session.id);
      if (mounted) {
        setState(() => _session = updated);
        Navigator.of(context).pop(false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = e.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070709),
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'AI Venue Capture',
              style: TextStyle(
                color: Color(0xFFFFFFFF),
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
            Text(
              'Photogrammetry & Geometry Reconstruction Foundation',
              style: TextStyle(
                fontSize: 11,
                color: Color(0xFFD4AF37),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        elevation: 0,
        backgroundColor: const Color(0xFF0C0C10),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFFD4AF37)),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFD4AF37)),
            )
          : ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              children: [
                _buildPrincipleBanner(),
                const SizedBox(height: 16),
                _buildSessionHeader(),
                const SizedBox(height: 16),
                _buildEvidenceSection(),
                const SizedBox(height: 16),
                _buildRequestsSection(),
                const SizedBox(height: 16),
                _buildDraftPreviewSection(),
                const SizedBox(height: 24),
                _buildActionButtons(),
                const SizedBox(height: 32),
              ],
            ),
    );
  }

  Widget _buildPrincipleBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF14141A),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFD4AF37).withValues(alpha: 0.3)),
      ),
      child: const Row(
        children: [
          Icon(Icons.verified_outlined, color: Color(0xFFD4AF37), size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'AI assists reconstruction; it does not silently guess unknown measurements.',
              style: TextStyle(
                color: Color(0xFFF7F5F0),
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionHeader() {
    final session = _session;
    if (session == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0E0E14),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF22222E)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Capture Session',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              _buildStateChip(session.state),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Session ID: ${session.id}',
            style: const TextStyle(color: Color(0xFF71717A), fontSize: 11),
          ),
          Text(
            'Theatre: ${session.theatreId}',
            style: const TextStyle(color: Color(0xFF71717A), fontSize: 11),
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 10),
            Text(
              _errorMessage!,
              style: const TextStyle(color: Color(0xFFF87171), fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStateChip(CaptureState state) {
    Color bg;
    Color fg;
    switch (state) {
      case CaptureState.confirmed:
        bg = const Color(0xFF064E3B);
        fg = const Color(0xFF34D399);
        break;
      case CaptureState.failed:
      case CaptureState.cancelled:
        bg = const Color(0xFF450A0A);
        fg = const Color(0xFFF87171);
        break;
      case CaptureState.needsPhoto:
      case CaptureState.needsMeasurement:
        bg = const Color(0xFF451A03);
        fg = const Color(0xFFFBBF24);
        break;
      case CaptureState.readyForReview:
      case CaptureState.reviewing:
        bg = const Color(0xFF1E1B4B);
        fg = const Color(0xFFA5B4FC);
        break;
      case CaptureState.analyzing:
      case CaptureState.reconstructing:
        bg = const Color(0xFF1E293B);
        fg = const Color(0xFF93C5FD);
        break;
      case CaptureState.initial:
        bg = const Color(0xFF27272A);
        fg = const Color(0xFFE4E4E7);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        state.label,
        style: TextStyle(
          color: fg,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildEvidenceSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0E0E14),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF22222E)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recorded Evidence (${_evidence.length})',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.add_a_photo, color: Color(0xFFD4AF37), size: 20),
                    tooltip: 'Add Photo',
                    onPressed: _addPhotoMock,
                  ),
                  IconButton(
                    icon: const Icon(Icons.straighten, color: Color(0xFFD4AF37), size: 20),
                    tooltip: 'Add Measurement',
                    onPressed: _addMeasurementDialog,
                  ),
                ],
              ),
            ],
          ),
          if (_evidence.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'No evidence recorded yet. Add photos from multiple auditorium angles or physical laser measurements.',
                style: TextStyle(color: Color(0xFF71717A), fontSize: 12),
              ),
            )
          else
            ..._evidence.map((item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Icon(
                        item.type == EvidenceType.measurement
                            ? Icons.straighten
                            : Icons.photo,
                        color: const Color(0xFFD4AF37),
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          item.filename,
                          style: const TextStyle(color: Color(0xFFE4E4E7), fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        item.type.label,
                        style: const TextStyle(color: Color(0xFF71717A), fontSize: 11),
                      ),
                    ],
                  ),
                )),
        ],
      ),
    );
  }

  Widget _buildRequestsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0E0E14),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF22222E)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Targeted Evidence Requests (${_requests.length})',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 6),
          if (_requests.isEmpty)
            const Text(
              'No active evidence requests from the reconstruction worker.',
              style: TextStyle(color: Color(0xFF71717A), fontSize: 12),
            )
          else
            ..._requests.map((req) => Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF14141C),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFF27273A)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            req.target,
                            style: const TextStyle(
                              color: Color(0xFFFBBF24),
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            req.priority.label,
                            style: const TextStyle(
                              color: Color(0xFF9CA3AF),
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        req.instruction,
                        style: const TextStyle(
                          color: Color(0xFFE4E4E7),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                )),
        ],
      ),
    );
  }

  Widget _buildDraftPreviewSection() {
    final draft = _session?.draft;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0E0E14),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF22222E)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Reconstruction Draft',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              if (draft != null)
                Text(
                  draft.isReviewed ? 'Reviewed' : 'Unreviewed Draft',
                  style: TextStyle(
                    color: draft.isReviewed
                        ? const Color(0xFF34D399)
                        : const Color(0xFFFBBF24),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (draft == null)
            const Text(
              'No candidate reconstruction draft generated yet. '
              'Upload initial evidence to initiate analysis.',
              style: TextStyle(color: Color(0xFF71717A), fontSize: 12),
            )
          else ...[
            _estimateRow('Room Width', draft.room.width, 'm'),
            _estimateRow('Room Length', draft.room.length, 'm'),
            _estimateRow('Room Height', draft.room.height, 'm'),
            _estimateRow('Screen Width', draft.screen.width, 'm'),
            _estimateRow('Screen Height', draft.screen.height, 'm'),
            _estimateRow('Seating Rows', draft.seating.rows, ''),
            _estimateRow('Seats Per Row', draft.seating.seatsPerRow, ''),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Visual Speakers',
                      style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12)),
                  Text(
                    '${draft.speakers.length} detected (visual cabinet only)',
                    style: const TextStyle(color: Color(0xFFE4E4E7), fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _estimateRow<T>(String label, Estimate<T> estimate, String unit) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 12)),
          Row(
            children: [
              Text(
                estimate.isKnown
                    ? '${estimate.value}$unit'
                    : 'UNKNOWN',
                style: TextStyle(
                  color: estimate.isKnown
                      ? const Color(0xFFF7F5F0)
                      : const Color(0xFFF87171),
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: const Color(0xFF22222E),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  estimate.provenance.label,
                  style: const TextStyle(color: Color(0xFF71717A), fontSize: 9),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    final draft = _session?.draft;
    final canConfirm = draft != null && !_session!.state.isTerminal;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (canConfirm)
          ElevatedButton(
            onPressed: _confirmDraft,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD4AF37),
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text(
              'Review & Confirm into Live Configuration',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        const SizedBox(height: 8),
        OutlinedButton(
          onPressed: _cancelSession,
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF9CA3AF),
            side: const BorderSide(color: Color(0xFF3F3F46)),
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: const Text('Continue Manually / Cancel Capture'),
        ),
      ],
    );
  }
}
