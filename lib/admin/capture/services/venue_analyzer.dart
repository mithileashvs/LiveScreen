import '../models/models.dart';
import '../../models/theatre_configuration.dart';
import '../../models/screen_config.dart' show Position3, ScreenType;
import '../../models/speaker_model.dart' show SpeakerType;
import '../../models/seat_config.dart' show SeatCategory;

/// Input payload passed to an AI Venue Analyzer or reconstruction worker.
class VenueAnalysisInput {
  final VenueCaptureSession session;
  final List<VenueCaptureMedia> evidence;
  final TheatreConfiguration? baselineConfig;
  final List<VenueCaptureRequest> existingRequests;
  final ReconstructionDraft? previousDraft;

  const VenueAnalysisInput({
    required this.session,
    required this.evidence,
    this.baselineConfig,
    this.existingRequests = const [],
    this.previousDraft,
  });
}

/// Structured outcome of an AI reconstruction analysis pass.
class VenueAnalysisResult {
  final bool isSuccess;
  final ReconstructionDraft? draft;
  final List<VenueCaptureRequest> targetedRequests;
  final List<VenueCaptureObservation> observations;
  final List<String> unresolvedFields;
  final Map<String, String> unresolvedReasons;
  final String? errorMessage;
  final String analyzerName;
  final double overallConfidence;
  final bool isWorkerAvailable;

  const VenueAnalysisResult({
    required this.isSuccess,
    this.draft,
    this.targetedRequests = const [],
    this.observations = const [],
    this.unresolvedFields = const [],
    this.unresolvedReasons = const {},
    this.errorMessage,
    this.analyzerName = 'VenueAnalyzer',
    this.overallConfidence = 0.0,
    this.isWorkerAvailable = true,
  });

  factory VenueAnalysisResult.unavailable({String? reason}) {
    return VenueAnalysisResult(
      isSuccess: false,
      isWorkerAvailable: false,
      analyzerName: 'External GPU Worker (Not Configured)',
      errorMessage: reason ??
          'AI Reconstruction Worker is not configured or offline. '
              'No external GPU/ML worker endpoint is connected. '
              'LiveScreen never embeds neural network weights in the client application.',
      unresolvedFields: const [
        'Room Dimensions',
        'Screen & Stage Geometry',
        'Seating Lattice',
      ],
      unresolvedReasons: const {
        'Room Dimensions': 'Worker unavailable to process geometry.',
        'Screen & Stage Geometry': 'Worker unavailable to detect screen plane.',
        'Seating Lattice': 'Worker unavailable to extract seating rows.',
      },
    );
  }

  factory VenueAnalysisResult.failed(String message, {String? analyzerName}) {
    return VenueAnalysisResult(
      isSuccess: false,
      isWorkerAvailable: true,
      analyzerName: analyzerName ?? 'VenueAnalyzer',
      errorMessage: message,
    );
  }
}

/// Abstract contract for venue analysis and 3D reconstruction workers.
///
/// Principles:
/// 1. Decouples Flutter client from external ML/GPU reconstruction infrastructure.
/// 2. Never embeds neural network weights, CUDA runtimes, or API secrets in Flutter.
/// 3. "AI assists reconstruction; it does not silently guess unknown measurements."
/// 4. When evidence is insufficient, values remain [Estimate.unknown] and targeted
///    evidence requests are generated.
abstract class VenueAnalyzer {
  String get name;
  bool get isAvailable;

  Future<VenueAnalysisResult> analyze(VenueAnalysisInput input);
}

/// Default production analyzer when no external GPU worker microservice is connected.
///
/// Honestly informs the theatre admin that the worker is unavailable instead of
/// fabricating results.
class UnavailableVenueAnalyzer implements VenueAnalyzer {
  final String? customMessage;

  const UnavailableVenueAnalyzer({this.customMessage});

  @override
  String get name => 'None (External Worker Unconnected)';

