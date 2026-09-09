import '../models/screen_config.dart';
import '../models/seat_config.dart';

/// Generates a full grid of [SeatConfig]s from [SeatLayoutParams] (PART 4),
/// so an admin never has to type individual seat coordinates.
///
/// The row-depth/row-height formulas intentionally mirror Unity's
/// SeatGenerator.ComputeRowDepth/ComputeRowHeight (straight-arrangement
/// case) — same inputs, same outputs — so a layout authored here and one
/// generated in Unity agree on where every seat physically sits.
class SeatLayoutGenerator {
  static List<SeatConfig> generate(SeatLayoutParams params) {
    final seats = <SeatConfig>[];

    for (int rowIndex = 0; rowIndex < params.rows; rowIndex++) {
      final rowLabel = _rowLabel(rowIndex);
      final rowDepth = params.startPosition.z + (rowIndex * params.rowSpacing);
      final rowHeight = params.startPosition.y + (rowIndex * params.rowElevation);

      final rowWidth = (params.seatsPerRow - 1) * params.seatSpacing;
      final startX = params.startPosition.x - (rowWidth / 2);

      for (int seatIndex = 0; seatIndex < params.seatsPerRow; seatIndex++) {
        final x = startX + (seatIndex * params.seatSpacing);
        seats.add(SeatConfig(
          row: rowLabel,
          number: seatIndex + 1,
          position: Position3(x: x, y: rowHeight, z: rowDepth),
        ));
      }
    }

    return seats;
  }

  /// A, B, C ... Z, AA, AB ... — same scheme Unity's GetRowLabel uses, so row
  /// labels never diverge between the two if a venue ever exceeds 26 rows.
  static String _rowLabel(int index) {
    String label = '';
    int n = index;
    do {
      label = String.fromCharCode(65 + (n % 26)) + label;
      n = (n ~/ 26) - 1;
    } while (n >= 0);
    return label;
  }
}
