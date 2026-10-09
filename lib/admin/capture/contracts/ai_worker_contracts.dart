import '../models/models.dart';
import '../../models/screen_config.dart' show Position3;

/// CONTRACTS ONLY for future external AI workers.
///
/// Principles:
/// 1. These interfaces establish standard typed communication protocols between
///    LiveScreen and external GPU/ML reconstruction microservices.
/// 2. No ML weights, inference libraries, or neural network runtimes are bundled in Flutter.
/// 3. AI workers run server-side / worker-side; secrets and models never reside in client apps.
/// 4. "AI assists reconstruction; it does not silently guess unknown measurements."

// ============================================================================
// 1. Viewpoint Analysis
// ============================================================================

class ViewpointCoverageReport {
  final double coverageScore; // 0.0 to 1.0
  final List<String> coveredZones;
  final List<String> missingZones;
  final List<String> blindSpots;

  const ViewpointCoverageReport({
    required this.coverageScore,
    this.coveredZones = const [],
    this.missingZones = const [],
    this.blindSpots = const [],
  });
}

abstract class ViewpointAnalysisWorkerContract {
  Future<ViewpointCoverageReport> analyzeViewpoints({
    required String sessionId,
    required List<VenueCaptureMedia> media,
  });
}

// ============================================================================
// 2. Semantic Architectural Segmentation
// ============================================================================

class SegmentedRegion {
  final String label; // 'floor', 'ceiling', 'front_wall', 'side_wall_left', 'side_wall_right', 'screen'
  final double confidence;
  final Map<String, dynamic> polygonOrMask;

  const SegmentedRegion({
    required this.label,
    required this.confidence,
    this.polygonOrMask = const {},
  });
}

abstract class SegmentationWorkerContract {
  Future<List<SegmentedRegion>> segmentMedia({
    required String mediaId,
    required String storagePath,
  });
}

// ============================================================================
// 3. Object Detection (Screens, Visual Speakers, Seats, Fixtures)
// ============================================================================

class DetectedObject {
  final String label; // 'screen_bezel', 'speaker_cabinet', 'seat_unit', 'projector_port'
  final double confidence;
  final List<double> boundingBox2D; // [ymin, xmin, ymax, xmax]
  final Position3? estimatedCenter3D;

  const DetectedObject({
    required this.label,
    required this.confidence,
    required this.boundingBox2D,
    this.estimatedCenter3D,
  });
}

abstract class ObjectDetectionWorkerContract {
  Future<List<DetectedObject>> detectObjects({
    required String mediaId,
    required String storagePath,
  });
}

// ============================================================================
// 4. Metric Depth Estimation
// ============================================================================

class DepthEstimationResult {
  final String depthMapStoragePath;
  final double confidence;
  final double minDepthMeters;
  final double maxDepthMeters;

  const DepthEstimationResult({
    required this.depthMapStoragePath,
    required this.confidence,
    required this.minDepthMeters,
    required this.maxDepthMeters,
  });
}

abstract class DepthEstimationWorkerContract {
  Future<DepthEstimationResult> estimateDepth({
    required String mediaId,
    required String storagePath,
  });
}

// ============================================================================
// 5. Multi-View Reconstruction (Structure-from-Motion / NeRF / Gaussian Splat)
// ============================================================================

class MultiViewReconstructionResult {
  final String pointCloudStoragePath;
  final int matchedKeypoints;
  final double reprojectionError;
  final DraftRoomGeometry estimatedRoom;

  const MultiViewReconstructionResult({
    required this.pointCloudStoragePath,
    required this.matchedKeypoints,
    required this.reprojectionError,
    required this.estimatedRoom,
  });
}

abstract class MultiViewReconstructionWorkerContract {
  Future<MultiViewReconstructionResult> reconstructGeometry({
    required String sessionId,
    required List<VenueCaptureMedia> media,
  });
}

// ============================================================================
// 6. Scale Calibration
// ============================================================================

class ScaleCalibrationResult {
  final double scaleFactor;
  final double confidence;
  final String referenceEvidenceId;
  final String note;

  const ScaleCalibrationResult({
    required this.scaleFactor,
    required this.confidence,
    required this.referenceEvidenceId,
    required this.note,
  });
}

