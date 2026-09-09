/// A plain X/Y/Z position shared by anything placed in the theatre (screen,
/// seats, speakers). Kept as its own tiny type rather than three loose
/// doubles on every model, and shaped to map 1:1 onto Unity's Vector3
/// (see SeatData.Position in the existing Unity project).
class Position3 {
  double x;
  double y;
  double z;

  Position3({this.x = 0, this.y = 0, this.z = 0});

  Map<String, dynamic> toJson() => {'x': x, 'y': y, 'z': z};

  factory Position3.fromJson(Map<String, dynamic> json) {
    return Position3(
      x: (json['x'] as num?)?.toDouble() ?? 0,
      y: (json['y'] as num?)?.toDouble() ?? 0,
      z: (json['z'] as num?)?.toDouble() ?? 0,
    );
  }
}

enum ScreenType { standard, imax, curved, led }

extension ScreenTypeLabel on ScreenType {
  String get label {
    switch (this) {
      case ScreenType.standard:
        return 'Standard';
      case ScreenType.imax:
        return 'IMAX';
      case ScreenType.curved:
        return 'Curved';
      case ScreenType.led:
        return 'LED Wall';
    }
  }
}

/// PART 3. Position/rotation are never hardcoded — an admin sets them
/// (or accepts the defaults below), and this is what Unity's ScreenGenerator
/// will eventually read instead of its own VenueParameters fields.
class ScreenConfig {
  double width;
  double height;
  Position3 position;

  /// Degrees around the vertical (Y) axis. 0 = facing straight down +Z,
  /// matching the existing Unity scene's forward-facing screen.
  double rotationY;
  ScreenType type;

  ScreenConfig({
    this.width = 18,
    this.height = 8,
    Position3? position,
    this.rotationY = 0,
    this.type = ScreenType.standard,
  }) : position = position ?? Position3(x: 0, y: 4, z: 1);

  List<String> validate() {
    final errors = <String>[];
    if (width <= 0) errors.add('Screen width must be greater than zero.');
    if (height <= 0) errors.add('Screen height must be greater than zero.');
    return errors;
  }

  Map<String, dynamic> toJson() => {
        'width': width,
        'height': height,
        'position': position.toJson(),
        'rotationY': rotationY,
        'type': type.name,
      };

  factory ScreenConfig.fromJson(Map<String, dynamic> json) {
    return ScreenConfig(
      width: (json['width'] as num?)?.toDouble() ?? 18,
      height: (json['height'] as num?)?.toDouble() ?? 8,
      position: json['position'] == null
          ? null
          : Position3.fromJson(json['position'] as Map<String, dynamic>),
      rotationY: (json['rotationY'] as num?)?.toDouble() ?? 0,
      type: ScreenType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => ScreenType.standard,
      ),
    );
  }
}
