import '../models/estimate.dart';
import '../../models/screen_config.dart' show Position3, ScreenType;
import '../../models/seat_config.dart' show SeatCategory;
import '../../models/speaker_model.dart' show SpeakerType;

/// LiveScreen coordinate conventions as captured in the reconstruction draft.
///
/// Convention:
/// - Units: metres
/// - Unity: left-handed, Y-up
/// - Origin: front wall floor center (X=0, Y=0, Z=0)
/// - +X: lateral (width: positive right, negative left facing screen)
/// - +Y: vertical (height above floor)
/// - +Z: front-to-back (depth from screen wall into auditorium)
/// - Seat orientation: rotationY = 0 faces -Z (toward screen).
class DraftCoordinateFrame {
  final String units;
  final String origin;
  final String lateralAxis;
  final String upAxis;
  final String forwardAxis;
  final String seatForwardFacing;

  const DraftCoordinateFrame({
    this.units = 'metres',
    this.origin = 'front_wall_floor_center',
    this.lateralAxis = '+X',
    this.upAxis = '+Y',
    this.forwardAxis = '+Z',
    this.seatForwardFacing = '-Z',
  });

  Map<String, dynamic> toJson() => {
        'units': units,
        'origin': origin,
        'lateralAxis': lateralAxis,
        'upAxis': upAxis,
        'forwardAxis': forwardAxis,
        'seatForwardFacing': seatForwardFacing,
      };

  factory DraftCoordinateFrame.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const DraftCoordinateFrame();
    return DraftCoordinateFrame(
      units: json['units'] as String? ?? 'metres',
      origin: json['origin'] as String? ?? 'front_wall_floor_center',
      lateralAxis: json['lateralAxis'] as String? ?? '+X',
      upAxis: json['upAxis'] as String? ?? '+Y',
      forwardAxis: json['forwardAxis'] as String? ?? '+Z',
      seatForwardFacing: json['seatForwardFacing'] as String? ?? '-Z',
    );
  }
}

/// Room envelope geometry in the draft.
/// Dimensions must preserve uncertainty and never invent values.
class DraftRoomGeometry {
  final Estimate<double> width;
  final Estimate<double> length;
  final Estimate<double> height;

  const DraftRoomGeometry({
    this.width = const Estimate<double>.unknown(),
    this.length = const Estimate<double>.unknown(),
    this.height = const Estimate<double>.unknown(),
  });

  Map<String, dynamic> toJson() => {
        'width': width.toJson(),
        'length': length.toJson(),
        'height': height.toJson(),
      };

  factory DraftRoomGeometry.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const DraftRoomGeometry();
    return DraftRoomGeometry(
      width: json['width'] != null
          ? Estimate<double>.fromJson(
              json['width'] as Map<String, dynamic>,
              (v) => (v as num).toDouble(),
            )
          : const Estimate<double>.unknown(),
      length: json['length'] != null
          ? Estimate<double>.fromJson(
              json['length'] as Map<String, dynamic>,
              (v) => (v as num).toDouble(),
            )
          : const Estimate<double>.unknown(),
      height: json['height'] != null
          ? Estimate<double>.fromJson(
              json['height'] as Map<String, dynamic>,
              (v) => (v as num).toDouble(),
            )
          : const Estimate<double>.unknown(),
    );
  }
}

/// Screen specifications in the draft.
class DraftScreen {
  final Estimate<double> width;
  final Estimate<double> height;
  final Estimate<Position3> position;
  final Estimate<double> rotationY;
  final Estimate<ScreenType> type;

  const DraftScreen({
    this.width = const Estimate<double>.unknown(),
    this.height = const Estimate<double>.unknown(),
    this.position = const Estimate<Position3>.unknown(),
    this.rotationY = const Estimate<double>.unknown(),
    this.type = const Estimate<ScreenType>.unknown(),
  });

  Map<String, dynamic> toJson() => {
        'width': width.toJson(),
        'height': height.toJson(),
        'position': position.toJson((pos) => pos.toJson()),
        'rotationY': rotationY.toJson(),
        'type': type.toJson((t) => t.name),
      };