abstract class ScaleCalibrationWorkerContract {
  Future<ScaleCalibrationResult> calibrateScale({
    required String sessionId,
    required ReconstructionDraft unscaledDraft,
    required VenueCaptureMedia measurementEvidence,
  });
}

// ============================================================================
// 7. Seating Lattice Detection
// ============================================================================

class SeatLatticeDetectionResult {
  final DraftSeatLattice lattice;
  final double confidence;
  final String patternType; // 'regular_grid', 'curved_amphitheatre', 'tiered_stadium'

  const SeatLatticeDetectionResult({
    required this.lattice,
    required this.confidence,
    required this.patternType,
  });
}

abstract class SeatLatticeDetectionWorkerContract {
  Future<SeatLatticeDetectionResult> detectSeatLattice({
    required String sessionId,
    required List<VenueCaptureObservation> observations,
  });
}

// ============================================================================
// 8. Visual Appearance & Materials Estimation
// ============================================================================

abstract class AppearanceEstimationWorkerContract {
  Future<DraftAppearance> estimateAppearance({
    required String sessionId,
    required List<VenueCaptureMedia> media,
  });
}

// ============================================================================
// 9. Targeted Evidence Request Planner
// ============================================================================

abstract class EvidenceRequestPlannerContract {
  Future<List<VenueCaptureRequest>> planTargetedRequests({
    required String sessionId,
    required String theatreId,
    required CaptureState currentState,
    required List<VenueCaptureObservation> observations,
    required ReconstructionDraft? currentDraft,
  });
}

// ============================================================================
// 10. Phase 4 Reconstruction Worker Contracts & Data Models
// ============================================================================

enum ScaleStatus {
  known,
  calibrated,
  unknown,
}

enum ReconstructionUncertaintyState {
  confident,
  uncertain,
  conflict,
  needsMeasurement,
  needsPhoto,
  unsupported,
}

enum ObservationType {
  roomGeometry,
  screen,
  seating,
  seat,
  speaker,
  lighting,
  material,
  color,
  scale,
  other,
}

/// A structured observation made by an AI reconstruction worker.
/// Directly references supporting evidence IDs and carries provenance & confidence.
class VenueObservation {
  final String id;
  final ObservationType type;
  final Map<String, dynamic> value;
  final double? confidence; // 0.0 to 1.0
  final EstimateProvenance provenance;
  final List<String> evidenceIds;
  final String? source;
  final String? notes;
  final int revision;

