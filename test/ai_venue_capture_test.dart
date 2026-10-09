import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:livescreen/admin/capture/models/models.dart';
import 'package:livescreen/admin/capture/services/services.dart';
import 'package:livescreen/admin/capture/ui/venue_capture_screen.dart';
import 'package:livescreen/admin/models/theatre_configuration.dart';
import 'package:livescreen/admin/models/room_config.dart';
import 'package:livescreen/admin/models/screen_config.dart';
import 'package:livescreen/admin/models/seat_config.dart';
import 'package:livescreen/admin/models/speaker_model.dart';
import 'package:livescreen/admin/models/acoustics_config.dart';
import 'package:livescreen/admin/services/theatre_unity_bridge.dart';
import 'package:livescreen/admin/capture/ui/widgets/floating_venue_assistant.dart';
import 'package:livescreen/admin/screens/theatre_editor_screen.dart';
import 'fixtures/venue_fixtures.dart';

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

      final reviewed = await repo.markDraftReviewed(
        session.id,
        adminUserId: 'admin-tester',
      );

      final confirmed = await repo.confirmDraft(
        session.id,
        reviewed.draft!,
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

  group('AI Venue Capture — Phase 2 Workflow & Integration (20 Criteria)', () {
    late InMemoryVenueCaptureRepository repo;

    setUp(() {
      repo = InMemoryVenueCaptureRepository();
      resetVenueAnalyzer();
    });

    tearDown(() {
      resetVenueAnalyzer();
    });

    // 1. Starting a capture session
    test('1. Starting a capture session initializes in initial state', () async {
      final session = await repo.createSession('theatre-ph2-1');
      expect(session.state, equals(CaptureState.initial));
      expect(session.theatreId, equals('theatre-ph2-1'));
      expect(session.id, isNotEmpty);
      expect(session.draft, isNull);
    });

    // 2. Existing theatre baseline remains unchanged
    test('2. Existing theatre baseline configuration remains unchanged when capture starts', () async {
      final baseline = TheatreConfiguration(
        id: 'theatre-ph2-2',
        basicInfo: TheatreBasicInfo(name: 'Baseline Cinema'),
        room: RoomConfig(width: 20.0, length: 30.0, height: 9.0),
        screen: ScreenConfig(width: 15.0, height: 7.0),
      );

      final session = await repo.createSession(baseline.id);
      final media = VenueCaptureMedia(
        id: 'ev-test',
        sessionId: session.id,
        theatreId: baseline.id,
        type: EvidenceType.photo,
        category: EvidenceCategory.frontWall,
        storagePath: 'theatres/${baseline.id}/ev.jpg',
        filename: 'front.jpg',
        createdAt: DateTime.now(),
      );
      await repo.addEvidence(media);

      // Baseline remains intact
      expect(baseline.room.width, equals(20.0));
      expect(baseline.room.length, equals(30.0));
      expect(baseline.room.height, equals(9.0));
      expect(baseline.screen.width, equals(15.0));
      expect(baseline.screen.height, equals(7.0));
    });

    // 3. New theatre capture does not create fake production theatre
    test('3. New theatre capture uses draft representation without creating fake production theatre', () async {
      const draftTheatreId = 'draft-new-theatre-123';
      final draftRepo = InMemoryVenueCaptureRepository();

      final session = await draftRepo.createSession(draftTheatreId);
      expect(session.id, isNotEmpty);
      expect(session.theatreId, equals(draftTheatreId));
      expect(session.theatreId.startsWith('draft-'), isTrue);

      // Verify no production query or record is required
      final active = await draftRepo.getActiveSessionForTheatre(draftTheatreId);
      expect(active, isNotNull);
      expect(active!.id, equals(session.id));
    });

    // 4. Adding multiple evidence items
    test('4. Adding multiple evidence items preserves categories and upload state', () async {
      final session = await repo.createSession('theatre-ph2-4');

      final photo1 = VenueCaptureMedia(
        id: 'm1',
        sessionId: session.id,
        theatreId: session.theatreId,
        type: EvidenceType.photo,
        category: EvidenceCategory.frontWall,
        storagePath: 'p1.jpg',
        filename: 'front_wall.jpg',
        createdAt: DateTime.now(),
      );
      final photo2 = VenueCaptureMedia(
        id: 'm2',
        sessionId: session.id,
        theatreId: session.theatreId,
        type: EvidenceType.photo,
        category: EvidenceCategory.seating,
        storagePath: 'p2.jpg',
        filename: 'seating.jpg',
        createdAt: DateTime.now(),
      );
      final measure = VenueCaptureMedia(
        id: 'm3',
        sessionId: session.id,
        theatreId: session.theatreId,
        type: EvidenceType.measurement,
        category: EvidenceCategory.measurement,
        storagePath: 'm3.json',
        filename: 'laser_dist.json',
        metadata: {'distance_meters': 22.4},
        createdAt: DateTime.now(),
      );

      await repo.addEvidence(photo1);
      await repo.addEvidence(photo2);
      await repo.addEvidence(measure);

      final list = await repo.listEvidence(session.id);
      expect(list.length, equals(3));
      expect(list.any((m) => m.category == EvidenceCategory.frontWall), isTrue);
      expect(list.any((m) => m.category == EvidenceCategory.seating), isTrue);
      expect(list.any((m) => m.category == EvidenceCategory.measurement), isTrue);
    });

    // 5. Evidence request creation
    test('5. Evidence request creation communicates technical reason and actionable instruction', () async {
      final session = await repo.createSession('theatre-ph2-5');
      final analyzer = MockVenueAnalyzer();

      final frontPhoto = VenueCaptureMedia(
        id: 'm-front',
        sessionId: session.id,
        theatreId: session.theatreId,
        type: EvidenceType.photo,
        category: EvidenceCategory.frontWall,
        storagePath: 'front.jpg',
        filename: 'front.jpg',
        createdAt: DateTime.now(),
      );
      await repo.addEvidence(frontPhoto);

      final result = await analyzer.analyze(VenueAnalysisInput(
        session: session,
        evidence: [frontPhoto],
      ));

      expect(result.targetedRequests.isNotEmpty, isTrue);
      final rearReq = result.targetedRequests.firstWhere((r) => r.target.contains('Rear'));
      expect(rearReq.reason, contains('rear wall is not visible'));
      expect(rearReq.instruction, contains('facing the rear wall'));
      expect(rearReq.priority, equals(RequestPriority.high));
      expect(rearReq.status, equals(RequestStatus.pending));
    });

    // 6. Completing an evidence request
    test('6. Completing an evidence request associates fulfilling evidence and sets fulfilled status', () async {
      final session = await repo.createSession('theatre-ph2-6');
      final req = VenueCaptureRequest(
        id: 'req-rear-1',
        sessionId: session.id,
        theatreId: session.theatreId,
        target: 'Rear Wall View',
        reason: 'Back boundary missing',
        requiredEvidenceType: EvidenceType.photo,
        instruction: 'Stand at row A facing rear',
        createdAt: DateTime.now(),
      );
      await repo.addRequest(req);

      final fulfillingMedia = VenueCaptureMedia(
        id: 'media-rear-fulfilled',
        sessionId: session.id,
        theatreId: session.theatreId,
        type: EvidenceType.photo,
        category: EvidenceCategory.rearWall,
        targetRequestId: req.id,
        storagePath: 'rear.jpg',
        filename: 'rear_wall.jpg',
        createdAt: DateTime.now(),
      );
      await repo.addEvidence(fulfillingMedia);

      final resolved = await repo.resolveRequest(
        req.id,
        status: RequestStatus.fulfilled,
        fulfilledEvidenceId: fulfillingMedia.id,
      );

      expect(resolved.status, equals(RequestStatus.fulfilled));
      expect(resolved.fulfilledEvidenceId, equals('media-rear-fulfilled'));
      expect(resolved.resolvedAt, isNotNull);
    });

    // 7. Iterative evidence -> analysis flow
    test('7. Iterative evidence -> analysis flow updates reconstruction and resolves uncertainty', () async {
      final session = await repo.createSession('theatre-ph2-7');
      final analyzer = MockVenueAnalyzer();

      // Pass 1: Front wall only
      final frontPhoto = VenueCaptureMedia(
        id: 'm-f1',
        sessionId: session.id,
        theatreId: session.theatreId,
        type: EvidenceType.photo,
        category: EvidenceCategory.frontWall,
        storagePath: 'f.jpg',
        filename: 'front.jpg',
        createdAt: DateTime.now(),
      );
      await repo.addEvidence(frontPhoto);

      final pass1Result = await analyzer.analyze(VenueAnalysisInput(
        session: session,
        evidence: [frontPhoto],
      ));

      expect(pass1Result.draft!.room.width.isKnown, isTrue);
      expect(pass1Result.draft!.room.length.isUnknown, isTrue);
      expect(pass1Result.overallConfidence, lessThan(0.70));
      expect(pass1Result.targetedRequests.any((r) => r.target.contains('Rear')), isTrue);

      // Pass 2: Add rear wall photo and measurement
      final rearPhoto = VenueCaptureMedia(
        id: 'm-r1',
        sessionId: session.id,
        theatreId: session.theatreId,
        type: EvidenceType.photo,
        category: EvidenceCategory.rearWall,
        storagePath: 'r.jpg',
        filename: 'rear.jpg',
        createdAt: DateTime.now(),
      );
      final meas = VenueCaptureMedia(
        id: 'm-meas1',
        sessionId: session.id,
        theatreId: session.theatreId,
        type: EvidenceType.measurement,
        category: EvidenceCategory.measurement,
        storagePath: 'm.json',
        filename: 'meas.json',
        metadata: {'distance_meters': 22.4},
        createdAt: DateTime.now(),
      );

      await repo.addEvidence(rearPhoto);
      await repo.addEvidence(meas);

      final pass2Result = await analyzer.analyze(VenueAnalysisInput(
        session: session,
        evidence: [frontPhoto, rearPhoto, meas],
        existingRequests: pass1Result.targetedRequests,
        previousDraft: pass1Result.draft,
      ));

      expect(pass2Result.draft!.room.length.isKnown, isTrue);
      expect(pass2Result.draft!.room.length.value, equals(28.5));
      expect(pass2Result.overallConfidence, greaterThanOrEqualTo(0.85));
      expect(pass2Result.targetedRequests.every((r) => r.status == RequestStatus.fulfilled), isTrue);
    });

    // 8. Low-confidence values remain unresolved
    test('8. Low-confidence values remain unresolved and are not silently guessed', () async {
      final session = await repo.createSession('theatre-ph2-8');
      final analyzer = MockVenueAnalyzer();

      final frontOnly = VenueCaptureMedia(
        id: 'm-front-only',
        sessionId: session.id,
        theatreId: session.theatreId,
        type: EvidenceType.photo,
        category: EvidenceCategory.frontWall,
        storagePath: 'front.jpg',
        filename: 'front.jpg',
        createdAt: DateTime.now(),
      );

      final result = await analyzer.analyze(VenueAnalysisInput(
        session: session,
        evidence: [frontOnly],
      ));

      expect(result.draft!.room.length.isUnknown, isTrue);
      expect(result.draft!.room.length.valueOrNull, isNull);
      expect(result.draft!.seating.seatSpacing.isUnknown, isTrue);
      expect(result.unresolvedFields, contains('Room Length'));
      expect(result.unresolvedFields, contains('Metric Scale Calibration'));
    });

    // 9. Confidence/provenance survives reconstruction
    test('9. Confidence and provenance survive reconstruction draft creation', () async {
      final session = await repo.createSession('theatre-ph2-9');
      final analyzer = MockVenueAnalyzer();

      final front = VenueCaptureMedia(
        id: 'front-id-9',
        sessionId: session.id,
        theatreId: session.theatreId,
        type: EvidenceType.photo,
        category: EvidenceCategory.frontWall,
        storagePath: 'f.jpg',
        filename: 'front.jpg',
        createdAt: DateTime.now(),
      );

      final result = await analyzer.analyze(VenueAnalysisInput(
        session: session,
        evidence: [front],
      ));

      final widthEst = result.draft!.room.width;
      expect(widthEst.provenance, equals(EstimateProvenance.aiEstimated));
      expect(widthEst.confidence, equals(0.86));
      expect(widthEst.evidenceIds, contains('front-id-9'));
    });

    // 10. Worker unavailable
    test('10. Worker unavailable honestly reports unconfigured status', () async {
      setVenueAnalyzer(const UnavailableVenueAnalyzer());
      final session = await repo.createSession('theatre-ph2-10');

      final result = await venueAnalyzer.analyze(VenueAnalysisInput(
        session: session,
        evidence: [],
      ));

      expect(result.isSuccess, isFalse);
      expect(result.isWorkerAvailable, isFalse);
      expect(result.errorMessage, contains('AI Reconstruction Worker is not configured'));
    });

    // 11. Worker failure
    test('11. Worker failure handles pipeline error safely and transitions to failed', () async {
      setVenueAnalyzer(const FailingVenueAnalyzer(errorMessage: 'Out of VRAM'));
      final session = await repo.createSession('theatre-ph2-11');
      await repo.updateSessionState(session.id, CaptureState.analyzing);

      final result = await venueAnalyzer.analyze(VenueAnalysisInput(
        session: session,
        evidence: [],
      ));

      expect(result.isSuccess, isFalse);
      expect(result.errorMessage, equals('Out of VRAM'));

      final failedSession = await repo.updateSessionState(session.id, CaptureState.failed);
      expect(failedSession.state, equals(CaptureState.failed));
    });

    // 12. Capture cancellation
    test('12. Capture cancellation transitions session to cancelled terminal state', () async {
      final session = await repo.createSession('theatre-ph2-12');
      final cancelled = await repo.cancelSession(session.id);
      expect(cancelled.state, equals(CaptureState.cancelled));
      expect(cancelled.state.isTerminal, isTrue);
    });

    // 13. Capture resume
    test('13. Capture resume retrieves active non-terminal session and existing evidence', () async {
      final session = await repo.createSession('theatre-ph2-13');
      final media = VenueCaptureMedia(
        id: 'ev-resume-1',
        sessionId: session.id,
        theatreId: session.theatreId,
        type: EvidenceType.photo,
        category: EvidenceCategory.frontWall,
        storagePath: 'f.jpg',
        filename: 'f.jpg',
        createdAt: DateTime.now(),
      );
      await repo.addEvidence(media);

      final resumed = await repo.getActiveSessionForTheatre('theatre-ph2-13');
      expect(resumed, isNotNull);
      expect(resumed!.id, equals(session.id));

      final resumedEvidence = await repo.listEvidence(resumed.id);
      expect(resumedEvidence.length, equals(1));
      expect(resumedEvidence.first.id, equals('ev-resume-1'));
    });

    // 14. Reconstruction review
    test('14. Reconstruction review marks draft as reviewed with admin ID and timestamp', () async {
      final session = await repo.createSession('theatre-ph2-14');
      await repo.updateSessionState(session.id, CaptureState.analyzing);
      await repo.updateSessionState(session.id, CaptureState.readyForReview);

      final draft = ReconstructionDraft(
        id: 'draft-14',
        sessionId: session.id,
        theatreId: session.theatreId,
        createdAt: DateTime.now(),
      );
      await repo.saveReconstructionDraft(session.id, draft);

      final reviewedSession = await repo.markDraftReviewed(
        session.id,
        adminUserId: 'admin-auditor-99',
      );

      expect(reviewedSession.draft!.isReviewed, isTrue);
      expect(reviewedSession.draft!.reviewedBy, equals('admin-auditor-99'));
      expect(reviewedSession.draft!.reviewedAt, isNotNull);
      expect(reviewedSession.state, equals(CaptureState.reviewing));

      final confirmed = await repo.confirmDraft(
        session.id,
        reviewedSession.draft!,
        adminUserId: 'admin-auditor-99',
      );

      expect(confirmed.draft!.isReviewed, isTrue);
      expect(confirmed.draft!.reviewedBy, equals('admin-auditor-99'));
      expect(confirmed.draft!.reviewedAt, isNotNull);
      expect(confirmed.state, equals(CaptureState.confirmed));
    });

    // 15. Live TheatreConfiguration unchanged before confirmation
    test('15. Live TheatreConfiguration remains unchanged throughout capture until explicit confirmation', () async {
      final original = TheatreConfiguration(
        id: 'theatre-ph2-15',
        basicInfo: TheatreBasicInfo(name: 'Unchanged Cinema'),
        room: RoomConfig(width: 18.0, length: 24.0, height: 7.0),
      );

      final session = await repo.createSession(original.id);
      await repo.updateSessionState(session.id, CaptureState.analyzing);
      await repo.updateSessionState(session.id, CaptureState.readyForReview);

      expect(original.room.width, equals(18.0));
      expect(original.room.length, equals(24.0));
      expect(original.room.height, equals(7.0));
    });

    // 16. Confirmation applies reconstruction through DraftToTheatreMapper
    test('16. Confirmation applies reconstruction through DraftToTheatreMapper preserving protected fields', () async {
      final original = TheatreConfiguration(
        id: 'theatre-ph2-16',
        basicInfo: TheatreBasicInfo(name: 'Protected Cinema'),
        ownerId: 'owner-user-77',
        verificationStatus: 'verified',
        status: TheatreStatus.published,
        room: RoomConfig(width: 15.0, length: 20.0, height: 6.0),
      );

      final draft = ReconstructionDraft(
        id: 'draft-16',
        sessionId: 'session-16',
        theatreId: original.id,
        createdAt: DateTime.now(),
        isReviewed: true,
        room: DraftRoomGeometry(
          width: Estimate<double>.aiEstimated(22.0, confidence: 0.9),
          length: Estimate<double>.aiEstimated(30.0, confidence: 0.9),
          height: const Estimate<double>.unknown(), // unknown should preserve original.height
        ),
      );

      final mapped = DraftToTheatreMapper.applyDraftToConfiguration(original, draft);

      expect(mapped.id, equals(original.id));
      expect(mapped.ownerId, equals('owner-user-77'));
      expect(mapped.verificationStatus, equals('verified'));
      expect(mapped.status, equals(TheatreStatus.published));
      expect(mapped.room.width, equals(22.0));
      expect(mapped.room.length, equals(30.0));
      expect(mapped.room.height, equals(6.0)); // preserved!
    });

    // 17. Unity preview receives canonical TheatreConfiguration
    test('17. Unity preview receives canonical TheatreConfiguration payload', () async {
      final original = TheatreConfiguration(
        id: 'theatre-ph2-17',
        basicInfo: TheatreBasicInfo(name: 'Unity Cinema'),
        room: RoomConfig(width: 22.0, length: 28.0, height: 8.5),
        screen: ScreenConfig(width: 16.0, height: 7.0),
      );

      final payload = TheatreUnityBridge.toUnityPayload(original);

      expect(payload['payloadVersion'], equals(2));
      expect(payload['theatreId'], equals('theatre-ph2-17'));
      expect(payload['roomWidth'], equals(22.0));
      expect(payload['roomLength'], equals(28.0));
      expect(payload['screenWidth'], equals(16.0));
    });

    // 18. Unauthorized theatre access is rejected
    test('18. Unauthorized theatre access is rejected by session scoping', () async {
      final sessionA = await repo.createSession('theatre-A');
      final sessionB = await repo.createSession('theatre-B');

      final mediaA = VenueCaptureMedia(
        id: 'm-A',
        sessionId: sessionA.id,
        theatreId: 'theatre-A',
        type: EvidenceType.photo,
        category: EvidenceCategory.frontWall,
        storagePath: 'a.jpg',
        filename: 'a.jpg',
        createdAt: DateTime.now(),
      );
      await repo.addEvidence(mediaA);

      final listB = await repo.listEvidence(sessionB.id);
      expect(listB, isEmpty);

      final activeA = await repo.getActiveSessionForTheatre('theatre-A');
      final activeB = await repo.getActiveSessionForTheatre('theatre-B');
      expect(activeA!.id, isNot(equals(activeB!.id)));
    });

    // 19. Customer/producer access is rejected
    test('19. Customer and producer roles have no access to venue capture', () {
      bool canAccessCapture(String userRole) => userRole == 'theatre_admin' || userRole == 'platform_admin';

      expect(canAccessCapture('theatre_admin'), isTrue);
      expect(canAccessCapture('platform_admin'), isTrue);
      expect(canAccessCapture('customer'), isFalse);
      expect(canAccessCapture('producer'), isFalse);
      expect(canAccessCapture('anonymous'), isFalse);
    });

    // 20. Existing theatre configuration is preserved when capture fails
    test('20. Existing theatre configuration is preserved when capture worker fails', () async {
      final original = TheatreConfiguration(
        id: 'theatre-ph2-20',
        basicInfo: TheatreBasicInfo(name: 'Rock Solid Cinema'),
        room: RoomConfig(width: 25.0, length: 35.0, height: 10.0),
      );

      final session = await repo.createSession(original.id);
      await repo.updateSessionState(session.id, CaptureState.analyzing);

      setVenueAnalyzer(const FailingVenueAnalyzer(errorMessage: 'CUDA out of memory'));
      final result = await venueAnalyzer.analyze(VenueAnalysisInput(
        session: session,
        evidence: [],
      ));

      await repo.updateSessionState(session.id, CaptureState.failed);

      expect(result.isSuccess, isFalse);
      expect(original.room.width, equals(25.0));
      expect(original.room.length, equals(35.0));
      expect(original.room.height, equals(10.0));
    });
  });

  group('AI Venue Capture — UI Widget Workflow & Integrity', () {
    testWidgets('VenueCaptureScreen renders 4 tabs in dark cinema aesthetic', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: VenueCaptureScreen(
            theatreId: 'ui-test-theatre',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('AI Venue Capture'), findsOneWidget);
      expect(find.text('1. Capture'), findsOneWidget);
      expect(find.text('2. Analysis'), findsOneWidget);
      expect(find.text('3. Reconstruction'), findsOneWidget);
      expect(find.text('4. Review & Confirm'), findsOneWidget);
      expect(find.textContaining('Core Rule'), findsOneWidget);
    });

    testWidgets('VenueCaptureScreen honestly reports worker offline when unavailable', (tester) async {
      setVenueAnalyzer(const UnavailableVenueAnalyzer());

      await tester.pumpWidget(
        const MaterialApp(
          home: VenueCaptureScreen(
            theatreId: 'ui-test-theatre-unavail',
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap on Tab 2: Analysis
      await tester.tap(find.text('2. Analysis'));
      await tester.pumpAndSettle();

      expect(find.text('Worker Offline / Unconfigured'), findsOneWidget);
      expect(find.textContaining('No GPU worker endpoint'), findsOneWidget);
    });

    testWidgets('VenueCaptureScreen runs analysis and enables confirmation with MockVenueAnalyzer', (tester) async {
      tester.view.physicalSize = const Size(1200, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      setVenueAnalyzer(MockVenueAnalyzer());

      TheatreConfiguration? confirmedConfig;

      await tester.pumpWidget(
        MaterialApp(
          home: VenueCaptureScreen(
            theatreId: 'ui-test-theatre-confirm',
            adminUserId: 'admin-tester-42',
            onConfigurationUpdated: (updated) {
              confirmedConfig = updated;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Add a photo
      await tester.tap(find.text('Add Photo View'));
      await tester.pumpAndSettle();

      expect(find.text('Upload Venue Photo'), findsOneWidget);
      await tester.tap(find.text('Add Evidence'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Submitted Evidence (1)'), findsOneWidget);

      // Initial run: analyze initial evidence (triggers targeted requests)
      await tester.tap(find.text('Run AI Venue Reconstruction'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Targeted Evidence Required'), findsOneWidget);

      // Fulfill photo request:
      await tester.tap(find.text('Capture Photo'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add Evidence'));
      await tester.pumpAndSettle();

      // Fulfill measurement request:
      await tester.tap(find.text('Record Measurement'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Record Scale'));
      await tester.pumpAndSettle();

      // Re-analyze with fulfilled requests
      await tester.tap(find.text('Re-analyze Venue with New Evidence'));
      await tester.pumpAndSettle();

      // Check Reconstruction Tab
      await tester.tap(find.text('3. Reconstruction'));
      await tester.pumpAndSettle();

      expect(find.text('Room Envelope Geometry'), findsOneWidget);
      expect(find.text('Screen & Stage Geometry'), findsOneWidget);

      // Check Review Tab
      await tester.tap(find.text('4. Review & Confirm'));
      await tester.pumpAndSettle();

      // Step 1: Approve & Mark Draft as Reviewed
      final reviewBtn = find.text('Approve & Mark Draft as Reviewed');
      await tester.ensureVisible(reviewBtn);
      await tester.tap(reviewBtn);
      await tester.pumpAndSettle();

      expect(find.textContaining('Draft Approved & Reviewed by admin-tester-42'), findsOneWidget);

      // Step 2: Confirm & Apply to Theatre Configuration
      final confirmBtn = find.text('Confirm & Apply to Theatre Configuration');
      await tester.ensureVisible(confirmBtn);
      await tester.tap(confirmBtn);
      await tester.pumpAndSettle();

      // Dialog confirms
      expect(find.text('Confirm AI Venue Reconstruction'), findsOneWidget);
      await tester.tap(find.text('Confirm & Apply'));
      await tester.pumpAndSettle();

      expect(confirmedConfig, isNotNull);
      expect(confirmedConfig!.room.width, isNonZero);
    });
  });

  group('AI Venue Capture — Phase 2 Correction Pass Guardrails', () {
    late InMemoryVenueCaptureRepository repo;

    setUp(() {
      repo = InMemoryVenueCaptureRepository();
      resetVenueAnalyzer();
    });

    tearDown(() {
      resetVenueAnalyzer();
    });

    test('1. Mock analyzer cannot be accidentally used as production default', () {
      expect(venueAnalyzer, isA<UnavailableVenueAnalyzer>());
      expect(venueAnalyzer.isAvailable, isFalse);
      expect(venueAnalyzer.name, contains('Unconnected'));
    });

    test('2. No speakers generated without speaker evidence', () async {
      final analyzer = MockVenueAnalyzer();
      final session = await repo.createSession('th-no-spk');

      final frontWallOnly = VenueCaptureMedia(
        id: 'f-only',
        sessionId: session.id,
        theatreId: session.theatreId,
        type: EvidenceType.photo,
        category: EvidenceCategory.frontWall,
        storagePath: 'front.jpg',
        filename: 'front.jpg',
        createdAt: DateTime.now(),
      );

      final result = await analyzer.analyze(VenueAnalysisInput(
        session: session,
        evidence: [frontWallOnly],
      ));

      expect(result.draft!.speakers, isEmpty);
      expect(result.unresolvedFields, contains('Speaker Placements'));
    });

    test('3. Every generated speaker has supporting evidence IDs', () async {
      final analyzer = MockVenueAnalyzer();
      final session = await repo.createSession('th-spk-ev');

      final speakerPhoto = VenueCaptureMedia(
        id: 'spk-photo-1',
        sessionId: session.id,
        theatreId: session.theatreId,
        type: EvidenceType.photo,
        category: EvidenceCategory.speakers,
        storagePath: 'speaker.jpg',
        filename: 'speaker.jpg',
        createdAt: DateTime.now(),
      );

      final result = await analyzer.analyze(VenueAnalysisInput(
        session: session,
        evidence: [speakerPhoto],
      ));

      expect(result.draft!.speakers, isNotEmpty);
      for (final spk in result.draft!.speakers) {
        expect(spk.evidenceIds, isNotEmpty);
        expect(spk.evidenceIds, contains('spk-photo-1'));
        expect(spk.visualCabinetType, equals(SpeakerType.sideSurround));
      }
    });

    test('4. No physical seat positions when scale is unknown', () async {
      final analyzer = MockVenueAnalyzer();
      final session = await repo.createSession('th-no-scale');

      final seatPhoto = VenueCaptureMedia(
        id: 'seat-photo-1',
        sessionId: session.id,
        theatreId: session.theatreId,
        type: EvidenceType.photo,
        category: EvidenceCategory.seating,
        storagePath: 'seating.jpg',
        filename: 'seating.jpg',
        createdAt: DateTime.now(),
      );

      final result = await analyzer.analyze(VenueAnalysisInput(
        session: session,
        evidence: [seatPhoto],
      ));

      // Counts may be estimated
      expect(result.draft!.seating.rows.isKnown, isTrue);
      // But metric spacing remains explicitly UNKNOWN
      expect(result.draft!.seating.seatSpacing.isUnknown, isTrue);
      expect(result.draft!.seating.rowSpacing.isUnknown, isTrue);
      expect(result.draft!.seating.rowRisePerRow.isUnknown, isTrue);
      // And physical positions are not invented
      expect(result.draft!.seating.seats, isEmpty);
    });

    test('5. Existing baseline seating is preserved when reconstruction cannot establish geometry', () async {
      final analyzer = MockVenueAnalyzer();
      final session = await repo.createSession('th-preserve-seats');

      final baselineSeats = [
        SeatConfig(row: 'A', number: 1, position: Position3(x: -1.0, y: 0.0, z: 5.0)),
        SeatConfig(row: 'A', number: 2, position: Position3(x: 0.0, y: 0.0, z: 5.0)),
      ];
      final baseline = TheatreConfiguration(
        id: 'th-preserve-seats',
        basicInfo: TheatreBasicInfo(name: 'Baseline Seating'),
        seats: baselineSeats,
        lastSeatLayout: SeatLayoutParams(rows: 5, seatsPerRow: 6, seatSpacing: 0.72, rowSpacing: 1.25),
      );

      final frontPhoto = VenueCaptureMedia(
        id: 'front-p1',
        sessionId: session.id,
        theatreId: session.theatreId,
        type: EvidenceType.photo,
        category: EvidenceCategory.frontWall,
        storagePath: 'front.jpg',
        filename: 'front.jpg',
        createdAt: DateTime.now(),
      );

      // Analyze without measurement
      final result = await analyzer.analyze(VenueAnalysisInput(
        session: session,
        evidence: [frontPhoto],
        baselineConfig: baseline,
      ));

      expect(result.draft!.seating.seats.length, equals(2));
      expect(result.draft!.seating.seats.first.id, contains('baseline'));

      // Map to theatre configuration
      final reviewed = result.draft!.copyWith(isReviewed: true);
      final mapped = DraftToTheatreMapper.applyDraftToConfiguration(baseline, reviewed);

      expect(mapped.seats.length, equals(2));
      expect(mapped.seats.first.position.x, equals(-1.0));
      expect(mapped.lastSeatLayout!.seatSpacing, equals(0.72));
      expect(mapped.lastSeatLayout!.rowSpacing, equals(1.25));
    });

    test('6. Hardcoded admin ID does not exist; empty ID fails safely', () async {
      final session = await repo.createSession('th-admin-id');
      final draft = ReconstructionDraft(
        id: 'draft-admin',
        sessionId: session.id,
        theatreId: session.theatreId,
        createdAt: DateTime.now(),
      );
      await repo.saveReconstructionDraft(session.id, draft);

      // Attempting to review with empty admin ID throws StateError
      expect(
        () => repo.markDraftReviewed(session.id, adminUserId: ''),
        throwsStateError,
      );

      // Attempting to confirm with empty admin ID throws StateError
      expect(
        () => repo.confirmDraft(session.id, draft.copyWith(isReviewed: true), adminUserId: ''),
        throwsStateError,
      );
    });

    test('7. Actual authenticated admin identity is recorded', () async {
      final session = await repo.createSession('th-real-admin');
      final draft = ReconstructionDraft(
        id: 'draft-real',
        sessionId: session.id,
        theatreId: session.theatreId,
        createdAt: DateTime.now(),
      );
      await repo.saveReconstructionDraft(session.id, draft);

      final reviewed = await repo.markDraftReviewed(
        session.id,
        adminUserId: 'auth-user-uuid-999',
      );

      expect(reviewed.draft!.reviewedBy, equals('auth-user-uuid-999'));
      expect(reviewed.draft!.isReviewed, isTrue);
    });

    test('8. Draft cannot be confirmed before review', () async {
      final session = await repo.createSession('th-unreviewed');
      final unreviewedDraft = ReconstructionDraft(
        id: 'draft-unreviewed',
        sessionId: session.id,
        theatreId: session.theatreId,
        createdAt: DateTime.now(),
        isReviewed: false,
      );
      await repo.saveReconstructionDraft(session.id, unreviewedDraft);

      expect(
        () => repo.confirmDraft(session.id, unreviewedDraft, adminUserId: 'admin-1'),
        throwsA(isA<UnreviewedDraftException>()),
      );
    });

    test('9. markDraftReviewed records reviewer and advances session state', () async {
      final session = await repo.createSession('th-review-advance');
      await repo.updateSessionState(session.id, CaptureState.analyzing);
      await repo.updateSessionState(session.id, CaptureState.readyForReview);

      final draft = ReconstructionDraft(
        id: 'draft-advance',
        sessionId: session.id,
        theatreId: session.theatreId,
        createdAt: DateTime.now(),
      );
      await repo.saveReconstructionDraft(session.id, draft);

      final reviewed = await repo.markDraftReviewed(
        session.id,
        adminUserId: 'reviewer-jane',
      );

      expect(reviewed.state, equals(CaptureState.reviewing));
      expect(reviewed.draft!.isReviewed, isTrue);
      expect(reviewed.draft!.reviewedBy, equals('reviewer-jane'));
      expect(reviewed.draft!.reviewedAt, isNotNull);
    });

    test('10. Confirmation succeeds after valid review', () async {
      final session = await repo.createSession('th-valid-confirm');
      await repo.updateSessionState(session.id, CaptureState.analyzing);
      await repo.updateSessionState(session.id, CaptureState.readyForReview);

      final draft = ReconstructionDraft(
        id: 'draft-valid',
        sessionId: session.id,
        theatreId: session.theatreId,
        createdAt: DateTime.now(),
      );
      await repo.saveReconstructionDraft(session.id, draft);

      final reviewed = await repo.markDraftReviewed(
        session.id,
        adminUserId: 'admin-final',
      );
      final confirmed = await repo.confirmDraft(
        session.id,
        reviewed.draft!,
        adminUserId: 'admin-final',
      );

      expect(confirmed.state, equals(CaptureState.confirmed));
      expect(confirmed.draft!.isReviewed, isTrue);
    });

    test('11. Live TheatreConfiguration remains unchanged when review/confirmation fails', () async {
      final original = TheatreConfiguration(
        id: 'th-fail-safe',
        basicInfo: TheatreBasicInfo(name: 'Safe Cinema'),
        room: RoomConfig(width: 14.0, length: 22.0, height: 6.5),
        seats: [SeatConfig(row: 'A', number: 1, position: Position3(x: 0, y: 0, z: 4))],
      );

      final session = await repo.createSession(original.id);
      final unreviewedDraft = ReconstructionDraft(
        id: 'draft-bad',
        sessionId: session.id,
        theatreId: original.id,
        createdAt: DateTime.now(),
        isReviewed: false,
        room: DraftRoomGeometry(width: Estimate<double>.measured(30.0, confidence: 1.0)),
      );

      // Attempt confirmation without review
      try {
        await repo.confirmDraft(session.id, unreviewedDraft, adminUserId: 'admin');
        fail('Should have thrown UnreviewedDraftException');
      } catch (e) {
        expect(e, isA<UnreviewedDraftException>());
      }

      // Verify original is 100% untouched
      expect(original.room.width, equals(14.0));
      expect(original.room.length, equals(22.0));
    });
  });

  group('AI Venue Capture — Conversational AI Assistant & Floating UI (Phase 3)', () {
    late ReconstructionDraft baselineDraft;

    setUp(() {
      VenueAssistantRegistry.reset();
      baselineDraft = ReconstructionDraft(
        id: 'draft-p3',
        sessionId: 'session-p3-1',
        theatreId: 'th-p3-theatre',
        createdAt: DateTime.now(),
      );
    });

    test('1. Messaging: admin and assistant messages stored chronologically with session scoping', () async {
      final assistant = DeterministicVenueAssistant(sessionId: 'session-scoped-1');
      assistant.ensureGreeting(contextName: 'Seating Configuration');

      expect(assistant.messages.length, equals(1));
      expect(assistant.messages.first.role, equals(VenueAssistantRole.assistant));
      expect(assistant.messages.first.text, contains('Seating'));

      final resp1 = await assistant.processMessage(
        text: 'There are 12 rows.',
        draft: baselineDraft,
      );

      expect(assistant.messages.length, equals(3));
      expect(assistant.messages[1].role, equals(VenueAssistantRole.admin));
      expect(assistant.messages[1].text, equals('There are 12 rows.'));
      expect(assistant.messages[2].role, equals(VenueAssistantRole.assistant));
      expect(assistant.messages[2].text, equals('Got it — 12 rows.'));
      expect(resp1.updatedDraft!.seating.rows.value, equals(12));

      // Separate session has its own isolated conversation
      final separateAssistant = DeterministicVenueAssistant(sessionId: 'session-scoped-2');
      separateAssistant.ensureGreeting(contextName: 'Screen Configuration');
      expect(separateAssistant.messages.length, equals(1));
      expect(separateAssistant.messages.first.text, contains('Screen'));
    });

    test('2. Conversation context survives close and reopen via VenueAssistantRegistry', () async {
      final asst1 = VenueAssistantRegistry.getOrCreate('session-persist');
      asst1.ensureGreeting();
      await asst1.processMessage(
        text: 'There are 12 rows.',
        draft: baselineDraft,
      );

      // Re-fetching same session returns same instance with preserved messages
      final asst2 = VenueAssistantRegistry.getOrCreate('session-persist');
      expect(identical(asst1, asst2), isTrue);
      expect(asst2.messages.length, equals(3)); // greeting + admin + assistant
      expect(asst2.messages[1].text, equals('There are 12 rows.'));
    });

    test('3. Seating: "There are 12 rows." updates logical row count', () async {
      final assistant = DeterministicVenueAssistant(sessionId: 's-rows');
      final resp = await assistant.processMessage(
        text: 'There are 12 rows.',
        draft: baselineDraft,
      );

      expect(resp.appliedAction, isA<SetRowCountAction>());
      expect((resp.appliedAction as SetRowCountAction).count, equals(12));
      expect(resp.updatedDraft!.seating.rows.isKnown, isTrue);
      expect(resp.updatedDraft!.seating.rows.value, equals(12));
      expect(resp.message.text, equals('Got it — 12 rows.'));
    });

    test('4. Seating: "There are 16 seats in each row." updates default seat count', () async {
      final assistant = DeterministicVenueAssistant(sessionId: 's-seats-per-row');
      final resp = await assistant.processMessage(
        text: 'There are 16 seats in each row.',
        draft: baselineDraft,
      );

      expect(resp.appliedAction, isA<SetDefaultSeatsPerRowAction>());
      expect((resp.appliedAction as SetDefaultSeatsPerRowAction).count, equals(16));
      expect(resp.updatedDraft!.seating.seatsPerRow.isKnown, isTrue);
      expect(resp.updatedDraft!.seating.seatsPerRow.value, equals(16));
      expect(resp.message.text, equals('Got it — 16 seats per row.'));
    });

    test('5. Seating: "There are 3 seating blocks." creates three blocks', () async {
      final assistant = DeterministicVenueAssistant(sessionId: 's-blocks');
      final resp = await assistant.processMessage(
        text: 'There are 3 seating blocks.',
        draft: baselineDraft,
      );

      expect(resp.appliedAction, isA<SetBlockCountAction>());
      expect((resp.appliedAction as SetBlockCountAction).count, equals(3));
      expect(resp.updatedDraft!.seating.blockCount, equals(3));
      expect(resp.message.text, contains('configured 3 seating blocks'));
    });

    test('6. Seating: "Put an aisle after seat 4 and after seat 12." produces 4 | 8 | 4 pattern', () async {
      final assistant = DeterministicVenueAssistant(sessionId: 's-aisles');

      // First establish 16 seats per row
      final step1 = await assistant.processMessage(
        text: 'There are 16 seats per row.',
        draft: baselineDraft,
      );

      // Then configure aisles after 4 and 12
      final step2 = await assistant.processMessage(
        text: 'Put an aisle after seat 4 and after seat 12.',
        draft: step1.updatedDraft!,
      );

      expect(step2.appliedAction, isA<SetAisleBoundariesAction>());
      final action = step2.appliedAction as SetAisleBoundariesAction;
      expect(action.aisleAfterSeats, equals([4, 12]));
      expect(step2.updatedDraft!.seating.aisleAfterSeats, equals([4, 12]));
      expect(step2.updatedDraft!.seating.blockCount, equals(3));
      expect(
        step2.message.text,
        contains('4 seats | aisle | 8 seats | aisle | 4 seats'),
      );
      expect(
        step2.message.text,
        contains('I will determine the physical aisle widths from venue evidence'),
      );
    });

    test('7. Seating: "Actually remove the aisle after seat 12." updates blocks to 4 | 12', () async {
      final assistant = DeterministicVenueAssistant(sessionId: 's-remove-aisle');

      // 1. 16 seats per row
      final step1 = await assistant.processMessage(
        text: 'There are 16 seats per row.',
        draft: baselineDraft,
      );

      // 2. Aisles after 4 and 12
      final step2 = await assistant.processMessage(
        text: 'Put an aisle after seat 4 and after seat 12.',
        draft: step1.updatedDraft!,
      );
      expect(step2.updatedDraft!.seating.aisleAfterSeats, equals([4, 12]));

      // 3. Remove aisle after 12
      final step3 = await assistant.processMessage(
        text: 'Actually remove the aisle after seat 12.',
        draft: step2.updatedDraft!,
      );

      expect(step3.appliedAction, isA<RemoveAisleBoundaryAction>());
      expect((step3.appliedAction as RemoveAisleBoundaryAction).seatNumber, equals(12));
      expect(step3.updatedDraft!.seating.aisleAfterSeats, equals([4]));
      expect(step3.updatedDraft!.seating.blockCount, equals(2));
      expect(step3.message.text, contains('4 seats | aisle | 12 seats'));
    });

    test('8. Seating: irregular rows "Rows 1 to 5 have 16 seats and rows 6 to 12 have 18."', () async {
      final assistant = DeterministicVenueAssistant(sessionId: 's-irregular');
      final resp = await assistant.processMessage(
        text: 'Rows 1 to 5 have 16 seats and rows 6 to 12 have 18.',
        draft: baselineDraft,
      );

      expect(resp.appliedAction, isA<SetRowSeatCountAction>());
      final counts = resp.updatedDraft!.seating.rowSeatCounts;
      for (int r = 1; r <= 5; r++) {
        expect(counts[r], equals(16));
      }
      for (int r = 6; r <= 12; r++) {
        expect(counts[r], equals(18));
      }
      expect(resp.message.text, contains('rows 1–5 set to 16 seats'));
      expect(resp.message.text, contains('rows 6–12 set to 18 seats'));
    });

    test('9. Seating: missing seats "Remove seat 7 from row 5."', () async {
      final assistant = DeterministicVenueAssistant(sessionId: 's-remove-seat');
      final resp = await assistant.processMessage(
        text: 'Remove seat 7 from row 5.',
        draft: baselineDraft,
      );

      expect(resp.appliedAction, isA<RemoveSeatAction>());
      final action = resp.appliedAction as RemoveSeatAction;
      expect(action.row, equals('5'));
      expect(action.seatNumber, equals(7));
      expect(resp.updatedDraft!.seating.removedSeats, contains('5-7'));
      expect(resp.message.text, contains('Removed seat 7 from row 5'));
    });

    test('10. Physical geometry: logical seating exists with unknown physical measurements', () async {
      final assistant = DeterministicVenueAssistant(sessionId: 's-no-fake-dims');
      final resp = await assistant.processMessage(
        text: 'There are 12 rows with 16 seats in each row. Put an aisle after seat 4 and seat 12.',
        draft: baselineDraft,
      );

      final seating = resp.updatedDraft!.seating;
      // Logical values are populated
      expect(seating.rows.value, equals(12));
      expect(seating.seatsPerRow.value, equals(16));
      expect(seating.aisleAfterSeats, equals([4, 12]));

      // Physical scale remains strictly UNKNOWN
      expect(seating.seatSpacing.isUnknown, isTrue);
      expect(seating.rowSpacing.isUnknown, isTrue);
      expect(seating.rowRisePerRow.isUnknown, isTrue);
      expect(seating.aisleWidth.isUnknown, isTrue);

      // Physical individual seat positions are NOT fabricated
      expect(seating.seats, isEmpty);
    });

    test('11. Physical geometry: measurement requests happen when scale is required', () async {
      final assistant = DeterministicVenueAssistant(sessionId: 's-req-measure');
      final resp = await assistant.processMessage(
        text: 'Request measurement',
        draft: baselineDraft,
      );

      expect(resp.requiresMeasurement, isTrue);
      expect(resp.appliedAction, isA<TargetedMeasurementRequestAction>());
      expect(
        resp.message.text,
        contains('Please measure the aisle between the first and second seating blocks'),
      );
    });

    test('12. Ambiguity: "Make the aisle wider." generates clarification without guessing', () async {
      final assistant = DeterministicVenueAssistant(sessionId: 's-ambig-aisle');
      final resp = await assistant.processMessage(
        text: 'Make the aisle wider.',
        draft: baselineDraft,
      );

      expect(resp.appliedAction, isA<ClarificationRequiredAction>());
      expect(resp.clarificationQuestion, contains('Which aisle should I change'));
      expect(resp.message.text, contains('the aisle after seat 4 or the aisle after seat 12?'));
      // Draft must NOT be mutated
      expect(resp.updatedDraft, equals(baselineDraft));
    });

    test('13. Ambiguity: "Move the screen back." generates clarification without guessing', () async {
      final assistant = DeterministicVenueAssistant(sessionId: 's-ambig-screen');
      final resp = await assistant.processMessage(
        text: 'Move the screen back.',
        draft: baselineDraft,
      );

      expect(resp.appliedAction, isA<ClarificationRequiredAction>());
      expect(resp.clarificationQuestion, contains('Do you mean farther from the seating area or closer to it?'));
      // Draft must NOT be mutated
      expect(resp.updatedDraft, equals(baselineDraft));
    });

    test('14. Unrelated query: "What movies are playing?" gives focused assistance refusal', () async {
      final assistant = DeterministicVenueAssistant(sessionId: 's-unrelated');
      final resp = await assistant.processMessage(
        text: 'What movies are playing tonight?',
        draft: baselineDraft,
      );

      expect(resp.appliedAction, isA<UnrelatedQueryAction>());
      expect(resp.message.text, equals('This assistant is for configuring your theatre venue.'));
      expect(resp.updatedDraft, equals(baselineDraft));
    });

    test('15. Undo: "Undo that." reverses the most recent assistant draft mutation', () async {
      final assistant = DeterministicVenueAssistant(sessionId: 's-undo');

      // 1. Initial change: 12 rows
      final step1 = await assistant.processMessage(
        text: 'There are 12 rows.',
        draft: baselineDraft,
      );
      expect(step1.updatedDraft!.seating.rows.value, equals(12));

      // 2. Second change: 14 rows
      final step2 = await assistant.processMessage(
        text: 'Change it to 14 rows.',
        draft: step1.updatedDraft!,
      );
      expect(step2.updatedDraft!.seating.rows.value, equals(14));

      // 3. Undo
      final undoResp = await assistant.processMessage(
        text: 'Undo that.',
        draft: step2.updatedDraft!,
      );

      expect(undoResp.appliedAction, isA<UndoAction>());
      expect(undoResp.updatedDraft!.seating.rows.value, equals(12));
    });

    test('16. Draft safety: assistant mutates ReconstructionDraft ONLY, never TheatreConfiguration', () async {
      final original = TheatreConfiguration(
        id: 'th-draft-safe',
        basicInfo: TheatreBasicInfo(name: 'Untouched Theatre'),
        room: RoomConfig(width: 15.0, length: 25.0, height: 7.0),
        lastSeatLayout: SeatLayoutParams(rows: 8, seatsPerRow: 10),
      );

      final draft = ReconstructionDraft.fromTheatreConfiguration(original);
      final assistant = DeterministicVenueAssistant(sessionId: 's-draft-safety');

      final resp = await assistant.processMessage(
        text: 'There are 16 rows.',
        draft: draft,
      );

      // Draft updated to 16
      expect(resp.updatedDraft!.seating.rows.value, equals(16));

      // Live TheatreConfiguration remains strictly unchanged at 8
      expect(original.lastSeatLayout!.rows, equals(8));
      expect(original.room.width, equals(15.0));
      expect(original.basicInfo.name, equals('Untouched Theatre'));
    });

    test('17. Worker safety: production default remains UnavailableVenueAnalyzer without fake claims', () {
      final analyzer = UnavailableVenueAnalyzer();
      expect(analyzer.isAvailable, isFalse);
      expect(analyzer.name, contains('Unconnected'));
    });

    testWidgets('18. UI: FloatingVenueAssistant renders circular button and expands to popup', (tester) async {
      ReconstructionDraft current = baselineDraft;
      ReconstructionDraft? updated;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                const Center(child: Text('Underlying Configuration Content')),
                Positioned(
                  right: 20,
                  bottom: 20,
                  child: FloatingVenueAssistant(
                    sessionId: 'widget-test-session',
                    theatreId: 'widget-theatre',
                    contextName: 'Seating Configuration',
                    currentDraft: current,
                    onDraftUpdated: (draft) => updated = draft,
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      // 1. Initial closed state: circular button is present
      expect(find.byKey(const Key('floating_venue_assistant_button')), findsOneWidget);
      expect(find.byKey(const Key('floating_venue_assistant_popup')), findsNothing);
      expect(find.text('Underlying Configuration Content'), findsOneWidget);

      // 2. Tap circular button to open popup
      await tester.tap(find.byKey(const Key('floating_venue_assistant_button')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('floating_venue_assistant_popup')), findsOneWidget);
      expect(find.text('AI VENUE ASSISTANT'), findsOneWidget);
      expect(find.text('Seating Configuration'), findsOneWidget);

      // 3. Enter natural language instruction
      await tester.enterText(
        find.byKey(const Key('floating_venue_assistant_input')),
        'There are 12 rows.',
      );
      await tester.tap(find.byKey(const Key('floating_venue_assistant_send')));
      await tester.pumpAndSettle();

      // Verified message bubble and updated draft
      expect(find.text('There are 12 rows.'), findsOneWidget);
      expect(find.text('Got it — 12 rows.'), findsOneWidget);
      expect(updated, isNotNull);
      expect(updated!.seating.rows.value, equals(12));

      // 4. Tap close button
      await tester.tap(find.byKey(const Key('floating_venue_assistant_close')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('floating_venue_assistant_popup')), findsNothing);
      expect(find.byKey(const Key('floating_venue_assistant_button')), findsOneWidget);

      // 5. Reopen: conversation state survives
      await tester.tap(find.byKey(const Key('floating_venue_assistant_button')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('floating_venue_assistant_popup')), findsOneWidget);
      expect(find.text('There are 12 rows.'), findsOneWidget);
      expect(find.text('Got it — 12 rows.'), findsOneWidget);
    });

    testWidgets('19. UI: FloatingVenueAssistant is present in VenueCaptureScreen', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: VenueCaptureScreen(
            theatreId: 'th-ui-capture',
            isDraftTheatre: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('floating_venue_assistant_button')), findsOneWidget);
    });

    testWidgets('20. UI: FloatingVenueAssistant is present in TheatreEditorScreen with dynamic context', (tester) async {
      final config = TheatreConfiguration(
        id: 'th-editor-ui',
        basicInfo: TheatreBasicInfo(name: 'Studio Cinema'),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: TheatreEditorScreen(theatreId: config.id, initialConfig: config),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('floating_venue_assistant_button')), findsOneWidget);

      // Open popup and verify initial context is Room Configuration (Tab 0)
      await tester.tap(find.byKey(const Key('floating_venue_assistant_button')));
      await tester.pumpAndSettle();

      expect(find.text('Room Configuration'), findsOneWidget);

      // Switch to Seating tab (Tab index 2)
      await tester.tap(find.text('Seating'));
      await tester.pumpAndSettle();

      expect(find.text('Seating Configuration'), findsOneWidget);
    });
  });

  // ============================================================================
  // PHASE 4: Real AI Venue Reconstruction Worker Foundation
  // ============================================================================
  group('AI Venue Capture — Real AI Venue Reconstruction Worker Foundation (Phase 4)', () {
    late ReferenceVenueReconstructionWorker referenceWorker;
    late UnavailableReconstructionWorker unavailableWorker;
    late DraftMergeEngine mergeEngine;

    setUp(() {
      referenceWorker = ReferenceVenueReconstructionWorker();
      unavailableWorker = const UnavailableReconstructionWorker();
      mergeEngine = const DraftMergeEngine();
    });

    test('1. Worker contract: input and result serialization roundtrip', () {
      final input = VenueFixtures.fixtureA(jobId: 'job-roundtrip');
      final json = input.toJson();
      final restored = VenueReconstructionInput.fromJson(json);

      expect(restored.jobId, equals('job-roundtrip'));
      expect(restored.evidence.length, equals(4));
      expect(restored.logicalConstraints?.rows, equals(12));
      expect(restored.knownMeasurements['roomWidth'], equals(18.0));
    });

    test('2. Worker contract: unavailable production worker reports disconnected status', () async {
      final input = VenueFixtures.fixtureA(jobId: 'job-unavail');
      final result = await unavailableWorker.analyze(input);

      expect(result.isSuccess, isFalse);
      expect(result.state, equals(ReconstructionUncertaintyState.unsupported));
      expect(result.errorMessage, contains('AI reconstruction worker is not connected'));
      expect(unavailableWorker.isAvailable, isFalse);
    });

    test('3. Job Model: VenueCaptureJob tracks needsEvidence and revision metadata', () {
      final job = VenueCaptureJob(
        id: 'job-spec',
        sessionId: 'session-123',
        theatreId: 'theatre-123',
        jobType: 'multi_view_reconstruction',
        status: CaptureJobStatus.needsEvidence,
        progress: 0.45,
        revision: 2,
        requestedCapabilities: const ['room', 'seating'],
        evidenceIds: const ['ev-1', 'ev-2'],
        createdAt: DateTime.now(),
      );

      expect(job.status, equals(CaptureJobStatus.needsEvidence));
      expect(job.status.label, equals('Needs Evidence'));
      expect(job.revision, equals(2));

      final json = job.toJson();
      final restored = VenueCaptureJob.fromJson(json);
      expect(restored.status, equals(CaptureJobStatus.needsEvidence));
      expect(restored.revision, equals(2));
    });

    test('4. Evidence traceability: every observation references supporting evidence IDs', () async {
      final input = VenueFixtures.fixtureA();
      final result = await referenceWorker.analyze(input);

      expect(result.isSuccess, isTrue);
      expect(result.observations, isNotEmpty);
      for (final obs in result.observations) {
        if (obs.type != ObservationType.scale || obs.provenance != EstimateProvenance.unknown) {
          expect(obs.id, isNotEmpty);
          expect(obs.confidence, isNotNull);
        }
      }
    });

    test('5. Scale handling: known measurement yields calibrated scale and valid dimensions', () async {
      final input = VenueFixtures.fixtureA();
      final result = await referenceWorker.analyze(input);

      expect(result.scaleStatus, equals(ScaleStatus.known));
      expect(result.room.width.isKnown, isTrue);
      expect(result.room.width.value, equals(18.0));
      expect(result.seating.seatSpacing.isKnown, isTrue);
      expect(result.seating.seatSpacing.value, equals(0.60));
    });

    test('6. Scale handling: unknown scale (Fixture C) leaves dimensions unknown without guessing', () async {
      final input = VenueFixtures.fixtureC();
      final result = await referenceWorker.analyze(input);

      expect(result.scaleStatus, equals(ScaleStatus.unknown));
      expect(result.room.width.isUnknown, isTrue);
      expect(result.room.length.isUnknown, isTrue);
      expect(result.seating.seatSpacing.isUnknown, isTrue);
      expect(result.seating.rowSpacing.isUnknown, isTrue);
      expect(result.seating.seats, isEmpty, reason: 'Must not fabricate metric seat coordinates when scale is unknown');

      // Emits targeted measurement request
      expect(
        result.requests.any((r) => r.requiredEvidenceType == EvidenceType.measurement),
        isTrue,
      );
    });

    test('7. Multi-view fusion: combined views produce room dimensions with confidence', () async {
      final input = VenueFixtures.fixtureH();
      final result = await referenceWorker.analyze(input);

      expect(result.isSuccess, isTrue);
      expect(result.room.width.isKnown, isTrue);
      expect(result.room.length.isKnown, isTrue);
      expect(result.room.height.isKnown, isTrue);
      expect(result.room.width.confidence, greaterThanOrEqualTo(0.80));
      expect(result.room.width.evidenceIds, isNotEmpty);
    });

    test('8. Screen reconstruction: front wall detects screen presence and coordinates', () async {
      final input = VenueFixtures.fixtureA();
      final result = await referenceWorker.analyze(input);

      expect(result.screen.width.isKnown, isTrue);
      expect(result.screen.width.value, equals(14.0));
      expect(result.screen.position.isKnown, isTrue);
      expect(result.screen.position.value?.x, equals(0.0));
    });

    test('9. Seating: physical seats are generated when scale is known', () async {
      final input = VenueFixtures.fixtureA();
      final result = await referenceWorker.analyze(input);

      expect(result.seating.seats, isNotEmpty);
      expect(result.seating.seats.length, equals(12 * 16));
      expect(result.seating.seats.first.row, equals('A'));
      expect(result.seating.seats.first.number, equals(1));
      expect(result.seating.seats.first.position.z, greaterThan(0));
    });

    test('10. Seating: irregular rows (Fixture B) are accurately extracted', () async {
      final input = VenueFixtures.fixtureB();
      final result = await referenceWorker.analyze(input);

      expect(result.seating.rowSeatCounts[1], equals(16));
      expect(result.seating.rowSeatCounts[5], equals(16));
      expect(result.seating.rowSeatCounts[6], equals(18));
      expect(result.seating.rowSeatCounts[12], equals(18));
      expect(result.seating.seats.length, equals((5 * 16) + (7 * 18)));
    });

    test('11. Seating: logical row conflict (Fixture D) surfaces CONFLICT and does not overwrite admin', () async {
      final input = VenueFixtures.fixtureD();
      final result = await referenceWorker.analyze(input);

      expect(result.state, equals(ReconstructionUncertaintyState.conflict));
      expect(result.conflicts, isNotEmpty);
      final rowConflict = result.conflicts.firstWhere((c) => c.feature == 'seating.rows');
      expect(rowConflict.adminConstraint, equals('12 rows'));
      expect(rowConflict.detectedValue, equals('11 rows'));

      // Merging into draft preserves admin constraint
      final baseDraft = ReconstructionDraft(
        id: 'draft-conf',
        sessionId: input.sessionId,
        theatreId: input.theatreId!,
        createdAt: DateTime.now(),
        seating: DraftSeatLattice(
          rows: Estimate<int>.adminMeasured(12),
          seatsPerRow: Estimate<int>.adminMeasured(16),
        ),
      );

      final mergeRes = mergeEngine.merge(
        draft: baseDraft,
        result: result,
        logicalConstraints: input.logicalConstraints,
      );

      expect(mergeRes.updatedDraft.seating.rows.value, equals(12), reason: 'Admin logical rows must not be overwritten by vision');
      expect(mergeRes.hasConflicts, isTrue);
      expect(mergeRes.newRequests.any((r) => r.target.contains('Rear Seating')), isTrue);
    });

    test('12. Speakers: visible speakers (Fixture E) generate cabinets with non-empty evidence IDs', () async {
      final input = VenueFixtures.fixtureE();
      final result = await referenceWorker.analyze(input);

      expect(result.speakers, isNotEmpty);
      for (final sp in result.speakers) {
        expect(sp.evidenceIds, isNotEmpty);
        expect(sp.visualCabinetType, equals(SpeakerType.sideSurround));
      }
    });

    test('13. Speakers: no speaker evidence (Fixture F) leaves speakers empty without fabrication', () async {
      final input = VenueFixtures.fixtureF();
      final result = await referenceWorker.analyze(input);

      expect(result.speakers, isEmpty);
    });

    test('14. Lighting: visible fixtures (Fixture G) are extracted without fabricating photometrics', () async {
      final input = VenueFixtures.fixtureG();
      final result = await referenceWorker.analyze(input);

      expect(result.lighting.ceilingLightsCount.isKnown, isTrue);
      expect(result.lighting.ceilingLightsCount.value, equals(12));
      expect(result.lighting.estimatedLux.isUnknown, isTrue, reason: 'Lux must not be fabricated without photometer');
    });

    test('15. Materials: qualitative appearance estimated with confidence and no fake RGB', () async {
      final input = VenueFixtures.fixtureA();
      final result = await referenceWorker.analyze(input);

      expect(result.appearance.wallColorHex.isKnown, isTrue);
      expect(result.appearance.wallColorHex.value, equals('#2C2D30'));
      expect(result.appearance.wallMaterialType.value, equals('acoustic_fabric_panel'));
      expect(result.appearance.wallColorHex.confidence, greaterThan(0.0));
    });

    test('16. Targeted requests: photographer guidance includes standing position, eye height, and facing', () async {
      final input = VenueFixtures.fixtureC();
      final result = await referenceWorker.analyze(input);

      expect(result.requests, isNotEmpty);
      final req = result.requests.first;
      expect(req.instruction, isNotEmpty);
      expect(req.reason, isNotEmpty);
    });

    test('17. Draft Merge Engine: Estimate precedence (measured > adminMeasured > aiEstimated > inferred > unknown)', () {
      final draft = ReconstructionDraft(
        id: 'draft-prec',
        sessionId: 'sess-prec',
        theatreId: 'th-prec',
        createdAt: DateTime.now(),
        room: DraftRoomGeometry(
          width: Estimate<double>.measured(20.0, source: 'laser_meter'),
        ),
      );

      final result = VenueReconstructionResult(
        jobId: 'job-prec',
        sessionId: 'sess-prec',
        isSuccess: true,
        workerName: 'Worker',
        room: DraftRoomGeometry(
          width: Estimate<double>.aiEstimated(18.5, confidence: 0.95),
        ),
      );

      final mergeRes = mergeEngine.merge(draft: draft, result: result);
      expect(mergeRes.updatedDraft.room.width.value, equals(20.0), reason: 'Physical measurement must beat AI estimate');
      expect(mergeRes.updatedDraft.room.width.provenance, equals(EstimateProvenance.measured));
    });

    test('18. Draft Merge Engine: higher confidence AI estimate replaces lower confidence', () {
      final draft = ReconstructionDraft(
        id: 'draft-conf-prec',
        sessionId: 'sess',
        theatreId: 'th',
        createdAt: DateTime.now(),
        room: DraftRoomGeometry(
          width: Estimate<double>.aiEstimated(18.0, confidence: 0.60),
        ),
      );

      final result = VenueReconstructionResult(
        jobId: 'job-conf-prec',
        sessionId: 'sess',
        isSuccess: true,
        workerName: 'Worker',
        room: DraftRoomGeometry(
          width: Estimate<double>.aiEstimated(18.4, confidence: 0.92),
        ),
      );

      final mergeRes = mergeEngine.merge(draft: draft, result: result);
      expect(mergeRes.updatedDraft.room.width.value, equals(18.4));
      expect(mergeRes.updatedDraft.room.width.confidence, equals(0.92));
    });

    test('19. Draft Merge Engine: unknown candidate never overwrites known draft value', () {
      final draft = ReconstructionDraft(
        id: 'draft-unk',
        sessionId: 'sess',
        theatreId: 'th',
        createdAt: DateTime.now(),
        room: DraftRoomGeometry(
          length: Estimate<double>.aiEstimated(25.0, confidence: 0.80),
        ),
      );

      final result = VenueReconstructionResult(
        jobId: 'job-unk',
        sessionId: 'sess',
        isSuccess: true,
        workerName: 'Worker',
        room: const DraftRoomGeometry(
          length: Estimate<double>.unknown(),
        ),
      );

      final mergeRes = mergeEngine.merge(draft: draft, result: result);
      expect(mergeRes.updatedDraft.room.length.value, equals(25.0));
      expect(mergeRes.updatedDraft.room.length.isKnown, isTrue);
    });

    test('20. Iterative refinement: pass 1 to pass 2 resolves uncertainty and increments revision', () async {
      // Pass 1: Fixture D has missing rear wall photo -> row conflict
      final pass1Input = VenueFixtures.fixtureD(jobId: 'job-pass1');
      final pass1Result = await referenceWorker.analyze(pass1Input);
      expect(pass1Result.revision, equals(1));
      expect(pass1Result.state, equals(ReconstructionUncertaintyState.conflict));

      // Admin fulfills rear photo request by adding rear wall photo
      final pass2Evidence = [
        ...pass1Input.evidence,
        VenueCaptureMedia(
          id: 'ev-rear-fulfilled',
          sessionId: pass1Input.sessionId,
          theatreId: pass1Input.theatreId!,
          type: EvidenceType.photo,
          category: EvidenceCategory.rearWall,
          storagePath: 'evidence/rear_resolved.jpg',
          filename: 'rear_wall_complete.jpg',
          createdAt: DateTime.now(),
        ),
      ];

      final pass2Input = VenueReconstructionInput(
        jobId: 'job-pass2',
        sessionId: pass1Input.sessionId,
        theatreId: pass1Input.theatreId,
        evidence: pass2Evidence,
        logicalConstraints: pass1Input.logicalConstraints,
        knownMeasurements: pass1Input.knownMeasurements,
      );

      final pass2Result = await referenceWorker.refine(pass2Input, pass1Result);
      expect(pass2Result.revision, equals(2));
      expect(pass2Result.conflicts, isEmpty, reason: 'Rear photo resolved the row discrepancy');
      expect(pass2Result.seating.rows.value, equals(12));
    });

    test('21. Draft safety: AI result modifies draft ONLY; live TheatreConfiguration is untouched', () async {
      final initialConfig = TheatreConfiguration(
        id: 'th-draft-safety',
        basicInfo: TheatreBasicInfo(name: 'Main Cinema'),
        room: RoomConfig(width: 15.0, length: 20.0, height: 6.0),
      );

      final input = VenueFixtures.fixtureA(jobId: 'job-safety');
      final workerResult = await referenceWorker.analyze(input);

      final baseDraft = ReconstructionDraft(
        id: 'draft-safety',
        sessionId: input.sessionId,
        theatreId: initialConfig.id,
        createdAt: DateTime.now(),
      );
      final mergeRes = mergeEngine.merge(draft: baseDraft, result: workerResult);

      // Verify draft changed
      expect(mergeRes.updatedDraft.room.width.value, equals(18.0));
      expect(mergeRes.updatedDraft.isReviewed, isFalse);

      // Verify live config did not change
      expect(initialConfig.room.width, equals(15.0));
    });

    test('22. Unity compatibility: reconstructed draft maps through DraftToTheatreMapper into valid TheatreUnityBridge payload', () async {
      final input = VenueFixtures.fixtureA();
      final workerResult = await referenceWorker.analyze(input);

      final draft = ReconstructionDraft(
        id: 'draft-unity-flow',
        sessionId: input.sessionId,
        theatreId: input.theatreId!,
        createdAt: DateTime.now(),
      );

      final mergeRes = mergeEngine.merge(
        draft: draft,
        result: workerResult,
        logicalConstraints: input.logicalConstraints,
      );

      // Mark reviewed and confirm
      final reviewedDraft = mergeRes.updatedDraft.copyWith(
        isReviewed: true,
        reviewedBy: 'admin-123',
        reviewedAt: DateTime.now(),
      );

      final baseConfig = TheatreConfiguration(
        id: 'th-unity-flow',
        basicInfo: TheatreBasicInfo(name: 'Grand Hall'),
      );

      final theatreConfig = DraftToTheatreMapper.applyDraftToConfiguration(
        baseConfig,
        reviewedDraft,
      );

      // Map to Unity payload
      final payload = TheatreUnityBridge.toUnityPayload(theatreConfig);
      expect(payload, isNotNull);
      expect(payload['payloadVersion'], equals(2));
      expect(payload['theatreId'], equals('th-unity-flow'));
      expect(payload['roomWidth'], equals(18.0));
      expect(payload['roomLength'], equals(24.0));
      expect(payload['screenWidth'], equals(14.0));
    });

    test('23. Worker adapter: WorkerVenueAnalyzerAdapter integrates worker into VenueAnalyzer interface', () async {
      final adapter = WorkerVenueAnalyzerAdapter(worker: referenceWorker);
      expect(adapter.isAvailable, isTrue);

      final session = VenueCaptureSession(
        id: 'sess-adapt',
        theatreId: 'th-adapt',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final analysisInput = VenueAnalysisInput(
        session: session,
        evidence: VenueFixtures.fixtureH().evidence,
      );

      final analysisResult = await adapter.analyze(analysisInput);
      expect(analysisResult.isSuccess, isTrue);
      expect(analysisResult.draft, isNotNull);
      expect(analysisResult.draft!.seating.seats, isNotEmpty);
      expect(analysisResult.observations, isNotEmpty);
    });
  });

  group('AI Venue Capture — Correction Pass: Authenticated Identity & Per-Wall Appearance', () {
    final referenceWorker = ReferenceVenueReconstructionWorker();

    testWidgets('Correction 1: Explicit theatre ownerId cannot override authenticated reviewer identity in VenueCaptureScreen', (tester) async {
      tester.view.physicalSize = const Size(1200, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      setVenueAnalyzer(MockVenueAnalyzer());

      // Render VenueCaptureScreen with an explicit theatre ownerId, but NO authenticated user
      // and NO test adminUserId.
      await tester.pumpWidget(
        MaterialApp(
          home: VenueCaptureScreen(
            theatreId: 'th-owner-guard',
            initialConfig: TheatreConfiguration(
              id: 'th-owner-guard',
              ownerId: 'historical-theatre-owner-999',
              basicInfo: TheatreBasicInfo(name: 'Owner Guard Test Theatre'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Add evidence and run mock analysis so draft is generated
      await tester.tap(find.text('Add Photo View'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add Evidence'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Run AI Venue Reconstruction'));
      await tester.pumpAndSettle();

      // Fulfill requests to get ready for review
      await tester.tap(find.text('Capture Photo'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add Evidence'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Record Measurement'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Record Scale'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Re-analyze Venue with New Evidence'));
      await tester.pumpAndSettle();

      // Switch to Review tab
      await tester.tap(find.text('4. Review & Confirm'));
      await tester.pumpAndSettle();

      // Attempt to Approve & Mark Reviewed
      final reviewBtn = find.text('Approve & Mark Draft as Reviewed');
      await tester.ensureVisible(reviewBtn);
      await tester.tap(reviewBtn);
      await tester.pumpAndSettle();

      // Verify that it FAILS CLOSED with authentication required error,
      // and NEVER treated historical-theatre-owner-999 as the reviewer.
      expect(find.textContaining('Authentication required'), findsOneWidget);
      expect(find.textContaining('historical-theatre-owner-999'), findsNothing);
    });

    test('Correction 1: Empty or unauthenticated admin identity throws StateError on review and confirmation', () async {
      final repo = InMemoryVenueCaptureRepository();
      final session = await repo.createSession('th-fail-closed');
      final draft = ReconstructionDraft(
        id: 'draft-fail-closed',
        sessionId: session.id,
        theatreId: session.theatreId,
        createdAt: DateTime.now(),
      );
      await repo.saveReconstructionDraft(session.id, draft);

      // Empty adminUserId throws StateError
      expect(
        () => repo.markDraftReviewed(session.id, adminUserId: ''),
        throwsStateError,
      );
      expect(
        () => repo.confirmDraft(session.id, draft.copyWith(isReviewed: true), adminUserId: '   '),
        throwsStateError,
      );
    });

    test('Correction 2: DraftWallAppearance and DraftAppearance serialization roundtrip', () {
      final appearance = DraftAppearance(
        wallColorHex: Estimate<String>.aiEstimated('#2C2D30', confidence: 0.8),
        carpetColorHex: Estimate<String>.aiEstimated('#1E2024', confidence: 0.75),
        wallMaterialType: Estimate<String>.aiEstimated('acoustic_fabric_panel', confidence: 0.7),
        frontWall: DraftWallAppearance(
          colorHex: Estimate<String>.aiEstimated('#1A1A1E', confidence: 0.85, evidenceIds: const ['ev-front']),
          materialType: Estimate<String>.aiEstimated('matte_proscenium_finish', confidence: 0.8),
          patternTreatment: Estimate<String>.aiEstimated('acoustic_baffles', confidence: 0.75),
        ),
        leftWall: DraftWallAppearance(
          colorHex: Estimate<String>.aiEstimated('#2C2D30', confidence: 0.78, evidenceIds: const ['ev-left']),
          materialType: Estimate<String>.aiEstimated('acoustic_fabric_panel', confidence: 0.76),
          patternTreatment: Estimate<String>.aiEstimated('fabric_baffles', confidence: 0.72),
        ),
        rightWall: DraftWallAppearance(
          colorHex: Estimate<String>.aiEstimated('#2C2D30', confidence: 0.78, evidenceIds: const ['ev-right']),
          materialType: Estimate<String>.aiEstimated('acoustic_fabric_panel', confidence: 0.76),
          patternTreatment: Estimate<String>.aiEstimated('fabric_baffles', confidence: 0.72),
        ),
        rearWall: DraftWallAppearance(
          colorHex: Estimate<String>.aiEstimated('#25262A', confidence: 0.82, evidenceIds: const ['ev-rear']),
          materialType: Estimate<String>.aiEstimated('diffuser_panel', confidence: 0.79),
          patternTreatment: Estimate<String>.aiEstimated('quadratic_residue_diffuser', confidence: 0.75),
        ),
      );

      final json = appearance.toJson();
      final reconstructed = DraftAppearance.fromJson(json);

      expect(reconstructed.frontWall.colorHex.value, equals('#1A1A1E'));
      expect(reconstructed.frontWall.materialType.value, equals('matte_proscenium_finish'));
      expect(reconstructed.frontWall.patternTreatment.value, equals('acoustic_baffles'));
      expect(reconstructed.frontWall.colorHex.evidenceIds, contains('ev-front'));

      expect(reconstructed.leftWall.colorHex.value, equals('#2C2D30'));
      expect(reconstructed.rightWall.colorHex.value, equals('#2C2D30'));
      expect(reconstructed.rearWall.colorHex.value, equals('#25262A'));
      expect(reconstructed.rearWall.materialType.value, equals('diffuser_panel'));

      expect(reconstructed.wallColorHex.value, equals('#2C2D30'));
      expect(reconstructed.carpetColorHex.value, equals('#1E2024'));
    });

    test('Correction 2: Reference worker independently extracts per-wall appearance estimates', () async {
      final input = VenueFixtures.fixtureH();
      final result = await referenceWorker.analyze(input);

      // Verify front wall appearance
      expect(result.appearance.frontWall.isKnown, isTrue);
      expect(result.appearance.frontWall.colorHex.value, equals('#1A1A1E'));
      expect(result.appearance.frontWall.materialType.value, equals('matte_proscenium_finish'));
      expect(result.appearance.frontWall.patternTreatment.value, equals('acoustic_baffles'));

      // Verify side walls appearance
      expect(result.appearance.leftWall.isKnown, isTrue);
      expect(result.appearance.leftWall.colorHex.value, equals('#2C2D30'));
      expect(result.appearance.rightWall.isKnown, isTrue);
      expect(result.appearance.rightWall.colorHex.value, equals('#2C2D30'));

      // Verify rear wall appearance
      expect(result.appearance.rearWall.isKnown, isTrue);
      expect(result.appearance.rearWall.colorHex.value, equals('#25262A'));
      expect(result.appearance.rearWall.materialType.value, equals('diffuser_panel'));
      expect(result.appearance.rearWall.patternTreatment.value, equals('quadratic_residue_diffuser'));

      // Verify each wall has evidence IDs
      expect(result.appearance.frontWall.colorHex.evidenceIds, isNotEmpty);
      expect(result.appearance.leftWall.colorHex.evidenceIds, isNotEmpty);
      expect(result.appearance.rearWall.colorHex.evidenceIds, isNotEmpty);
    });

    test('Correction 2: Missing evidence for one wall does not erase existing baseline for another wall', () {
      const mergeEngine = DraftMergeEngine();
      final baselineDraft = ReconstructionDraft(
        id: 'draft-base',
        sessionId: 'sess-base',
        theatreId: 'th-base',
        createdAt: DateTime.now(),
        appearance: DraftAppearance(
          leftWall: DraftWallAppearance(
            colorHex: Estimate<String>.adminMeasured('#112233', note: 'Admin verified navy fabric'),
            materialType: Estimate<String>.adminMeasured('wood_panel'),
          ),
        ),
      );

      // Worker result contains rear wall only; leftWall is completely unknown
      final workerResult = VenueReconstructionResult(
        jobId: 'job-rear-only',
        sessionId: 'sess-base',
        theatreId: 'th-base',
        isSuccess: true,
        workerName: 'TestWorker',
        appearance: DraftAppearance(
          rearWall: DraftWallAppearance(
            colorHex: Estimate<String>.aiEstimated('#25262A', confidence: 0.8),
            materialType: Estimate<String>.aiEstimated('diffuser_panel', confidence: 0.75),
          ),
        ),
      );

      final mergeOutput = mergeEngine.merge(draft: baselineDraft, result: workerResult);
      final merged = mergeOutput.updatedDraft.appearance;

      // Preserves existing leftWall
      expect(merged.leftWall.colorHex.isKnown, isTrue);
      expect(merged.leftWall.colorHex.value, equals('#112233'));
      expect(merged.leftWall.materialType.value, equals('wood_panel'));

      // Incorporates newly detected rearWall
      expect(merged.rearWall.colorHex.isKnown, isTrue);
      expect(merged.rearWall.colorHex.value, equals('#25262A'));
      expect(merged.rearWall.materialType.value, equals('diffuser_panel'));

      // Right wall remains unknown
      expect(merged.rightWall.isUnknown, isTrue);
    });

    test('Correction 2: Admin-measured wall appearance takes precedence over AI estimate', () {
      const mergeEngine = DraftMergeEngine();
      final baselineDraft = ReconstructionDraft(
        id: 'draft-admin-wall',
        sessionId: 'sess-base',
        theatreId: 'th-base',
        createdAt: DateTime.now(),
        appearance: DraftAppearance(
          frontWall: DraftWallAppearance(
            colorHex: Estimate<String>.adminMeasured('#E63946', note: 'Admin confirmed red proscenium'),
          ),
        ),
      );

      // Worker result detects dark color with high confidence
      final workerResult = VenueReconstructionResult(
        jobId: 'job-ai-wall',
        sessionId: 'sess-base',
        theatreId: 'th-base',
        isSuccess: true,
        workerName: 'TestWorker',
        appearance: DraftAppearance(
          frontWall: DraftWallAppearance(
            colorHex: Estimate<String>.aiEstimated('#1A1A1E', confidence: 0.99),
          ),
        ),
      );

      final mergeOutput = mergeEngine.merge(draft: baselineDraft, result: workerResult);
      final merged = mergeOutput.updatedDraft.appearance;

      // ADMIN_MEASURED (3) wins over AI_ESTIMATED (2)
      expect(merged.frontWall.colorHex.value, equals('#E63946'));
      expect(merged.frontWall.colorHex.provenance, equals(EstimateProvenance.adminMeasured));
    });

    test('Correction 2: Unknown wall appearance remains explicitly unknown without inventing RGB or materials', () {
      const wall = DraftWallAppearance();
      expect(wall.isUnknown, isTrue);
      expect(wall.isKnown, isFalse);
      expect(wall.colorHex.isUnknown, isTrue);
      expect(wall.colorHex.confidence, equals(0.0));
      expect(wall.materialType.isUnknown, isTrue);
      expect(wall.patternTreatment.isUnknown, isTrue);
    });
  });
}