  @override
  bool get isAvailable => false;

  @override
  Future<VenueAnalysisResult> analyze(VenueAnalysisInput input) async {
    return VenueAnalysisResult.unavailable(reason: customMessage);
  }
}

/// A simulated failure analyzer for verifying error handling and recovery.
class FailingVenueAnalyzer implements VenueAnalyzer {
  final String errorMessage;

  const FailingVenueAnalyzer({
    this.errorMessage = 'External GPU worker memory allocation failed during mesh reconstruction.',
  });

  @override
  String get name => 'Failing Test Worker';

  @override
  bool get isAvailable => true;

  @override
  Future<VenueAnalysisResult> analyze(VenueAnalysisInput input) async {
    return VenueAnalysisResult.failed(errorMessage, analyzerName: name);
  }
}

/// DETERMINISTIC TEST FIXTURE ONLY: [MockVenueAnalyzer] is strictly intended for
/// automated test suites and local development simulations. It is NOT a production
/// reconstruction pipeline and must NEVER be silently used as a production path.
///
/// Predefined geometry values (e.g., room width 22.4m, room length 28.5m, room height 8.2m,
/// screen width 16.2m, screen height 7.2m, seat spacing 0.65m, row spacing 1.15m) are
/// deterministic test fixtures only, designed to verify state machine transitions, targeted
/// request cycles, confidence tracking, and review mapping.
///
/// Production environments default to [UnavailableVenueAnalyzer] unless an external
/// asynchronous GPU reconstruction worker microservice or daemon is explicitly connected.
class MockVenueAnalyzer implements VenueAnalyzer {
  @override
  String get name => 'LiveScreen Vision Reconstruction Worker (Mock)';

  @override
  bool get isAvailable => true;

