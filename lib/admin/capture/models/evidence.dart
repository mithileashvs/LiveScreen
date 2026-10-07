/// Canonical evidence types supporting venue capture and reconstruction.
enum EvidenceType {
  /// Still photograph of the auditorium, screen, seats, walls, ceiling, or speakers.
  photo,

  /// Video clip of the venue. (Architecture-only in Phase 1; no video ML pipeline is executed).
  video,

  /// On-site physical measurement (laser distance measure, tape measurement, architect drawing).
  measurement,
}

extension EvidenceTypeLabel on EvidenceType {
  String get label {
    switch (this) {
      case EvidenceType.photo:
        return 'Photo';
      case EvidenceType.video:
        return 'Video';
      case EvidenceType.measurement:
        return 'Physical Measurement';
    }
  }
}

/// A reference pointing to a specific piece of evidence backing an observation or estimate.
class EvidenceReference {
  final String evidenceId;
  final EvidenceType type;
  final String? note;
  final DateTime? timestamp;

  const EvidenceReference({
    required this.evidenceId,
    required this.type,
    this.note,
    this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'evidenceId': evidenceId,
        'type': type.name,
        'note': note,
        'timestamp': timestamp?.toIso8601String(),
      };

  factory EvidenceReference.fromJson(Map<String, dynamic> json) {
    return EvidenceReference(
      evidenceId: json['evidenceId'] as String,
      type: EvidenceType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => EvidenceType.photo,
      ),
      note: json['note'] as String?,
      timestamp: json['timestamp'] == null
          ? null
          : DateTime.tryParse(json['timestamp'] as String),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EvidenceReference &&
          runtimeType == other.runtimeType &&
          evidenceId == other.evidenceId &&
          type == other.type;

  @override
  int get hashCode => Object.hash(evidenceId, type);
}

/// A stored media item or physical measurement record in a capture session.
/// Stored in private capture storage, accessible only to authorized theatre admins.
class VenueCaptureMedia {
  final String id;
  final String sessionId;
  final String theatreId;
  final EvidenceType type;
  final String storagePath;
  final String filename;
  final String? mimeType;
  final int? byteSize;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;
  final DateTime? capturedAt;

  const VenueCaptureMedia({
    required this.id,
    required this.sessionId,
    required this.theatreId,
    required this.type,
    required this.storagePath,
    required this.filename,
    this.mimeType,
    this.byteSize,
    this.metadata = const {},
    required this.createdAt,
    this.capturedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'sessionId': sessionId,
        'theatreId': theatreId,
        'type': type.name,
        'storagePath': storagePath,
        'filename': filename,
        'mimeType': mimeType,
        'byteSize': byteSize,
        'metadata': metadata,
        'createdAt': createdAt.toIso8601String(),
        'capturedAt': capturedAt?.toIso8601String(),
      };

  factory VenueCaptureMedia.fromJson(Map<String, dynamic> json) {
    return VenueCaptureMedia(
      id: json['id'] as String,
      sessionId: json['sessionId'] as String,
      theatreId: json['theatreId'] as String,
      type: EvidenceType.values.firstWhere(
        (t) => t.name == json['type'] || t.name == json['media_type'],
        orElse: () => EvidenceType.photo,
      ),
      storagePath: (json['storagePath'] ?? json['storage_path']) as String? ?? '',
      filename: json['filename'] as String? ?? '',
      mimeType: (json['mimeType'] ?? json['mime_type']) as String?,
      byteSize: (json['byteSize'] ?? json['byte_size']) as int?,
      metadata: (json['metadata'] as Map<String, dynamic>?) ?? const {},
      createdAt: DateTime.tryParse(
              (json['createdAt'] ?? json['created_at']) as String? ?? '') ??
          DateTime.now(),
      capturedAt: json['capturedAt'] != null || json['captured_at'] != null
          ? DateTime.tryParse(
              (json['capturedAt'] ?? json['captured_at']) as String)
          : null,
    );
  }
}
