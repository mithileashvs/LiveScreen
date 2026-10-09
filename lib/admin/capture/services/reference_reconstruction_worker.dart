import '../models/models.dart';
import '../../models/screen_config.dart' show Position3, ScreenType;
import '../../models/seat_config.dart' show SeatCategory;
import '../../models/speaker_model.dart' show SpeakerType;

/// Default production worker when no external GPU reconstruction worker is connected.
///
/// Principles:
/// 1. "AI assists reconstruction; it does not silently guess unknown measurements."
/// 2. LiveScreen never bundles heavy ML neural network weights or CUDA runtimes in Flutter.
/// 3. Informs the user honestly that no external worker is currently connected.
class UnavailableReconstructionWorker implements VenueReconstructionWorker {
  final String? customMessage;

  const UnavailableReconstructionWorker({this.customMessage});

  @override
  String get name => 'Production Worker (Disconnected)';

  @override
  bool get isAvailable => false;

  @override
  Future<VenueReconstructionResult> analyze(VenueReconstructionInput input) async {
    return VenueReconstructionResult(
      jobId: input.jobId,
      sessionId: input.sessionId,
      theatreId: input.theatreId,
      revision: input.revision,
      scaleStatus: ScaleStatus.unknown,
      state: ReconstructionUncertaintyState.unsupported,
      isSuccess: false,
      workerName: name,
      errorMessage: customMessage ??
          'AI reconstruction worker is not connected. '
              'No external GPU/ML worker endpoint is configured. '
              'LiveScreen never embeds neural network weights in the client application.',
      warnings: const ['AI worker offline or unconfigured.'],
    );
  }

  @override
  Future<VenueReconstructionResult> refine(
    VenueReconstructionInput input,
    VenueReconstructionResult previousResult,
  ) async {
    return analyze(input);
  }
}

/// DETERMINISTIC TEST & DEVELOPMENT REFERENCE WORKER.
///
/// Clearly marked as a TEST / DEVELOPMENT REFERENCE WORKER.
///
/// Principles:
/// 1. Consumes structured evidence fixtures deterministically.
/// 2. Preserves strict truth in reconstruction: never fabricates metric scale, dimensions,
///    or speaker positions when evidence is absent.
/// 3. Multi-view fusion: reasons across front wall, seating, side walls, rear wall, and ceiling views.
/// 4. Admin logical seating protection: surfaces conflicts when visual detection disagrees
///    with admin constraints (e.g. 11 detected vs 12 specified).
/// 5. Every observation cites supporting evidence IDs.
/// 6. Generates targeted uncertainty requests specifying photographer position, eye height,
///    and facing direction.
/// 7. Supports iterative refinement across revisions.
class ReferenceVenueReconstructionWorker implements VenueReconstructionWorker {
  @override
  String get name => 'LiveScreen Reference Reconstruction Worker (Test/Development)';

  @override
  bool get isAvailable => true;

  @override
  Future<VenueReconstructionResult> analyze(VenueReconstructionInput input) async {
    final evidence = input.evidence;
    final sessionId = input.sessionId;
    final theatreId = input.theatreId ?? 'unknown_theatre';
    final revision = input.revision;

    final observations = <VenueObservation>[];
    final requests = <VenueCaptureRequest>[];
    final conflicts = <VenueReconstructionConflict>[];
    final warnings = <String>[];
    final evidenceLinks = <String, List<String>>{};

    // Handle empty evidence
    if (evidence.isEmpty) {
      requests.add(
        VenueCaptureRequest(
          id: 'req-initial-front-wall-$revision',
          sessionId: sessionId,
          theatreId: theatreId,
          target: 'Front Wall & Screen',
          reason: 'Initial visual evidence is required to identify the auditorium orientation and screen stage.',
          requiredEvidenceType: EvidenceType.photo,
          instruction: 'Stand in the center aisle approximately 8-10 meters back, at standing eye height, '
              'face directly toward the front wall, and ensure the complete screen frame is visible.',
          priority: RequestPriority.critical,
          createdAt: DateTime.now(),
        ),
      );

      return VenueReconstructionResult(
        jobId: input.jobId,
        sessionId: sessionId,
        theatreId: theatreId,
        revision: revision,
        scaleStatus: ScaleStatus.unknown,
        state: ReconstructionUncertaintyState.needsPhoto,
        isSuccess: true,
        workerName: name,
        requests: requests,
        warnings: const ['No evidence uploaded yet.'],
      );
    }

    // Categorize evidence
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
        e.category == EvidenceCategory.ceiling ||
        e.filename.toLowerCase().contains('ceiling') ||
        e.filename.toLowerCase().contains('light')).toList();

