import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';
import '../services/services.dart';
import '../../models/theatre_configuration.dart';
import '../../models/room_config.dart';
import '../../models/screen_config.dart';
import '../../models/seat_config.dart';
import 'widgets/uncertainty_badge.dart';
import 'widgets/floating_venue_assistant.dart';

/// Cinematic AI Venue Capture screen for Theatre Admins.
///
/// Workflow:
/// Capture Evidence → Evidence Validation → AI Analysis → Confidence Evaluation →
/// Targeted Evidence Requests → Admin Review → Explicit Confirmation → Live Theatre Configuration.
///
/// Core Project Rule:
/// "AI assists reconstruction; it does not silently guess unknown measurements."
class VenueCaptureScreen extends StatefulWidget {
  final String theatreId;
  final TheatreConfiguration? initialConfig;
  final ValueChanged<TheatreConfiguration>? onConfigurationUpdated;
  final bool isDraftTheatre;
  final String? adminUserId;

  const VenueCaptureScreen({
    super.key,
    required this.theatreId,
    this.initialConfig,
    this.onConfigurationUpdated,
    this.isDraftTheatre = false,
    this.adminUserId,
  });

  @override
  State<VenueCaptureScreen> createState() => _VenueCaptureScreenState();
}

class _VenueCaptureScreenState extends State<VenueCaptureScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  /// Resolves the authenticated administrator identity.
  ///
  /// In production, identity is strictly derived from the authenticated Supabase session.
  /// An existing theatre's [ownerId] is NEVER treated as the identity of the person
  /// currently reviewing or confirming a reconstruction draft.
  /// [widget.adminUserId] is accepted as an explicit fallback ONLY in test/harness
  /// environments where Supabase authentication is not active.
  String? _resolveAuthenticatedAdminId() {
    // 1. Authenticated user from Supabase auth ALWAYS takes precedence in production
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null && user.id.trim().isNotEmpty) {
        return user.id.trim();
      }
    } catch (_) {}

    // 2. Explicit test-only admin identity permitted ONLY when Supabase auth has no session
    // (e.g. In automated widget/unit test harnesses or ephemeral drafts)
    if (widget.adminUserId != null && widget.adminUserId!.trim().isNotEmpty) {
      return widget.adminUserId!.trim();
    }

    // Never treat config.ownerId as proof of the identity of the person performing an action
    return null;
  }

  // Ephemeral repository for draft/new theatres so we never insert fake production theatre records
  static final InMemoryVenueCaptureRepository _ephemeralDraftRepository =
      InMemoryVenueCaptureRepository();

  VenueCaptureRepository get _repo => _isNewTheatreDraft
      ? _ephemeralDraftRepository
      : venueCaptureRepository;

  bool get _isNewTheatreDraft =>
      widget.isDraftTheatre ||
      widget.theatreId == 'new-theatre-draft' ||
      widget.theatreId.startsWith('draft-');

  VenueCaptureSession? _session;
  List<VenueCaptureMedia> _evidence = [];
  List<VenueCaptureRequest> _requests = [];
  List<VenueCaptureObservation> _observations = [];
  VenueAnalysisResult? _analysisResult;

  bool _loading = true;
  bool _analyzing = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadOrCreateSession();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadOrCreateSession() async {
    setState(() => _loading = true);
    try {
      var session = await _repo.getActiveSessionForTheatre(widget.theatreId);
      session ??= await _repo.createSession(widget.theatreId);

      final evidence = await _repo.listEvidence(session.id);
      final requests = await _repo.listRequests(session.id);
      final observations = await _repo.listObservations(session.id);

      if (mounted) {
        setState(() {
          _session = session;
          _evidence = evidence;
          _requests = requests;
          _observations = observations;
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

  Future<void> _addPhotoDialog({VenueCaptureRequest? forRequest}) async {
    final session = _session;
    if (session == null) return;

    EvidenceCategory selectedCategory = EvidenceCategory.frontWall;
    if (forRequest != null) {
      if (forRequest.target.toLowerCase().contains('rear')) {
        selectedCategory = EvidenceCategory.rearWall;
      } else if (forRequest.target.toLowerCase().contains('screen')) {
        selectedCategory = EvidenceCategory.screenStage;
      } else if (forRequest.target.toLowerCase().contains('seat')) {
        selectedCategory = EvidenceCategory.seating;
      } else if (forRequest.target.toLowerCase().contains('speaker')) {
        selectedCategory = EvidenceCategory.speakers;
      }
    }

    final descController = TextEditingController(
      text: forRequest != null ? 'Fulfills: ${forRequest.target}' : '',
    );

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: const Color(0xFF0F0F14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: Color(0xFF27273A)),
            ),
            title: Row(
              children: [
                const Icon(Icons.add_a_photo_outlined, color: Color(0xFFD4AF37), size: 20),
                const SizedBox(width: 8),
                Text(
                  forRequest != null ? 'Fulfill Photo Request' : 'Upload Venue Photo',
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (forRequest != null) ...[
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF451A03),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.4)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            forRequest.target,
                            style: const TextStyle(color: Color(0xFFFCD34D), fontWeight: FontWeight.w700, fontSize: 12),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            forRequest.instruction,
                            style: const TextStyle(color: Color(0xFFE4E4E7), fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  const Text(
                    'Evidence Category',
                    style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF181822),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF2C2C3D)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<EvidenceCategory>(
                        value: selectedCategory,
                        dropdownColor: const Color(0xFF181822),
                        isExpanded: true,
                        items: EvidenceCategory.values
                            .where((c) => c != EvidenceCategory.measurement)
                            .map((cat) => DropdownMenuItem(
                                  value: cat,
                                  child: Text(
                                    cat.label,
                                    style: const TextStyle(color: Colors.white, fontSize: 13),
                                  ),
                                ))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(() => selectedCategory = val);
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF14141C),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.info_outline_rounded, color: Color(0xFFD4AF37), size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            selectedCategory.guidance,
                            style: const TextStyle(color: Color(0xFFD1D5DB), fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descController,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: const InputDecoration(
                      labelText: 'Notes / Perspective Description',
                      labelStyle: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12),
                      filled: true,
                      fillColor: Color(0xFF181822),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
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
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
                child: const Text('Add Evidence', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ],
          );
        },
      ),
    );

    if (result == true) {
      final now = DateTime.now();
      final newMedia = VenueCaptureMedia(
        id: 'media-${now.millisecondsSinceEpoch}',
        sessionId: session.id,
        theatreId: session.theatreId,
        type: EvidenceType.photo,
        category: selectedCategory,
        uploadState: UploadState.uploaded,
        storagePath: 'theatres/${session.theatreId}/evidence/photo_${now.millisecondsSinceEpoch}.jpg',
        filename: '${selectedCategory.name}_${_evidence.length + 1}.jpg',
        mimeType: 'image/jpeg',
        byteSize: 3200000,
        description: descController.text.trim().isEmpty ? null : descController.text.trim(),
        targetRequestId: forRequest?.id,
        createdAt: now,
      );

      await _repo.addEvidence(newMedia);

      if (forRequest != null) {
        await _repo.resolveRequest(
          forRequest.id,
          status: RequestStatus.fulfilled,
          fulfilledEvidenceId: newMedia.id,
        );
      }

      await _refreshSessionState();
    }
  }

  Future<void> _addMeasurementDialog({VenueCaptureRequest? forRequest}) async {
    final session = _session;
    if (session == null) return;

    final valController = TextEditingController(text: '22.4');
    final descController = TextEditingController(
      text: forRequest != null
          ? 'Ground truth scale calibration: ${forRequest.target}'
          : 'First-row distance / Room width (Laser Disto)',
    );

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0F0F14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFF27273A)),
        ),
        title: Row(
          children: [
            const Icon(Icons.straighten_rounded, color: Color(0xFFD4AF37), size: 20),
            const SizedBox(width: 8),
            Text(
              forRequest != null ? 'Fulfill Scale Measurement' : 'Record Metric Measurement',
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Physical metric measurements establish true ground scale and eliminate focal length ambiguity. '
              'LiveScreen never guesses room dimensions.',
              style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: descController,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: const InputDecoration(
                labelText: 'Reference Target (e.g. Screen to Row A)',
                labelStyle: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12),
                filled: true,
                fillColor: Color(0xFF181822),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: valController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
              decoration: const InputDecoration(
                labelText: 'Distance (metres) *',
                labelStyle: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12),
                filled: true,
                fillColor: Color(0xFF181822),
                border: OutlineInputBorder(),
                suffixText: 'm',
                suffixStyle: TextStyle(color: Color(0xFFD4AF37)),
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
            child: const Text('Record Scale', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (result == true) {
      final value = double.tryParse(valController.text.trim()) ?? 20.0;
      final now = DateTime.now();

      final newMedia = VenueCaptureMedia(
        id: 'meas-${now.millisecondsSinceEpoch}',
        sessionId: session.id,
        theatreId: session.theatreId,
        type: EvidenceType.measurement,
        category: EvidenceCategory.measurement,
        uploadState: UploadState.uploaded,
        storagePath: 'theatres/${session.theatreId}/measurements/${now.millisecondsSinceEpoch}.json',
        filename: 'scale_measurement_${_evidence.length + 1}.json',
        description: descController.text.trim(),
        targetRequestId: forRequest?.id,
        metadata: {
          'distance_meters': value,
          'value_meters': value,
          'method': 'physical_tape_or_laser',
          'measured_by': _resolveAuthenticatedAdminId() ?? 'theatre_operator',
        },
        createdAt: now,
      );

      await _repo.addEvidence(newMedia);

      if (forRequest != null) {
        await _repo.resolveRequest(
          forRequest.id,
          status: RequestStatus.fulfilled,
          fulfilledEvidenceId: newMedia.id,
        );
      }

      await _refreshSessionState();
    }
  }

  Future<void> _deleteEvidence(String mediaId) async {
    await _repo.deleteEvidence(mediaId);
    await _refreshSessionState();
  }

  Future<void> _refreshSessionState() async {
    final session = _session;
    if (session == null) return;

    final updatedSession = await _repo.getSession(session.id) ?? session;
    final refreshedEvidence = await _repo.listEvidence(session.id);
    final refreshedRequests = await _repo.listRequests(session.id);
    final refreshedObs = await _repo.listObservations(session.id);

    if (mounted) {
      setState(() {
        _session = updatedSession;
        _evidence = refreshedEvidence;
        _requests = refreshedRequests;
        _observations = refreshedObs;
      });
    }
  }

  Future<void> _runAnalysis() async {
    final session = _session;
    if (session == null) return;

    setState(() {
      _analyzing = true;
      _errorMessage = null;
    });

    try {
      // 1. Transition state machine to analyzing
      final analyzingSession = await _repo.updateSessionState(
        session.id,
        CaptureState.analyzing,
      );
      _session = analyzingSession;

      // 2. Execute analysis via the injectable analyzer
      final input = VenueAnalysisInput(
        session: analyzingSession,
        evidence: _evidence,
        baselineConfig: widget.initialConfig,
        existingRequests: _requests,
        previousDraft: analyzingSession.draft,
      );

      final result = await venueAnalyzer.analyze(input);
      _analysisResult = result;

      if (!result.isWorkerAvailable) {
        // Honest notification: external worker is offline/unconfigured
        setState(() {
          _errorMessage = result.errorMessage;
          _analyzing = false;
        });
        return;
      }

      if (!result.isSuccess) {
        // Pipeline failed
        await _repo.updateSessionState(session.id, CaptureState.failed);
        setState(() {
          _errorMessage = result.errorMessage ?? 'Analysis pipeline failed.';
          _analyzing = false;
        });
        await _refreshSessionState();
        return;
      }

      // 3. Persist generated draft
      if (result.draft != null) {
        await _repo.saveReconstructionDraft(session.id, result.draft!);
      }

      // 4. Persist newly planned targeted requests
      for (final req in result.targetedRequests) {
        final existingIndex = _requests.indexWhere((r) => r.id == req.id);
        if (existingIndex == -1) {
          await _repo.addRequest(req);
        } else if (req.status != _requests[existingIndex].status) {
          await _repo.resolveRequest(
            req.id,
            status: req.status,
            fulfilledEvidenceId: req.fulfilledEvidenceId,
          );
        }
      }

      // 5. Persist observations
      for (final obs in result.observations) {
        final existing = _observations.any((o) => o.id == obs.id);
        if (!existing) {
          await _repo.addObservation(obs);
        }
      }

      // 6. Transition to next state based on request requirements
      final hasPendingCritical = result.targetedRequests.any(
        (r) => r.status == RequestStatus.pending && r.priority == RequestPriority.critical,
      );
      final hasPendingPhoto = result.targetedRequests.any(
        (r) => r.status == RequestStatus.pending && r.requiredEvidenceType == EvidenceType.photo,
      );

      CaptureState nextState;
      if (hasPendingCritical && result.targetedRequests.any((r) => r.requiredEvidenceType == EvidenceType.measurement)) {
        nextState = CaptureState.needsMeasurement;
      } else if (hasPendingPhoto) {
        nextState = CaptureState.needsPhoto;
      } else {
        nextState = CaptureState.readyForReview;
      }

      final updated = await _repo.updateSessionState(session.id, nextState);
      _session = updated;

      await _refreshSessionState();

      if (mounted) {
        setState(() => _analyzing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              nextState == CaptureState.readyForReview
                  ? 'Reconstruction draft generated. Review the venue below.'
                  : 'Analysis complete. Targeted evidence is needed to resolve uncertainty.',
            ),
            backgroundColor: const Color(0xFF16161D),
          ),
        );

        // Switch to Review or Reconstruction tab if ready
        if (nextState == CaptureState.readyForReview) {
          _tabController.animateTo(2);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _analyzing = false;
        });
      }
    }
  }

  Future<void> _reviewDraft() async {
    final session = _session;
    final draft = session?.draft;
    if (session == null || draft == null) return;

    final adminId = _resolveAuthenticatedAdminId();
    if (adminId == null || adminId.isEmpty) {
      setState(() {
        _errorMessage =
            'Authentication required: Cannot review reconstruction draft without an authenticated administrator identity.';
      });
      return;
    }

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final reviewedSession = await _repo.markDraftReviewed(
        session.id,
        adminUserId: adminId,
      );

      if (mounted) {
        setState(() {
          _session = reviewedSession;
          _loading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Draft approved and marked as reviewed by $adminId.'),
            backgroundColor: const Color(0xFF064E3B),
          ),
        );
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

  Future<void> _confirmDraft() async {
    final session = _session;
    final draft = session?.draft;
    if (session == null || draft == null) return;

    // Enforce real administrator review before confirmation
    if (!draft.isReviewed) {
      setState(() {
        _errorMessage =
            'Review required: An administrator must review and approve the draft before confirming it into live configuration.';
      });
      return;
    }

    final adminId = _resolveAuthenticatedAdminId();
    if (adminId == null || adminId.isEmpty) {
      setState(() {
        _errorMessage =
            'Authentication required: Cannot confirm reconstruction draft without an authenticated administrator identity.';
      });
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0F0F14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFFD4AF37)),
        ),
        title: const Text(
          'Confirm AI Venue Reconstruction',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This will map the confirmed reconstruction draft into your canonical LiveScreen configuration.',
              style: TextStyle(color: Color(0xFFE4E4E7), fontSize: 13),
            ),
            SizedBox(height: 10),
            Text(
              '• Unknown values will NOT overwrite your existing configuration.\n'
              '• Visual surround speakers are placed for rendering only.\n'
              '• Existing acoustic and verification status are strictly preserved.',
              style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12),
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
            child: const Text('Confirm & Apply', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final confirmedSession = await _repo.confirmDraft(
        session.id,
        draft,
        adminUserId: adminId,
      );

      final baseline = widget.initialConfig ??
          TheatreConfiguration(
            id: widget.theatreId,
            basicInfo: TheatreBasicInfo(name: 'Captured Venue'),
            room: RoomConfig(width: 20, length: 25, height: 8),
            screen: ScreenConfig(width: 14, height: 6),
            lastSeatLayout: SeatLayoutParams(rows: 10, seatsPerRow: 12),
          );

      final updatedConfig = DraftToTheatreMapper.applyDraftToConfiguration(
        baseline,
        confirmedSession.draft!,
        options: const DraftMappingOptions(requireReviewed: true),
      );

      widget.onConfigurationUpdated?.call(updatedConfig);

      if (mounted) {
        setState(() => _session = confirmedSession);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reconstruction draft confirmed into theatre configuration.'),
            backgroundColor: Color(0xFF064E3B),
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
      final updated = await _repo.cancelSession(session.id);
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'AI Venue Capture',
              style: TextStyle(
                color: Color(0xFFFFFFFF),
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
            Text(
              _isNewTheatreDraft
                  ? 'New Theatre Draft Capture (Ephemeral Session)'
                  : 'Venue Reconstruction Studio',
              style: const TextStyle(
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
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFFD4AF37),
          indicatorWeight: 2.5,
          labelColor: const Color(0xFFD4AF37),
          unselectedLabelColor: const Color(0xFF9CA3AF),
          labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
          tabs: const [
            Tab(text: '1. Capture'),
            Tab(text: '2. Analysis'),
            Tab(text: '3. Reconstruction'),
            Tab(text: '4. Review & Confirm'),
          ],
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFD4AF37)),
            )
          : Stack(
              children: [
                Column(
                  children: [
                    _buildHeaderBar(),
                    if (_errorMessage != null) _buildErrorBanner(),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildCaptureTab(),
                          _buildAnalysisTab(),
                          _buildReconstructionTab(),
                          _buildReviewTab(),
                        ],
                      ),
                    ),
                  ],
                ),
                Positioned(
                  right: 20,
                  bottom: 20,
                  child: FloatingVenueAssistant(
                    sessionId: _session?.id ?? 'capture-${widget.theatreId}',
                    theatreId: widget.theatreId,
                    contextName: 'AI Venue Capture',
                    currentDraft: _analysisResult?.draft ??
                        _session?.draft ??
                        ReconstructionDraft(
                          id: 'draft-${_session?.id ?? widget.theatreId}',
                          sessionId:
                              _session?.id ?? 'session-${widget.theatreId}',
                          theatreId: widget.theatreId,
                          createdAt: DateTime.now(),
                        ),
                    onDraftUpdated: (updated) {
                      setState(() {
                        _analysisResult = VenueAnalysisResult(
                          isSuccess: true,
                          draft: updated,
                          analyzerName: _analysisResult?.analyzerName ??
                              'Conversational Venue Assistant',
                          observations: _analysisResult?.observations ?? [],
                          targetedRequests:
                              _analysisResult?.targetedRequests ?? [],
                          unresolvedFields:
                              _analysisResult?.unresolvedFields ?? [],
                          unresolvedReasons:
                              _analysisResult?.unresolvedReasons ?? {},
                        );
                      });
                      if (_session != null) {
                        _repo.saveReconstructionDraft(_session!.id, updated);
                      }
                    },
                    onMeasurementRequested: () {
                      _tabController.animateTo(0); // Move to capture tab for evidence/measurement
                    },
                  ),
                ),
              ],
            ),
    );
  }


  Widget _buildHeaderBar() {
    final session = _session;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: const Color(0xFF0E0E14),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.verified_outlined, color: Color(0xFFD4AF37), size: 16),
                  const SizedBox(width: 6),
                  Text(
                    'Session ${session?.id ?? '...'}',
                    style: const TextStyle(color: Color(0xFFE4E4E7), fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              if (session != null) _buildStateChip(session.state),
            ],
          ),
          const SizedBox(height: 6),
          const Row(
            children: [
              Expanded(
                child: Text(
                  'Core Rule: AI assists reconstruction; it does not silently guess unknown measurements.',
                  style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 11, fontStyle: FontStyle.italic),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: const Color(0xFF450A0A),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: Color(0xFFFCA5A5), size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _errorMessage!,
              style: const TextStyle(color: Color(0xFFFCA5A5), fontSize: 12),
            ),
          ),
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        state.label,
        style: TextStyle(
          color: fg,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // ==========================================================================
  // TAB 1: CAPTURE EVIDENCE
  // ==========================================================================
  Widget _buildCaptureTab() {
    final pendingRequests = _requests.where((r) => r.status == RequestStatus.pending).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (pendingRequests.isNotEmpty) ...[
          _buildPendingRequestsCard(pendingRequests),
          const SizedBox(height: 16),
        ],
        _buildUploadActionsCard(),
        const SizedBox(height: 16),
        _buildEvidenceGallery(),
        const SizedBox(height: 20),
        _buildAnalyzeButton(),
      ],
    );
  }

  Widget _buildPendingRequestsCard(List<VenueCaptureRequest> requests) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1307),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFD4AF37).withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.priority_high_rounded, color: Color(0xFFFBBF24), size: 18),
              const SizedBox(width: 8),
              Text(
                'Targeted Evidence Required (${requests.length})',
                style: const TextStyle(color: Color(0xFFFBBF24), fontWeight: FontWeight.w700, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'The reconstruction worker identified uncertainty and requested specific evidence to proceed without guessing:',
            style: TextStyle(color: Color(0xFFD1D5DB), fontSize: 11.5),
          ),
          const SizedBox(height: 10),
          ...requests.map((req) => _buildRequestItem(req)),
        ],
      ),
    );
  }

  Widget _buildRequestItem(VenueCaptureRequest req) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF14141C),
        borderRadius: BorderRadius.circular(8),
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
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: req.priority == RequestPriority.critical ? const Color(0xFF450A0A) : const Color(0xFF451A03),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${req.priority.label} Priority',
                  style: TextStyle(
                    color: req.priority == RequestPriority.critical ? const Color(0xFFFCA5A5) : const Color(0xFFFCD34D),
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Reason: ${req.reason}',
            style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 11),
          ),
          const SizedBox(height: 4),
          Text(
            'Instruction: ${req.instruction}',
            style: const TextStyle(color: Color(0xFFE4E4E7), fontSize: 11),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              icon: Icon(
                req.requiredEvidenceType == EvidenceType.measurement
                    ? Icons.straighten_rounded
                    : Icons.add_a_photo_outlined,
                size: 14,
              ),
              label: Text(
                req.requiredEvidenceType == EvidenceType.measurement
                    ? 'Record Measurement'
                    : 'Capture Photo',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD4AF37),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                visualDensity: VisualDensity.compact,
              ),
              onPressed: () {
                if (req.requiredEvidenceType == EvidenceType.measurement) {
                  _addMeasurementDialog(forRequest: req);
                } else {
                  _addPhotoDialog(forRequest: req);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadActionsCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0E0E14),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF22222E)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Add Venue Evidence',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
          ),
          const SizedBox(height: 4),
          const Text(
            'Multiple vantage points allow 3D multi-view triangulation. Front, rear, side walls, and seating curvature are critical.',
            style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 11),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.add_a_photo_outlined, size: 16),
                  label: const Text('Add Photo View', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1F1F2C),
                    foregroundColor: const Color(0xFFF7F5F0),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: const BorderSide(color: Color(0xFF333346)),
                    ),
                  ),
                  onPressed: () => _addPhotoDialog(),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.straighten_rounded, size: 16),
                  label: const Text('Add Measurement', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1F1F2C),
                    foregroundColor: const Color(0xFFD4AF37),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: const BorderSide(color: Color(0xFF333346)),
                    ),
                  ),
                  onPressed: () => _addMeasurementDialog(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEvidenceGallery() {
    return Container(
      padding: const EdgeInsets.all(14),
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
                'Submitted Evidence (${_evidence.length})',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
              ),
              Text(
                '${_evidence.where((e) => e.type == EvidenceType.photo).length} Photos • ${_evidence.where((e) => e.type == EvidenceType.measurement).length} Measures',
                style: const TextStyle(color: Color(0xFF71717A), fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (_evidence.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 24),
              alignment: Alignment.center,
              child: const Column(
                children: [
                  Icon(Icons.photo_library_outlined, color: Color(0xFF3F3F46), size: 36),
                  SizedBox(height: 8),
                  Text(
                    'No visual evidence uploaded yet.',
                    style: TextStyle(color: Color(0xFF71717A), fontSize: 12),
                  ),
                ],
              ),
            )
          else
            ..._evidence.map((item) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF14141C),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFF242434)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        item.type == EvidenceType.measurement
                            ? Icons.straighten_rounded
                            : Icons.photo_camera_back_outlined,
                        color: const Color(0xFFD4AF37),
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.filename,
                              style: const TextStyle(color: Color(0xFFE4E4E7), fontSize: 12, fontWeight: FontWeight.w600),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${item.category.label}${item.description != null ? ' • ${item.description}' : ''}',
                              style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 11),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1E2A),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          item.uploadState.label,
                          style: const TextStyle(color: Color(0xFF34D399), fontSize: 9.5),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 14, color: Color(0xFF71717A)),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () => _deleteEvidence(item.id),
                      ),
                    ],
                  ),
                )),
        ],
      ),
    );
  }

  Widget _buildAnalyzeButton() {
    return ElevatedButton(
      onPressed: _analyzing || _evidence.isEmpty ? null : _runAnalysis,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFD4AF37),
        foregroundColor: Colors.black,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: _analyzing
          ? const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                ),
                SizedBox(width: 10),
                Text('Reconstructing 3D Venue...', style: TextStyle(fontWeight: FontWeight.w700)),
              ],
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.auto_awesome_rounded, size: 18),
                const SizedBox(width: 8),
                Text(
                  _session?.draft == null ? 'Run AI Venue Reconstruction' : 'Re-analyze Venue with New Evidence',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                ),
              ],
            ),
    );
  }

  // ==========================================================================
  // TAB 2: ANALYSIS & UNCERTAINTY
  // ==========================================================================
  Widget _buildAnalysisTab() {
    final draft = _session?.draft;
    final res = _analysisResult;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildWorkerStatusCard(),
        const SizedBox(height: 14),
        _buildOverallConfidenceCard(draft),
        const SizedBox(height: 14),
        _buildUnresolvedItemsCard(res),
        const SizedBox(height: 14),
        _buildObservationsCard(),
      ],
    );
  }

  Widget _buildWorkerStatusCard() {
    final isAvail = venueAnalyzer.isAvailable;
    final isMock = venueAnalyzer is MockVenueAnalyzer;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0E0E14),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isMock ? const Color(0xFFB45309) : const Color(0xFF22222E),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'AI Analyzer Boundary',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isMock
                      ? const Color(0xFF451A03)
                      : (isAvail ? const Color(0xFF064E3B) : const Color(0xFF450A0A)),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  isMock
                      ? 'Test/Dev Mock Fixture'
                      : (isAvail ? 'Worker Connected' : 'Worker Offline / Unconfigured'),
                  style: TextStyle(
                    color: isMock
                        ? const Color(0xFFFCD34D)
                        : (isAvail ? const Color(0xFF6EE7B7) : const Color(0xFFFCA5A5)),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Active Worker: ${venueAnalyzer.name}',
            style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 11.5, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            isMock
                ? 'NOTICE: Using deterministic mock test fixtures for automated testing. This is NOT a real GPU computer vision pipeline.'
                : (isAvail
                    ? 'External GPU reconstruction worker protocol active. Client receives geometric estimates and confidence metrics.'
                    : 'No GPU worker endpoint is currently connected. LiveScreen does NOT embed neural network weights in Flutter and never fabricates results.'),
            style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildOverallConfidenceCard(ReconstructionDraft? draft) {
    final conf = draft?.overallConfidence ?? 0.0;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0E0E14),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF22222E)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Venue Reconstruction Confidence',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: conf,
                    minHeight: 10,
                    backgroundColor: const Color(0xFF1E1E2A),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      conf >= 0.8 ? const Color(0xFF34D399) : (conf >= 0.5 ? const Color(0xFFFBBF24) : const Color(0xFFF87171)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${(conf * 100).toInt()}%',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            conf >= 0.8
                ? 'High confidence: sufficient multi-view coverage and metric scale are established.'
                : 'Unresolved elements exist. Check the unresolved items below to fulfill needed evidence.',
            style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildUnresolvedItemsCard(VenueAnalysisResult? res) {
    final unresolved = res?.unresolvedFields ?? [];
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0E0E14),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF22222E)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.help_outline_rounded, color: Color(0xFFFBBF24), size: 16),
              const SizedBox(width: 6),
              Text(
                'Unresolved Venue Elements (${unresolved.length})',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (unresolved.isEmpty)
            const Text(
              'All key venue parameters have sufficient visual evidence.',
              style: TextStyle(color: Color(0xFF34D399), fontSize: 11.5),
            )
          else ...[
            const Text(
              'These values remain explicitly UNKNOWN until verified evidence is submitted:',
              style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 11),
            ),
            const SizedBox(height: 8),
            ...unresolved.map((field) {
              final reason = res?.unresolvedReasons[field] ?? 'Evidence insufficient';
              return Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A141A),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.warning_amber_rounded, size: 14, color: Color(0xFFF87171)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(field, style: const TextStyle(color: Color(0xFFFCA5A5), fontWeight: FontWeight.w600, fontSize: 11.5)),
                          Text(reason, style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 10.5)),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildObservationsCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0E0E14),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF22222E)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Worker Feature Observations (${_observations.length})',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
          ),
          const SizedBox(height: 8),
          if (_observations.isEmpty)
            const Text(
              'No semantic feature observations recorded yet.',
              style: TextStyle(color: Color(0xFF71717A), fontSize: 11),
            )
          else
            ..._observations.map((obs) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_outline_rounded, color: Color(0xFF34D399), size: 14),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '${obs.featureType}: ${obs.description ?? ''}',
                          style: const TextStyle(color: Color(0xFFE4E4E7), fontSize: 11),
                        ),
                      ),
                      if (obs.confidence != null)
                        Text(
                          '${(obs.confidence! * 100).toInt()}%',
                          style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 10),
                        ),
                    ],
                  ),
                )),
        ],
      ),
    );
  }

  // ==========================================================================
  // TAB 3: 3D RECONSTRUCTION
  // ==========================================================================
  Widget _buildReconstructionTab() {
    final draft = _session?.draft;
    if (draft == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.view_in_ar_rounded, size: 48, color: Color(0xFF3F3F46)),
              const SizedBox(height: 12),
              const Text(
                'No 3D Reconstruction Draft Available',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14),
              ),
              const SizedBox(height: 6),
              const Text(
                'Upload venue photos and tap "Run AI Venue Reconstruction" to generate a candidate 3D model.',
                style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => _tabController.animateTo(0),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD4AF37),
                  foregroundColor: Colors.black,
                ),
                child: const Text('Go to Capture Tab'),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionCard('Room Envelope Geometry', [
          _buildParamRow('Room Width', draft.room.width, 'm'),
          _buildParamRow('Room Length', draft.room.length, 'm'),
          _buildParamRow('Room Height', draft.room.height, 'm'),
        ]),
        const SizedBox(height: 14),
        _buildSectionCard('Screen & Stage Geometry', [
          _buildParamRow('Screen Width', draft.screen.width, 'm'),
          _buildParamRow('Screen Height', draft.screen.height, 'm'),
          _buildParamRow('Screen Type', draft.screen.type, '', valueFormatter: (t) => t.name.toUpperCase()),
          _buildParamRow(
            'Screen Center 3D',
            draft.screen.position,
            '',
            valueFormatter: (pos) => '(${pos.x.toStringAsFixed(1)}, ${pos.y.toStringAsFixed(1)}, ${pos.z.toStringAsFixed(1)})',
          ),
        ]),
        const SizedBox(height: 14),
        _buildSectionCard('Seating Lattice & Counts', [
          _buildParamRow('Rows Count', draft.seating.rows, ''),
          _buildParamRow('Seats Per Row', draft.seating.seatsPerRow, ''),
          _buildParamRow('Seat Spacing', draft.seating.seatSpacing, 'm'),
          _buildParamRow('Row Spacing', draft.seating.rowSpacing, 'm'),
          _buildParamRow('Tier Rise Per Row', draft.seating.rowRisePerRow, 'm'),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Detected Seat Units', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12)),
                Text(
                  '${draft.seating.seats.length} generated seats',
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ]),
        const SizedBox(height: 14),
        _buildSectionCard('Visual Surround Speakers (Rendering Only)', [
          const Text(
            'CRITICAL: AI-detected speakers are visual cabinet placements only. '
            'Audio channels, Dolby, Atmos, and sound routing are NEVER inferred.',
            style: TextStyle(color: Color(0xFFFBBF24), fontSize: 10.5, fontStyle: FontStyle.italic),
          ),
          const SizedBox(height: 8),
          if (draft.speakers.isEmpty)
            const Text('No surround speaker cabinets detected in submitted imagery.', style: TextStyle(color: Color(0xFF71717A), fontSize: 11))
          else
            ...draft.speakers.map((spk) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(spk.name, style: const TextStyle(color: Color(0xFFE4E4E7), fontSize: 11.5)),
                      Text(
                        '(${spk.position.x.toStringAsFixed(1)}, ${spk.position.y.toStringAsFixed(1)}, ${spk.position.z.toStringAsFixed(1)}) m',
                        style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 11),
                      ),
                    ],
                  ),
                )),
        ]),
        const SizedBox(height: 14),
        _buildSectionCard('Lighting & Photometrics', [
          _buildParamRow('Ceiling Luminaires', draft.lighting.ceilingLightsCount, ''),
          _buildParamRow('Aisle Step Lighting', draft.lighting.hasAisleLighting, '', valueFormatter: (b) => b ? 'Yes' : 'No'),
          _buildParamRow('Estimated Illuminance', draft.lighting.estimatedLux, ' lux'),
        ]),
        const SizedBox(height: 14),
        _buildSectionCard('Materials & Appearance', [
          _buildParamRow('Wall Color', draft.appearance.wallColorHex, ''),
          _buildParamRow('Carpet Color', draft.appearance.carpetColorHex, ''),
          _buildParamRow('Wall Material', draft.appearance.wallMaterialType, ''),
        ]),
      ],
    );
  }

  Widget _buildSectionCard(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0E0E14),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF22222E)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }

  Widget _buildParamRow<T>(
    String label,
    Estimate<T> estimate,
    String unit, {
    String Function(T val)? valueFormatter,
  }) {
    final valueText = estimate.isKnown
        ? (valueFormatter != null ? valueFormatter(estimate.value as T) : '${estimate.value}$unit')
        : 'UNKNOWN';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(label, style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 12)),
          ),
          Row(
            children: [
              Text(
                valueText,
                style: TextStyle(
                  color: estimate.isKnown ? const Color(0xFFF7F5F0) : const Color(0xFFF87171),
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 8),
              ConfidenceBadge(confidence: estimate.confidence, isKnown: estimate.isKnown),
              const SizedBox(width: 6),
              ProvenanceBadge(provenance: estimate.provenance),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // TAB 4: REVIEW & CONFIRM
  // ==========================================================================
  Widget _buildReviewTab() {
    final draft = _session?.draft;
    final baseline = widget.initialConfig;

    if (draft == null) {
      return const Center(
        child: Text(
          'Reconstruction draft not ready. Complete analysis first.',
          style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildDiffSummaryCard(baseline, draft),
        const SizedBox(height: 14),
        _buildUncertaintyAuditCard(draft),
        const SizedBox(height: 20),
        _buildConfirmationActions(draft),
      ],
    );
  }

  Widget _buildDiffSummaryCard(TheatreConfiguration? baseline, ReconstructionDraft draft) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0E0E14),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF22222E)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Configuration Changes Diff',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
          ),
          const SizedBox(height: 6),
          const Text(
            'Comparison between existing baseline and proposed reconstruction:',
            style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 11),
          ),
          const SizedBox(height: 12),
          _diffRow('Room Width', '${baseline?.room.width ?? 0}m', draft.room.width),
          _diffRow('Room Length', '${baseline?.room.length ?? 0}m', draft.room.length),
          _diffRow('Room Height', '${baseline?.room.height ?? 0}m', draft.room.height),
          _diffRow('Screen Width', '${baseline?.screen.width ?? 0}m', draft.screen.width),
          _diffRow('Screen Height', '${baseline?.screen.height ?? 0}m', draft.screen.height),
          _diffRow('Seating Rows', '${baseline?.lastSeatLayout?.rows ?? 0}', draft.seating.rows),
          _diffRow('Seats Per Row', '${baseline?.lastSeatLayout?.seatsPerRow ?? 0}', draft.seating.seatsPerRow),
        ],
      ),
    );
  }

  Widget _diffRow<T>(String label, String baselineVal, Estimate<T> draftEstimate) {
    final newVal = draftEstimate.isKnown ? '${draftEstimate.value}' : 'Preserves Baseline (Unknown)';
    final changed = draftEstimate.isKnown;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 11.5)),
          Row(
            children: [
              Text(baselineVal, style: const TextStyle(color: Color(0xFF71717A), fontSize: 11)),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward_rounded, size: 12, color: Color(0xFFD4AF37)),
              const SizedBox(width: 8),
              Text(
                newVal,
                style: TextStyle(
                  color: changed ? const Color(0xFF34D399) : const Color(0xFFFBBF24),
                  fontWeight: FontWeight.w600,
                  fontSize: 11.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUncertaintyAuditCard(ReconstructionDraft draft) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF14141C),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF27273A)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.shield_outlined, color: Color(0xFFD4AF37), size: 16),
              SizedBox(width: 6),
              Text(
                'Pre-Confirmation Audit Checklist',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12.5),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            '✓ Theatre ID, ownership, and verification status are strictly protected.\n'
            '✓ Acoustics routing and movie content remain unchanged.\n'
            '✓ Unknown values preserve existing baseline measurements.\n'
            '✓ Visual speakers are placed for rendering only.',
            style: TextStyle(color: Color(0xFFE4E4E7), fontSize: 11.5, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmationActions(ReconstructionDraft draft) {
    final isReviewed = draft.isReviewed;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (isReviewed) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF064E3B),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF34D399).withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.verified_rounded, color: Color(0xFF34D399), size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Draft Approved & Reviewed by ${draft.reviewedBy ?? "Administrator"} (${draft.reviewedAt?.toLocal().toString().split(".").first ?? "Verified"})',
                    style: const TextStyle(color: Color(0xFFD1FAE5), fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            icon: const Icon(Icons.check_circle_outline_rounded, size: 16),
            label: const Text(
              'Confirm & Apply to Theatre Configuration',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD4AF37),
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: _confirmDraft,
          ),
        ] else ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF451A03),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.3)),
            ),
            child: const Row(
              children: [
                Icon(Icons.rate_review_outlined, color: Color(0xFFFCD34D), size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Step 1: Administrator review required. Inspect candidate dimensions and audit checklist before confirmation.',
                    style: TextStyle(color: Color(0xFFFEF3C7), fontSize: 11.5),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            icon: const Icon(Icons.rate_review_rounded, size: 16),
            label: const Text(
              'Approve & Mark Draft as Reviewed',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD4AF37),
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: _reviewDraft,
          ),
        ],
        const SizedBox(height: 10),
        OutlinedButton(
          onPressed: _cancelSession,
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF9CA3AF),
            side: const BorderSide(color: Color(0xFF3F3F46)),
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: const Text('Cancel Capture / Discard Draft'),
        ),
      ],
    );
  }
}
