import '../../models/seat.dart' as booking;
import 'screen_config.dart' show Position3;

/// The seat "kind" an admin assigns when authoring a venue layout.
///
/// Deliberately NOT reusing the existing app's [booking.SeatType] enum
/// (available/selected/booked/premium/recliner) — that enum encodes a
/// seat's live *booking state*, which has no meaning while an admin is
/// laying out a venue. [SeatCategory] instead mirrors Unity's SeatType
/// (Standard/Premium/Recliner) since that's the concept an admin is
/// actually choosing.
enum SeatCategory { standard, premium, recliner }

/// PART 4: parameters used to auto-generate a full grid of [SeatConfig]s,
/// mirroring the same shape Unity's VenueParameters already uses for the
/// exact same purpose (rows, seatsPerRow, spacing, etc.) so a future
/// "send this layout to Unity" step is a straight field-for-field mapping.
class SeatLayoutParams {
  int rows;
  int seatsPerRow;
  double rowSpacing;
  double seatSpacing;
  double seatWidth;
  double seatDepth;
  double seatHeight;
  Position3 startPosition;

  /// Metres each row rises above the previous one (gentle stadium slope).
  double rowElevation;

  SeatLayoutParams({
    this.rows = 10,
    this.seatsPerRow = 12,
    this.rowSpacing = 1.1,
    this.seatSpacing = 0.6,
    this.seatWidth = 0.5,
    this.seatDepth = 0.6,
    this.seatHeight = 0.9,
    Position3? startPosition,
    this.rowElevation = 0.12,
  }) : startPosition = startPosition ?? Position3(x: 0, y: 0, z: 7);

  Map<String, dynamic> toJson() => {
        'rows': rows,
        'seatsPerRow': seatsPerRow,
        'rowSpacing': rowSpacing,
        'seatSpacing': seatSpacing,
        'seatWidth': seatWidth,
        'seatDepth': seatDepth,
        'seatHeight': seatHeight,
        'startPosition': startPosition.toJson(),
        'rowElevation': rowElevation,
      };

  factory SeatLayoutParams.fromJson(Map<String, dynamic> json) {
    return SeatLayoutParams(
      rows: json['rows'] as int? ?? 10,
      seatsPerRow: json['seatsPerRow'] as int? ?? 12,
      rowSpacing: (json['rowSpacing'] as num?)?.toDouble() ?? 1.1,
      seatSpacing: (json['seatSpacing'] as num?)?.toDouble() ?? 0.6,
      seatWidth: (json['seatWidth'] as num?)?.toDouble() ?? 0.5,
      seatDepth: (json['seatDepth'] as num?)?.toDouble() ?? 0.6,
      seatHeight: (json['seatHeight'] as num?)?.toDouble() ?? 0.9,
      startPosition: json['startPosition'] == null
          ? null
          : Position3.fromJson(json['startPosition'] as Map<String, dynamic>),
      rowElevation: (json['rowElevation'] as num?)?.toDouble() ?? 0.12,
    );
  }
}

/// One admin-authored seat placement (PART 4). This is the venue-authoring
/// counterpart to the app's existing runtime [booking.SeatModel] — that
/// model carries a live price + booking state for the user-facing seat map;
/// this one carries the physical layout an admin defines once per theatre.
/// [toBookingSeat] bridges the two without duplicating the row/number/id logic.
class SeatConfig {
  final String id; // e.g. "C12" — row + number, matching Unity's SeatData.Id
  final String row;
  final int number;
  Position3 position;
  double rotationY;
  SeatCategory category;

  SeatConfig({
    required this.row,
    required this.number,
    Position3? position,
    this.rotationY = 0,
    this.category = SeatCategory.standard,
  })  : id = '$row$number',
        position = position ?? Position3();

  /// Bridges into the existing app's booking-facing [booking.SeatModel],
  /// so the user-facing seat map and Unity preview can be driven by the
  /// exact same seats an admin configured, instead of a second hand-typed
  /// seat list (PART 4: "do not duplicate seat data unnecessarily").
  booking.SeatModel toBookingSeat({required double price}) {
    booking.SeatType bookingType;
    switch (category) {
      case SeatCategory.premium:
        bookingType = booking.SeatType.premium;
        break;
      case SeatCategory.recliner:
        bookingType = booking.SeatType.recliner;
        break;
      case SeatCategory.standard:
        bookingType = booking.SeatType.available;
        break;
    }
    return booking.SeatModel(
      row: row,
      number: number,
      price: price,
      type: bookingType,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'row': row,
        'number': number,
        'position': position.toJson(),
        'rotationY': rotationY,
        'category': category.name,
      };

  factory SeatConfig.fromJson(Map<String, dynamic> json) {
    return SeatConfig(
      row: json['row'] as String,
      number: json['number'] as int,
      position: json['position'] == null
          ? null
          : Position3.fromJson(json['position'] as Map<String, dynamic>),
      rotationY: (json['rotationY'] as num?)?.toDouble() ?? 0,
      category: SeatCategory.values.firstWhere(
        (c) => c.name == json['category'],
        orElse: () => SeatCategory.standard,
      ),
    );
  }
}