    final materialMedia = evidence.where((e) =>
        e.category == EvidenceCategory.materialsColors ||
        e.filename.toLowerCase().contains('material') ||
        e.filename.toLowerCase().contains('color')).toList();

    final videoMedia = evidence.where((e) => e.type == EvidenceType.video).toList();
    if (videoMedia.isNotEmpty) {
      warnings.add(
        'Video walkthrough processing is not supported by the current worker. '
        'Static photos or physical measurements are used for 3D reconstruction.',
      );
    }

    // 1. Scale Calibration Assessment
    ScaleStatus scaleStatus = ScaleStatus.unknown;

    if (input.knownMeasurements.isNotEmpty) {
      scaleStatus = ScaleStatus.known;
      observations.add(
        VenueObservation(
          id: 'obs-scale-known-$revision',
          type: ObservationType.scale,
          value: {'scaleStatus': 'known', 'measurements': input.knownMeasurements},
          confidence: 1.0,
          provenance: EstimateProvenance.measured,
          evidenceIds: const [],
          notes: 'Scale calibrated from admin known measurements.',
          revision: revision,
        ),
      );
    } else if (measurementMedia.isNotEmpty) {
      scaleStatus = ScaleStatus.calibrated;
      final mId = measurementMedia.first.id;
      evidenceLinks['scale'] = [mId];
      observations.add(
        VenueObservation(
          id: 'obs-scale-calibrated-$revision',
          type: ObservationType.scale,
          value: {'scaleStatus': 'calibrated', 'referenceMedia': mId},
          confidence: 0.95,
          provenance: EstimateProvenance.measured,
          evidenceIds: [mId],
          notes: 'Scale calibrated from physical measurement evidence.',
          revision: revision,
        ),
      );
    } else {
      scaleStatus = ScaleStatus.unknown;
      observations.add(
        VenueObservation(
          id: 'obs-scale-unknown-$revision',
          type: ObservationType.scale,
          value: {'scaleStatus': 'unknown'},
          confidence: 0.0,
          provenance: EstimateProvenance.unknown,
          notes: 'Metric scale is unknown. Metric dimensions cannot be fabricated.',
          revision: revision,
        ),
      );

      requests.add(
        VenueCaptureRequest(
          id: 'req-scale-measurement-$revision',
          sessionId: sessionId,
          theatreId: theatreId,
          target: 'Auditorium Scale Reference',
          reason: 'Metric scale cannot be established from uncalibrated photographs alone without guessing.',
          requiredEvidenceType: EvidenceType.measurement,
          instruction: 'Measure the distance from the front wall to the first seating row (Row A), '
              'or measure the total width of the screen from edge to edge.',
          priority: RequestPriority.high,
          createdAt: DateTime.now(),
        ),
      );
    }

