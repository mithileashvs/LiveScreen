import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';
import 'venue_capture_repository.dart';

/// Supabase-backed implementation of [VenueCaptureRepository].
///
/// Talks to private capture tables:
/// - `venue_capture_sessions`
/// - `venue_capture_media`
/// - `venue_capture_requests`
/// - `venue_capture_observations`
/// - `venue_capture_jobs`
///
/// Protected by RLS policies using `public.is_authorized_theatre_admin(theatre_id)`.
class SupabaseVenueCaptureRepository implements VenueCaptureRepository {
  final SupabaseClient? _customClient;

  SupabaseVenueCaptureRepository({SupabaseClient? client})
      : _customClient = client;

  SupabaseClient get _client => _customClient ?? Supabase.instance.client;

  @override
  Future<VenueCaptureSession> createSession(
    String theatreId, {
    Map<String, dynamic> metadata = const {},
  }) async {
    final response = await _client
        .from('venue_capture_sessions')
        .insert({
          'theatre_id': theatreId,
          'state': CaptureState.initial.name,
          'metadata': metadata,
        })
        .select()
        .single();

    return VenueCaptureSession.fromJson(response);
  }

  @override
  Future<VenueCaptureSession?> getSession(String sessionId) async {
    final response = await _client
        .from('venue_capture_sessions')
        .select()
        .eq('id', sessionId)
        .maybeSingle();

    if (response == null) return null;
    return VenueCaptureSession.fromJson(response);
  }

  @override
  Future<VenueCaptureSession?> getActiveSessionForTheatre(String theatreId) async {
    final response = await _client
        .from('venue_capture_sessions')
        .select()
        .eq('theatre_id', theatreId)
        .not('state', 'in', ['confirmed', 'cancelled'])
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();

    if (response == null) return null;
    return VenueCaptureSession.fromJson(response);
  }

  @override
  Future<VenueCaptureSession> updateSessionState(
    String sessionId,
    CaptureState newState,
  ) async {
    final current = await getSession(sessionId);
    if (current == null) {
      throw StateError('Capture session $sessionId not found.');
    }

    // Verify valid state machine transition before writing
    final validatedNext = current.transitionTo(newState);

    final payload = <String, dynamic>{
      'state': validatedNext.state.name,
      'updated_at': DateTime.now().toIso8601String(),
    };
    if (validatedNext.state == CaptureState.confirmed) {
      payload['confirmed_at'] = DateTime.now().toIso8601String();
    }

    final response = await _client
        .from('venue_capture_sessions')
        .update(payload)
        .eq('id', sessionId)
        .select()
        .single();

    return VenueCaptureSession.fromJson(response);
  }

