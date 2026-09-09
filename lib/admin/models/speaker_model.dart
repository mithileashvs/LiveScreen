import 'screen_config.dart' show Position3;

/// PART 5: kept extensible on purpose — this is a plain enum today, but if a
/// future theatre needs a type not listed here, adding one is a one-line,
/// backward-compatible change (existing saved speakers keep working;
/// [SpeakerModel.fromJson] falls back to [SpeakerType.other] for anything it
/// doesn't recognise instead of crashing).
enum SpeakerType {
  frontLeft,
  frontCenter,
  frontRight,
  sideSurround,
  rearSurround,
  ceiling,
  subwoofer,
  other,
}

extension SpeakerTypeLabel on SpeakerType {
  String get label {
    switch (this) {
      case SpeakerType.frontLeft:
        return 'Front Left';
      case SpeakerType.frontCenter:
        return 'Front Center';
      case SpeakerType.frontRight:
        return 'Front Right';
      case SpeakerType.sideSurround:
        return 'Side Surround';
      case SpeakerType.rearSurround:
        return 'Rear Surround';
      case SpeakerType.ceiling:
        return 'Ceiling';
      case SpeakerType.subwoofer:
        return 'Subwoofer';
      case SpeakerType.other:
        return 'Other';
    }
  }
}

enum SpeakerChannel {
  left,
  center,
  right,
  leftSurround,
  rightSurround,
  lfe, // low-frequency effects (subwoofer channel)
  overhead,
}

extension SpeakerChannelLabel on SpeakerChannel {
  String get label {
    switch (this) {
      case SpeakerChannel.left:
        return 'Left';
      case SpeakerChannel.center:
        return 'Center';
      case SpeakerChannel.right:
        return 'Right';
      case SpeakerChannel.leftSurround:
        return 'Left Surround';
      case SpeakerChannel.rightSurround:
        return 'Right Surround';
      case SpeakerChannel.lfe:
        return 'LFE';
      case SpeakerChannel.overhead:
        return 'Overhead';
    }
  }
}

/// PART 6: optional technical fields, deliberately separated from the
/// required configuration (position + type + channel) on [SpeakerModel]
/// itself. A speaker is fully valid with every field here left null.
class SpeakerSpecs {
  double? ratedPowerWatts;
  double? frequencyRangeLowHz;
  double? frequencyRangeHighHz;
  double? sensitivityDb;

  SpeakerSpecs({
    this.ratedPowerWatts,
    this.frequencyRangeLowHz,
    this.frequencyRangeHighHz,
    this.sensitivityDb,
  });

  bool get isEmpty =>
      ratedPowerWatts == null &&
      frequencyRangeLowHz == null &&
      frequencyRangeHighHz == null &&
      sensitivityDb == null;

  Map<String, dynamic> toJson() => {
        'ratedPowerWatts': ratedPowerWatts,
        'frequencyRangeLowHz': frequencyRangeLowHz,
        'frequencyRangeHighHz': frequencyRangeHighHz,
        'sensitivityDb': sensitivityDb,
      };

  factory SpeakerSpecs.fromJson(Map<String, dynamic> json) {
    return SpeakerSpecs(
      ratedPowerWatts: (json['ratedPowerWatts'] as num?)?.toDouble(),
      frequencyRangeLowHz: (json['frequencyRangeLowHz'] as num?)?.toDouble(),
      frequencyRangeHighHz: (json['frequencyRangeHighHz'] as num?)?.toDouble(),
      sensitivityDb: (json['sensitivityDb'] as num?)?.toDouble(),
    );
  }
}

/// PART 5/6/9. Required configuration is just [position] + [type] +
/// [channel] + a [name]; everything acoustic-specific lives in the
/// optional [specs]. This is the data the future spatial-audio engine
/// will read — no simulation happens here, just accurate storage.
class SpeakerModel {
  final String id;
  String name;
  SpeakerType type;
  SpeakerChannel channel;
  Position3 position;
  double rotationY;
  bool enabled;
  SpeakerSpecs specs;

  SpeakerModel({
    required this.id,
    this.name = '',
    this.type = SpeakerType.frontLeft,
    this.channel = SpeakerChannel.left,
    Position3? position,
    this.rotationY = 0,
    this.enabled = true,
    SpeakerSpecs? specs,
  })  : position = position ?? Position3(),
        specs = specs ?? SpeakerSpecs();

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type.name,
        'channel': channel.name,
        'position': position.toJson(),
        'rotationY': rotationY,
        'enabled': enabled,
        'specs': specs.isEmpty ? null : specs.toJson(),
      };

  factory SpeakerModel.fromJson(Map<String, dynamic> json) {
    return SpeakerModel(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      type: SpeakerType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => SpeakerType.other,
      ),
      channel: SpeakerChannel.values.firstWhere(
        (c) => c.name == json['channel'],
        orElse: () => SpeakerChannel.left,
      ),
      position: json['position'] == null
          ? null
          : Position3.fromJson(json['position'] as Map<String, dynamic>),
      rotationY: (json['rotationY'] as num?)?.toDouble() ?? 0,
      enabled: json['enabled'] as bool? ?? true,
      specs: json['specs'] == null
          ? null
          : SpeakerSpecs.fromJson(json['specs'] as Map<String, dynamic>),
    );
  }
}