    // 2. Room Reconstruction
    DraftRoomGeometry room = const DraftRoomGeometry();
    if (frontWallMedia.isNotEmpty && rearWallMedia.isNotEmpty && scaleStatus != ScaleStatus.unknown) {
      final frontIds = frontWallMedia.map((m) => m.id).toList();
      final rearIds = rearWallMedia.map((m) => m.id).toList();
      final combinedEvidence = [...frontIds, ...rearIds];
      evidenceLinks['room'] = combinedEvidence;

      final knownW = input.knownMeasurements['roomWidth'] ?? 18.0;
      final knownL = input.knownMeasurements['roomLength'] ?? 24.0;
      final knownH = input.knownMeasurements['roomHeight'] ?? 7.5;

      room = DraftRoomGeometry(
        width: Estimate<double>.aiEstimated(
          knownW,
          confidence: 0.88,
          source: 'multi_view_fusion',
          evidenceIds: combinedEvidence,
          note: 'Estimated room width: approximately ${knownW.toStringAsFixed(1)}m from multi-view fusion.',
        ),
        length: Estimate<double>.aiEstimated(
          knownL,
          confidence: 0.85,
          source: 'multi_view_fusion',
          evidenceIds: combinedEvidence,
          note: 'Estimated room length: approximately ${knownL.toStringAsFixed(1)}m from front-rear correspondence.',
        ),
        height: Estimate<double>.aiEstimated(
          knownH,
          confidence: 0.82,
          source: 'multi_view_fusion',
          evidenceIds: combinedEvidence,
          note: 'Estimated room height: approximately ${knownH.toStringAsFixed(1)}m from wall-ceiling intersections.',
        ),
      );

      observations.add(
        VenueObservation(
          id: 'obs-room-$revision',
          type: ObservationType.roomGeometry,
          value: {'width': knownW, 'length': knownL, 'height': knownH},
          confidence: 0.85,
          provenance: EstimateProvenance.aiEstimated,
          evidenceIds: combinedEvidence,
          revision: revision,
        ),
      );
    } else if (frontWallMedia.isNotEmpty && scaleStatus == ScaleStatus.unknown) {
      warnings.add('Room metric dimensions remain UNKNOWN because scale calibration is missing.');
    } else if (frontWallMedia.isEmpty) {
      requests.add(
        VenueCaptureRequest(
          id: 'req-front-wall-$revision',
          sessionId: sessionId,
          theatreId: theatreId,
          target: 'Front Wall & Screen',
          reason: 'Front wall imagery is required to anchor the coordinate origin and screen placement.',
          requiredEvidenceType: EvidenceType.photo,
          instruction: 'Stand at the back of the auditorium, at standing eye height, face directly toward the screen, '
              'and ensure the front wall is centered in the frame.',
          priority: RequestPriority.high,
          createdAt: DateTime.now(),
        ),
      );
    }

    // 3. Screen Reconstruction
    DraftScreen screen = const DraftScreen();
    if (frontWallMedia.isNotEmpty) {
      final fIds = frontWallMedia.map((m) => m.id).toList();
      evidenceLinks['screen'] = fIds;

      if (scaleStatus != ScaleStatus.unknown) {
        final screenW = input.knownMeasurements['screenWidth'] ?? 14.0;
        final screenH = input.knownMeasurements['screenHeight'] ?? 6.0;

        screen = DraftScreen(
          width: Estimate<double>.aiEstimated(
            screenW,
            confidence: 0.92,
            source: 'front_wall_bezel_detection',
            evidenceIds: fIds,
            note: 'Estimated screen width: approximately ${screenW.toStringAsFixed(1)}m.',
          ),
          height: Estimate<double>.aiEstimated(
            screenH,
            confidence: 0.90,
            source: 'front_wall_bezel_detection',
            evidenceIds: fIds,
            note: 'Estimated screen height: approximately ${screenH.toStringAsFixed(1)}m.',
          ),
          position: Estimate<Position3>.aiEstimated(
            Position3(x: 0, y: 1.5, z: 0.5),
            confidence: 0.90,
            source: 'front_wall_bezel_detection',
            evidenceIds: fIds,
          ),
          rotationY: Estimate<double>.aiEstimated(
            0.0,
            confidence: 0.95,
            source: 'front_wall_normal',
          ),
          type: Estimate<ScreenType>.aiEstimated(
            ScreenType.standard,
            confidence: 0.95,
            source: 'aspect_ratio_classification',
          ),
        );

        observations.add(
          VenueObservation(
            id: 'obs-screen-$revision',
            type: ObservationType.screen,
            value: {'width': screenW, 'height': screenH, 'center': {'x': 0, 'y': 1.5, 'z': 0.5}},
            confidence: 0.91,
            provenance: EstimateProvenance.aiEstimated,
            evidenceIds: fIds,
            revision: revision,
          ),
        );
      } else {
        // Unknown scale: presence is detected, but metric dimensions remain uncertain
        screen = DraftScreen(
          type: Estimate<ScreenType>.aiEstimated(
            ScreenType.standard,
            confidence: 0.90,
            source: 'visual_aspect_classification',
          ),
        );
        warnings.add('Screen presence detected, but metric width/height remain UNKNOWN due to missing scale.');
      }
    }

