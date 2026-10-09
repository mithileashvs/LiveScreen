import 'package:livescreen/admin/capture/models/models.dart';

/// Synthetic venue capture test fixtures for deterministic Phase 4 worker testing.
/// These test fixtures avoid all external network dependencies and provide
/// reproducible scenarios across simple cinema, irregular rows, unknown scale,
/// multi-view fusion, conflicting detections, speakers, and lighting.
class VenueFixtures {
  static const String testSessionId = 'session-test-fixture';
  static const String testTheatreId = 'theatre-test-fixture';

  /// FIXTURE A: Simple standard cinema auditorium.
  /// - 12 rows, 16 seats per row, 3 seating blocks.
  /// - Known room width = 18.0m (calibrated metric scale).
  /// - Photos covering front wall, left seating, right seating, and rear wall.
  static VenueReconstructionInput fixtureA({String jobId = 'job-fixture-a'}) {
    final media = [
      VenueCaptureMedia(
        id: 'ev-front-a',
        sessionId: testSessionId,
        theatreId: testTheatreId,
        type: EvidenceType.photo,
        category: EvidenceCategory.frontWall,
        storagePath: 'evidence/front_wall.jpg',
        filename: 'auditorium_front_wall_screen.jpg',
        createdAt: DateTime.now(),
      ),
      VenueCaptureMedia(
        id: 'ev-left-seating-a',
        sessionId: testSessionId,
        theatreId: testTheatreId,
        type: EvidenceType.photo,
        category: EvidenceCategory.seating,
        storagePath: 'evidence/left_seating.jpg',
        filename: 'auditorium_left_seating.jpg',
        createdAt: DateTime.now(),
      ),
      VenueCaptureMedia(
        id: 'ev-right-seating-a',
        sessionId: testSessionId,
        theatreId: testTheatreId,
        type: EvidenceType.photo,
        category: EvidenceCategory.seating,
        storagePath: 'evidence/right_seating.jpg',
        filename: 'auditorium_right_seating.jpg',
        createdAt: DateTime.now(),
      ),
      VenueCaptureMedia(
        id: 'ev-rear-a',
        sessionId: testSessionId,
        theatreId: testTheatreId,
        type: EvidenceType.photo,
        category: EvidenceCategory.rearWall,
        storagePath: 'evidence/rear_wall.jpg',
        filename: 'auditorium_rear_wall.jpg',
        createdAt: DateTime.now(),
      ),
    ];

    return VenueReconstructionInput(
      jobId: jobId,
      sessionId: testSessionId,
      theatreId: testTheatreId,
      evidence: media,
      logicalConstraints: const LogicalVenueConstraints(
        rows: 12,
        seatsPerRow: 16,
        blockCount: 3,
        aisleAfterSeats: [4, 12],
      ),
      knownMeasurements: const {
        'roomWidth': 18.0,
        'roomLength': 24.0,
        'roomHeight': 7.5,
        'screenWidth': 14.0,
        'screenHeight': 6.0,
        'seatSpacing': 0.60,
        'rowSpacing': 1.10,
        'rowRise': 0.15,
        'aisleWidth': 1.20,
      },
      revision: 1,
    );
  }

