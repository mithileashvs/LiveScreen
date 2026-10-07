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