  const VenueObservation({
    required this.id,
    required this.type,
    required this.value,
    this.confidence,
    this.provenance = EstimateProvenance.aiEstimated,
    this.evidenceIds = const [],
    this.source,
    this.notes,
    this.revision = 1,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'value': value,
        'confidence': confidence,
        'provenance': provenance.name,
        'evidenceIds': evidenceIds,
        'source': source,
        'notes': notes,
        'revision': revision,
      };

  factory VenueObservation.fromJson(Map<String, dynamic> json) {
    final rawType = json['type'] as String?;
    final rawProv = json['provenance'] as String?;
    final rawConf = (json['confidence'] as num?)?.toDouble();

    return VenueObservation(
      id: json['id'] as String,
      type: ObservationType.values.firstWhere(
        (t) => t.name == rawType,
        orElse: () => ObservationType.other,
      ),
      value: (json['value'] as Map<String, dynamic>?) ?? {},
      confidence: rawConf?.clamp(0.0, 1.0),
      provenance: EstimateProvenance.values.firstWhere(
        (p) => p.name == rawProv,
        orElse: () => EstimateProvenance.aiEstimated,
      ),
      evidenceIds: ((json['evidenceIds'] ?? json['evidence_ids']) as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      source: json['source'] as String?,
      notes: json['notes'] as String?,
      revision: (json['revision'] as num?)?.toInt() ?? 1,
    );
  }
}

/// Explicit logical seating structure provided by the theatre administrator.
/// Physical AI reconstruction must NEVER overwrite these constraints without permission.
class LogicalVenueConstraints {
  final int? rows;
  final int? seatsPerRow;
  final int? blockCount;
  final List<int> aisleAfterSeats;
  final Map<int, int> rowSeatCounts;
  final Set<String> removedSeats;
  final double? aisleWidth;

  const LogicalVenueConstraints({
    this.rows,
    this.seatsPerRow,
    this.blockCount,
    this.aisleAfterSeats = const [],
    this.rowSeatCounts = const {},
    this.removedSeats = const {},
    this.aisleWidth,
  });

  Map<String, dynamic> toJson() => {
        if (rows != null) 'rows': rows,
        if (seatsPerRow != null) 'seatsPerRow': seatsPerRow,
        if (blockCount != null) 'blockCount': blockCount,
        if (aisleAfterSeats.isNotEmpty) 'aisleAfterSeats': aisleAfterSeats,
        if (rowSeatCounts.isNotEmpty)
          'rowSeatCounts':
              rowSeatCounts.map((k, v) => MapEntry(k.toString(), v)),
        if (removedSeats.isNotEmpty) 'removedSeats': removedSeats.toList(),
        if (aisleWidth != null) 'aisleWidth': aisleWidth,
      };

  factory LogicalVenueConstraints.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const LogicalVenueConstraints();
    final rawRowCounts = json['rowSeatCounts'] as Map<String, dynamic>?;
    final rowSeatCounts = <int, int>{};
    if (rawRowCounts != null) {
      for (final entry in rawRowCounts.entries) {
        final parsedKey = int.tryParse(entry.key);
        final parsedVal = (entry.value as num?)?.toInt();
        if (parsedKey != null && parsedVal != null) {
          rowSeatCounts[parsedKey] = parsedVal;
        }
      }
    }

    final rawRemoved = json['removedSeats'] as List<dynamic>?;
    final removedSeats = rawRemoved != null
        ? rawRemoved.map((e) => e.toString()).toSet()
        : const <String>{};

    return LogicalVenueConstraints(
      rows: (json['rows'] as num?)?.toInt(),
      seatsPerRow: (json['seatsPerRow'] as num?)?.toInt(),
      blockCount: (json['blockCount'] as num?)?.toInt(),
      aisleAfterSeats: (json['aisleAfterSeats'] as List<dynamic>? ?? [])
          .map((e) => (e as num).toInt())
          .toList(),
      rowSeatCounts: rowSeatCounts,
      removedSeats: removedSeats,
      aisleWidth: (json['aisleWidth'] as num?)?.toDouble(),
    );
  }
}

/// A conflict surfaced when AI visual detection disagrees with admin constraints
/// or when multi-view evidence contradicts itself.
class VenueReconstructionConflict {
  final String id;
  final String feature;
  final String description;
  final String adminConstraint;
  final String detectedValue;
  final String suggestedResolution;
  final List<String> evidenceIds;

