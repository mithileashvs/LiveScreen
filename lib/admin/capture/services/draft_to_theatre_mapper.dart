import '../models/reconstruction_draft.dart';
import '../../models/theatre_configuration.dart';
import '../../models/room_config.dart';
import '../../models/screen_config.dart';
import '../../models/seat_config.dart';
import '../../models/speaker_model.dart';

/// Thrown when attempting to apply an unreviewed or unconfirmed draft.
class UnreviewedDraftException implements Exception {
  final String message;
  const UnreviewedDraftException(
      [this.message = 'Draft has not been reviewed or confirmed by a theatre admin.']);

  @override
  String toString() => 'UnreviewedDraftException: $message';
}

/// Options controlling how a [ReconstructionDraft] maps onto a live [TheatreConfiguration].
class DraftMappingOptions {
  /// Whether to require [ReconstructionDraft.isReviewed] to be true before mapping.
  final bool requireReviewed;

  /// Whether to map room dimensions if known.
  final bool mapRoom;

  /// Whether to map screen configuration if known.
  final bool mapScreen;

  /// Whether to map seating if known seats exist in draft.
  final bool mapSeating;

  /// Whether to map visual-only speakers if detected.
  final bool mapSpeakers;

  const DraftMappingOptions({
    this.requireReviewed = true,
    this.mapRoom = true,
    this.mapScreen = true,
    this.mapSeating = true,
    this.mapSpeakers = true,
  });
}