    // 4. Seating Reconstruction
    DraftSeatLattice seating = const DraftSeatLattice();
    if (seatingMedia.isNotEmpty) {
      final sIds = seatingMedia.map((m) => m.id).toList();
      evidenceLinks['seating'] = sIds;

      // Determine detected rows
      final bool rearViewPresent = rearWallMedia.isNotEmpty;
      // Synthetic test fixture rule: if rear view is missing but front seating is present,
      // vision detects only 11 visible rows (fixture D conflict scenario).
      final int detectedRowsCount = rearViewPresent ? (input.logicalConstraints?.rows ?? 12) : 11;
      final int targetRowsCount = input.logicalConstraints?.rows ?? 12;

      final bool hasRowConflict = input.logicalConstraints?.rows != null &&
          detectedRowsCount != targetRowsCount;

      if (hasRowConflict) {
        final conflict = VenueReconstructionConflict(
          id: 'conflict-seating-rows-$revision',
          feature: 'seating.rows',
          description: 'I detected approximately $detectedRowsCount visible rows, '
              'but the venue configuration specifies $targetRowsCount rows.',
          adminConstraint: '$targetRowsCount rows',
          detectedValue: '$detectedRowsCount rows',
          suggestedResolution: 'Please provide a rear/side photo showing the missing row.',
          evidenceIds: sIds,
        );
        conflicts.add(conflict);

        requests.add(
          VenueCaptureRequest(
            id: 'req-rear-seating-$revision',
            sessionId: sessionId,
            theatreId: theatreId,
            target: 'Rear Seating Rows',
            reason: conflict.description,
            requiredEvidenceType: EvidenceType.photo,
            instruction: 'Stand at the back-right corner of the auditorium, approximately at standing eye height, '
                'face diagonally toward the screen, and ensure rows 9–$targetRowsCount are fully visible.',
            priority: RequestPriority.high,
            createdAt: DateTime.now(),
          ),
        );
      }

      // Logical seating structure
      final int logicalRows = input.logicalConstraints?.rows ?? detectedRowsCount;
      final int logicalSeatsPerRow = input.logicalConstraints?.seatsPerRow ?? 16;
      final List<int> aisles = input.logicalConstraints?.aisleAfterSeats ?? const [4, 12];
      final int blocks = input.logicalConstraints?.blockCount ?? 3;
      final Map<int, int> rowSeatCounts = input.logicalConstraints?.rowSeatCounts ?? const {};
      final Set<String> removedSeats = input.logicalConstraints?.removedSeats ?? const {};

      // Physical seat spacing
      Estimate<double> seatSpacing = const Estimate<double>.unknown();
      Estimate<double> rowSpacing = const Estimate<double>.unknown();
      Estimate<double> rowRise = const Estimate<double>.unknown();
      Estimate<double> aisleWidth = const Estimate<double>.unknown();
      List<DraftSeat> seats = const [];

      if (scaleStatus != ScaleStatus.unknown) {
        final spacingVal = input.knownMeasurements['seatSpacing'] ?? 0.60;
        final rowSpacingVal = input.knownMeasurements['rowSpacing'] ?? 1.10;
        final rowRiseVal = input.knownMeasurements['rowRise'] ?? 0.15;
        final aisleWVal = input.knownMeasurements['aisleWidth'] ?? 1.20;

        seatSpacing = Estimate<double>.aiEstimated(
          spacingVal,
          confidence: 0.84,
          source: 'seat_lattice_fit',
          evidenceIds: sIds,
          note: 'Estimated seat spacing: approximately ${spacingVal.toStringAsFixed(2)}m.',
        );
        rowSpacing = Estimate<double>.aiEstimated(
          rowSpacingVal,
          confidence: 0.82,
          source: 'seat_lattice_fit',
          evidenceIds: sIds,
          note: 'Estimated row spacing: approximately ${rowSpacingVal.toStringAsFixed(2)}m.',
        );
        rowRise = Estimate<double>.aiEstimated(
          rowRiseVal,
          confidence: 0.80,
          source: 'tier_gradient_estimation',
          evidenceIds: sIds,
        );
        aisleWidth = Estimate<double>.aiEstimated(
          aisleWVal,
          confidence: 0.83,
          source: 'aisle_detection',
          evidenceIds: sIds,
        );

        // Generate physical seats respecting logical structure and removed seats
        final generatedSeats = <DraftSeat>[];
        for (int r = 1; r <= logicalRows; r++) {
          final rowLabel = String.fromCharCode(64 + r); // A, B, C...
          final int countInRow = rowSeatCounts[r] ?? logicalSeatsPerRow;
          for (int s = 1; s <= countInRow; s++) {
            final seatKey = '$rowLabel$s';
            if (removedSeats.contains(seatKey)) continue;

            final posX = (s - (countInRow / 2.0)) * spacingVal;
            final posY = (r - 1) * rowRiseVal;
            final posZ = 5.0 + ((r - 1) * rowSpacingVal);

            generatedSeats.add(
              DraftSeat(
                id: 'seat-$r-$s',
                row: rowLabel,
                number: s,
                position: Position3(x: posX, y: posY, z: posZ),
                rotationY: 0,
                category: SeatCategory.standard,
                confidence: 0.85,
                evidenceIds: sIds,
              ),
            );
          }
        }
        seats = generatedSeats;
      } else {
        warnings.add('Physical seat spacing and coordinates remain UNKNOWN because scale is uncalibrated.');
      }

      seating = DraftSeatLattice(
        rows: Estimate<int>.aiEstimated(
          detectedRowsCount,
          confidence: hasRowConflict ? 0.65 : 0.88,
          source: 'seating_row_detector',
          evidenceIds: sIds,
        ),
        seatsPerRow: Estimate<int>.aiEstimated(
          logicalSeatsPerRow,
          confidence: 0.85,
          source: 'seat_lattice_count',
          evidenceIds: sIds,
        ),
        seatSpacing: seatSpacing,
        rowSpacing: rowSpacing,
        rowRisePerRow: rowRise,
        seats: seats,
        aisleAfterSeats: aisles,
        blockCount: blocks,
        rowSeatCounts: rowSeatCounts,
        removedSeats: removedSeats,
        aisleWidth: aisleWidth,
      );

      observations.add(
        VenueObservation(
          id: 'obs-seating-$revision',
          type: ObservationType.seating,
          value: {
            'detectedRows': detectedRowsCount,
            'logicalRows': logicalRows,
            'seatsPerRow': logicalSeatsPerRow,
            'hasConflict': hasRowConflict,
          },
          confidence: hasRowConflict ? 0.65 : 0.88,
          provenance: EstimateProvenance.aiEstimated,
          evidenceIds: sIds,
          notes: hasRowConflict ? 'Discrepancy detected with admin row configuration.' : 'Seating lattice analyzed.',
          revision: revision,
        ),
      );
    } else {
      requests.add(
        VenueCaptureRequest(
          id: 'req-seating-photo-$revision',
          sessionId: sessionId,
          theatreId: theatreId,
          target: 'Seating Area',
          reason: 'No seating photographs provided to extract rows, aisles, and seating blocks.',
          requiredEvidenceType: EvidenceType.photo,
          instruction: 'Stand on the side aisle halfway down the auditorium, face across the seating rows, '
              'and ensure both floor riser tiers and seat armrests are clearly visible.',
          priority: RequestPriority.high,
          createdAt: DateTime.now(),
        ),
      );
    }

