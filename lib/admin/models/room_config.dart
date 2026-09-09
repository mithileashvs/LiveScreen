/// Physical room dimensions, in metres (PART 2). Kept intentionally tiny —
/// this is the same width/length/height shape Unity's VenueParameters
/// already uses, so mapping this into Unity later is a direct 1:1 copy.
class RoomConfig {
  double width;
  double length;
  double height;

  RoomConfig({this.width = 20, this.length = 30, this.height = 8});

  /// PART 2: reject negative, zero, or otherwise invalid dimensions.
  /// Returns null when valid, or a user-facing error message otherwise.
  static String? validateDimension(String label, double? value) {
    if (value == null) return '$label must be a number.';
    if (value.isNaN || value.isInfinite) return '$label must be a valid number.';
    if (value <= 0) return '$label must be greater than zero.';
    return null;
  }

  List<String> validate() {
    final errors = <String>[];
    final w = validateDimension('Width', width);
    final l = validateDimension('Length', length);
    final h = validateDimension('Height', height);
    if (w != null) errors.add(w);
    if (l != null) errors.add(l);
    if (h != null) errors.add(h);
    return errors;
  }

  Map<String, dynamic> toJson() => {
        'width': width,
        'length': length,
        'height': height,
      };

  factory RoomConfig.fromJson(Map<String, dynamic> json) {
    return RoomConfig(
      width: (json['width'] as num?)?.toDouble() ?? 20,
      length: (json['length'] as num?)?.toDouble() ?? 30,
      height: (json['height'] as num?)?.toDouble() ?? 8,
    );
  }
}