  const VenueReconstructionConflict({
    required this.id,
    required this.feature,
    required this.description,
    required this.adminConstraint,
    required this.detectedValue,
    required this.suggestedResolution,
    this.evidenceIds = const [],
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'feature': feature,
        'description': description,
        'adminConstraint': adminConstraint,
        'detectedValue': detectedValue,
        'suggestedResolution': suggestedResolution,
        'evidenceIds': evidenceIds,
      };

  factory VenueReconstructionConflict.fromJson(Map<String, dynamic> json) {
    return VenueReconstructionConflict(
      id: json['id'] as String,
      feature: json['feature'] as String? ?? '',
      description: json['description'] as String? ?? '',
      adminConstraint: json['adminConstraint'] as String? ?? '',
      detectedValue: json['detectedValue'] as String? ?? '',
      suggestedResolution: json['suggestedResolution'] as String? ?? '',
      evidenceIds: ((json['evidenceIds'] ?? json['evidence_ids']) as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
    );
  }
}

/// Input payload passed to an AI Venue Reconstruction Worker.
class VenueReconstructionInput {
  final String jobId;
  final String sessionId;
  final String? theatreId;
  final List<VenueCaptureMedia> evidence;
  final ReconstructionDraft? baselineDraft;
  final LogicalVenueConstraints? logicalConstraints;
  final Map<String, double> knownMeasurements;
  final DraftCoordinateFrame coordinateConvention;
  final List<String> requestedAnalysis;
  final List<VenueCaptureObservation> previousObservations;
  final int revision;

  const VenueReconstructionInput({
    required this.jobId,
    required this.sessionId,
    this.theatreId,
    required this.evidence,
    this.baselineDraft,
    this.logicalConstraints,
    this.knownMeasurements = const {},
    this.coordinateConvention = const DraftCoordinateFrame(),
    this.requestedAnalysis = const ['room', 'screen', 'seating', 'speakers', 'lighting', 'appearance'],
    this.previousObservations = const [],
    this.revision = 1,
  });

  Map<String, dynamic> toJson() => {
        'jobId': jobId,
        'sessionId': sessionId,
        'theatreId': theatreId,
        'evidence': evidence.map((e) => e.toJson()).toList(),
        'baselineDraft': baselineDraft?.toJson(),
        'logicalConstraints': logicalConstraints?.toJson(),
        'knownMeasurements': knownMeasurements,
        'coordinateConvention': coordinateConvention.toJson(),
        'requestedAnalysis': requestedAnalysis,
        'previousObservations': previousObservations.map((o) => o.toJson()).toList(),
        'revision': revision,
      };

  factory VenueReconstructionInput.fromJson(Map<String, dynamic> json) {
    return VenueReconstructionInput(
      jobId: json['jobId'] as String,
      sessionId: json['sessionId'] as String,
      theatreId: json['theatreId'] as String?,
      evidence: (json['evidence'] as List<dynamic>? ?? [])
          .map((e) => VenueCaptureMedia.fromJson(e as Map<String, dynamic>))
          .toList(),
      baselineDraft: json['baselineDraft'] != null
          ? ReconstructionDraft.fromJson(json['baselineDraft'] as Map<String, dynamic>)
          : null,
      logicalConstraints: json['logicalConstraints'] != null
          ? LogicalVenueConstraints.fromJson(json['logicalConstraints'] as Map<String, dynamic>)
          : null,
      knownMeasurements: ((json['knownMeasurements'] as Map<String, dynamic>?) ?? {})
          .map((k, v) => MapEntry(k, (v as num).toDouble())),
      coordinateConvention: DraftCoordinateFrame.fromJson(
          json['coordinateConvention'] as Map<String, dynamic>?),
      requestedAnalysis: (json['requestedAnalysis'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      previousObservations: (json['previousObservations'] as List<dynamic>? ?? [])
          .map((o) => VenueCaptureObservation.fromJson(o as Map<String, dynamic>))
          .toList(),
      revision: (json['revision'] as num?)?.toInt() ?? 1,
    );
  }
}

/// Structured outcome of an AI Venue Reconstruction Worker pass.
class VenueReconstructionResult {
  final String jobId;
  final String sessionId;
  final String? theatreId;
  final int revision;
  final ScaleStatus scaleStatus;
  final ReconstructionUncertaintyState state;
  final List<VenueObservation> observations;
  final DraftRoomGeometry room;
  final DraftScreen screen;
  final DraftSeatLattice seating;
  final List<DraftVisualSpeaker> speakers;
  final DraftLighting lighting;
  final DraftAppearance appearance;
  final double overallConfidence;
  final Map<String, List<String>> evidenceLinks;
  final List<VenueCaptureRequest> requests;
  final List<VenueReconstructionConflict> conflicts;
  final List<String> warnings;
  final DraftCoordinateFrame coordinateConvention;
  final bool isSuccess;
  final String? errorMessage;
  final String workerName;

  const VenueReconstructionResult({
    required this.jobId,
    required this.sessionId,
    this.theatreId,
    this.revision = 1,
    this.scaleStatus = ScaleStatus.unknown,
    this.state = ReconstructionUncertaintyState.uncertain,
    this.observations = const [],
    this.room = const DraftRoomGeometry(),
    this.screen = const DraftScreen(),
    this.seating = const DraftSeatLattice(),
    this.speakers = const [],
    this.lighting = const DraftLighting(),
    this.appearance = const DraftAppearance(),
    this.overallConfidence = 0.0,
    this.evidenceLinks = const {},
    this.requests = const [],
    this.conflicts = const [],
    this.warnings = const [],
    this.coordinateConvention = const DraftCoordinateFrame(),
    required this.isSuccess,
    this.errorMessage,
    required this.workerName,
  });

  Map<String, dynamic> toJson() => {
        'jobId': jobId,
        'sessionId': sessionId,
        'theatreId': theatreId,
        'revision': revision,
        'scaleStatus': scaleStatus.name,
        'state': state.name,
        'observations': observations.map((o) => o.toJson()).toList(),
        'room': room.toJson(),
        'screen': screen.toJson(),
        'seating': seating.toJson(),
        'speakers': speakers.map((s) => s.toJson()).toList(),
        'lighting': lighting.toJson(),
        'appearance': appearance.toJson(),
        'overallConfidence': overallConfidence,
        'evidenceLinks': evidenceLinks,
        'requests': requests.map((r) => r.toJson()).toList(),
        'conflicts': conflicts.map((c) => c.toJson()).toList(),
        'warnings': warnings,
        'coordinateConvention': coordinateConvention.toJson(),
        'isSuccess': isSuccess,
        'errorMessage': errorMessage,
        'workerName': workerName,
      };

  factory VenueReconstructionResult.fromJson(Map<String, dynamic> json) {
    return VenueReconstructionResult(
      jobId: json['jobId'] as String,
      sessionId: json['sessionId'] as String,
      theatreId: json['theatreId'] as String?,
      revision: (json['revision'] as num?)?.toInt() ?? 1,
      scaleStatus: ScaleStatus.values.firstWhere(
        (s) => s.name == json['scaleStatus'],
        orElse: () => ScaleStatus.unknown,
      ),
      state: ReconstructionUncertaintyState.values.firstWhere(
        (s) => s.name == json['state'],
        orElse: () => ReconstructionUncertaintyState.uncertain,
      ),
      observations: (json['observations'] as List<dynamic>? ?? [])
          .map((o) => VenueObservation.fromJson(o as Map<String, dynamic>))
          .toList(),
      room: DraftRoomGeometry.fromJson(json['room'] as Map<String, dynamic>?),
      screen: DraftScreen.fromJson(json['screen'] as Map<String, dynamic>?),
      seating: DraftSeatLattice.fromJson(json['seating'] as Map<String, dynamic>?),
      speakers: (json['speakers'] as List<dynamic>? ?? [])
          .map((s) => DraftVisualSpeaker.fromJson(s as Map<String, dynamic>))
          .toList(),
      lighting: DraftLighting.fromJson(json['lighting'] as Map<String, dynamic>?),
      appearance: DraftAppearance.fromJson(json['appearance'] as Map<String, dynamic>?),
      overallConfidence: (json['overallConfidence'] as num?)?.toDouble() ?? 0.0,
      evidenceLinks: ((json['evidenceLinks'] as Map<String, dynamic>?) ?? {}).map(
        (k, v) => MapEntry(k, (v as List<dynamic>).map((e) => e.toString()).toList()),
      ),
      requests: (json['requests'] as List<dynamic>? ?? [])
          .map((r) => VenueCaptureRequest.fromJson(r as Map<String, dynamic>))
          .toList(),
      conflicts: (json['conflicts'] as List<dynamic>? ?? [])
          .map((c) => VenueReconstructionConflict.fromJson(c as Map<String, dynamic>))
          .toList(),
      warnings: (json['warnings'] as List<dynamic>? ?? [])
          .map((w) => w.toString())
          .toList(),
      coordinateConvention: DraftCoordinateFrame.fromJson(
          json['coordinateConvention'] as Map<String, dynamic>?),
      isSuccess: json['isSuccess'] as bool? ?? true,
      errorMessage: json['errorMessage'] as String?,
      workerName: json['workerName'] as String? ?? 'VenueReconstructionWorker',
    );
  }
}

/// Abstract contract for an AI Venue Reconstruction Worker.
abstract class VenueReconstructionWorker {
  String get name;
  bool get isAvailable;

  Future<VenueReconstructionResult> analyze(VenueReconstructionInput input);
  Future<VenueReconstructionResult> refine(
    VenueReconstructionInput input,
    VenueReconstructionResult previousResult,
  );
}

/// Model adapter interfaces for future ML models.
abstract class DepthEstimator {
  Future<DepthEstimationResult> estimateDepth({
    required String mediaId,
    required String storagePath,
  });
}

abstract class ObjectDetector {
  Future<List<DetectedObject>> detectObjects({
    required String mediaId,
    required String storagePath,
  });
}

abstract class SegmentationModel {
  Future<List<SegmentedRegion>> segmentMedia({
    required String mediaId,
    required String storagePath,
  });
}

abstract class MultiViewReconstructor {
  Future<MultiViewReconstructionResult> reconstructGeometry({
    required String sessionId,
    required List<VenueCaptureMedia> media,
  });
}