  /// FIXTURE B: Irregular seating auditorium.
  /// - Rows 1–5 have 16 seats, Rows 6–12 have 18 seats.
  static VenueReconstructionInput fixtureB({String jobId = 'job-fixture-b'}) {
    final media = [
      VenueCaptureMedia(
        id: 'ev-front-b',
        sessionId: testSessionId,
        theatreId: testTheatreId,
        type: EvidenceType.photo,
        category: EvidenceCategory.frontWall,
        storagePath: 'evidence/front_b.jpg',
        filename: 'screen_front.jpg',
        createdAt: DateTime.now(),
      ),
      VenueCaptureMedia(
        id: 'ev-seating-front-b',
        sessionId: testSessionId,
        theatreId: testTheatreId,
        type: EvidenceType.photo,
        category: EvidenceCategory.seating,
        storagePath: 'evidence/seating_lower.jpg',
        filename: 'seating_lower_tiers.jpg',
        createdAt: DateTime.now(),
      ),
      VenueCaptureMedia(
        id: 'ev-seating-rear-b',
        sessionId: testSessionId,
        theatreId: testTheatreId,
        type: EvidenceType.photo,
        category: EvidenceCategory.seating,
        storagePath: 'evidence/seating_upper.jpg',
        filename: 'seating_upper_tiers.jpg',
        createdAt: DateTime.now(),
      ),
      VenueCaptureMedia(
        id: 'ev-rear-b',
        sessionId: testSessionId,
        theatreId: testTheatreId,
        type: EvidenceType.photo,
        category: EvidenceCategory.rearWall,
        storagePath: 'evidence/rear_b.jpg',
        filename: 'rear_wall_b.jpg',
        createdAt: DateTime.now(),
      ),
    ];

    final rowSeatCounts = <int, int>{};
    for (int r = 1; r <= 5; r++) {
      rowSeatCounts[r] = 16;
    }
    for (int r = 6; r <= 12; r++) {
      rowSeatCounts[r] = 18;
    }

    return VenueReconstructionInput(
      jobId: jobId,
      sessionId: testSessionId,
      theatreId: testTheatreId,
      evidence: media,
      logicalConstraints: LogicalVenueConstraints(
        rows: 12,
        seatsPerRow: 16,
        blockCount: 3,
        aisleAfterSeats: const [4, 12],
        rowSeatCounts: rowSeatCounts,
      ),
      knownMeasurements: const {
        'roomWidth': 20.0,
        'roomLength': 26.0,
        'roomHeight': 8.0,
        'seatSpacing': 0.60,
        'rowSpacing': 1.15,
      },
      revision: 1,
    );
  }

  /// FIXTURE C: Unknown metric scale.
  /// Photos provided, but zero measurements and zero reference objects.
  /// Metric values must remain explicitly UNKNOWN.
  static VenueReconstructionInput fixtureC({String jobId = 'job-fixture-c'}) {
    final media = [
      VenueCaptureMedia(
        id: 'ev-front-c',
        sessionId: testSessionId,
        theatreId: testTheatreId,
        type: EvidenceType.photo,
        category: EvidenceCategory.frontWall,
        storagePath: 'evidence/front_c.jpg',
        filename: 'auditorium_front_view.jpg',
        createdAt: DateTime.now(),
      ),
      VenueCaptureMedia(
        id: 'ev-seating-c',
        sessionId: testSessionId,
        theatreId: testTheatreId,
        type: EvidenceType.photo,
        category: EvidenceCategory.seating,
        storagePath: 'evidence/seating_c.jpg',
        filename: 'auditorium_seating_area.jpg',
        createdAt: DateTime.now(),
      ),
    ];

    return VenueReconstructionInput(
      jobId: jobId,
      sessionId: testSessionId,
      theatreId: testTheatreId,
      evidence: media,
      logicalConstraints: const LogicalVenueConstraints(
        rows: 10,
        seatsPerRow: 14,
      ),
      knownMeasurements: const {}, // NO scale available!
      revision: 1,
    );
  }

