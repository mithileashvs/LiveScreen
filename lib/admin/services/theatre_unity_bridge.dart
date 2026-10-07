import 'dart:convert';
import '../models/theatre_configuration.dart';
import '../models/seat_config.dart';
import '../models/screen_config.dart';
import '../../shared/services/trailer_url.dart';

/// The canonical Flutter -> Unity theatre payload.
///
/// ONE serialized TheatreConfiguration feeds BOTH the web preview (which
/// reads [TheatreConfiguration] directly) and Unity (which reads the JSON
/// below). There is deliberately no second, Unity-only configuration
/// object: every value here is read straight off the same
/// [TheatreConfiguration] the Theatre Admin saved to Supabase.
///
/// WHY THE SHAPE LOOKS LIKE THIS
///
/// The top-level scalar keys are spelled exactly like the public fields on
/// Unity's `VenueParameters` class, because Unity's `JsonUtility` matches
/// by exact field name. That also keeps this payload readable by the
/// PREVIOUS WebGL build, which only knew about the room/screen/seating
/// scalars — an older build silently ignores the newer keys instead of
/// failing to parse, so deploying Flutter ahead of a Unity rebuild
/// degrades rather than breaks.
///
/// [seats] and [speakers] are sent as EXPLICIT arrays rather than as
/// generator parameters alone. Sending only generator parameters (what
/// this used to do) meant Unity re-derived the grid with its own formulas,
/// so anything that wasn't a perfect grid — a per-seat category override, a
/// hand-placed speaker — was silently lost and replaced by Unity's own
/// heuristics. Sending the actual saved objects makes the saved
/// configuration the source of truth, which is the entire point. The
/// generator parameters are still sent alongside, because Unity needs them
/// for the things that are NOT per-seat (row rise, aisles, room fitting).
class TheatreUnityBridge {
  /// Bumped whenever the payload shape changes incompatibly. Unity reads
  /// this and can branch; older Unity builds ignore it harmlessly.
  static const int payloadVersion = 2;

  /// The seat ID to hand to `UnityExperienceScreen(seatLabel: ...)`.
  static String seatIdForPreview(String seatId) => seatId;

  /// True when this theatre has configuration a Theatre Owner actually
  /// saved, as opposed to a brand-new empty draft. Unity uses this to
  /// decide whether it is allowed to fall back to its own scene defaults:
  /// once an owner has saved anything, Unity must never substitute demo
  /// values (see FlutterBridge.LoadConfiguration on the Unity side).
  static bool hasSavedConfiguration(TheatreConfiguration config) {
    return config.seats.isNotEmpty ||
        config.speakers.isNotEmpty ||
        config.lastSeatLayout != null;
  }

  /// Recovers the seat-grid generator parameters for [config].
  ///
  /// [TheatreConfiguration.lastSeatLayout] is nullable, and the old bridge
  /// fell back to `SeatLayoutParams()` — i.e. the DEFAULTS, 10 rows x 12
  /// seats — whenever it was null. That was a silent replacement of a real
  /// theatre's layout with demo numbers. When it is null but seats exist,
  /// derive the parameters back out of the saved seats instead, so the
  /// numbers Unity gets still describe THIS theatre.
  static SeatLayoutParams effectiveSeatLayout(TheatreConfiguration config) {
    final saved = config.lastSeatLayout;
    if (saved != null) return saved;
    if (config.seats.isEmpty) return SeatLayoutParams();

    final rowLabels = <String>[];
    for (final seat in config.seats) {
      if (!rowLabels.contains(seat.row)) rowLabels.add(seat.row);
    }
    final firstRow = config.seats.where((s) => s.row == rowLabels.first).toList();

    double spacing(List<double> values) {
      if (values.length < 2) return 0;
      values.sort();
      return (values.last - values.first) / (values.length - 1);
    }

    final seatSpacing = spacing(firstRow.map((s) => s.position.x).toList());
    final rowDepths = <double>[];
    for (final label in rowLabels) {
      final seat = config.seats.firstWhere((s) => s.row == label);
      rowDepths.add(seat.position.z);
    }
    final rowSpacing = spacing(List<double>.from(rowDepths));

    final rowHeights = <double>[];
    for (final label in rowLabels) {
      final seat = config.seats.firstWhere((s) => s.row == label);
      rowHeights.add(seat.position.y);
    }
    final rowElevation = spacing(List<double>.from(rowHeights));

    final frontRowZ =
        config.seats.map((s) => s.position.z).reduce((a, b) => a < b ? a : b);
    final baseY =
        config.seats.map((s) => s.position.y).reduce((a, b) => a < b ? a : b);

    return SeatLayoutParams(
      rows: rowLabels.length,
      seatsPerRow: firstRow.length,
      seatSpacing: seatSpacing > 0 ? seatSpacing : 0.6,
      rowSpacing: rowSpacing > 0 ? rowSpacing : 1.1,
      rowElevation: rowElevation,
      startPosition: Position3(x: 0, y: baseY, z: frontRowZ),
    );
  }

