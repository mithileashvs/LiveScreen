import 'screen_config.dart' show Position3;

/// PART 7: material + a single absorption coefficient (0.0 = fully
/// reflective, 1.0 = fully absorptive) for one surface. Intentionally not a
/// full frequency-dependent absorption curve — "collect and store the
/// information the future audio engine may use," not simulate it.
class SurfaceAcoustics {
  String material;
  double absorptionCoefficient;

  SurfaceAcoustics({this.material = 'Standard', this.absorptionCoefficient = 0.3});

  Map<String, dynamic> toJson() => {
        'material': material,
        'absorptionCoefficient': absorptionCoefficient,
      };

  factory SurfaceAcoustics.fromJson(Map<String, dynamic> json) {
    return SurfaceAcoustics(
      material: json['material'] as String? ?? 'Standard',
      absorptionCoefficient:
          (json['absorptionCoefficient'] as num?)?.toDouble() ?? 0.3,
    );
  }
}

class AcousticPanelConfig {
  final String id;
  String material;
  Position3 position;

  /// Approximate area this panel covers, in square metres.
  double coverageSqm;

  AcousticPanelConfig({
    required this.id,
    this.material = 'Acoustic Foam',
    Position3? position,
    this.coverageSqm = 1.0,
  }) : position = position ?? Position3();

  Map<String, dynamic> toJson() => {
        'id': id,
        'material': material,
        'position': position.toJson(),
        'coverageSqm': coverageSqm,
      };

  factory AcousticPanelConfig.fromJson(Map<String, dynamic> json) {
    return AcousticPanelConfig(
      id: json['id'] as String,
      material: json['material'] as String? ?? 'Acoustic Foam',
      position: json['position'] == null
          ? null
          : Position3.fromJson(json['position'] as Map<String, dynamic>),
      coverageSqm: (json['coverageSqm'] as num?)?.toDouble() ?? 1.0,
    );
  }
}

class CurtainConfig {
  bool enabled;
  String material;
  Position3 position;

  CurtainConfig({this.enabled = false, this.material = 'Velvet', Position3? position})
      : position = position ?? Position3();

  Map<String, dynamic> toJson() => {
        'enabled': enabled,
        'material': material,
        'position': position.toJson(),
      };

  factory CurtainConfig.fromJson(Map<String, dynamic> json) {
    return CurtainConfig(
      enabled: json['enabled'] as bool? ?? false,
      material: json['material'] as String? ?? 'Velvet',
      position: json['position'] == null
          ? null
          : Position3.fromJson(json['position'] as Map<String, dynamic>),
    );
  }
}

/// PART 7. Designed so new acoustic parameters can be appended later
/// (e.g. a future frequency-band breakdown per surface) without breaking
/// configurations saved under the current shape — every field here is read
/// with a safe fallback in fromJson, and any future field would follow the
/// same pattern.
class AcousticsConfig {
  SurfaceAcoustics floor;
  SurfaceAcoustics walls;
  SurfaceAcoustics ceiling;
  List<AcousticPanelConfig> panels;
  CurtainConfig curtain;

  AcousticsConfig({
    SurfaceAcoustics? floor,
    SurfaceAcoustics? walls,
    SurfaceAcoustics? ceiling,
    List<AcousticPanelConfig>? panels,
    CurtainConfig? curtain,
  })  : floor = floor ?? SurfaceAcoustics(material: 'Carpet', absorptionCoefficient: 0.4),
        walls = walls ?? SurfaceAcoustics(material: 'Acoustic Fabric', absorptionCoefficient: 0.5),
        ceiling = ceiling ?? SurfaceAcoustics(material: 'Acoustic Panel', absorptionCoefficient: 0.6),
        panels = panels ?? [],
        curtain = curtain ?? CurtainConfig();

  Map<String, dynamic> toJson() => {
        'floor': floor.toJson(),
        'walls': walls.toJson(),
        'ceiling': ceiling.toJson(),
        'panels': panels.map((p) => p.toJson()).toList(),
        'curtain': curtain.toJson(),
      };

  factory AcousticsConfig.fromJson(Map<String, dynamic> json) {
    return AcousticsConfig(
      floor: json['floor'] == null
          ? null
          : SurfaceAcoustics.fromJson(json['floor'] as Map<String, dynamic>),
      walls: json['walls'] == null
          ? null
          : SurfaceAcoustics.fromJson(json['walls'] as Map<String, dynamic>),
      ceiling: json['ceiling'] == null
          ? null
          : SurfaceAcoustics.fromJson(json['ceiling'] as Map<String, dynamic>),
      panels: (json['panels'] as List<dynamic>? ?? [])
          .map((e) => AcousticPanelConfig.fromJson(e as Map<String, dynamic>))
          .toList(),
      curtain: json['curtain'] == null
          ? null
          : CurtainConfig.fromJson(json['curtain'] as Map<String, dynamic>),
    );
  }
}