  factory DraftScreen.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const DraftScreen();
    return DraftScreen(
      width: json['width'] != null
          ? Estimate<double>.fromJson(
              json['width'] as Map<String, dynamic>,
              (v) => (v as num).toDouble(),
            )
          : const Estimate<double>.unknown(),
      height: json['height'] != null
          ? Estimate<double>.fromJson(
              json['height'] as Map<String, dynamic>,
              (v) => (v as num).toDouble(),
            )
          : const Estimate<double>.unknown(),
      position: json['position'] != null
          ? Estimate<Position3>.fromJson(
              json['position'] as Map<String, dynamic>,
              (v) => Position3.fromJson(v as Map<String, dynamic>),
            )
          : const Estimate<Position3>.unknown(),
      rotationY: json['rotationY'] != null
          ? Estimate<double>.fromJson(
              json['rotationY'] as Map<String, dynamic>,
              (v) => (v as num).toDouble(),
            )
          : const Estimate<double>.unknown(),
      type: json['type'] != null
          ? Estimate<ScreenType>.fromJson(
              json['type'] as Map<String, dynamic>,
              (v) => ScreenType.values.firstWhere(
                (t) => t.name == v,
                orElse: () => ScreenType.standard,
              ),
            )
          : const Estimate<ScreenType>.unknown(),
    );
  }
}

/// An individually detected candidate seat placement in the draft.
class DraftSeat {
  final String id;
  final String row;
  final int number;
  final Position3 position;
  final double rotationY;
  final SeatCategory category;
  final double? confidence;
  final List<String> evidenceIds;

