/// A raw or intermediate feature observed by an AI analysis pass
/// (e.g. wall corner, screen bezel, seat row lattice, speaker enclosure).
class VenueCaptureObservation {
  final String id;
  final String sessionId;
  final String theatreId;
  final String featureType;
  final String? description;
  final double? confidence; // 0.0 to 1.0
  final List<String> evidenceIds;
  final Map<String, dynamic> data;
  final DateTime observedAt;

  const VenueCaptureObservation({
    required this.id,
    required this.sessionId,
    required this.theatreId,
    required this.featureType,
    this.description,
    this.confidence,
    this.evidenceIds = const [],
    this.data = const {},
    required this.observedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'sessionId': sessionId,
        'theatreId': theatreId,
        'featureType': featureType,
        'description': description,
        'confidence': confidence,
        'evidenceIds': evidenceIds,
        'data': data,
        'observedAt': observedAt.toIso8601String(),
      };

  factory VenueCaptureObservation.fromJson(Map<String, dynamic> json) {
    final rawConf = (json['confidence'] as num?)?.toDouble();
    return VenueCaptureObservation(
      id: json['id'] as String,
      sessionId: (json['sessionId'] ?? json['session_id']) as String,
      theatreId: (json['theatreId'] ?? json['theatre_id']) as String,
      featureType: (json['featureType'] ?? json['feature_type']) as String? ?? 'unknown',
      description: json['description'] as String?,
      confidence: rawConf?.clamp(0.0, 1.0),
      evidenceIds: ((json['evidenceIds'] ?? json['evidence_ids']) as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      data: (json['data'] as Map<String, dynamic>?) ?? const {},
      observedAt: DateTime.tryParse(
              (json['observedAt'] ?? json['observed_at']) as String? ?? '') ??
          DateTime.now(),
    );
  }
}
