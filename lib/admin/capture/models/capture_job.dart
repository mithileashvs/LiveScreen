enum CaptureJobStatus { pending, running, completed, failed, cancelled }

extension CaptureJobStatusLabel on CaptureJobStatus {
  String get label {
    switch (this) {
      case CaptureJobStatus.pending:
        return 'Pending';
      case CaptureJobStatus.running:
        return 'Running';
      case CaptureJobStatus.completed:
        return 'Completed';
      case CaptureJobStatus.failed:
        return 'Failed';
      case CaptureJobStatus.cancelled:
        return 'Cancelled';
    }
  }
}

/// An asynchronous task executed by an external AI reconstruction worker.
/// Tracks progress, job parameters, worker identity, and execution timestamps.
class VenueCaptureJob {
  final String id;
  final String sessionId;
  final String theatreId;
  final String jobType;
  final CaptureJobStatus status;
  final double progress; // 0.0 to 1.0
  final String? errorMessage;
  final String? workerId;
  final Map<String, dynamic> payload;
  final Map<String, dynamic>? resultSummary;
  final DateTime createdAt;
  final DateTime? startedAt;
  final DateTime? completedAt;

  const VenueCaptureJob({
    required this.id,
    required this.sessionId,
    required this.theatreId,
    required this.jobType,
    this.status = CaptureJobStatus.pending,
    this.progress = 0.0,
    this.errorMessage,
    this.workerId,
    this.payload = const {},
    this.resultSummary,
    required this.createdAt,
    this.startedAt,
    this.completedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'sessionId': sessionId,
        'theatreId': theatreId,
        'jobType': jobType,
        'status': status.name,
        'progress': progress,
        'errorMessage': errorMessage,
        'workerId': workerId,
        'payload': payload,
        'resultSummary': resultSummary,
        'createdAt': createdAt.toIso8601String(),
        'startedAt': startedAt?.toIso8601String(),
        'completedAt': completedAt?.toIso8601String(),
      };

  factory VenueCaptureJob.fromJson(Map<String, dynamic> json) {
    final rawStatus = json['status'] as String?;
    final rawProgress = (json['progress'] as num?)?.toDouble() ?? 0.0;

    return VenueCaptureJob(
      id: json['id'] as String,
      sessionId: (json['sessionId'] ?? json['session_id']) as String,
      theatreId: (json['theatreId'] ?? json['theatre_id']) as String,
      jobType: (json['jobType'] ?? json['job_type']) as String? ?? 'general_reconstruction',
      status: CaptureJobStatus.values.firstWhere(
        (s) => s.name == rawStatus,
        orElse: () => CaptureJobStatus.pending,
      ),
      progress: rawProgress.clamp(0.0, 1.0),
      errorMessage: (json['errorMessage'] ?? json['error_message']) as String?,
      workerId: (json['workerId'] ?? json['worker_id']) as String?,
      payload: (json['payload'] as Map<String, dynamic>?) ?? const {},
      resultSummary: (json['resultSummary'] ?? json['result_summary']) as Map<String, dynamic>?,
      createdAt: DateTime.tryParse(
              (json['createdAt'] ?? json['created_at']) as String? ?? '') ??
          DateTime.now(),
      startedAt: json['startedAt'] != null || json['started_at'] != null
          ? DateTime.tryParse(
              (json['startedAt'] ?? json['started_at']) as String)
          : null,
      completedAt: json['completedAt'] != null || json['completed_at'] != null
          ? DateTime.tryParse(
              (json['completedAt'] ?? json['completed_at']) as String)
          : null,
    );
  }
}
