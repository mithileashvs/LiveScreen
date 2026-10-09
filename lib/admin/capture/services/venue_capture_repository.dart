import '../models/models.dart';
import 'in_memory_venue_capture_repository.dart';

/// Abstract repository interface for AI Venue Capture operations.
abstract class VenueCaptureRepository {
  /// Creates a new capture session for [theatreId] in [CaptureState.initial].
  Future<VenueCaptureSession> createSession(
    String theatreId, {
    Map<String, dynamic> metadata = const {},
  });

  /// Loads a session by its [sessionId].
  Future<VenueCaptureSession?> getSession(String sessionId);

  /// Retrieves the active (non-terminal) capture session for [theatreId], if one exists.
  Future<VenueCaptureSession?> getActiveSessionForTheatre(String theatreId);

  /// Transitions a session to [newState], enforcing state machine constraints.
  Future<VenueCaptureSession> updateSessionState(
    String sessionId,
    CaptureState newState,
  );

  /// Saves or updates a [ReconstructionDraft] associated with [sessionId].
  Future<void> saveReconstructionDraft(
    String sessionId,
    ReconstructionDraft draft,
  );

  /// Records administrator inspection and approval of the candidate draft.
  /// Sets [draft.isReviewed = true], [draft.reviewedBy = adminUserId], and [draft.reviewedAt].
  /// Transitions session state to [CaptureState.reviewing] if currently in [CaptureState.readyForReview].
  Future<VenueCaptureSession> markDraftReviewed(
    String sessionId, {
    required String adminUserId,
  });

  /// Confirms a reviewed draft and transitions the session to [CaptureState.confirmed].
  Future<VenueCaptureSession> confirmDraft(
    String sessionId,
    ReconstructionDraft draft, {
    required String adminUserId,
  });

  /// Cancels a session.
  Future<VenueCaptureSession> cancelSession(String sessionId);

  /// Records an uploaded evidence item (photo, video reference, or measurement).
  Future<VenueCaptureMedia> addEvidence(VenueCaptureMedia media);

  /// Deletes an evidence item by its [mediaId].
  Future<void> deleteEvidence(String mediaId);

  /// Lists all evidence recorded for [sessionId].
  Future<List<VenueCaptureMedia>> listEvidence(String sessionId);

  /// Lists targeted evidence requests for [sessionId].
  Future<List<VenueCaptureRequest>> listRequests(String sessionId);

  /// Creates a targeted evidence request for admin follow-up.
  Future<VenueCaptureRequest> addRequest(VenueCaptureRequest request);

  /// Resolves an evidence request as fulfilled or dismissed.
  Future<VenueCaptureRequest> resolveRequest(
    String requestId, {
    required RequestStatus status,
    String? fulfilledEvidenceId,
  });

  /// Lists all intermediate observations recorded for [sessionId].
  Future<List<VenueCaptureObservation>> listObservations(String sessionId);

  /// Appends an observation from an AI analysis worker.
  Future<VenueCaptureObservation> addObservation(
    VenueCaptureObservation observation,
  );

  /// Lists jobs queued or executed for [sessionId].
  Future<List<VenueCaptureJob>> listJobs(String sessionId);

  /// Queues a capture worker job.
  Future<VenueCaptureJob> createJob(VenueCaptureJob job);

  /// Updates status/progress of a capture job (worker-facing operation).
  Future<VenueCaptureJob> updateJob(VenueCaptureJob job);
}

/// The shared instance used across capture screens and tests.
/// Defaults to in-memory for testing, and can be configured with Supabase.
VenueCaptureRepository venueCaptureRepository = InMemoryVenueCaptureRepository();