  @override
  Future<void> saveReconstructionDraft(
    String sessionId,
    ReconstructionDraft draft,
  ) async {
    await _client.from('venue_capture_sessions').update({
      'reconstruction_draft': draft.toJson(),
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', sessionId);
  }

  @override
  Future<VenueCaptureSession> confirmDraft(
    String sessionId,
    ReconstructionDraft draft, {
    required String adminUserId,
  }) async {
    final session = await getSession(sessionId);
    if (session == null) {
      throw StateError('Capture session $sessionId not found.');
    }

    final reviewedDraft = draft.copyWith(
      isReviewed: true,
      reviewedBy: adminUserId,
      reviewedAt: DateTime.now(),
    );

    // Verify transition to confirmed
    session.transitionTo(CaptureState.confirmed);

    final now = DateTime.now().toIso8601String();
    final response = await _client
        .from('venue_capture_sessions')
        .update({
          'state': CaptureState.confirmed.name,
          'reconstruction_draft': reviewedDraft.toJson(),
          'confirmed_at': now,
          'updated_at': now,
        })
        .eq('id', sessionId)
        .select()
        .single();

    return VenueCaptureSession.fromJson(response);
  }

  @override
  Future<VenueCaptureSession> cancelSession(String sessionId) async {
    return updateSessionState(sessionId, CaptureState.cancelled);
  }

  @override
  Future<VenueCaptureMedia> addEvidence(VenueCaptureMedia media) async {
    final response = await _client
        .from('venue_capture_media')
        .insert({
          'id': media.id,
          'session_id': media.sessionId,
          'theatre_id': media.theatreId,
          'media_type': media.type.name,
          'storage_path': media.storagePath,
          'filename': media.filename,
          'mime_type': media.mimeType,
          'byte_size': media.byteSize,
          'metadata': media.metadata,
        })
        .select()
        .single();

    return VenueCaptureMedia.fromJson(response);
  }

  @override
  Future<List<VenueCaptureMedia>> listEvidence(String sessionId) async {
    final response = await _client
        .from('venue_capture_media')
        .select()
        .eq('session_id', sessionId)
        .order('created_at', ascending: true);

    return (response as List<dynamic>)
        .map((row) => VenueCaptureMedia.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<VenueCaptureRequest>> listRequests(String sessionId) async {
    final response = await _client
        .from('venue_capture_requests')
        .select()
        .eq('session_id', sessionId)
        .order('created_at', ascending: true);

    return (response as List<dynamic>)
        .map((row) => VenueCaptureRequest.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<VenueCaptureRequest> addRequest(VenueCaptureRequest request) async {
    final response = await _client
        .from('venue_capture_requests')
        .insert({
          'id': request.id,
          'session_id': request.sessionId,
          'theatre_id': request.theatreId,
          'target': request.target,
          'reason': request.reason,
          'required_evidence_type': request.requiredEvidenceType.name,
          'instruction': request.instruction,
          'related_observation_ids': request.relatedObservationIds,
          'priority': request.priority.name,
          'status': request.status.name,
        })
        .select()
        .single();

    return VenueCaptureRequest.fromJson(response);
  }

  @override
  Future<VenueCaptureRequest> resolveRequest(
    String requestId, {
    required RequestStatus status,
  }) async {
    final response = await _client
        .from('venue_capture_requests')
        .update({
          'status': status.name,
          'resolved_at': DateTime.now().toIso8601String(),
        })
        .eq('id', requestId)
        .select()
        .single();

    return VenueCaptureRequest.fromJson(response);
  }

  @override
  Future<List<VenueCaptureObservation>> listObservations(String sessionId) async {
    final response = await _client
        .from('venue_capture_observations')
        .select()
        .eq('session_id', sessionId)
        .order('created_at', ascending: true);

    return (response as List<dynamic>)
        .map((row) =>
            VenueCaptureObservation.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<VenueCaptureObservation> addObservation(
    VenueCaptureObservation observation,
  ) async {
    final response = await _client
        .from('venue_capture_observations')
        .insert({
          'id': observation.id,
          'session_id': observation.sessionId,
          'theatre_id': observation.theatreId,
          'feature_type': observation.featureType,
          'description': observation.description,
          'confidence': observation.confidence,
          'evidence_ids': observation.evidenceIds,
          'data': observation.data,
        })
        .select()
        .single();

    return VenueCaptureObservation.fromJson(response);
  }

  @override
  Future<List<VenueCaptureJob>> listJobs(String sessionId) async {
    final response = await _client
        .from('venue_capture_jobs')
        .select()
        .eq('session_id', sessionId)
        .order('created_at', ascending: false);

    return (response as List<dynamic>)
        .map((row) => VenueCaptureJob.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<VenueCaptureJob> createJob(VenueCaptureJob job) async {
    final response = await _client
        .from('venue_capture_jobs')
        .insert({
          'id': job.id,
          'session_id': job.sessionId,
          'theatre_id': job.theatreId,
          'job_type': job.jobType,
          'status': job.status.name,
          'progress': job.progress,
          'error_message': job.errorMessage,
          'worker_id': job.workerId,
          'payload': job.payload,
          'result_summary': job.resultSummary,
        })
        .select()
        .single();

    return VenueCaptureJob.fromJson(response);
  }

  @override
  Future<VenueCaptureJob> updateJob(VenueCaptureJob job) async {
    final response = await _client
        .from('venue_capture_jobs')
        .update({
          'status': job.status.name,
          'progress': job.progress,
          'error_message': job.errorMessage,
          'worker_id': job.workerId,
          'result_summary': job.resultSummary,
          'started_at': job.startedAt?.toIso8601String(),
          'completed_at': job.completedAt?.toIso8601String(),
        })
        .eq('id', job.id)
        .select()
        .single();

    return VenueCaptureJob.fromJson(response);
  }
}