/// Safely maps a verified [ReconstructionDraft] into a live [TheatreConfiguration].
///
/// Enforcement Rules:
/// 1. Only reviewed/confirmed drafts may become live configuration (unless explicitly bypassed by options).
/// 2. UNKNOWN values remain unchanged in the existing configuration — NEVER invent measurements.
/// 3. Preserves existing configuration where draft estimates are absent or unknown.
/// 4. NEVER modifies theatre identity ([TheatreConfiguration.id]).
/// 5. NEVER modifies ownership ([TheatreConfiguration.ownerId]).
/// 6. NEVER modifies verification status or reason ([TheatreConfiguration.verificationStatus], [reviewReason]).
/// 7. NEVER modifies publication/status fields ([TheatreConfiguration.status]).
/// 8. NEVER modifies movie content ([TheatreConfiguration.content]) or show/booking state.
/// 9. Preserves acoustics ([TheatreConfiguration.acoustics]) — visual speakers do NOT alter audio routing.
/// 10. AI-detected speakers are VISUAL ONLY (no inferred audio channels, Dolby, Atmos, or routing).
class DraftToTheatreMapper {
  /// Applies [draft] to [original] returning an updated [TheatreConfiguration].
  /// The returned configuration is an independent clone preserving all protected identity fields.
  static TheatreConfiguration applyDraftToConfiguration(
    TheatreConfiguration original,
    ReconstructionDraft draft, {
    DraftMappingOptions options = const DraftMappingOptions(),
  }) {
    if (options.requireReviewed && !draft.isReviewed) {
      throw const UnreviewedDraftException(
        'Cannot map draft into live TheatreConfiguration: draft is unreviewed. '
        'A theatre admin must inspect and approve the reconstruction draft first.',
      );
    }

    // 1. Preserve Theatre Identity and Basic Info
    final result = TheatreConfiguration(
      id: original.id, // Strictly protected
      schemaVersion: original.schemaVersion,
      basicInfo: TheatreBasicInfo(
        name: original.basicInfo.name,
        hallName: original.basicInfo.hallName,
        description: original.basicInfo.description,
        address: original.basicInfo.address,
        city: original.basicInfo.city,
        state: original.basicInfo.state,
        country: original.basicInfo.country,
        contactNumber: original.basicInfo.contactNumber,
      ),
      // Identity, status, and verification fields are strictly preserved
      status: original.status,
      verificationStatus: original.verificationStatus,
      reviewReason: original.reviewReason,
      ownerId: original.ownerId,
      // Content (movies) is strictly preserved
      content: original.content,
      // Acoustics configuration is strictly preserved
      acoustics: original.acoustics,
      // Seating is preserved by default from original
      seats: original.seats
          .map((s) => SeatConfig(
                row: s.row,
                number: s.number,
                position: Position3(
                  x: s.position.x,
                  y: s.position.y,
                  z: s.position.z,
                ),
                rotationY: s.rotationY,
                category: s.category,
              ))
          .toList(),
      // Last seat layout parameters are preserved or updated below
      lastSeatLayout: original.lastSeatLayout,
    );

    // 2. Map Room Dimensions (only known estimates overwrite original)
    if (options.mapRoom) {
      final updatedRoom = RoomConfig(
        width: draft.room.width.isKnown
            ? draft.room.width.value!
            : original.room.width,
        length: draft.room.length.isKnown
            ? draft.room.length.value!
            : original.room.length,
        height: draft.room.height.isKnown
            ? draft.room.height.value!
            : original.room.height,
      );
      result.room = updatedRoom;
    } else {
      result.room = RoomConfig(
        width: original.room.width,
        length: original.room.length,
        height: original.room.height,
      );
    }

    // 3. Map Screen Configuration
    if (options.mapScreen) {
      final updatedScreen = ScreenConfig(
        width: draft.screen.width.isKnown
            ? draft.screen.width.value!
            : original.screen.width,
        height: draft.screen.height.isKnown
            ? draft.screen.height.value!
            : original.screen.height,
        position: draft.screen.position.isKnown
            ? draft.screen.position.value!
            : Position3(
                x: original.screen.position.x,
                y: original.screen.position.y,
                z: original.screen.position.z,
              ),
        rotationY: draft.screen.rotationY.isKnown
            ? draft.screen.rotationY.value!
            : original.screen.rotationY,
        type: draft.screen.type.isKnown
            ? draft.screen.type.value!
            : original.screen.type,
      );
      result.screen = updatedScreen;
    } else {
      result.screen = ScreenConfig(
        width: original.screen.width,
        height: original.screen.height,
        position: Position3(
          x: original.screen.position.x,
          y: original.screen.position.y,
          z: original.screen.position.z,
        ),
        rotationY: original.screen.rotationY,
        type: original.screen.type,
      );
    }

    // 4. Map Seating
    if (options.mapSeating && draft.seating.seats.isNotEmpty) {
      result.seats = draft.seating.seats
          .map((ds) => SeatConfig(
                row: ds.row,
                number: ds.number,
                position: Position3(
                  x: ds.position.x,
                  y: ds.position.y,
                  z: ds.position.z,
                ),
                rotationY: ds.rotationY,
                category: ds.category,
              ))
          .toList();

      // If generator lattice params were estimated, update lastSeatLayout
      if (draft.seating.rows.isKnown && draft.seating.seatsPerRow.isKnown) {
        final origLayout = original.lastSeatLayout;
        result.lastSeatLayout = SeatLayoutParams(
          rows: draft.seating.rows.value!,
          seatsPerRow: draft.seating.seatsPerRow.value!,
          seatSpacing: draft.seating.seatSpacing.isKnown
              ? draft.seating.seatSpacing.value!
              : (origLayout?.seatSpacing ?? 0.6),
          rowSpacing: draft.seating.rowSpacing.isKnown
              ? draft.seating.rowSpacing.value!
              : (origLayout?.rowSpacing ?? 1.1),
          rowElevation: draft.seating.rowRisePerRow.isKnown
              ? draft.seating.rowRisePerRow.value!
              : (origLayout?.rowElevation ?? 0.12),
          seatWidth: origLayout?.seatWidth ?? 0.5,
          seatDepth: origLayout?.seatDepth ?? 0.6,
          seatHeight: origLayout?.seatHeight ?? 0.9,
          startPosition: origLayout?.startPosition != null
              ? Position3(
                  x: origLayout!.startPosition.x,
                  y: origLayout.startPosition.y,
                  z: origLayout.startPosition.z,
                )
              : null,
        );
      }
    } else {
      // Preserve existing seats
      result.seats = original.seats
          .map((s) => SeatConfig(
                row: s.row,
                number: s.number,
                position: Position3(
                  x: s.position.x,
                  y: s.position.y,
                  z: s.position.z,
                ),
                rotationY: s.rotationY,
                category: s.category,
              ))
          .toList();
    }

    // 5. Map Speakers (VISUAL ONLY)
    if (options.mapSpeakers && draft.speakers.isNotEmpty) {
      result.speakers = draft.speakers.map((ds) {
        // Find existing speaker to preserve configured channel/specs if present
        final existingMatch = original.speakers
            .where((s) => s.id == ds.id || s.name == ds.name)
            .firstOrNull;

        return SpeakerModel(
          id: ds.id,
          name: ds.name,
          type: ds.visualCabinetType,
          // CRITICAL: Audio channel is NEVER inferred by AI. Preserve existing or default.
          channel: existingMatch?.channel ?? SpeakerChannel.left,
          position: Position3(
            x: ds.position.x,
            y: ds.position.y,
            z: ds.position.z,
          ),
          rotationY: ds.rotationY,
          enabled: true,
          // Specifications remain empty unless previously configured manually
          specs: existingMatch?.specs ?? SpeakerSpecs(),
        );
      }).toList();
    } else {
      // Preserve existing speakers
      result.speakers = original.speakers
          .map((s) => SpeakerModel(
                id: s.id,
                name: s.name,
                type: s.type,
                channel: s.channel,
                position: Position3(
                  x: s.position.x,
                  y: s.position.y,
                  z: s.position.z,
                ),
                rotationY: s.rotationY,
                enabled: s.enabled,
                specs: s.specs,
              ))
          .toList();
    }

    return result;
  }
}
