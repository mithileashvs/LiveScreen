import 'room_config.dart';
import 'screen_config.dart';
import 'seat_config.dart';
import 'speaker_model.dart';
import 'acoustics_config.dart';
import 'movie_content.dart';

/// The current schema version for [TheatreConfiguration].
///
/// PART 14 (versioning): bump this whenever the JSON shape changes in a way
/// that isn't backward compatible, and branch in [TheatreConfiguration.fromJson]
/// based on the stored value. Configurations saved with an older
/// schemaVersion should still be loadable — never redefine what an existing
/// version number means.
const int kTheatreConfigSchemaVersion = 1;

/// Draft / Published / Archived — see PART 12.
enum TheatreStatus { draft, published, archived }

extension TheatreStatusLabel on TheatreStatus {
  String get label {
    switch (this) {
      case TheatreStatus.draft:
        return 'Draft';
      case TheatreStatus.published:
        return 'Published';
      case TheatreStatus.archived:
        return 'Archived';
    }
  }
}

/// Name / hall number / description — the basic identity of a theatre,
/// separate from its physical/technical configuration (PART 2).
class TheatreBasicInfo {
  String name;
  String hallName;
  String description;

  TheatreBasicInfo({
    this.name = '',
    this.hallName = '',
    this.description = '',
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'hallName': hallName,
        'description': description,
      };

  factory TheatreBasicInfo.fromJson(Map<String, dynamic> json) {
    return TheatreBasicInfo(
      name: json['name'] as String? ?? '',
      hallName: json['hallName'] as String? ?? '',
      description: json['description'] as String? ?? '',
    );
  }
}

/// The single top-level structure described in PART 13. Everything an admin
/// configures for one theatre lives here, and this is what eventually gets
/// handed to Unity (see TheatreUnityBridge) and to a real backend later.
///
/// Deliberately JSON-plain: no BuildContext, no UI state, nothing that only
/// makes sense inside Flutter widgets — this needs to survive being sent
/// to/from storage and, eventually, Unity untouched.
class TheatreConfiguration {
  final int schemaVersion;
  final String id;
  TheatreBasicInfo basicInfo;
  RoomConfig room;
  ScreenConfig screen;
  List<SeatConfig> seats;
  List<SpeakerModel> speakers;
  AcousticsConfig acoustics;
  MovieContent? content;
  TheatreStatus status;

  /// The seat-grid parameters last used to generate [seats] (PART 4).
  /// Kept so re-opening a theatre in the editor shows the values that
  /// actually produced the current seats, instead of resetting the
  /// Seating tab's form back to defaults every time.
  SeatLayoutParams? lastSeatLayout;

  TheatreConfiguration({
    required this.id,
    this.schemaVersion = kTheatreConfigSchemaVersion,
    TheatreBasicInfo? basicInfo,
    RoomConfig? room,
    ScreenConfig? screen,
    List<SeatConfig>? seats,
    List<SpeakerModel>? speakers,
    AcousticsConfig? acoustics,
    this.content,
    this.status = TheatreStatus.draft,
    this.lastSeatLayout,
  })  : basicInfo = basicInfo ?? TheatreBasicInfo(),
        room = room ?? RoomConfig(),
        screen = screen ?? ScreenConfig(),
        seats = seats ?? [],
        speakers = speakers ?? [],
        acoustics = acoustics ?? AcousticsConfig();

  Map<String, dynamic> toJson() => {
        'schemaVersion': schemaVersion,
        'id': id,
        'basicInfo': basicInfo.toJson(),
        'room': room.toJson(),
        'screen': screen.toJson(),
        'seats': seats.map((s) => s.toJson()).toList(),
        'speakers': speakers.map((s) => s.toJson()).toList(),
        'acoustics': acoustics.toJson(),
        'content': content?.toJson(),
        'status': status.name,
        'lastSeatLayout': lastSeatLayout?.toJson(),
      };

  factory TheatreConfiguration.fromJson(Map<String, dynamic> json) {
    // PART 14: every version branch reads what IT understands and leaves
    // sensible defaults for anything newer fields would have added.
    final version = json['schemaVersion'] as int? ?? 1;
    switch (version) {
      case 1:
      default:
        return TheatreConfiguration(
          id: json['id'] as String,
          schemaVersion: version,
          basicInfo: TheatreBasicInfo.fromJson(
              json['basicInfo'] as Map<String, dynamic>? ?? {}),
          room: RoomConfig.fromJson(json['room'] as Map<String, dynamic>? ?? {}),
          screen:
              ScreenConfig.fromJson(json['screen'] as Map<String, dynamic>? ?? {}),
          seats: (json['seats'] as List<dynamic>? ?? [])
              .map((e) => SeatConfig.fromJson(e as Map<String, dynamic>))
              .toList(),
          speakers: (json['speakers'] as List<dynamic>? ?? [])
              .map((e) => SpeakerModel.fromJson(e as Map<String, dynamic>))
              .toList(),
          acoustics: AcousticsConfig.fromJson(
              json['acoustics'] as Map<String, dynamic>? ?? {}),
          content: json['content'] == null
              ? null
              : MovieContent.fromJson(json['content'] as Map<String, dynamic>),
          status: TheatreStatus.values.firstWhere(
            (s) => s.name == json['status'],
            orElse: () => TheatreStatus.draft,
          ),
          lastSeatLayout: json['lastSeatLayout'] == null
              ? null
              : SeatLayoutParams.fromJson(json['lastSeatLayout'] as Map<String, dynamic>),
        );
    }
  }

  TheatreConfiguration copyWith({TheatreStatus? status}) {
    return TheatreConfiguration.fromJson(toJson())..status = status ?? this.status;
  }
}