  /// The canonical payload as a Dart map — exposed separately from
  /// [toUnityTheatreConfigJson] so tests can assert on structure without
  /// re-parsing JSON.
  static Map<String, dynamic> toUnityPayload(TheatreConfiguration config) {
    final layout = effectiveSeatLayout(config);
    final screen = config.screen;

    return {
      'payloadVersion': payloadVersion,
      'theatreId': config.id,
      'theatreName': config.basicInfo.name,
      'hasSavedConfiguration': hasSavedConfiguration(config),

      // --- Room ------------------------------------------------------
      'roomWidth': config.room.width,
      'roomLength': config.room.length,
      'roomHeight': config.room.height,

      // --- Screen ----------------------------------------------------
      // ScreenConfig.position is the CENTRE of the screen panel: x =
      // lateral offset, y = centre height above the floor, z = distance
      // from the front wall. Unity previously derived centre height from
      // its own screenHeightFromFloor field and ignored x/rotation
      // entirely, which is why a moved or rotated screen never showed up.
      'screenWidth': screen.width,
      'screenHeight': screen.height,
      'screenOffsetX': screen.position.x,
      'screenCenterY': screen.position.y,
      'screenDistanceFromFrontWall': screen.position.z,
      'screenRotationY': screen.rotationY,
      'screenType': screen.type.name,

      // --- Seating generator parameters ------------------------------
      'rows': layout.rows,
      'seatsPerRow': layout.seatsPerRow,
      'seatSpacing': layout.seatSpacing,
      'rowSpacing': layout.rowSpacing,
      'seatWidth': layout.seatWidth,
      'seatDepth': layout.seatDepth,
      'seatHeight': layout.seatHeight,
      'firstRowDistanceFromScreen': layout.startPosition.z,
      'rowRisePerRow': layout.rowElevation,
      'seatingOriginX': layout.startPosition.x,
      'seatingBaseY': layout.startPosition.y,

      // --- Actual saved seats ----------------------------------------
      // Stable IDs, straight from the same list the web seat map and the
      // booking system use. Unity places exactly these, so "A1..A12 on the
      // web" and "A1..A12 in Unity" cannot drift apart.
      'seats': config.seats
          .map((s) => {
                'id': s.id,
                'row': s.row,
                'number': s.number,
                'x': s.position.x,
                'y': s.position.y,
                'z': s.position.z,
                'rotationY': s.rotationY,
                'category': s.category.name,
              })
          .toList(),

      // --- Actual saved speakers -------------------------------------
      'speakers': config.speakers
          .where((s) => s.enabled)
          .map((s) => {
                'id': s.id,
                'name': s.name,
                'type': s.type.name,
                'channel': s.channel.name,
                'x': s.position.x,
                'y': s.position.y,
                'z': s.position.z,
                'rotationY': s.rotationY,
                'ratedPowerWatts': s.specs.ratedPowerWatts ?? 0,
                'frequencyRangeLowHz': s.specs.frequencyRangeLowHz ?? 0,
                'frequencyRangeHighHz': s.specs.frequencyRangeHighHz ?? 0,
                'sensitivityDb': s.specs.sensitivityDb ?? 0,
              })
          .toList(),

      // --- Acoustics --------------------------------------------------
      // Passed into Unity's existing spatial-audio system as reverb/decay
      // inputs. This is NOT a claim of accurate acoustic simulation — it
      // is the theatre's configured absorption actually reaching the audio
      // system instead of being dropped on the floor.
      'acoustics': {
        'floorAbsorption': config.acoustics.floor.absorptionCoefficient,
        'wallAbsorption': config.acoustics.walls.absorptionCoefficient,
        'ceilingAbsorption': config.acoustics.ceiling.absorptionCoefficient,
        'panelCount': config.acoustics.panels.length,
        'panelCoverageSqm': config.acoustics.panels
            .fold<double>(0, (sum, p) => sum + p.coverageSqm),
        'curtainEnabled': config.acoustics.curtain.enabled,
      },
    };
  }

  /// The canonical payload, JSON encoded, ready for
  /// `postMessage('load_configuration:<json>')`.
  static String toUnityTheatreConfigJson(TheatreConfiguration config) =>
      jsonEncode(toUnityPayload(config));

  /// Previous name, kept so nothing that still calls it breaks.
  @Deprecated('Use toUnityTheatreConfigJson — same payload, clearer name.')
  static String toUnityVenueParametersJson(TheatreConfiguration config) =>
      toUnityTheatreConfigJson(config);

  /// The trailer payload for `postMessage('load_trailer:<json>')`.
  ///
  /// [TrailerSource] (trailer_url.dart) is the ONE place that decides what a
  /// saved `movies.trailer_path` value actually is — this just hands that
  /// same classification to Unity rather than re-guessing it. `kind` is
  /// [TrailerKind.name] ("directFile", "youtube", "vimeo", "missing",
  /// "unsupported"), which Unity's FlutterBridge.LoadTrailer branches on:
  /// only "directFile" can become an actual video texture on the generated
  /// screen (see TrailerScreenPlayer.cs for exactly why the others can't).
  static Map<String, String> toUnityTrailerPayload(TrailerSource source) => {
        'kind': source.kind.name,
        'url': source.playbackUrl,
      };

  static String toUnityTrailerJson(TrailerSource source) =>
      jsonEncode(toUnityTrailerPayload(source));
}
