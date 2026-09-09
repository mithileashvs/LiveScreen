import 'dart:convert';
import '../models/theatre_configuration.dart';
import '../models/seat_config.dart';

/// The real Flutter -> Unity data bridge. This is what makes "the theatre a
/// user experiences actually matches what its admin configured" true,
/// instead of Unity always generating whatever numbers happen to be set on
/// its own scene's VenueParameters component.
///
/// Design choice worth explaining: rather than sending an explicit
/// per-seat array of positions, this sends the same GENERATOR PARAMETERS
/// (rows, seatsPerRow, spacing, etc.) that produced [config.seats] in the
/// first place — [config.lastSeatLayout], set by SeatLayoutGenerator on
/// this side. Unity's own SeatGenerator uses the exact same row-depth/
/// row-height formulas (see SeatGenerator.ComputeRowDepth/ComputeRowHeight
/// — this was deliberately kept in sync with SeatLayoutGenerator back when
/// both were written), so handing Unity the same generator inputs
/// reproduces the identical seat grid, without needing Unity to parse and
/// place an arbitrary list of individual seat coordinates. It also means
/// the payload is flat and matches VenueParameters' own field names
/// directly, so Unity can parse it with a single `JsonUtility.FromJson
/// <VenueParameters>` call instead of custom nested DTOs.
///
/// Known gap: this does not yet carry per-seat category overrides (an
/// admin who manually changed one seat from Standard to Premium in the
/// Seating tab) or speaker positions — Unity still assigns seat types with
/// its own built-in heuristic and generates its own default speaker rig
/// (see SpatialAudioManager). Room/screen/seating-layout dimensions are
/// what this connects today.
class TheatreUnityBridge {
  /// The seat ID to hand to `UnityExperienceScreen(seatLabel: ...)`.
  static String seatIdForPreview(String seatId) => seatId;

  /// A flat map of VenueParameters field names -> configured values, JSON
  /// encoded. Every key here MUST spell exactly the same as the
  /// corresponding public field on Unity's VenueParameters class — Unity's
  /// JsonUtility matches by exact field name, not by attribute/annotation.
  static String toUnityVenueParametersJson(TheatreConfiguration config) {
    final layout = config.lastSeatLayout ?? SeatLayoutParams();

    return jsonEncode({
      // Room
      'roomWidth': config.room.width,
      'roomLength': config.room.length,
      'roomHeight': config.room.height,
      // Screen
      'screenWidth': config.screen.width,
      'screenHeight': config.screen.height,
      // Seating layout — same inputs SeatLayoutGenerator used on this side.
      'rows': layout.rows,
      'seatsPerRow': layout.seatsPerRow,
      'seatSpacing': layout.seatSpacing,
      'rowSpacing': layout.rowSpacing,
      'seatWidth': layout.seatWidth,
      'firstRowDistanceFromScreen': layout.startPosition.z,
      'rowRisePerRow': layout.rowElevation,
    });
  }
}
