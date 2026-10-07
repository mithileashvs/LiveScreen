import 'package:flutter_test/flutter_test.dart';
import 'package:livescreen/admin/capture/models/models.dart';
import 'package:livescreen/admin/capture/services/services.dart';
import 'package:livescreen/admin/capture/contracts/ai_worker_contracts.dart';
import 'package:livescreen/admin/models/theatre_configuration.dart';
import 'package:livescreen/admin/models/room_config.dart';
import 'package:livescreen/admin/models/screen_config.dart';
import 'package:livescreen/admin/models/seat_config.dart';
import 'package:livescreen/admin/models/speaker_model.dart';
import 'package:livescreen/admin/models/acoustics_config.dart';
import 'package:livescreen/admin/services/theatre_unity_bridge.dart';

void main() {
  group('AI Venue Capture — Estimate<T> & Uncertainty', () {
    test('explicitly unknown estimate preserves unknown state and never invents values', () {
      const unknownDim = Estimate<double>.unknown(note: 'Cannot triangulate from single view');

      expect(unknownDim.isUnknown, isTrue);
      expect(unknownDim.isKnown, isFalse);
      expect(unknownDim.valueOrNull, isNull);
      expect(unknownDim.valueOr(25.0), equals(25.0));
      expect(unknownDim.provenance, equals(EstimateProvenance.unknown));
      expect(unknownDim.confidence, equals(0.0));
      expect(unknownDim.note, equals('Cannot triangulate from single view'));
    });

    test('measured and adminMeasured preserve provenance and clamp confidence', () {
      final measured = Estimate<double>.measured(
        24.5,
        source: 'laser_disto_x4',
        evidenceIds: ['media-123'],
        confidence: 1.5, // should clamp to 1.0
      );

      expect(measured.isKnown, isTrue);
      expect(measured.value, equals(24.5));
      expect(measured.provenance, equals(EstimateProvenance.measured));
      expect(measured.confidence, equals(1.0));
      expect(measured.evidenceIds, contains('media-123'));

      final adminMeasured = Estimate<double>.adminMeasured(
        8.2,
        evidenceIds: ['media-tape-1'],
        note: 'Measured from floor to ceiling beam',
      );

      expect(adminMeasured.isKnown, isTrue);
      expect(adminMeasured.value, equals(8.2));
      expect(adminMeasured.provenance, equals(EstimateProvenance.adminMeasured));
      expect(adminMeasured.note, equals('Measured from floor to ceiling beam'));
    });

    test('aiEstimated and inferred preserve confidence and source', () {
      final aiEst = Estimate<double>.aiEstimated(
        18.4,
        confidence: 0.82,
        source: 'screen_bezel_detector_v1',
        evidenceIds: ['photo-1', 'photo-2'],
      );

      expect(aiEst.isKnown, isTrue);
      expect(aiEst.value, equals(18.4));
      expect(aiEst.provenance, equals(EstimateProvenance.aiEstimated));
      expect(aiEst.confidence, equals(0.82));
      expect(aiEst.source, equals('screen_bezel_detector_v1'));

      final inferred = Estimate<int>.inferred(
        14,
        confidence: 0.9,
        source: 'seat_lattice_row_counter',
      );
      expect(inferred.isKnown, isTrue);
      expect(inferred.value, equals(14));
      expect(inferred.provenance, equals(EstimateProvenance.inferred));
    });

    test('Estimate<T> JSON serialization round-trips unknown and known values cleanly', () {
      const unknown = Estimate<double>.unknown(note: 'No view');
      final unknownJson = unknown.toJson();
      final roundTripUnknown = Estimate<double>.fromJson(
        unknownJson,
        (v) => (v as num).toDouble(),
      );

      expect(roundTripUnknown.isUnknown, isTrue);
      expect(roundTripUnknown.note, equals('No view'));
      expect(roundTripUnknown.valueOrNull, isNull);

      final known = Estimate<double>.aiEstimated(
        32.0,
        confidence: 0.75,
        source: 'sfm_point_cloud',
        evidenceIds: ['img-1'],
        note: 'Depth triangulated',
      );
      final knownJson = known.toJson();
      final roundTripKnown = Estimate<double>.fromJson(
        knownJson,
        (v) => (v as num).toDouble(),
      );

      expect(roundTripKnown.isKnown, isTrue);
      expect(roundTripKnown.value, equals(32.0));
      expect(roundTripKnown.confidence, equals(0.75));
      expect(roundTripKnown.provenance, equals(EstimateProvenance.aiEstimated));
      expect(roundTripKnown.source, equals('sfm_point_cloud'));
      expect(roundTripKnown.evidenceIds, equals(['img-1']));
    });
  });

  group('AI Venue Capture — Evidence & Traceability', () {
    test('EvidenceReference serialization round-trip', () {
      final ref = EvidenceReference(
        evidenceId: 'ev-9988',
        type: EvidenceType.photo,
        note: 'Rear corner perspective',
        timestamp: DateTime.parse('2026-10-07T10:00:00Z'),
      );

      final json = ref.toJson();
      final decoded = EvidenceReference.fromJson(json);

      expect(decoded.evidenceId, equals('ev-9988'));
      expect(decoded.type, equals(EvidenceType.photo));
      expect(decoded.note, equals('Rear corner perspective'));
      expect(decoded.timestamp, equals(DateTime.parse('2026-10-07T10:00:00Z')));
    });

    test('VenueCaptureMedia supports photo, video, and measurement types with stable IDs', () {
      final photo = VenueCaptureMedia(
        id: 'media-p1',
        sessionId: 'session-1',
        theatreId: 'theatre-1',
        type: EvidenceType.photo,
        storagePath: 'theatres/theatre-1/evidence/p1.jpg',
        filename: 'p1.jpg',
        mimeType: 'image/jpeg',
        byteSize: 3120000,
        createdAt: DateTime.parse('2026-10-07T10:00:00Z'),
      );

      final measurement = VenueCaptureMedia(
        id: 'media-m1',
        sessionId: 'session-1',
        theatreId: 'theatre-1',
        type: EvidenceType.measurement,
        storagePath: 'theatres/theatre-1/measurements/m1.json',
        filename: 'm1.json',
        metadata: {'distance_meters': 21.4, 'tool': 'Leica DISTO D2'},
        createdAt: DateTime.parse('2026-10-07T10:05:00Z'),
      );

      expect(photo.type, equals(EvidenceType.photo));
      expect(measurement.type, equals(EvidenceType.measurement));
      expect(measurement.metadata['distance_meters'], equals(21.4));

      final json = photo.toJson();
      final roundTripPhoto = VenueCaptureMedia.fromJson(json);
      expect(roundTripPhoto.id, equals('media-p1'));
      expect(roundTripPhoto.storagePath, equals('theatres/theatre-1/evidence/p1.jpg'));
    });
  });

  group('AI Venue Capture — State Machine & Transitions', () {
    test('valid lifecycle transitions succeed sequentially', () {
      var state = CaptureState.initial;

      expect(CaptureStateMachine.canTransition(state, CaptureState.analyzing), isTrue);
      state = CaptureStateMachine.transition(state, CaptureState.analyzing);
      expect(state, equals(CaptureState.analyzing));

      expect(CaptureStateMachine.canTransition(state, CaptureState.reconstructing), isTrue);
      state = CaptureStateMachine.transition(state, CaptureState.reconstructing);
      expect(state, equals(CaptureState.reconstructing));

      expect(CaptureStateMachine.canTransition(state, CaptureState.readyForReview), isTrue);
      state = CaptureStateMachine.transition(state, CaptureState.readyForReview);
      expect(state, equals(CaptureState.readyForReview));

      expect(CaptureStateMachine.canTransition(state, CaptureState.reviewing), isTrue);
      state = CaptureStateMachine.transition(state, CaptureState.reviewing);
      expect(state, equals(CaptureState.reviewing));

      expect(CaptureStateMachine.canTransition(state, CaptureState.confirmed), isTrue);
      state = CaptureStateMachine.transition(state, CaptureState.confirmed);
      expect(state, equals(CaptureState.confirmed));
      expect(state.isTerminal, isTrue);
    });

    test('valid branching to needsPhoto and needsMeasurement', () {
      expect(CaptureStateMachine.canTransition(CaptureState.analyzing, CaptureState.needsPhoto), isTrue);
      expect(CaptureStateMachine.canTransition(CaptureState.analyzing, CaptureState.needsMeasurement), isTrue);
      expect(CaptureStateMachine.canTransition(CaptureState.reconstructing, CaptureState.needsPhoto), isTrue);
      expect(CaptureStateMachine.canTransition(CaptureState.reconstructing, CaptureState.needsMeasurement), isTrue);

      final stateFromNeedsPhoto = CaptureStateMachine.transition(CaptureState.needsPhoto, CaptureState.analyzing);
      expect(stateFromNeedsPhoto, equals(CaptureState.analyzing));

      final stateFromNeedsMeas = CaptureStateMachine.transition(CaptureState.needsMeasurement, CaptureState.reconstructing);
      expect(stateFromNeedsMeas, equals(CaptureState.reconstructing));
    });

    test('invalid state transitions fail safely and throw InvalidCaptureStateTransitionException', () {
      // Cannot jump from initial directly to confirmed
      expect(CaptureStateMachine.canTransition(CaptureState.initial, CaptureState.confirmed), isFalse);
      expect(
        () => CaptureStateMachine.transition(CaptureState.initial, CaptureState.confirmed),
        throwsA(isA<InvalidCaptureStateTransitionException>()),
      );

      // Terminal state confirmed cannot transition to anything
      expect(CaptureStateMachine.canTransition(CaptureState.confirmed, CaptureState.initial), isFalse);
      expect(CaptureStateMachine.canTransition(CaptureState.confirmed, CaptureState.analyzing), isFalse);
      expect(
        () => CaptureStateMachine.transition(CaptureState.confirmed, CaptureState.reviewing),
        throwsA(isA<InvalidCaptureStateTransitionException>()),
      );

      // Terminal state cancelled cannot transition to anything
      expect(CaptureStateMachine.canTransition(CaptureState.cancelled, CaptureState.analyzing), isFalse);
      expect(
        () => CaptureStateMachine.transition(CaptureState.cancelled, CaptureState.initial),
        throwsA(isA<InvalidCaptureStateTransitionException>()),
      );
    });
  });

  group('AI Venue Capture — Targeted Evidence Requests', () {
    test('supports precise, non-generic instructions with priority and status', () {
      const detailedInstruction =
          'Take a photo from the rear-right aisle facing diagonally toward the rear-left wall, '
          'keeping the ceiling and speaker area visible.';

      final request = VenueCaptureRequest(
        id: 'req-01',
        sessionId: 'session-101',
        theatreId: 'theatre-202',
        target: 'rear_wall_speaker_cluster',
        reason: 'Rear ceiling elevation and speaker cabinet positions occluded in front views.',
        requiredEvidenceType: EvidenceType.photo,
        instruction: detailedInstruction,
        relatedObservationIds: ['obs-12', 'obs-15'],
        priority: RequestPriority.high,
        status: RequestStatus.pending,
        createdAt: DateTime.parse('2026-10-07T10:00:00Z'),
      );

      expect(request.instruction, equals(detailedInstruction));
      expect(request.priority, equals(RequestPriority.high));
      expect(request.status, equals(RequestStatus.pending));

      final json = request.toJson();
      final roundTrip = VenueCaptureRequest.fromJson(json);

      expect(roundTrip.instruction, equals(detailedInstruction));
      expect(roundTrip.target, equals('rear_wall_speaker_cluster'));
      expect(roundTrip.priority, equals(RequestPriority.high));
      expect(roundTrip.status, equals(RequestStatus.pending));

      final fulfilled = roundTrip.copyWith(
        status: RequestStatus.fulfilled,
        resolvedAt: DateTime.parse('2026-10-07T10:15:00Z'),
      );
      expect(fulfilled.status, equals(RequestStatus.fulfilled));
      expect(fulfilled.resolvedAt, isNotNull);
    });
  });

  group('AI Venue Capture — Coordinate Frame & LiveScreen Convention', () {
    test('LiveScreen coordinate convention matches Unity generators', () {
      const frame = DraftCoordinateFrame();

      expect(frame.units, equals('metres'));
      expect(frame.origin, equals('front_wall_floor_center'));
      expect(frame.lateralAxis, equals('+X'));
      expect(frame.upAxis, equals('+Y'));
      expect(frame.forwardAxis, equals('+Z'));
      expect(frame.seatForwardFacing, equals('-Z'));
    });

    test('seat forward vector for rotationY = 0 points towards -Z (the screen)', () {
      final forward = CoordinateTransformer.seatForwardVector(0.0);
      expect(forward.x, closeTo(0.0, 0.0001));
      expect(forward.y, equals(0.0));
      expect(forward.z, closeTo(-1.0, 0.0001));
    });

    test('auditorium bounding box check identifies inside and outside coordinates', () {
      const roomWidth = 20.0;
      const roomLength = 30.0;
      const roomHeight = 8.0;

      // Inside
      final seatPos = Position3(x: 2.0, y: 1.2, z: 12.0);
      expect(
        CoordinateTransformer.isWithinAuditorium(
          seatPos,
          roomWidth: roomWidth,
          roomLength: roomLength,
          roomHeight: roomHeight,
        ),
        isTrue,
      );

      // Outside lateral
      final outLateral = Position3(x: 15.0, y: 1.0, z: 10.0);
      expect(
        CoordinateTransformer.isWithinAuditorium(
          outLateral,
          roomWidth: roomWidth,
          roomLength: roomLength,
          roomHeight: roomHeight,
        ),
        isFalse,
      );

      // Outside rear
      final outRear = Position3(x: 0.0, y: 1.0, z: 35.0);
      expect(
        CoordinateTransformer.isWithinAuditorium(
          outRear,
          roomWidth: roomWidth,
          roomLength: roomLength,
          roomHeight: roomHeight,
        ),
        isFalse,
      );
    });
  });

  group('AI Venue Capture — ReconstructionDraft', () {
    test('ReconstructionDraft models all dimensions and serializes cleanly', () {
      final draft = ReconstructionDraft(
        id: 'draft-1',
        sessionId: 'session-1',
        theatreId: 'theatre-1',
        createdAt: DateTime.parse('2026-10-07T10:00:00Z'),
        room: DraftRoomGeometry(
          width: Estimate<double>.measured(22.0, confidence: 1.0),
          length: Estimate<double>.aiEstimated(34.0, confidence: 0.85),
          height: const Estimate<double>.unknown(note: 'Ceiling not detected'),
        ),
        screen: DraftScreen(
          width: Estimate<double>.aiEstimated(16.0, confidence: 0.9),
          height: Estimate<double>.aiEstimated(7.5, confidence: 0.9),
          position: Estimate<Position3>.aiEstimated(
            Position3(x: 0, y: 4, z: 1.2),
            confidence: 0.9,
          ),
          type: Estimate<ScreenType>.aiEstimated(
            ScreenType.curved,
            confidence: 0.95,
          ),
        ),
        seating: DraftSeatLattice(
          rows: Estimate<int>.aiEstimated(8, confidence: 0.88),
          seatsPerRow: Estimate<int>.aiEstimated(10, confidence: 0.88),
          seats: [
            DraftSeat(
              id: 'A1',
              row: 'A',
              number: 1,
              position: Position3(x: -3.0, y: 0.0, z: 6.0),
              category: SeatCategory.standard,
            ),
            DraftSeat(
              id: 'A2',
              row: 'A',
              number: 2,
              position: Position3(x: -2.4, y: 0.0, z: 6.0),
              category: SeatCategory.standard,
            ),
          ],
        ),
        speakers: [
          DraftVisualSpeaker(
            id: 'vs-1',
            name: 'WallSpeaker_Left_1',
            position: Position3(x: -10.5, y: 3.0, z: 8.0),
            visualCabinetType: SpeakerType.sideSurround,
          ),
        ],
        lighting: DraftLighting(
          ceilingLightsCount: Estimate<int>.aiEstimated(8, confidence: 0.7),
          hasAisleLighting: Estimate<bool>.aiEstimated(true, confidence: 0.9),
        ),
        appearance: DraftAppearance(
          wallColorHex: Estimate<String>.aiEstimated('#1C1A21', confidence: 0.8),
        ),
        overallConfidence: 0.84,
      );

      final json = draft.toJson();
      final decoded = ReconstructionDraft.fromJson(json);

      expect(decoded.id, equals('draft-1'));
      expect(decoded.room.width.isKnown, isTrue);
      expect(decoded.room.width.value, equals(22.0));
      expect(decoded.room.height.isUnknown, isTrue);
      expect(decoded.screen.width.value, equals(16.0));
      expect(decoded.screen.type.value, equals(ScreenType.curved));
      expect(decoded.seating.seats.length, equals(2));
      expect(decoded.speakers.length, equals(1));
      expect(decoded.speakers.first.name, equals('WallSpeaker_Left_1'));
      expect(decoded.speakers.first.visualCabinetType, equals(SpeakerType.sideSurround));
      expect(decoded.overallConfidence, equals(0.84));
    });
  });

  group('AI Venue Capture — DraftToTheatreMapper & Rules', () {
    late TheatreConfiguration existingConfig;

    setUp(() {
      existingConfig = TheatreConfiguration(
        id: 'theatre-live-99',
        basicInfo: TheatreBasicInfo(
          name: 'Grand Horizon Cinema',
          hallName: 'Screen 1',
          city: 'London',
        ),
        room: RoomConfig(width: 20.0, length: 30.0, height: 8.0),
        screen: ScreenConfig(width: 15.0, height: 7.0),
        seats: [
          SeatConfig(row: 'A', number: 1, position: Position3(x: 0, y: 0, z: 5)),
        ],
        speakers: [
          SpeakerModel(
            id: 'spk-orig',
            name: 'Main Left',
            type: SpeakerType.frontLeft,
            channel: SpeakerChannel.left,
            position: Position3(x: -8, y: 3, z: 1),
            specs: SpeakerSpecs(ratedPowerWatts: 450.0),
          ),
        ],
        acoustics: AcousticsConfig(
          floor: SurfaceAcoustics(material: 'Carpet', absorptionCoefficient: 0.35),
        ),
        status: TheatreStatus.draft,
        verificationStatus: 'verified',
        ownerId: 'owner-uuid-44',
      );
    });

    test('rejects unreviewed draft with UnreviewedDraftException when requireReviewed is true', () {
      final unreviewedDraft = ReconstructionDraft(
        id: 'draft-unreviewed',
        sessionId: 'session-1',
        theatreId: 'theatre-live-99',
        createdAt: DateTime.now(),
        isReviewed: false,
      );

      expect(
        () => DraftToTheatreMapper.applyDraftToConfiguration(
          existingConfig,
          unreviewedDraft,
          options: const DraftMappingOptions(requireReviewed: true),
        ),
        throwsA(isA<UnreviewedDraftException>()),
      );
    });

    test('reviewed draft maps confirmed values while preserving UNKNOWN measurements', () {
      final reviewedDraft = ReconstructionDraft(
        id: 'draft-reviewed',
        sessionId: 'session-1',
        theatreId: 'theatre-live-99',
        createdAt: DateTime.now(),
        isReviewed: true,
        reviewedBy: 'admin-alice',
        reviewedAt: DateTime.now(),
        room: DraftRoomGeometry(
          width: Estimate<double>.measured(24.0, confidence: 1.0),
          length: const Estimate<double>.unknown(note: 'Length unmeasured'),
          height: Estimate<double>.measured(9.0, confidence: 1.0),
        ),
        screen: DraftScreen(
          width: Estimate<double>.aiEstimated(17.5, confidence: 0.9),
          height: const Estimate<double>.unknown(),
        ),
      );

      final mapped = DraftToTheatreMapper.applyDraftToConfiguration(
        existingConfig,
        reviewedDraft,
      );

      // Known measurements updated
      expect(mapped.room.width, equals(24.0));
      expect(mapped.room.height, equals(9.0));
      expect(mapped.screen.width, equals(17.5));

      // UNKNOWN values preserved from existing configuration (NEVER silently overwritten with 0 or guessed defaults)
      expect(mapped.room.length, equals(30.0)); // original preserved
      expect(mapped.screen.height, equals(7.0)); // original preserved
    });

    test('strictly preserves theatre identity, ownership, verification, status, and acoustics', () {
      final reviewedDraft = ReconstructionDraft(
        id: 'draft-reviewed',
        sessionId: 'session-1',
        theatreId: 'theatre-live-99',
        createdAt: DateTime.now(),
        isReviewed: true,
        room: DraftRoomGeometry(
          width: Estimate<double>.measured(25.0, confidence: 1.0),
        ),
      );

      final mapped = DraftToTheatreMapper.applyDraftToConfiguration(
        existingConfig,
        reviewedDraft,
      );

      // Identity and security fields strictly preserved
      expect(mapped.id, equals('theatre-live-99'));
      expect(mapped.ownerId, equals('owner-uuid-44'));
      expect(mapped.verificationStatus, equals('verified'));
      expect(mapped.status, equals(TheatreStatus.draft));

      // Acoustics strictly preserved
      expect(mapped.acoustics.floor.absorptionCoefficient, equals(0.35));
    });

    test('unknown seat layout spacing preserves original.lastSeatLayout and does not substitute hardcoded defaults', () {
      existingConfig.lastSeatLayout = SeatLayoutParams(
        rows: 12,
        seatsPerRow: 14,
        seatSpacing: 0.75, // custom spacing
        rowSpacing: 1.35,  // custom spacing
        rowElevation: 0.18,// custom elevation
        seatWidth: 0.55,
        seatDepth: 0.65,
        seatHeight: 0.95,
      );

      final reviewedDraft = ReconstructionDraft(
        id: 'draft-lattice-unknown-spacing',
        sessionId: 'session-1',
        theatreId: 'theatre-live-99',
        createdAt: DateTime.now(),
        isReviewed: true,
        seating: DraftSeatLattice(
          rows: Estimate<int>.aiEstimated(10, confidence: 0.9),
          seatsPerRow: Estimate<int>.aiEstimated(12, confidence: 0.9),
          // seatSpacing, rowSpacing, rowRisePerRow are UNKNOWN in AI draft:
          seatSpacing: const Estimate<double>.unknown(note: 'Camera perspective too steep to resolve seat gap'),
          rowSpacing: const Estimate<double>.unknown(),
          rowRisePerRow: const Estimate<double>.unknown(),
          seats: [
            DraftSeat(
              id: 'A1',
              row: 'A',
              number: 1,
              position: Position3(x: 0, y: 0, z: 6),
            ),
          ],
        ),
      );

      final mapped = DraftToTheatreMapper.applyDraftToConfiguration(
        existingConfig,
        reviewedDraft,
      );

      expect(mapped.lastSeatLayout, isNotNull);
      // Known AI rows and seatsPerRow are updated:
      expect(mapped.lastSeatLayout!.rows, equals(10));
      expect(mapped.lastSeatLayout!.seatsPerRow, equals(12));

      // Crucial test for Fix 1: UNKNOWN measurements must preserve existing measurements,
      // NOT default 0.6 / 1.1 / 0.12!
      expect(mapped.lastSeatLayout!.seatSpacing, equals(0.75));
      expect(mapped.lastSeatLayout!.rowSpacing, equals(1.35));
      expect(mapped.lastSeatLayout!.rowElevation, equals(0.18));
      expect(mapped.lastSeatLayout!.seatWidth, equals(0.55));
      expect(mapped.lastSeatLayout!.seatDepth, equals(0.65));
    });

    test('unknown seat layout spacing falls back to system defaults only when original.lastSeatLayout was null', () {
      existingConfig.lastSeatLayout = null;

      final reviewedDraft = ReconstructionDraft(
        id: 'draft-lattice-no-orig',
        sessionId: 'session-1',
        theatreId: 'theatre-live-99',
        createdAt: DateTime.now(),
        isReviewed: true,
        seating: DraftSeatLattice(
          rows: Estimate<int>.aiEstimated(8, confidence: 0.9),
          seatsPerRow: Estimate<int>.aiEstimated(10, confidence: 0.9),
          seatSpacing: const Estimate<double>.unknown(),
          rowSpacing: const Estimate<double>.unknown(),
          rowRisePerRow: const Estimate<double>.unknown(),
          seats: [
            DraftSeat(
              id: 'A1',
              row: 'A',
              number: 1,
              position: Position3(x: 0, y: 0, z: 6),
            ),
          ],
        ),
      );

      final mapped = DraftToTheatreMapper.applyDraftToConfiguration(
        existingConfig,
        reviewedDraft,
      );

      expect(mapped.lastSeatLayout, isNotNull);
      expect(mapped.lastSeatLayout!.rows, equals(8));
      expect(mapped.lastSeatLayout!.seatsPerRow, equals(10));
      expect(mapped.lastSeatLayout!.seatSpacing, equals(0.6));
      expect(mapped.lastSeatLayout!.rowSpacing, equals(1.1));
      expect(mapped.lastSeatLayout!.rowElevation, equals(0.12));
    });

    test('AI-detected speakers are VISUAL ONLY and do NOT infer audio channels or specs', () {
      final reviewedDraft = ReconstructionDraft(
        id: 'draft-speakers',
        sessionId: 'session-1',
        theatreId: 'theatre-live-99',
        createdAt: DateTime.now(),
        isReviewed: true,
        speakers: [
          DraftVisualSpeaker(
            id: 'ai-speaker-1',
            name: 'SideWallSpeaker_L1',
            position: Position3(x: -11.0, y: 3.2, z: 14.0),
            rotationY: 75.0,
            visualCabinetType: SpeakerType.sideSurround,
          ),
        ],
      );

      final mapped = DraftToTheatreMapper.applyDraftToConfiguration(
        existingConfig,
        reviewedDraft,
      );

      expect(mapped.speakers.length, equals(1));
      final spk = mapped.speakers.first;
      expect(spk.id, equals('ai-speaker-1'));
      expect(spk.position.x, equals(-11.0));
      expect(spk.type, equals(SpeakerType.sideSurround));
      // Audio specs remain empty (visual only)
      expect(spk.specs.isEmpty, isTrue);
    });
  });

  group('AI Venue Capture — Backward Compatibility with Unity Bridge', () {
    test('mapped configuration serializes into canonical Unity payload version 2', () {
      final config = TheatreConfiguration(
        id: 'theatre-test-unity',
        basicInfo: TheatreBasicInfo(name: 'Odeon Test'),
        room: RoomConfig(width: 22.0, length: 32.0, height: 8.5),
        screen: ScreenConfig(width: 18.0, height: 8.0),
        seats: [
          SeatConfig(row: 'A', number: 1, position: Position3(x: -1, y: 0, z: 6)),
          SeatConfig(row: 'A', number: 2, position: Position3(x: 1, y: 0, z: 6)),
        ],
        speakers: [
          SpeakerModel(
            id: 'spk-vis-1',
            name: 'VisualSpeaker1',
            type: SpeakerType.sideSurround,
            position: Position3(x: -10, y: 3, z: 10),
          ),
        ],
      );

      final payload = TheatreUnityBridge.toUnityPayload(config);

      expect(payload['payloadVersion'], equals(2));
      expect(payload['theatreId'], equals('theatre-test-unity'));
      expect(payload['roomWidth'], equals(22.0));
      expect(payload['roomLength'], equals(32.0));
      expect(payload['roomHeight'], equals(8.5));
      expect(payload['seats'], isA<List>());
      expect((payload['seats'] as List).length, equals(2));
      expect(payload['speakers'], isA<List>());
      expect((payload['speakers'] as List).length, equals(1));

      final json = TheatreUnityBridge.toUnityTheatreConfigJson(config);
      expect(json, contains('"payloadVersion":2'));
      expect(json, contains('"theatreId":"theatre-test-unity"'));
    });
  });

  group('AI Venue Capture — InMemoryVenueCaptureRepository', () {
    late InMemoryVenueCaptureRepository repo;

    setUp(() {
      repo = InMemoryVenueCaptureRepository();
    });

    test('lifecycle operations create, advance state, add evidence, and confirm draft', () async {
      final session = await repo.createSession('theatre-100');
      expect(session.state, equals(CaptureState.initial));
      expect(session.theatreId, equals('theatre-100'));

      final media = await repo.addEvidence(
        VenueCaptureMedia(
          id: 'med-1',
          sessionId: session.id,
          theatreId: session.theatreId,
          type: EvidenceType.photo,
          storagePath: 'theatres/theatre-100/p1.jpg',
          filename: 'p1.jpg',
          createdAt: DateTime.now(),
        ),
      );
      expect(media.id, equals('med-1'));

      final evidenceList = await repo.listEvidence(session.id);
      expect(evidenceList.length, equals(1));

      // Advance state machine
      final analyzing = await repo.updateSessionState(session.id, CaptureState.analyzing);
      expect(analyzing.state, equals(CaptureState.analyzing));

      final reconstructing = await repo.updateSessionState(session.id, CaptureState.reconstructing);
      expect(reconstructing.state, equals(CaptureState.reconstructing));

      final readyForReview = await repo.updateSessionState(session.id, CaptureState.readyForReview);
      expect(readyForReview.state, equals(CaptureState.readyForReview));

      final draft = ReconstructionDraft(
        id: 'draft-auto-1',
        sessionId: session.id,
        theatreId: session.theatreId,
        createdAt: DateTime.now(),
        room: DraftRoomGeometry(
          width: Estimate<double>.measured(20.0, confidence: 1.0),
        ),
      );

      await repo.saveReconstructionDraft(session.id, draft);

      final confirmed = await repo.confirmDraft(
        session.id,
        draft,
        adminUserId: 'admin-tester',
      );

      expect(confirmed.state, equals(CaptureState.confirmed));
      expect(confirmed.draft?.isReviewed, isTrue);
      expect(confirmed.draft?.reviewedBy, equals('admin-tester'));
      expect(confirmed.confirmedAt, isNotNull);
    });

    test('targeted evidence request workflow', () async {
      final session = await repo.createSession('theatre-100');

      final req = await repo.addRequest(
        VenueCaptureRequest(
          id: 'req-1',
          sessionId: session.id,
          theatreId: session.theatreId,
          target: 'rear_wall_speaker',
          reason: 'Ambiguous height',
          requiredEvidenceType: EvidenceType.photo,
          instruction: 'Take photo from aisle facing rear wall',
          createdAt: DateTime.now(),
        ),
      );

      expect(req.id, equals('req-1'));

      final list = await repo.listRequests(session.id);
      expect(list.length, equals(1));
      expect(list.first.status, equals(RequestStatus.pending));

      final resolved = await repo.resolveRequest(req.id, status: RequestStatus.fulfilled);
      expect(resolved.status, equals(RequestStatus.fulfilled));
      expect(resolved.resolvedAt, isNotNull);
    });

    test('session cancellation', () async {
      final session = await repo.createSession('theatre-cancel');
      final cancelled = await repo.cancelSession(session.id);

      expect(cancelled.state, equals(CaptureState.cancelled));
      expect(cancelled.state.isTerminal, isTrue);
    });
  });

  group('AI Venue Capture — AI Worker Contracts Definition', () {
    test('worker contract classes are strongly typed and instantiate cleanly', () {
      const coverage = ViewpointCoverageReport(
        coverageScore: 0.88,
        coveredZones: ['stage', 'screen_wall', 'front_rows'],
        missingZones: ['rear_balcony'],
        blindSpots: ['upper_rear_corners'],
      );

      expect(coverage.coverageScore, equals(0.88));
      expect(coverage.missingZones, contains('rear_balcony'));

      const detected = DetectedObject(
        label: 'screen_bezel',
        confidence: 0.94,
        boundingBox2D: [0.1, 0.05, 0.65, 0.95],
      );
      expect(detected.label, equals('screen_bezel'));
      expect(detected.confidence, equals(0.94));
    });
  });
}