  /// FIXTURE D: Conflicting row detection.
  /// Admin specifies 12 rows. Visual evidence detects only 11 rows (rear tier obscured).
  /// AI vision must NOT silently overwrite admin logical structure.
  static VenueReconstructionInput fixtureD({String jobId = 'job-fixture-d'}) {
    final media = [
      VenueCaptureMedia(
        id: 'ev-front-d',
        sessionId: testSessionId,
        theatreId: testTheatreId,
        type: EvidenceType.photo,
        category: EvidenceCategory.frontWall,
        storagePath: 'evidence/front_d.jpg',
        filename: 'front_screen_view.jpg',
        createdAt: DateTime.now(),
      ),
      // Only front/mid seating photo: rear row is out of frame!
      VenueCaptureMedia(
        id: 'ev-seating-d',
        sessionId: testSessionId,
        theatreId: testTheatreId,
        type: EvidenceType.photo,
        category: EvidenceCategory.seating,
        storagePath: 'evidence/seating_d.jpg',
        filename: 'front_ten_rows_only.jpg',
        createdAt: DateTime.now(),
      ),
    ];

    return VenueReconstructionInput(
      jobId: jobId,
      sessionId: testSessionId,
      theatreId: testTheatreId,
      evidence: media,
      logicalConstraints: const LogicalVenueConstraints(
        rows: 12,
        seatsPerRow: 16,
      ),
      knownMeasurements: const {
        'roomWidth': 18.0,
      },
      revision: 1,
    );
  }

  /// FIXTURE E: Visible speaker cabinets.
  /// Evidence contains clearly visible side-wall speaker enclosures.
  static VenueReconstructionInput fixtureE({String jobId = 'job-fixture-e'}) {
    final media = [
      VenueCaptureMedia(
        id: 'ev-speakers-e',
        sessionId: testSessionId,
        theatreId: testTheatreId,
        type: EvidenceType.photo,
        category: EvidenceCategory.speakers,
        storagePath: 'evidence/left_wall_speakers.jpg',
        filename: 'left_wall_speaker_surrounds.jpg',
        createdAt: DateTime.now(),
      ),
      VenueCaptureMedia(
        id: 'ev-front-e',
        sessionId: testSessionId,
        theatreId: testTheatreId,
        type: EvidenceType.photo,
        category: EvidenceCategory.frontWall,
        storagePath: 'evidence/front_e.jpg',
        filename: 'front_screen_e.jpg',
        createdAt: DateTime.now(),
      ),
    ];

    return VenueReconstructionInput(
      jobId: jobId,
      sessionId: testSessionId,
      theatreId: testTheatreId,
      evidence: media,
      knownMeasurements: const {'roomWidth': 18.0},
      revision: 1,
    );
  }

  /// FIXTURE F: No visible speakers.
  /// Photos of front wall and seating, but NO speaker evidence.
  /// Resulting speakers must be empty.
  static VenueReconstructionInput fixtureF({String jobId = 'job-fixture-f'}) {
    final media = [
      VenueCaptureMedia(
        id: 'ev-front-f',
        sessionId: testSessionId,
        theatreId: testTheatreId,
        type: EvidenceType.photo,
        category: EvidenceCategory.frontWall,
        storagePath: 'evidence/front_f.jpg',
        filename: 'front_f.jpg',
        createdAt: DateTime.now(),
      ),
      VenueCaptureMedia(
        id: 'ev-seating-f',
        sessionId: testSessionId,
        theatreId: testTheatreId,
        type: EvidenceType.photo,
        category: EvidenceCategory.seating,
        storagePath: 'evidence/seating_f.jpg',
        filename: 'seating_f.jpg',
        createdAt: DateTime.now(),
      ),
    ];

    return VenueReconstructionInput(
      jobId: jobId,
      sessionId: testSessionId,
      theatreId: testTheatreId,
      evidence: media,
      knownMeasurements: const {'roomWidth': 18.0},
      revision: 1,
    );
  }

  /// FIXTURE G: Visible lighting arrangement.
  /// Ceiling photograph showing architectural lighting strips.
  static VenueReconstructionInput fixtureG({String jobId = 'job-fixture-g'}) {
    final media = [
      VenueCaptureMedia(
        id: 'ev-front-g',
        sessionId: testSessionId,
        theatreId: testTheatreId,
        type: EvidenceType.photo,
        category: EvidenceCategory.frontWall,
        storagePath: 'evidence/front_g.jpg',
        filename: 'front_g.jpg',
        createdAt: DateTime.now(),
      ),
      VenueCaptureMedia(
        id: 'ev-ceiling-g',
        sessionId: testSessionId,
        theatreId: testTheatreId,
        type: EvidenceType.photo,
        category: EvidenceCategory.ceiling,
        storagePath: 'evidence/ceiling_lighting.jpg',
        filename: 'ceiling_lighting_arrangement.jpg',
        createdAt: DateTime.now(),
      ),
    ];

    return VenueReconstructionInput(
      jobId: jobId,
      sessionId: testSessionId,
      theatreId: testTheatreId,
      evidence: media,
      knownMeasurements: const {'roomWidth': 18.0},
      revision: 1,
    );
  }