  const DraftSeat({
    required this.id,
    required this.row,
    required this.number,
    required this.position,
    this.rotationY = 0,
    this.category = SeatCategory.standard,
    this.confidence,
    this.evidenceIds = const [],
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'row': row,
        'number': number,
        'position': position.toJson(),
        'rotationY': rotationY,
        'category': category.name,
        'confidence': confidence,
        'evidenceIds': evidenceIds,
      };

  factory DraftSeat.fromJson(Map<String, dynamic> json) {
    return DraftSeat(
      id: json['id'] as String,
      row: json['row'] as String,
      number: json['number'] as int,
      position: Position3.fromJson(json['position'] as Map<String, dynamic>),
      rotationY: (json['rotationY'] as num?)?.toDouble() ?? 0,
      category: SeatCategory.values.firstWhere(
        (c) => c.name == json['category'],
        orElse: () => SeatCategory.standard,
      ),
      confidence: (json['confidence'] as num?)?.toDouble(),
      evidenceIds: ((json['evidenceIds'] ?? json['evidence_ids']) as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
    );
  }
}

/// Detected seating lattice and individual seats.
class DraftSeatLattice {
  final Estimate<int> rows;
  final Estimate<int> seatsPerRow;
  final Estimate<double> seatSpacing;
  final Estimate<double> rowSpacing;
  final Estimate<double> rowRisePerRow;
  final List<DraftSeat> seats;

  const DraftSeatLattice({
    this.rows = const Estimate<int>.unknown(),
    this.seatsPerRow = const Estimate<int>.unknown(),
    this.seatSpacing = const Estimate<double>.unknown(),
    this.rowSpacing = const Estimate<double>.unknown(),
    this.rowRisePerRow = const Estimate<double>.unknown(),
    this.seats = const [],
  });

  Map<String, dynamic> toJson() => {
        'rows': rows.toJson(),
        'seatsPerRow': seatsPerRow.toJson(),
        'seatSpacing': seatSpacing.toJson(),
        'rowSpacing': rowSpacing.toJson(),
        'rowRisePerRow': rowRisePerRow.toJson(),
        'seats': seats.map((s) => s.toJson()).toList(),
      };

  factory DraftSeatLattice.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const DraftSeatLattice();
    return DraftSeatLattice(
      rows: json['rows'] != null
          ? Estimate<int>.fromJson(
              json['rows'] as Map<String, dynamic>,
              (v) => (v as num).toInt(),
            )
          : const Estimate<int>.unknown(),
      seatsPerRow: json['seatsPerRow'] != null
          ? Estimate<int>.fromJson(
              json['seatsPerRow'] as Map<String, dynamic>,
              (v) => (v as num).toInt(),
            )
          : const Estimate<int>.unknown(),
      seatSpacing: json['seatSpacing'] != null
          ? Estimate<double>.fromJson(
              json['seatSpacing'] as Map<String, dynamic>,
              (v) => (v as num).toDouble(),
            )
          : const Estimate<double>.unknown(),
      rowSpacing: json['rowSpacing'] != null
          ? Estimate<double>.fromJson(
              json['rowSpacing'] as Map<String, dynamic>,
              (v) => (v as num).toDouble(),
            )
          : const Estimate<double>.unknown(),
      rowRisePerRow: json['rowRisePerRow'] != null
          ? Estimate<double>.fromJson(
              json['rowRisePerRow'] as Map<String, dynamic>,
              (v) => (v as num).toDouble(),
            )
          : const Estimate<double>.unknown(),
      seats: (json['seats'] as List<dynamic>? ?? [])
          .map((e) => DraftSeat.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// Visual-only speaker detected from imagery.
///
/// CRITICAL:
/// AI-detected speakers are VISUAL ONLY.
/// Do NOT infer brand, model, audio channel, Dolby, Atmos, or audio routing.
class DraftVisualSpeaker {
  final String id;
  final String name;
  final Position3 position;
  final double rotationY;
  final SpeakerType visualCabinetType;
  final double? confidence;
  final List<String> evidenceIds;

  const DraftVisualSpeaker({
    required this.id,
    required this.name,
    required this.position,
    this.rotationY = 0,
    this.visualCabinetType = SpeakerType.other,
    this.confidence,
    this.evidenceIds = const [],
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'position': position.toJson(),
        'rotationY': rotationY,
        'visualCabinetType': visualCabinetType.name,
        'confidence': confidence,
        'evidenceIds': evidenceIds,
      };

  factory DraftVisualSpeaker.fromJson(Map<String, dynamic> json) {
    return DraftVisualSpeaker(
      id: json['id'] as String,
      name: json['name'] as String? ?? 'VisualSpeaker',
      position: Position3.fromJson(json['position'] as Map<String, dynamic>),
      rotationY: (json['rotationY'] as num?)?.toDouble() ?? 0,
      visualCabinetType: SpeakerType.values.firstWhere(
        (t) => t.name == (json['visualCabinetType'] ?? json['type']),
        orElse: () => SpeakerType.other,
      ),
      confidence: (json['confidence'] as num?)?.toDouble(),
      evidenceIds: ((json['evidenceIds'] ?? json['evidence_ids']) as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
    );
  }
}

/// Architectural lighting detected in the venue.
class DraftLighting {
  final Estimate<int> ceilingLightsCount;
  final Estimate<int> aisleLightsCount;
  final Estimate<bool> hasAisleLighting;
  final Estimate<double> estimatedLux;

  const DraftLighting({
    this.ceilingLightsCount = const Estimate<int>.unknown(),
    this.aisleLightsCount = const Estimate<int>.unknown(),
    this.hasAisleLighting = const Estimate<bool>.unknown(),
    this.estimatedLux = const Estimate<double>.unknown(),
  });

  Map<String, dynamic> toJson() => {
        'ceilingLightsCount': ceilingLightsCount.toJson(),
        'aisleLightsCount': aisleLightsCount.toJson(),
        'hasAisleLighting': hasAisleLighting.toJson(),
        'estimatedLux': estimatedLux.toJson(),
      };

  factory DraftLighting.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const DraftLighting();
    return DraftLighting(
      ceilingLightsCount: json['ceilingLightsCount'] != null
          ? Estimate<int>.fromJson(
              json['ceilingLightsCount'] as Map<String, dynamic>,
              (v) => (v as num).toInt(),
            )
          : const Estimate<int>.unknown(),
      aisleLightsCount: json['aisleLightsCount'] != null
          ? Estimate<int>.fromJson(
              json['aisleLightsCount'] as Map<String, dynamic>,
              (v) => (v as num).toInt(),
            )
          : const Estimate<int>.unknown(),
      hasAisleLighting: json['hasAisleLighting'] != null
          ? Estimate<bool>.fromJson(
              json['hasAisleLighting'] as Map<String, dynamic>,
              (v) => v as bool,
            )
          : const Estimate<bool>.unknown(),
      estimatedLux: json['estimatedLux'] != null
          ? Estimate<double>.fromJson(
              json['estimatedLux'] as Map<String, dynamic>,
              (v) => (v as num).toDouble(),
            )
          : const Estimate<double>.unknown(),
    );
  }
}

/// Visual material appearance and palette.
class DraftAppearance {
  final Estimate<String> wallColorHex;
  final Estimate<String> carpetColorHex;
  final Estimate<String> wallMaterialType;

  const DraftAppearance({
    this.wallColorHex = const Estimate<String>.unknown(),
    this.carpetColorHex = const Estimate<String>.unknown(),
    this.wallMaterialType = const Estimate<String>.unknown(),
  });

  Map<String, dynamic> toJson() => {
        'wallColorHex': wallColorHex.toJson(),
        'carpetColorHex': carpetColorHex.toJson(),
        'wallMaterialType': wallMaterialType.toJson(),
      };

  factory DraftAppearance.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const DraftAppearance();
    return DraftAppearance(
      wallColorHex: json['wallColorHex'] != null
          ? Estimate<String>.fromJson(
              json['wallColorHex'] as Map<String, dynamic>,
              (v) => v.toString(),
            )
          : const Estimate<String>.unknown(),
      carpetColorHex: json['carpetColorHex'] != null
          ? Estimate<String>.fromJson(
              json['carpetColorHex'] as Map<String, dynamic>,
              (v) => v.toString(),
            )
          : const Estimate<String>.unknown(),
      wallMaterialType: json['wallMaterialType'] != null
          ? Estimate<String>.fromJson(
              json['wallMaterialType'] as Map<String, dynamic>,
              (v) => v.toString(),
            )
          : const Estimate<String>.unknown(),
    );
  }
}

/// An identified functional zone in the auditorium.
class DraftZone {
  final String id;
  final String name;
  final Position3 boundsMin;
  final Position3 boundsMax;

  const DraftZone({
    required this.id,
    required this.name,
    required this.boundsMin,
    required this.boundsMax,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'boundsMin': boundsMin.toJson(),
        'boundsMax': boundsMax.toJson(),
      };

  factory DraftZone.fromJson(Map<String, dynamic> json) {
    return DraftZone(
      id: json['id'] as String,
      name: json['name'] as String,
      boundsMin: Position3.fromJson(json['boundsMin'] as Map<String, dynamic>),
      boundsMax: Position3.fromJson(json['boundsMax'] as Map<String, dynamic>),
    );
  }
}

/// Provenance metadata regarding the reconstruction pipeline.
class DraftPipelineMetadata {
  final String pipelineVersion;
  final String? workerVersion;
  final DateTime? reconstructedAt;
  final String? notes;

  const DraftPipelineMetadata({
    this.pipelineVersion = '1.0.0-phase1',
    this.workerVersion,
    this.reconstructedAt,
    this.notes,
  });

  Map<String, dynamic> toJson() => {
        'pipelineVersion': pipelineVersion,
        'workerVersion': workerVersion,
        'reconstructedAt': reconstructedAt?.toIso8601String(),
        'notes': notes,
      };

  factory DraftPipelineMetadata.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const DraftPipelineMetadata();
    return DraftPipelineMetadata(
      pipelineVersion: json['pipelineVersion'] as String? ?? '1.0.0-phase1',
      workerVersion: json['workerVersion'] as String?,
      reconstructedAt: json['reconstructedAt'] != null
          ? DateTime.tryParse(json['reconstructedAt'] as String)
          : null,
      notes: json['notes'] as String?,
    );
  }
}

/// A complete candidate 3D reconstruction draft produced by an AI reconstruction pass.
///
/// The draft is completely separate from the live [TheatreConfiguration].
/// AI outputs never automatically overwrite or alter a live theatre.
class ReconstructionDraft {
  final String id;
  final String sessionId;
  final String theatreId;
  final DateTime createdAt;
  final DraftCoordinateFrame coordinateFrame;
  final DraftRoomGeometry room;
  final DraftScreen screen;
  final DraftSeatLattice seating;
  final List<DraftVisualSpeaker> speakers;
  final DraftLighting lighting;
  final DraftAppearance appearance;
  final List<DraftZone> zones;
  final DraftPipelineMetadata pipeline;
  final double overallConfidence; // 0.0 to 1.0
  final bool isReviewed;
  final String? reviewedBy;
  final DateTime? reviewedAt;

  const ReconstructionDraft({
    required this.id,
    required this.sessionId,
    required this.theatreId,
    required this.createdAt,
    this.coordinateFrame = const DraftCoordinateFrame(),
    this.room = const DraftRoomGeometry(),
    this.screen = const DraftScreen(),
    this.seating = const DraftSeatLattice(),
    this.speakers = const [],
    this.lighting = const DraftLighting(),
    this.appearance = const DraftAppearance(),
    this.zones = const [],
    this.pipeline = const DraftPipelineMetadata(),
    this.overallConfidence = 0.0,
    this.isReviewed = false,
    this.reviewedBy,
    this.reviewedAt,
  });

  ReconstructionDraft copyWith({
    bool? isReviewed,
    String? reviewedBy,
    DateTime? reviewedAt,
    DraftRoomGeometry? room,
    DraftScreen? screen,
    DraftSeatLattice? seating,
    List<DraftVisualSpeaker>? speakers,
    DraftLighting? lighting,
    DraftAppearance? appearance,
    List<DraftZone>? zones,
  }) {
    return ReconstructionDraft(
      id: id,
      sessionId: sessionId,
      theatreId: theatreId,
      createdAt: createdAt,
      coordinateFrame: coordinateFrame,
      room: room ?? this.room,
      screen: screen ?? this.screen,
      seating: seating ?? this.seating,
      speakers: speakers ?? this.speakers,
      lighting: lighting ?? this.lighting,
      appearance: appearance ?? this.appearance,
      zones: zones ?? this.zones,
      pipeline: pipeline,
      overallConfidence: overallConfidence,
      isReviewed: isReviewed ?? this.isReviewed,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      reviewedAt: reviewedAt ?? this.reviewedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'sessionId': sessionId,
        'theatreId': theatreId,
        'createdAt': createdAt.toIso8601String(),
        'coordinateFrame': coordinateFrame.toJson(),
        'room': room.toJson(),
        'screen': screen.toJson(),
        'seating': seating.toJson(),
        'speakers': speakers.map((s) => s.toJson()).toList(),
        'lighting': lighting.toJson(),
        'appearance': appearance.toJson(),
        'zones': zones.map((z) => z.toJson()).toList(),
        'pipeline': pipeline.toJson(),
        'overallConfidence': overallConfidence,
        'isReviewed': isReviewed,
        'reviewedBy': reviewedBy,
        'reviewedAt': reviewedAt?.toIso8601String(),
      };

  factory ReconstructionDraft.fromJson(Map<String, dynamic> json) {
    return ReconstructionDraft(
      id: json['id'] as String,
      sessionId: (json['sessionId'] ?? json['session_id']) as String,
      theatreId: (json['theatreId'] ?? json['theatre_id']) as String,
      createdAt: DateTime.tryParse(
              (json['createdAt'] ?? json['created_at']) as String? ?? '') ??
          DateTime.now(),
      coordinateFrame: DraftCoordinateFrame.fromJson(
          json['coordinateFrame'] as Map<String, dynamic>?),
      room: DraftRoomGeometry.fromJson(json['room'] as Map<String, dynamic>?),
      screen: DraftScreen.fromJson(json['screen'] as Map<String, dynamic>?),
      seating: DraftSeatLattice.fromJson(json['seating'] as Map<String, dynamic>?),
      speakers: (json['speakers'] as List<dynamic>? ?? [])
          .map((e) => DraftVisualSpeaker.fromJson(e as Map<String, dynamic>))
          .toList(),
      lighting: DraftLighting.fromJson(json['lighting'] as Map<String, dynamic>?),
      appearance: DraftAppearance.fromJson(json['appearance'] as Map<String, dynamic>?),
      zones: (json['zones'] as List<dynamic>? ?? [])
          .map((e) => DraftZone.fromJson(e as Map<String, dynamic>))
          .toList(),
      pipeline: DraftPipelineMetadata.fromJson(
          json['pipeline'] as Map<String, dynamic>?),
      overallConfidence:
          (json['overallConfidence'] as num?)?.toDouble() ?? 0.0,
      isReviewed: json['isReviewed'] as bool? ?? false,
      reviewedBy: json['reviewedBy'] as String?,
      reviewedAt: json['reviewedAt'] != null
          ? DateTime.tryParse(json['reviewedAt'] as String)
          : null,
    );
  }
}