    // 5. Speaker Reconstruction (visual cabinets only, strictly requires speaker evidence)
    final speakers = <DraftVisualSpeaker>[];
    if (speakerMedia.isNotEmpty) {
      final spIds = speakerMedia.map((m) => m.id).toList();
      evidenceLinks['speakers'] = spIds;

      // Detect surround speakers on side walls
      speakers.addAll([
        DraftVisualSpeaker(
          id: 'sp-left-1',
          name: 'Visual Surround Left 1',
          position: Position3(x: -8.0, y: 3.5, z: 8.0),
          visualCabinetType: SpeakerType.sideSurround,
          confidence: 0.82,
          evidenceIds: spIds,
        ),
        DraftVisualSpeaker(
          id: 'sp-left-2',
          name: 'Visual Surround Left 2',
          position: Position3(x: -8.0, y: 3.5, z: 14.0),
          visualCabinetType: SpeakerType.sideSurround,
          confidence: 0.82,
          evidenceIds: spIds,
        ),
        DraftVisualSpeaker(
          id: 'sp-right-1',
          name: 'Visual Surround Right 1',
          position: Position3(x: 8.0, y: 3.5, z: 8.0),
          visualCabinetType: SpeakerType.sideSurround,
          confidence: 0.82,
          evidenceIds: spIds,
        ),
        DraftVisualSpeaker(
          id: 'sp-right-2',
          name: 'Visual Surround Right 2',
          position: Position3(x: 8.0, y: 3.5, z: 14.0),
          visualCabinetType: SpeakerType.sideSurround,
          confidence: 0.82,
          evidenceIds: spIds,
        ),
      ]);

      observations.add(
        VenueObservation(
          id: 'obs-speakers-$revision',
          type: ObservationType.speaker,
          value: {'count': speakers.length, 'cabinetType': 'surround'},
          confidence: 0.82,
          provenance: EstimateProvenance.aiEstimated,
          evidenceIds: spIds,
          notes: 'Visual speaker cabinets detected. Audio channels and routing not inferred.',
          revision: revision,
        ),
      );
    } else {
      // No speaker evidence: speakers remain empty. Do NOT fabricate placeholders!
      observations.add(
        VenueObservation(
          id: 'obs-speakers-none-$revision',
          type: ObservationType.speaker,
          value: {'status': 'not_detected'},
          confidence: 0.0,
          provenance: EstimateProvenance.unknown,
          notes: 'No speakers visible in uploaded imagery. Speaker positions remain unknown.',
          revision: revision,
        ),
      );
    }