  /// FIXTURE H: Multi-view comprehensive capture with overlapping views.
  /// Front wall, left seating, right seating, rear wall, and ceiling views.
  static VenueReconstructionInput fixtureH({String jobId = 'job-fixture-h'}) {
    final media = [
      VenueCaptureMedia(
        id: 'ev-front-h',
        sessionId: testSessionId,
        theatreId: testTheatreId,
        type: EvidenceType.photo,
        category: EvidenceCategory.frontWall,
        storagePath: 'evidence/front_h.jpg',
        filename: 'view_01_front_wall.jpg',
        createdAt: DateTime.now(),
      ),
      VenueCaptureMedia(
        id: 'ev-left-h',
        sessionId: testSessionId,
        theatreId: testTheatreId,
        type: EvidenceType.photo,
        category: EvidenceCategory.seating,
        storagePath: 'evidence/left_h.jpg',
        filename: 'view_02_left_auditorium.jpg',
        createdAt: DateTime.now(),
      ),
      VenueCaptureMedia(
        id: 'ev-right-h',
        sessionId: testSessionId,
        theatreId: testTheatreId,
        type: EvidenceType.photo,
        category: EvidenceCategory.seating,
        storagePath: 'evidence/right_h.jpg',
        filename: 'view_03_right_auditorium.jpg',
        createdAt: DateTime.now(),
      ),
      VenueCaptureMedia(
        id: 'ev-rear-h',
        sessionId: testSessionId,
        theatreId: testTheatreId,
        type: EvidenceType.photo,
        category: EvidenceCategory.rearWall,
        storagePath: 'evidence/rear_h.jpg',
        filename: 'view_04_rear_wall.jpg',
        createdAt: DateTime.now(),
      ),
      VenueCaptureMedia(
        id: 'ev-ceiling-h',
        sessionId: testSessionId,
        theatreId: testTheatreId,
        type: EvidenceType.photo,
        category: EvidenceCategory.ceiling,
        storagePath: 'evidence/ceiling_h.jpg',
        filename: 'view_05_ceiling_lights.jpg',
        createdAt: DateTime.now(),
      ),
      VenueCaptureMedia(
        id: 'ev-speakers-h',
        sessionId: testSessionId,
        theatreId: testTheatreId,
        type: EvidenceType.photo,
        category: EvidenceCategory.speakers,
        storagePath: 'evidence/speakers_h.jpg',
        filename: 'view_06_surround_speakers.jpg',
        createdAt: DateTime.now(),
      ),
      VenueCaptureMedia(
        id: 'ev-measure-h',
        sessionId: testSessionId,
        theatreId: testTheatreId,
        type: EvidenceType.measurement,
        category: EvidenceCategory.measurement,
        storagePath: 'evidence/measure_h.json',
        filename: 'measurement_screen_width.json',
        metadata: const {'distance_meters': 15.0, 'target': 'screen_width'},
        createdAt: DateTime.now(),
      ),
    ];

    return VenueReconstructionInput(
      jobId: jobId,
      sessionId: testSessionId,
      theatreId: testTheatreId,
      evidence: media,
      logicalConstraints: const LogicalVenueConstraints(
        rows: 12,
        seatsPerRow: 16,
        blockCount: 3,
        aisleAfterSeats: [4, 12],
      ),
      knownMeasurements: const {
        'roomWidth': 18.0,
        'roomLength': 24.0,
        'roomHeight': 7.5,
      },
      revision: 1,
    );
  }
}
