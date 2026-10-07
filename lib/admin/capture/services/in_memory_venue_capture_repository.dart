import '../models/models.dart';
import 'venue_capture_repository.dart';

/// In-memory implementation of [VenueCaptureRepository] for fast, deterministic unit tests.
class InMemoryVenueCaptureRepository implements VenueCaptureRepository {
  final Map<String, VenueCaptureSession> _sessions = {};
  final Map<String, List<VenueCaptureMedia>> _evidence = {};
  final Map<String, List<VenueCaptureRequest>> _requests = {};
  final Map<String, List<VenueCaptureObservation>> _observations = {};
  final Map<String, List<VenueCaptureJob>> _jobs = {};

  int _idCounter = 1;
  String _nextId(String prefix) => '$prefix-${_idCounter++}';

  @override
  Future<VenueCaptureSession> createSession(
    String theatreId, {
    Map<String, dynamic> metadata = const {},
  }) async {
    final now = DateTime.now();
    final session = VenueCaptureSession(
      id: _nextId('vcs'),
      theatreId: theatreId,
      state: CaptureState.initial,
      createdAt: now,
      updatedAt: now,
      metadata: metadata,
    );
    _sessions[session.id] = session;
    _evidence[session.id] = [];
    _requests[session.id] = [];
    _observations[session.id] = [];
    _jobs[session.id] = [];
    return session;
  }

  @override
  Future<VenueCaptureSession?> getSession(String sessionId) async {
    return _sessions[sessionId];
  }

  @override
  Future<VenueCaptureSession?> getActiveSessionForTheatre(String theatreId) async {
    for (final session in _sessions.values) {
      if (session.theatreId == theatreId && !session.state.isTerminal) {
        return session;
      }
    }
    return null;
  }

  @override
  Future<VenueCaptureSession> updateSessionState(
    String sessionId,
    CaptureState newState,
  ) async {
    final session = _sessions[sessionId];
    if (session == null) {
      throw StateError('Session $sessionId not found.');
    }
    final updated = session.transitionTo(newState);
    _sessions[sessionId] = updated;
    return updated;
  }

  @override
  Future<void> saveReconstructionDraft(
    String sessionId,
    ReconstructionDraft draft,
  ) async {
    final session = _sessions[sessionId];
    if (session == null) {
      throw StateError('Session $sessionId not found.');
    }
    _sessions[sessionId] = session.copyWith(
      draft: draft,
      updatedAt: DateTime.now(),
    );
  }

  @override
  Future<VenueCaptureSession> confirmDraft(
    String sessionId,
    ReconstructionDraft draft, {
    required String adminUserId,
  }) async {
    final session = _sessions[sessionId];
    if (session == null) {
      throw StateError('Session $sessionId not found.');
    }

    final reviewedDraft = draft.copyWith(
      isReviewed: true,
      reviewedBy: adminUserId,
      reviewedAt: DateTime.now(),
    );

    final updated = session
        .copyWith(draft: reviewedDraft)
        .transitionTo(CaptureState.confirmed);
    _sessions[sessionId] = updated;
    return updated;
  }

  @override
  Future<VenueCaptureSession> cancelSession(String sessionId) async {
    return updateSessionState(sessionId, CaptureState.cancelled);
  }

  @override
  Future<VenueCaptureMedia> addEvidence(VenueCaptureMedia media) async {
    final list = _evidence.putIfAbsent(media.sessionId, () => []);
    list.add(media);
    return media;
  }

  @override
  Future<List<VenueCaptureMedia>> listEvidence(String sessionId) async {
    return List.unmodifiable(_evidence[sessionId] ?? const []);
  }

  @override
  Future<List<VenueCaptureRequest>> listRequests(String sessionId) async {
    return List.unmodifiable(_requests[sessionId] ?? const []);
  }

  @override
  Future<VenueCaptureRequest> addRequest(VenueCaptureRequest request) async {
    final list = _requests.putIfAbsent(request.sessionId, () => []);
    list.add(request);
    return request;
  }

  @override
  Future<VenueCaptureRequest> resolveRequest(
    String requestId, {
    required RequestStatus status,
  }) async {
    for (final list in _requests.values) {
      final index = list.indexWhere((r) => r.id == requestId);
      if (index != -1) {
        final existing = list[index];
        final updated = existing.copyWith(
          status: status,
          resolvedAt: DateTime.now(),
        );
        list[index] = updated;
        return updated;
      }
    }
    throw StateError('Request $requestId not found.');
  }

  @override
  Future<List<VenueCaptureObservation>> listObservations(String sessionId) async {
    return List.unmodifiable(_observations[sessionId] ?? const []);
  }

  @override
  Future<VenueCaptureObservation> addObservation(
    VenueCaptureObservation observation,
  ) async {
    final list = _observations.putIfAbsent(observation.sessionId, () => []);
    list.add(observation);
    return observation;
  }

  @override
  Future<List<VenueCaptureJob>> listJobs(String sessionId) async {
    return List.unmodifiable(_jobs[sessionId] ?? const []);
  }

  @override
  Future<VenueCaptureJob> createJob(VenueCaptureJob job) async {
    final list = _jobs.putIfAbsent(job.sessionId, () => []);
    list.add(job);
    return job;
  }

  @override
  Future<VenueCaptureJob> updateJob(VenueCaptureJob job) async {
    final list = _jobs[job.sessionId];
    if (list != null) {
      final index = list.indexWhere((j) => j.id == job.id);
      if (index != -1) {
        list[index] = job;
        return job;
      }
    }
    throw StateError('Job ${job.id} not found.');
  }
}
