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

/// Evidence categories for capturing comprehensive venue coverage.
enum EvidenceCategory {
  frontWall,
  rearWall,
  leftWall,
  rightWall,
  seating,
  screenStage,
  speakers,
  ceiling,
  lighting,
  materialsColors,
  measurement,
  general,
}

extension EvidenceCategoryExtension on EvidenceCategory {
  String get label {
    switch (this) {
      case EvidenceCategory.frontWall:
        return 'Front Wall & Screen';
      case EvidenceCategory.rearWall:
        return 'Rear Wall & Projection';
      case EvidenceCategory.leftWall:
        return 'Left Wall';
      case EvidenceCategory.rightWall:
        return 'Right Wall';
      case EvidenceCategory.seating:
        return 'Seating Area';
      case EvidenceCategory.screenStage:
        return 'Screen & Stage';
      case EvidenceCategory.speakers:
        return 'Surround Speakers';
      case EvidenceCategory.ceiling:
        return 'Ceiling & Rigging';
      case EvidenceCategory.lighting:
        return 'Aisle & House Lighting';
      case EvidenceCategory.materialsColors:
        return 'Finishes & Materials';
      case EvidenceCategory.measurement:
        return 'Physical Measurement';
      case EvidenceCategory.general:
        return 'General Auditorium';
    }
  }

  String get guidance {
    switch (this) {
      case EvidenceCategory.frontWall:
        return 'Take a wide photo from the centre aisle facing directly toward the screen and front wall.';
      case EvidenceCategory.rearWall:
        return 'Stand at the front seating area facing the back wall showing the projection port and rear exits.';
      case EvidenceCategory.leftWall:
        return 'Photograph the entire left wall from front to back, keeping wall-mounted speakers visible.';
      case EvidenceCategory.rightWall:
        return 'Photograph the entire right wall from front to back, keeping wall-mounted speakers visible.';
      case EvidenceCategory.seating:
        return 'Capture the entire seating area from an elevated or rear vantage point showing row curvature.';
      case EvidenceCategory.screenStage:
        return 'Take a framed photo of the screen frame and stage floor level to capture aspect ratio.';
      case EvidenceCategory.speakers:
        return 'Close-up photograph of visible surround speaker cabinets mounted on walls or ceiling.';
      case EvidenceCategory.ceiling:
        return 'Photograph the ceiling structure, acoustic baffles, and overhead lighting fixtures.';
      case EvidenceCategory.lighting:
        return 'Capture illuminated aisle steps, wall sconces, and house lights.';
      case EvidenceCategory.materialsColors:
        return 'Close-up photo of wall fabric/panel finish, carpet texture, and seat upholstery.';
      case EvidenceCategory.measurement:
        return 'Record a physical laser distance or tape measurement between known reference points.';
      case EvidenceCategory.general:
        return 'Overview wide-angle photo of the auditorium from any key corner.';
    }
  }
}

/// Lifecycle status of an evidence upload.
enum UploadState {
  pending,
  uploading,
  uploaded,
  failed,
}