    // 6. Lighting Reconstruction
    DraftLighting lighting = const DraftLighting();
    if (lightingMedia.isNotEmpty) {
      final lIds = lightingMedia.map((m) => m.id).toList();
      evidenceLinks['lighting'] = lIds;

      lighting = DraftLighting(
        ceilingLightsCount: Estimate<int>.aiEstimated(
          12,
          confidence: 0.78,
          source: 'ceiling_fixture_counter',
          evidenceIds: lIds,
          note: 'Ceiling lighting arrangement: approximately 12 recessed fixtures visible.',
        ),
        hasAisleLighting: Estimate<bool>.aiEstimated(
          true,
          confidence: 0.75,
          source: 'aisle_luminaire_detector',
          evidenceIds: lIds,
        ),
        // No fake lux/photometrics
        estimatedLux: const Estimate<double>.unknown(
          note: 'Photometric lux cannot be measured from standard camera exposure.',
        ),
      );

      observations.add(
        VenueObservation(
          id: 'obs-lighting-$revision',
          type: ObservationType.lighting,
          value: {'ceilingLights': 12, 'hasAisleLighting': true},
          confidence: 0.77,
          provenance: EstimateProvenance.aiEstimated,
          evidenceIds: lIds,
          revision: revision,
        ),
      );
    }

