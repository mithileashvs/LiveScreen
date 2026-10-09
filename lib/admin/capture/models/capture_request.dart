import 'evidence.dart';

enum RequestPriority { low, medium, high, critical }

extension RequestPriorityLabel on RequestPriority {
  String get label {
    switch (this) {
      case RequestPriority.low:
        return 'Low';
      case RequestPriority.medium:
        return 'Medium';
      case RequestPriority.high:
        return 'High';
      case RequestPriority.critical:
        return 'Critical';
    }
  }
}

enum RequestStatus { pending, fulfilled, dismissed }

extension RequestStatusLabel on RequestStatus {
  String get label {
    switch (this) {
      case RequestStatus.pending:
        return 'Pending';
      case RequestStatus.fulfilled:
        return 'Fulfilled';
      case RequestStatus.dismissed:
        return 'Dismissed';
    }
  }
}

/// A targeted evidence request generated when visual reconstruction
/// encounters ambiguity or missing scale/viewpoints.
///
/// Avoids generic prompts like "Upload another photo" and instead supplies
/// exact guidance such as:
/// "Take a photo from the rear-right aisle facing diagonally toward the rear-left wall,
/// keeping the ceiling and speaker area visible."
class VenueCaptureRequest {
  final String id;
  final String sessionId;
  final String theatreId;

  /// The target element or architectural feature needing clarification.
  final String target;

  /// Technical reason why additional evidence is needed.
  final String reason;

  /// Type of evidence required (photo, measurement, etc.).
  final EvidenceType requiredEvidenceType;

  /// Specific, actionable instruction for the theatre administrator.
  final String instruction;

  /// Identifiers of observations associated with this request.
  final List<String> relatedObservationIds;

  final RequestPriority priority;
  final RequestStatus status;
  final DateTime createdAt;
  final DateTime? resolvedAt;

  /// Identifier of the evidence item that fulfilled this request.
  final String? fulfilledEvidenceId;

  const VenueCaptureRequest({
    required this.id,
    required this.sessionId,
    required this.theatreId,
    required this.target,
    required this.reason,
    required this.requiredEvidenceType,
    required this.instruction,
    this.relatedObservationIds = const [],
    this.priority = RequestPriority.medium,
    this.status = RequestStatus.pending,
    this.fulfilledEvidenceId,
    required this.createdAt,
    this.resolvedAt,
  });

  VenueCaptureRequest copyWith({
    RequestStatus? status,
    DateTime? resolvedAt,
    String? fulfilledEvidenceId,
  }) {
    return VenueCaptureRequest(
      id: id,
      sessionId: sessionId,
      theatreId: theatreId,
      target: target,
      reason: reason,
      requiredEvidenceType: requiredEvidenceType,
      instruction: instruction,
      relatedObservationIds: relatedObservationIds,
      priority: priority,
      status: status ?? this.status,
      fulfilledEvidenceId: fulfilledEvidenceId ?? this.fulfilledEvidenceId,
      createdAt: createdAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
    );
  }

  VenueCaptureRequest fulfill(String evidenceId, {DateTime? now}) {
    return copyWith(
      status: RequestStatus.fulfilled,
      fulfilledEvidenceId: evidenceId,
      resolvedAt: now ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'sessionId': sessionId,
        'theatreId': theatreId,
        'target': target,
        'reason': reason,
        'requiredEvidenceType': requiredEvidenceType.name,
        'instruction': instruction,
        'relatedObservationIds': relatedObservationIds,
        'priority': priority.name,
        'status': status.name,
        'fulfilledEvidenceId': fulfilledEvidenceId,
        'createdAt': createdAt.toIso8601String(),
        'resolvedAt': resolvedAt?.toIso8601String(),
      };

  factory VenueCaptureRequest.fromJson(Map<String, dynamic> json) {
    final rawType = (json['requiredEvidenceType'] ??
        json['required_evidence_type']) as String?;
    final rawPriority = json['priority'] as String?;
    final rawStatus = json['status'] as String?;

    return VenueCaptureRequest(
      id: json['id'] as String,
      sessionId: (json['sessionId'] ?? json['session_id']) as String,
      theatreId: (json['theatreId'] ?? json['theatre_id']) as String,
      target: json['target'] as String? ?? '',
      reason: json['reason'] as String? ?? '',
      requiredEvidenceType: EvidenceType.values.firstWhere(
        (e) => e.name == rawType,
        orElse: () => EvidenceType.photo,
      ),
      instruction: json['instruction'] as String? ?? '',
      relatedObservationIds: ((json['relatedObservationIds'] ??
              json['related_observation_ids']) as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      priority: RequestPriority.values.firstWhere(
        (p) => p.name == rawPriority,
        orElse: () => RequestPriority.medium,
      ),
      status: RequestStatus.values.firstWhere(
        (s) => s.name == rawStatus,
        orElse: () => RequestStatus.pending,
      ),
      fulfilledEvidenceId: (json['fulfilledEvidenceId'] ?? json['fulfilled_evidence_id']) as String?,
      createdAt: DateTime.tryParse(
              (json['createdAt'] ?? json['created_at']) as String? ?? '') ??
          DateTime.now(),
      resolvedAt: json['resolvedAt'] != null || json['resolved_at'] != null
          ? DateTime.tryParse(
              (json['resolvedAt'] ?? json['resolved_at']) as String)
          : null,
    );
  }
}