  @override
  Future<VenueAnalysisResult> analyze(VenueAnalysisInput input) async {
    final evidence = input.evidence;
    final sessionId = input.session.id;
    final theatreId = input.session.theatreId;

    if (evidence.isEmpty) {
      return VenueAnalysisResult(
        isSuccess: true,
        analyzerName: name,
        overallConfidence: 0.0,
        unresolvedFields: const [
          'Room Dimensions',
          'Screen Geometry',
          'Seating Layout',
          'Speaker Placement',
        ],
        unresolvedReasons: const {
          'Room Dimensions': 'No venue imagery or measurements uploaded.',
          'Screen Geometry': 'Front wall and screen are not visible.',
          'Seating Layout': 'No seating area photographs provided.',
          'Speaker Placement': 'No wall or ceiling views provided.',
        },
        targetedRequests: [
          VenueCaptureRequest(
            id: 'req-initial-photo',
            sessionId: sessionId,
            theatreId: theatreId,
            target: 'Front Wall & Screen',
            reason: 'Initial visual evidence is required to identify the auditorium orientation and screen stage.',
            requiredEvidenceType: EvidenceType.photo,
            instruction: 'Take a wide photo from the centre aisle facing directly toward the screen and front wall.',
            priority: RequestPriority.critical,
            createdAt: DateTime.now(),
          ),
        ],
      );
    }

    // Partition evidence by category and type
    final frontWallMedia = evidence.where((e) =>
        e.category == EvidenceCategory.frontWall ||
        e.category == EvidenceCategory.screenStage ||
        e.filename.toLowerCase().contains('front') ||
        e.filename.toLowerCase().contains('screen')).toList();

    final rearWallMedia = evidence.where((e) =>
        e.category == EvidenceCategory.rearWall ||
        e.filename.toLowerCase().contains('rear') ||
        e.filename.toLowerCase().contains('back')).toList();

    final seatingMedia = evidence.where((e) =>
        e.category == EvidenceCategory.seating ||
        e.filename.toLowerCase().contains('seat')).toList();

    final measurementMedia = evidence.where((e) =>
        e.type == EvidenceType.measurement ||
        e.category == EvidenceCategory.measurement ||
        e.metadata.containsKey('distance_meters') ||
        e.metadata.containsKey('value_meters')).toList();

    final speakerMedia = evidence.where((e) =>
        e.category == EvidenceCategory.speakers ||
        e.category == EvidenceCategory.leftWall ||
        e.category == EvidenceCategory.rightWall ||
        e.filename.toLowerCase().contains('speaker')).toList();

    final lightingMedia = evidence.where((e) =>
        e.category == EvidenceCategory.lighting ||
        e.category == EvidenceCategory.ceiling).toList();

    final materialMedia = evidence.where((e) =>
        e.category == EvidenceCategory.materialsColors).toList();

    final targetedRequests = <VenueCaptureRequest>[];
    final observations = <VenueCaptureObservation>[];
    final unresolvedFields = <String>[];
    final unresolvedReasons = <String, String>{};

    // Track which existing requests have been fulfilled
    for (final req in input.existingRequests) {
      if (req.status == RequestStatus.pending) {
        bool fulfilled = false;
        String? matchingEvidenceId;

        if (req.requiredEvidenceType == EvidenceType.measurement && measurementMedia.isNotEmpty) {
          fulfilled = true;
          matchingEvidenceId = measurementMedia.first.id;
        } else if (req.target.toLowerCase().contains('rear') && rearWallMedia.isNotEmpty) {
          fulfilled = true;
          matchingEvidenceId = rearWallMedia.first.id;
        } else if (req.target.toLowerCase().contains('front') && frontWallMedia.isNotEmpty) {
          fulfilled = true;
          matchingEvidenceId = frontWallMedia.first.id;
        }

        if (fulfilled && matchingEvidenceId != null) {
          targetedRequests.add(req.fulfill(matchingEvidenceId));
        } else {
          targetedRequests.add(req);
        }
      } else {
        targetedRequests.add(req);
      }
    }

    // 1. ROOM RECONSTRUCTION
    Estimate<double> roomWidth;
    Estimate<double> roomLength;
    Estimate<double> roomHeight;

    if (frontWallMedia.isNotEmpty) {
      final frontIds = frontWallMedia.map((m) => m.id).toList();
      roomWidth = Estimate<double>.aiEstimated(
        22.4,
        confidence: 0.86,
        source: 'front_wall_semantic_segmentation',
        evidenceIds: frontIds,
        note: 'Triangulated from lateral corners of front wall',
      );
      roomHeight = Estimate<double>.aiEstimated(
        8.2,
        confidence: 0.82,
        source: 'vertical_wall_boundary',
        evidenceIds: frontIds,
        note: 'Measured from floor-wall junction to ceiling beam',
      );
      observations.add(VenueCaptureObservation(
        id: 'obs-front-wall',
        sessionId: sessionId,
        theatreId: theatreId,
        featureType: 'front_wall_boundary',
        description: 'Detected front wall boundary and ceiling juncture',
        confidence: 0.86,
        evidenceIds: frontIds,
        observedAt: DateTime.now(),
      ));
    } else {
      roomWidth = const Estimate<double>.unknown(
        note: 'Front wall not visible; cannot estimate room width',
      );
      roomHeight = const Estimate<double>.unknown(
        note: 'Front wall not visible; cannot estimate room height',
      );
      unresolvedFields.add('Room Width');
      unresolvedReasons['Room Width'] = 'Front wall is not captured in evidence.';
      unresolvedFields.add('Room Height');
      unresolvedReasons['Room Height'] = 'Vertical wall junctions not visible.';

      if (!_hasActiveRequestFor(targetedRequests, 'Front Wall')) {
        targetedRequests.add(VenueCaptureRequest(
          id: 'req-room-front',
          sessionId: sessionId,
          theatreId: theatreId,
          target: 'Front Wall & Screen',
          reason: 'Front wall corners are required to determine room width and ceiling clearance.',
          requiredEvidenceType: EvidenceType.photo,
          instruction: 'Take a photo from the centre aisle facing the front wall and screen.',
          priority: RequestPriority.high,
          createdAt: DateTime.now(),
        ));
      }
    }

    if (rearWallMedia.isNotEmpty) {
      final rearIds = rearWallMedia.map((m) => m.id).toList();
      roomLength = Estimate<double>.aiEstimated(
        28.5,
        confidence: 0.85,
        source: 'dual_perspective_reprojection',
        evidenceIds: rearIds,
        note: 'Reconstructed using front-to-rear perspective baseline',
      );
      observations.add(VenueCaptureObservation(
        id: 'obs-rear-wall',
        sessionId: sessionId,
        theatreId: theatreId,
        featureType: 'rear_wall_boundary',
        description: 'Detected rear wall exit frame and projection window',
        confidence: 0.85,
        evidenceIds: rearIds,
        observedAt: DateTime.now(),
      ));
    } else {
      roomLength = const Estimate<double>.unknown(
        note: 'Rear wall not visible in submitted imagery',
      );
      unresolvedFields.add('Room Length');
      unresolvedReasons['Room Length'] = 'The rear wall is not visible in submitted images.';

      if (!_hasActiveRequestFor(targetedRequests, 'Rear Wall')) {
        targetedRequests.add(VenueCaptureRequest(
          id: 'req-room-length',
          sessionId: sessionId,
          theatreId: theatreId,
          target: 'Room Length & Rear Wall',
          reason: 'The rear wall is not visible in the submitted images. Optical depth cannot determine venue length without back boundary.',
          requiredEvidenceType: EvidenceType.photo,
          instruction: 'Take one photo from the centre of the front seating area facing the rear wall. Include the floor and both side walls if possible.',
          priority: RequestPriority.high,
          createdAt: DateTime.now(),
        ));
      }
    }

    // 2. SCALE CALIBRATION (MEASUREMENT)
    final hasMeasurement = measurementMedia.isNotEmpty;
    if (hasMeasurement) {
      final m = measurementMedia.first;
      final measuredVal = (m.metadata['distance_meters'] ??
          m.metadata['value_meters'] ??
          m.metadata['measurement']) as num?;
      if (measuredVal != null) {
        observations.add(VenueCaptureObservation(
          id: 'obs-metric-scale',
          sessionId: sessionId,
          theatreId: theatreId,
          featureType: 'scale_calibration',
          description: 'Metric ground truth supplied via on-site measurement',
          confidence: 1.0,
          evidenceIds: [m.id],
          data: {'measured_meters': measuredVal.toDouble()},
          observedAt: DateTime.now(),
        ));
      }
    } else {
      unresolvedFields.add('Metric Scale Calibration');
      unresolvedReasons['Metric Scale Calibration'] = 'Physical distance measurement is required to eliminate focal length scale ambiguity.';

      if (!_hasActiveRequestFor(targetedRequests, 'Metric Scale')) {
        targetedRequests.add(VenueCaptureRequest(
          id: 'req-scale-calibration',
          sessionId: sessionId,
          theatreId: theatreId,
          target: 'Metric Scale Calibration',
          reason: 'Visual evidence is insufficient to establish metric scale. Ambiguity exists between camera focal length and venue dimensions.',
          requiredEvidenceType: EvidenceType.measurement,
          instruction: 'Measure the distance from the screen/front wall to the first row in metres using a laser distance meter or tape.',
          priority: RequestPriority.critical,
          createdAt: DateTime.now(),
        ));
      }
    }

    // 3. SCREEN RECONSTRUCTION
    DraftScreen screen;
    if (frontWallMedia.isNotEmpty) {
      final frontIds = frontWallMedia.map((m) => m.id).toList();
      screen = DraftScreen(
        width: Estimate<double>.aiEstimated(
          16.2,
          confidence: 0.88,
          source: 'screen_bezel_detector',
          evidenceIds: frontIds,
        ),
        height: Estimate<double>.aiEstimated(
          7.2,
          confidence: 0.88,
          source: 'screen_bezel_detector',
          evidenceIds: frontIds,
        ),
        position: Estimate<Position3>.aiEstimated(
          Position3(x: 0.0, y: 1.5, z: 0.5),
          confidence: 0.85,
          source: 'screen_plane_fitter',
          evidenceIds: frontIds,
        ),
        rotationY: Estimate<double>.aiEstimated(
          0.0,
          confidence: 0.95,
          source: 'screen_plane_normal',
          evidenceIds: frontIds,
        ),
        type: Estimate<ScreenType>.aiEstimated(
          ScreenType.standard,
          confidence: 0.90,
          source: 'screen_curvature_analyzer',
          evidenceIds: frontIds,
        ),
      );
    } else {
      screen = const DraftScreen();
      unresolvedFields.add('Screen Dimensions');
      unresolvedReasons['Screen Dimensions'] = 'Screen bezel and frame not visible.';
    }

    // 4. SEATING RECONSTRUCTION
    DraftSeatLattice seating;
    if (seatingMedia.isNotEmpty || frontWallMedia.isNotEmpty) {
      final seatEvidenceIds = [
        ...seatingMedia.map((m) => m.id),
        ...frontWallMedia.map((m) => m.id),
      ];

      final rowsEst = Estimate<int>.aiEstimated(
        12,
        confidence: 0.84,
        source: 'seat_lattice_row_counter',
        evidenceIds: seatEvidenceIds,
      );
      final seatsPerRowEst = Estimate<int>.aiEstimated(
        16,
        confidence: 0.82,
        source: 'seat_lattice_col_counter',
        evidenceIds: seatEvidenceIds,
      );

      // Only estimate physical spacing if scale calibration is established
      final Estimate<double> seatSpacingEst;
      final Estimate<double> rowSpacingEst;
      final Estimate<double> rowRiseEst;

      if (hasMeasurement) {
        seatSpacingEst = Estimate<double>.aiEstimated(
          0.65,
          confidence: 0.80,
          source: 'calibrated_seat_lattice',
          evidenceIds: seatEvidenceIds,
        );
        rowSpacingEst = Estimate<double>.aiEstimated(
          1.15,
          confidence: 0.80,
          source: 'calibrated_seat_lattice',
          evidenceIds: seatEvidenceIds,
        );
        rowRiseEst = Estimate<double>.aiEstimated(
          0.18,
          confidence: 0.78,
          source: 'tier_riser_profiler',
          evidenceIds: seatEvidenceIds,
        );
      } else {
        seatSpacingEst = const Estimate<double>.unknown(
          note: 'Requires metric scale calibration measurement',
        );
        rowSpacingEst = const Estimate<double>.unknown(
          note: 'Requires metric scale calibration measurement',
        );
        rowRiseEst = const Estimate<double>.unknown(
          note: 'Requires metric scale calibration measurement',
        );
        unresolvedFields.add('Seat Spacing & Row Spacing');
        unresolvedReasons['Seat Spacing & Row Spacing'] = 'Cannot compute metric spacing without scale measurement.';
      }

      final List<DraftSeat> draftSeats;
      if (hasMeasurement) {
        // Physical seat positions are generated ONLY when metric scale is verified
        draftSeats = [];
        for (int r = 1; r <= 12; r++) {
          final rowLetter = String.fromCharCode(64 + r); // A, B, C...
          for (int s = 1; s <= 16; s++) {
            final x = (s - 8.5) * 0.65;
            final z = 6.0 + (r * 1.15);
            final y = (r - 1) * 0.18;
            draftSeats.add(DraftSeat(
              id: 'seat-$rowLetter-$s',
              row: rowLetter,
              number: s,
              position: Position3(x: x, y: y, z: z),
              rotationY: 0.0,
              category: SeatCategory.standard,
              confidence: 0.82,
              evidenceIds: seatEvidenceIds,
            ));
          }
        }
      } else {
        // Scale is unknown: do NOT invent physical seat positions with arbitrary metre values!
        // If baseline configuration has existing seating geometry, preserve it.
        if (input.baselineConfig != null && input.baselineConfig!.seats.isNotEmpty) {
          draftSeats = input.baselineConfig!.seats
              .map((s) => DraftSeat(
                    id: 'baseline-${s.row}-${s.number}',
                    row: s.row,
                    number: s.number,
                    position: Position3(x: s.position.x, y: s.position.y, z: s.position.z),
                    rotationY: s.rotationY,
                    category: s.category,
                    confidence: 1.0,
                    evidenceIds: const [],
                  ))
              .toList();
        } else {
          draftSeats = const [];
        }
      }

      seating = DraftSeatLattice(
        rows: rowsEst,
        seatsPerRow: seatsPerRowEst,
        seatSpacing: seatSpacingEst,
        rowSpacing: rowSpacingEst,
        rowRisePerRow: rowRiseEst,
        seats: draftSeats,
      );
    } else {
      seating = const DraftSeatLattice();
      unresolvedFields.add('Seating Lattice');
      unresolvedReasons['Seating Lattice'] = 'No seating area imagery provided.';
    }

    // 5. VISUAL SPEAKERS (Visual cabinet only! Strictly requires speaker evidence)
    final draftSpeakers = <DraftVisualSpeaker>[];
    if (speakerMedia.isNotEmpty) {
      final speakerEvidenceIds = speakerMedia.map((m) => m.id).toList();
      draftSpeakers.addAll([
        DraftVisualSpeaker(
          id: 'spk-left-1',
          name: 'Left Wall Speaker 1',
          position: Position3(x: -11.0, y: 3.5, z: 8.0),
          visualCabinetType: SpeakerType.sideSurround,
          confidence: 0.78,
          evidenceIds: speakerEvidenceIds,
        ),
        DraftVisualSpeaker(
          id: 'spk-left-2',
          name: 'Left Wall Speaker 2',
          position: Position3(x: -11.0, y: 3.5, z: 16.0),
          visualCabinetType: SpeakerType.sideSurround,
          confidence: 0.78,
          evidenceIds: speakerEvidenceIds,
        ),
        DraftVisualSpeaker(
          id: 'spk-right-1',
          name: 'Right Wall Speaker 1',
          position: Position3(x: 11.0, y: 3.5, z: 8.0),
          visualCabinetType: SpeakerType.sideSurround,
          confidence: 0.78,
          evidenceIds: speakerEvidenceIds,
        ),
        DraftVisualSpeaker(
          id: 'spk-right-2',
          name: 'Right Wall Speaker 2',
          position: Position3(x: 11.0, y: 3.5, z: 16.0),
          visualCabinetType: SpeakerType.sideSurround,
          confidence: 0.78,
          evidenceIds: speakerEvidenceIds,
        ),
      ]);
    } else {
      unresolvedFields.add('Speaker Placements');
      unresolvedReasons['Speaker Placements'] =
          'No speaker or wall perimeter photos provided. Physical visual cabinets remain unobserved.';
    }

    // 6. LIGHTING
    DraftLighting lighting;
    if (lightingMedia.isNotEmpty) {
      final lightIds = lightingMedia.map((m) => m.id).toList();
      lighting = DraftLighting(
        ceilingLightsCount: Estimate<int>.aiEstimated(
          8,
          confidence: 0.75,
          source: 'overhead_luminaire_detector',
          evidenceIds: lightIds,
        ),
        aisleLightsCount: Estimate<int>.aiEstimated(
          12,
          confidence: 0.80,
          source: 'aisle_step_light_detector',
          evidenceIds: lightIds,
        ),
        hasAisleLighting: Estimate<bool>.aiEstimated(
          true,
          confidence: 0.85,
          source: 'aisle_step_light_detector',
          evidenceIds: lightIds,
        ),
        estimatedLux: Estimate<double>.aiEstimated(
          45.0,
          confidence: 0.70,
          source: 'photometric_estimator',
          evidenceIds: lightIds,
        ),
      );
    } else {
      lighting = const DraftLighting();
    }

    // 7. MATERIALS & APPEARANCE
    DraftAppearance appearance;
    if (materialMedia.isNotEmpty || frontWallMedia.isNotEmpty) {
      final matIds = materialMedia.isNotEmpty
          ? materialMedia.map((m) => m.id).toList()
          : frontWallMedia.map((m) => m.id).toList();
      appearance = DraftAppearance(
        wallColorHex: Estimate<String>.aiEstimated(
          '#1C1C24',
          confidence: 0.82,
          source: 'wall_palette_extractor',
          evidenceIds: matIds,
        ),
        carpetColorHex: Estimate<String>.aiEstimated(
          '#121218',
          confidence: 0.80,
          source: 'carpet_palette_extractor',
          evidenceIds: matIds,
        ),
        wallMaterialType: Estimate<String>.aiEstimated(
          'acoustic_fabric_panel',
          confidence: 0.78,
          source: 'material_texture_classifier',
          evidenceIds: matIds,
        ),
      );
    } else {
      appearance = const DraftAppearance();
    }

    // Compute overall confidence score
    final hasActiveCritical = targetedRequests
        .any((r) => r.status == RequestStatus.pending && r.priority == RequestPriority.critical);
    final hasActiveHigh = targetedRequests
        .any((r) => r.status == RequestStatus.pending && r.priority == RequestPriority.high);

    double overallConfidence;
    if (hasActiveCritical) {
      overallConfidence = 0.52;
    } else if (hasActiveHigh) {
      overallConfidence = 0.68;
    } else {
      overallConfidence = 0.88;
    }

    final draft = ReconstructionDraft(
      id: 'draft-${DateTime.now().millisecondsSinceEpoch}',
      sessionId: sessionId,
      theatreId: theatreId,
      createdAt: DateTime.now(),
      room: DraftRoomGeometry(
        width: roomWidth,
        length: roomLength,
        height: roomHeight,
      ),
      screen: screen,
      seating: seating,
      speakers: draftSpeakers,
      lighting: lighting,
      appearance: appearance,
      overallConfidence: overallConfidence,
      pipeline: DraftPipelineMetadata(
        pipelineVersion: '2.0.0-phase2',
        workerVersion: 'mock-reconstruction-v2.1',
        reconstructedAt: DateTime.now(),
        notes: 'Iterative multi-view reconstruction with scale calibration.',
      ),
    );

    return VenueAnalysisResult(
      isSuccess: true,
      draft: draft,
      targetedRequests: targetedRequests,
      observations: observations,
      unresolvedFields: unresolvedFields,
      unresolvedReasons: unresolvedReasons,
      analyzerName: name,
      overallConfidence: overallConfidence,
    );
  }

  bool _hasActiveRequestFor(List<VenueCaptureRequest> requests, String targetSubstring) {
    return requests.any((r) =>
        r.status == RequestStatus.pending &&
        r.target.toLowerCase().contains(targetSubstring.toLowerCase()));
  }
}

/// Active global analyzer instance.
/// Defaults to [UnavailableVenueAnalyzer] so client honestly reports unconfigured state.
VenueAnalyzer venueAnalyzer = const UnavailableVenueAnalyzer();

/// Injects a custom or mock analyzer (for testing and controlled demonstrations).
void setVenueAnalyzer(VenueAnalyzer analyzer) {
  venueAnalyzer = analyzer;
}

/// Resets to default [UnavailableVenueAnalyzer].
void resetVenueAnalyzer() {
  venueAnalyzer = const UnavailableVenueAnalyzer();
}
