/// Provenance describing how a particular estimate or measurement was obtained.
enum EstimateProvenance {
  /// Directly measured with physical measurement tool (tape measure, laser meter, etc.)
  measured,

  /// Measured directly by an admin user on-site
  adminMeasured,

  /// Inferred geometrically or algorithmically from constraints
  inferred,

  /// Estimated by an AI reconstruction worker from visual evidence
  aiEstimated,

  /// Unknown: no measurement, evidence, or inference exists
  unknown,
}

extension EstimateProvenanceLabel on EstimateProvenance {
  String get label {
    switch (this) {
      case EstimateProvenance.measured:
        return 'Measured';
      case EstimateProvenance.adminMeasured:
        return 'Admin Measured';
      case EstimateProvenance.inferred:
        return 'Inferred';
      case EstimateProvenance.aiEstimated:
        return 'AI Estimated';
      case EstimateProvenance.unknown:
        return 'Unknown';
    }
  }
}

/// Generic wrapper for measurements and parameters that preserves uncertainty,
/// provenance, confidence, and evidence traceability.
///
/// Core LiveScreen principle:
/// "AI assists reconstruction; it does not silently guess unknown measurements."
///
/// An [Estimate] must NEVER silently convert an unknown state to 0, false,
/// an empty string, or any guessed default.
class Estimate<T> {
  final T? value;
  final EstimateProvenance provenance;
  final String? source;
  final double? confidence; // 0.0 to 1.0
  final List<String> evidenceIds;
  final String? note;

  const Estimate({
    this.value,
    this.provenance = EstimateProvenance.unknown,
    this.source,
    this.confidence,
    this.evidenceIds = const [],
    this.note,
  });

  /// Factory for an explicitly unknown estimate.
  const Estimate.unknown({
    this.note,
    this.source,
  })  : value = null,
        provenance = EstimateProvenance.unknown,
        confidence = 0.0,
        evidenceIds = const [];

  /// Factory for a physical on-site measurement.
  Estimate.measured(
    T this.value, {
    this.source = 'physical_measurement',
    List<String> evidenceIds = const [],
    double confidence = 1.0,
    this.note,
  })  : provenance = EstimateProvenance.measured,
        confidence = confidence.clamp(0.0, 1.0),
        evidenceIds = List.unmodifiable(evidenceIds);

  /// Factory for a measurement confirmed by a theatre admin.
  Estimate.adminMeasured(
    T this.value, {
    this.source = 'theatre_admin',
    List<String> evidenceIds = const [],
    double confidence = 1.0,
    this.note,
  })  : provenance = EstimateProvenance.adminMeasured,
        confidence = confidence.clamp(0.0, 1.0),
        evidenceIds = List.unmodifiable(evidenceIds);

  /// Factory for an estimate derived by an AI model/worker.
  Estimate.aiEstimated(
    T this.value, {
    required double confidence,
    this.source,
    List<String> evidenceIds = const [],
    this.note,
  })  : provenance = EstimateProvenance.aiEstimated,
        confidence = confidence.clamp(0.0, 1.0),
        evidenceIds = List.unmodifiable(evidenceIds);

  /// Factory for a value inferred geometrically or logically.
  Estimate.inferred(
    T this.value, {
    required double confidence,
    this.source,
    List<String> evidenceIds = const [],
    this.note,
  })  : provenance = EstimateProvenance.inferred,
        confidence = confidence.clamp(0.0, 1.0),
        evidenceIds = List.unmodifiable(evidenceIds);

  /// True when a valid measurement/estimate is present.
  bool get isKnown => provenance != EstimateProvenance.unknown && value != null;

  /// True when the value is unknown or unmeasured.
  bool get isUnknown => !isKnown;

  /// Safely returns the value if known, or null if unknown.
  T? get valueOrNull => isKnown ? value : null;

  /// Returns the value if known, otherwise returns [fallback].
  T valueOr(T fallback) => isKnown ? value! : fallback;

  Map<String, dynamic> toJson([dynamic Function(T value)? valueToJson]) => {
        'value': value == null
            ? null
            : (valueToJson != null ? valueToJson(value as T) : value),
        'provenance': provenance.name,
        'source': source,
        'confidence': confidence,
        'evidenceIds': evidenceIds,
        'note': note,
      };

  factory Estimate.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic jsonValue) valueFromJson,
  ) {
    final rawProv = json['provenance'] as String?;
    final prov = EstimateProvenance.values.firstWhere(
      (p) => p.name == rawProv,
      orElse: () => EstimateProvenance.unknown,
    );

    final rawVal = json['value'];
    final T? val = rawVal != null ? valueFromJson(rawVal) : null;

    final rawConfidence = (json['confidence'] as num?)?.toDouble();

    return Estimate<T>(
      value: val,
      provenance: prov,
      source: json['source'] as String?,
      confidence: rawConfidence?.clamp(0.0, 1.0),
      evidenceIds: (json['evidenceIds'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      note: json['note'] as String?,
    );
  }

  @override
  String toString() {
    if (isUnknown) return 'Estimate<${T.toString()}>(UNKNOWN)';
    return 'Estimate<${T.toString()}>($value, provenance: ${provenance.name}, confidence: ${confidence?.toStringAsFixed(2)})';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Estimate<T> &&
          runtimeType == other.runtimeType &&
          value == other.value &&
          provenance == other.provenance &&
          source == other.source &&
          confidence == other.confidence &&
          note == other.note;

  @override
  int get hashCode => Object.hash(value, provenance, source, confidence, note);
}