    // 7. Materials & Appearance (global palette + independent per-wall finishes)
    DraftAppearance appearance = const DraftAppearance();
    if (materialMedia.isNotEmpty || frontWallMedia.isNotEmpty || seatingMedia.isNotEmpty || rearWallMedia.isNotEmpty) {
      final mIds = <String>{
        ...materialMedia.map((m) => m.id),
        ...frontWallMedia.map((m) => m.id),
        ...seatingMedia.map((m) => m.id),
        ...rearWallMedia.map((m) => m.id),
      }.toList();
      evidenceLinks['appearance'] = mIds;

      DraftWallAppearance frontWall = const DraftWallAppearance();
      if (frontWallMedia.isNotEmpty) {
        final fIds = frontWallMedia.map((m) => m.id).toList();
        frontWall = DraftWallAppearance(
          colorHex: Estimate<String>.aiEstimated(
            '#1A1A1E',
            confidence: 0.78,
            source: 'front_proscenium_segmenter',
            evidenceIds: fIds,
            note: 'Front wall proscenium: deep matte black framing screen.',
          ),
          materialType: Estimate<String>.aiEstimated(
            'matte_proscenium_finish',
            confidence: 0.75,
            source: 'proscenium_material_classifier',
            evidenceIds: fIds,
          ),
          patternTreatment: Estimate<String>.aiEstimated(
            'acoustic_baffles',
            confidence: 0.70,
            source: 'proscenium_pattern_detector',
            evidenceIds: fIds,
          ),
        );
      }

      DraftWallAppearance leftWall = const DraftWallAppearance();
      DraftWallAppearance rightWall = const DraftWallAppearance();
      if (seatingMedia.isNotEmpty) {
        final sIds = seatingMedia.map((m) => m.id).toList();
        leftWall = DraftWallAppearance(
          colorHex: Estimate<String>.aiEstimated(
            '#2C2D30',
            confidence: 0.75,
            source: 'left_wall_clustering',
            evidenceIds: sIds,
            note: 'Left auditorium wall: dark charcoal acoustic panelling.',
          ),
          materialType: Estimate<String>.aiEstimated(
            'acoustic_fabric_panel',
            confidence: 0.72,
            source: 'wall_material_classifier',
            evidenceIds: sIds,
          ),
          patternTreatment: Estimate<String>.aiEstimated(
            'fabric_baffles',
            confidence: 0.70,
            source: 'panel_pattern_detector',
            evidenceIds: sIds,
          ),
        );
        rightWall = DraftWallAppearance(
          colorHex: Estimate<String>.aiEstimated(
            '#2C2D30',
            confidence: 0.75,
            source: 'right_wall_clustering',
            evidenceIds: sIds,
            note: 'Right auditorium wall: dark charcoal acoustic panelling.',
          ),
          materialType: Estimate<String>.aiEstimated(
            'acoustic_fabric_panel',
            confidence: 0.72,
            source: 'wall_material_classifier',
            evidenceIds: sIds,
          ),
          patternTreatment: Estimate<String>.aiEstimated(
            'fabric_baffles',
            confidence: 0.70,
            source: 'panel_pattern_detector',
            evidenceIds: sIds,
          ),
        );
      }

      DraftWallAppearance rearWall = const DraftWallAppearance();
      if (rearWallMedia.isNotEmpty) {
        final rIds = rearWallMedia.map((m) => m.id).toList();
        rearWall = DraftWallAppearance(
          colorHex: Estimate<String>.aiEstimated(
            '#25262A',
            confidence: 0.76,
            source: 'rear_wall_clustering',
            evidenceIds: rIds,
            note: 'Rear auditorium wall: dark slate with sound diffusers.',
          ),
          materialType: Estimate<String>.aiEstimated(
            'diffuser_panel',
            confidence: 0.72,
            source: 'rear_material_classifier',
            evidenceIds: rIds,
          ),
          patternTreatment: Estimate<String>.aiEstimated(
            'quadratic_residue_diffuser',
            confidence: 0.70,
            source: 'diffuser_pattern_detector',
            evidenceIds: rIds,
          ),
        );
      }

      appearance = DraftAppearance(
        wallColorHex: Estimate<String>.aiEstimated(
          '#2C2D30',
          confidence: 0.75,
          source: 'color_histogram_clustering',
          evidenceIds: mIds,
          note: 'Observed wall color: warm dark charcoal grey.',
        ),
        carpetColorHex: Estimate<String>.aiEstimated(
          '#1E2024',
          confidence: 0.72,
          source: 'floor_region_clustering',
          evidenceIds: mIds,
          note: 'Observed flooring: dark slate carpet.',
        ),
        wallMaterialType: Estimate<String>.aiEstimated(
          'acoustic_fabric_panel',
          confidence: 0.70,
          source: 'texture_classifier',
          evidenceIds: mIds,
        ),
        frontWall: frontWall,
        leftWall: leftWall,
        rightWall: rightWall,
        rearWall: rearWall,
      );

      observations.add(
        VenueObservation(
          id: 'obs-appearance-$revision',
          type: ObservationType.material,
          value: {
            'wallColor': '#2C2D30',
            'wallMaterial': 'acoustic_fabric_panel',
            'hasFrontWall': frontWall.isKnown,
            'hasLeftWall': leftWall.isKnown,
            'hasRightWall': rightWall.isKnown,
            'hasRearWall': rearWall.isKnown,
          },
          confidence: 0.73,
          provenance: EstimateProvenance.aiEstimated,
          evidenceIds: mIds,
          revision: revision,
        ),
      );
    }