extension UploadStateLabel on UploadState {
  String get label {
    switch (this) {
      case UploadState.pending:
        return 'Pending';
      case UploadState.uploading:
        return 'Uploading';
      case UploadState.uploaded:
        return 'Uploaded';
      case UploadState.failed:
        return 'Upload Failed';
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
  final EvidenceCategory category;
  final UploadState uploadState;
  final String storagePath;
  final String filename;
  final String? mimeType;
  final int? byteSize;
  final String? description;
  final String? targetRequestId;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;
  final DateTime? capturedAt;

  const VenueCaptureMedia({
    required this.id,
    required this.sessionId,
    required this.theatreId,
    required this.type,
    this.category = EvidenceCategory.general,
    this.uploadState = UploadState.uploaded,
    required this.storagePath,
    required this.filename,
    this.mimeType,
    this.byteSize,
    this.description,
    this.targetRequestId,
    this.metadata = const {},
    required this.createdAt,
    this.capturedAt,
  });

  VenueCaptureMedia copyWith({
    EvidenceCategory? category,
    UploadState? uploadState,
    String? storagePath,
    String? filename,
    String? mimeType,
    int? byteSize,
    String? description,
    String? targetRequestId,
    Map<String, dynamic>? metadata,
    DateTime? capturedAt,
  }) {
    return VenueCaptureMedia(
      id: id,
      sessionId: sessionId,
      theatreId: theatreId,
      type: type,
      category: category ?? this.category,
      uploadState: uploadState ?? this.uploadState,
      storagePath: storagePath ?? this.storagePath,
      filename: filename ?? this.filename,
      mimeType: mimeType ?? this.mimeType,
      byteSize: byteSize ?? this.byteSize,
      description: description ?? this.description,
      targetRequestId: targetRequestId ?? this.targetRequestId,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt,
      capturedAt: capturedAt ?? this.capturedAt,
    );
  }

  Map<String, dynamic> toJson() {
    final mergedMetadata = Map<String, dynamic>.from(metadata);
    if (description != null) mergedMetadata['description'] = description;
    if (targetRequestId != null) mergedMetadata['target_request_id'] = targetRequestId;
    mergedMetadata['category'] = category.name;
    mergedMetadata['upload_state'] = uploadState.name;

    return {
      'id': id,
      'sessionId': sessionId,
      'theatreId': theatreId,
      'type': type.name,
      'category': category.name,
      'uploadState': uploadState.name,
      'storagePath': storagePath,
      'filename': filename,
      'mimeType': mimeType,
      'byteSize': byteSize,
      'description': description,
      'targetRequestId': targetRequestId,
      'metadata': mergedMetadata,
      'createdAt': createdAt.toIso8601String(),
      'capturedAt': capturedAt?.toIso8601String(),
    };
  }

  factory VenueCaptureMedia.fromJson(Map<String, dynamic> json) {
    final rawType = (json['type'] ?? json['media_type']) as String?;
    final resolvedType = EvidenceType.values.firstWhere(
      (t) => t.name == rawType,
      orElse: () => EvidenceType.photo,
    );

    final meta = (json['metadata'] as Map<String, dynamic>?) ?? const {};

    final rawCat = (json['category'] ?? meta['category']) as String?;
    final defaultCat = resolvedType == EvidenceType.measurement
        ? EvidenceCategory.measurement
        : EvidenceCategory.general;
    final resolvedCat = rawCat != null
        ? EvidenceCategory.values.firstWhere(
            (c) => c.name == rawCat,
            orElse: () => defaultCat,
          )
        : defaultCat;

    final rawState = (json['uploadState'] ?? json['upload_state'] ?? meta['upload_state']) as String?;
    final resolvedState = rawState != null
        ? UploadState.values.firstWhere(
            (u) => u.name == rawState,
            orElse: () => UploadState.uploaded,
          )
        : UploadState.uploaded;

    final desc = (json['description'] ?? meta['description']) as String?;
    final reqId = (json['targetRequestId'] ?? json['target_request_id'] ?? meta['target_request_id']) as String?;

    return VenueCaptureMedia(
      id: json['id'] as String,
      sessionId: (json['sessionId'] ?? json['session_id']) as String,
      theatreId: (json['theatreId'] ?? json['theatre_id']) as String,
      type: resolvedType,
      category: resolvedCat,
      uploadState: resolvedState,
      storagePath: (json['storagePath'] ?? json['storage_path']) as String? ?? '',
      filename: json['filename'] as String? ?? '',
      mimeType: (json['mimeType'] ?? json['mime_type']) as String?,
      byteSize: (json['byteSize'] ?? json['byte_size']) as int?,
      description: desc,
      targetRequestId: reqId,
      metadata: meta,
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