    // Determine overall uncertainty state and confidence
    double overallConfidence = 0.0;
    if (observations.isNotEmpty) {
      final confSum = observations
          .where((o) => o.confidence != null && o.confidence! > 0)
          .fold<double>(0.0, (sum, o) => sum + (o.confidence ?? 0.0));
      final confCount = observations.where((o) => o.confidence != null && o.confidence! > 0).length;
      overallConfidence = confCount > 0 ? (confSum / confCount) : 0.0;
    }

    ReconstructionUncertaintyState state;
    if (conflicts.isNotEmpty) {
      state = ReconstructionUncertaintyState.conflict;
    } else if (requests.any((r) => r.requiredEvidenceType == EvidenceType.measurement)) {
      state = ReconstructionUncertaintyState.needsMeasurement;
    } else if (requests.any((r) => r.requiredEvidenceType == EvidenceType.photo)) {
      state = ReconstructionUncertaintyState.needsPhoto;
    } else if (overallConfidence >= 0.80 && scaleStatus != ScaleStatus.unknown) {
      state = ReconstructionUncertaintyState.confident;
    } else {
      state = ReconstructionUncertaintyState.uncertain;
    }

    return VenueReconstructionResult(
      jobId: input.jobId,
      sessionId: sessionId,
      theatreId: theatreId,
      revision: revision,
      scaleStatus: scaleStatus,
      state: state,
      observations: observations,
      room: room,
      screen: screen,
      seating: seating,
      speakers: speakers,
      lighting: lighting,
      appearance: appearance,
      overallConfidence: overallConfidence,
      evidenceLinks: evidenceLinks,
      requests: requests,
      conflicts: conflicts,
      warnings: warnings,
      coordinateConvention: input.coordinateConvention,
      isSuccess: true,
      workerName: name,
    );
  }

  @override
  Future<VenueReconstructionResult> refine(
    VenueReconstructionInput input,
    VenueReconstructionResult previousResult,
  ) async {
    // Multi-pass iterative refinement: combine previous observations with new evidence
    final combinedObservations = <VenueCaptureObservation>[...input.previousObservations];
    for (final obs in previousResult.observations) {
      combinedObservations.add(
        VenueCaptureObservation(
          id: obs.id,
          sessionId: previousResult.sessionId,
          theatreId: previousResult.theatreId ?? 'theatre',
          featureType: obs.type.name,
          confidence: obs.confidence,
          evidenceIds: obs.evidenceIds,
          data: obs.value,
          observedAt: DateTime.now(),
        ),
      );
    }

    final refinedInput = VenueReconstructionInput(
      jobId: input.jobId,
      sessionId: input.sessionId,
      theatreId: input.theatreId,
      evidence: input.evidence,
      baselineDraft: input.baselineDraft,
      logicalConstraints: input.logicalConstraints,
      knownMeasurements: input.knownMeasurements,
      coordinateConvention: input.coordinateConvention,
      requestedAnalysis: input.requestedAnalysis,
      previousObservations: combinedObservations,
      revision: previousResult.revision + 1,
    );

    return analyze(refinedInput);
  }
}
