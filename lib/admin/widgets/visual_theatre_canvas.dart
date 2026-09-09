import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../models/room_config.dart';
import '../models/screen_config.dart';
import '../models/seat_config.dart';
import '../models/speaker_model.dart';

/// PART 8: the visual theatre editor. A top-down 2D layout — not a live
/// Unity render — showing the room, screen, seats, and speakers to scale,
/// with tap-to-select on everything and drag-to-move on the screen and
/// speakers (seats are auto-laid-out by [SeatLayoutGenerator] rather than
/// freely dragged, keeping rows straight; an admin adjusts a seat's exact
/// position via the object inspector instead if it ever needs to differ
/// from the generated grid).
///
/// World coordinates are metres, X = left/right, Z = front(screen)/back —
/// the same convention the existing Unity project already uses, so this
/// reads the same numbers Unity would.
class VisualTheatreCanvas extends StatelessWidget {
  final RoomConfig room;
  final ScreenConfig screen;
  final List<SeatConfig> seats;
  final List<SpeakerModel> speakers;
  final String? selectedId;

  final ValueChanged<SeatConfig> onSelectSeat;
  final ValueChanged<SpeakerModel> onSelectSpeaker;
  final VoidCallback onSelectScreen;
  final void Function(SpeakerModel speaker, Offset worldDelta) onMoveSpeaker;
  final void Function(Offset worldDelta) onMoveScreen;

  const VisualTheatreCanvas({
    super.key,
    required this.room,
    required this.screen,
    required this.seats,
    required this.speakers,
    required this.selectedId,
    required this.onSelectSeat,
    required this.onSelectSpeaker,
    required this.onSelectScreen,
    required this.onMoveSpeaker,
    required this.onMoveScreen,
  });

  static const double _padding = 24;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableW = constraints.maxWidth - (_padding * 2);
        final availableH = constraints.maxHeight - (_padding * 2);
        final scaleX = availableW / room.width;
        final scaleY = availableH / room.length;
        final double scale = (scaleX < scaleY ? scaleX : scaleY).clamp(1.0, 200.0).toDouble();

        final canvasW = room.width * scale;
        final canvasH = room.length * scale;

        // World (x, z) in metres -> canvas-local pixel offset.
        Offset toCanvas(double x, double z) {
          return Offset((canvasW / 2) + (x * scale), z * scale);
        }

        return InteractiveViewer(
          minScale: 0.5,
          maxScale: 4,
          boundaryMargin: const EdgeInsets.all(80),
          child: Center(
            child: Container(
              width: canvasW,
              height: canvasH,
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border.all(color: AppColors.surfaceElevated, width: 2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  ..._buildSeats(toCanvas, scale),
                  _buildScreen(toCanvas, scale),
                  ..._buildSpeakers(toCanvas, scale),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildSeats(Offset Function(double, double) toCanvas, double scale) {
    const seatSize = 10.0;
    return seats.map((seat) {
      final center = toCanvas(seat.position.x, seat.position.z);
      final isSelected = seat.id == selectedId;
      return Positioned(
        left: center.dx - (seatSize / 2),
        top: center.dy - (seatSize / 2),
        child: GestureDetector(
          onTap: () => onSelectSeat(seat),
          child: Container(
            width: seatSize,
            height: seatSize,
            decoration: BoxDecoration(
              color: _colorForCategory(seat.category),
              borderRadius: BorderRadius.circular(2),
              border: isSelected ? Border.all(color: AppColors.accent, width: 2) : null,
            ),
          ),
        ),
      );
    }).toList();
  }

  Widget _buildScreen(Offset Function(double, double) toCanvas, double scale) {
    final center = toCanvas(screen.position.x, screen.position.z);
    final w = screen.width * scale;
    final isSelected = selectedId == '__screen__';
    return Positioned(
      left: center.dx - (w / 2),
      top: center.dy - 6,
      child: GestureDetector(
        onTap: onSelectScreen,
        onPanUpdate: (details) => onMoveScreen(details.delta / scale),
        child: Container(
          width: w,
          height: 12,
          decoration: BoxDecoration(
            color: AppColors.electricBlue,
            borderRadius: BorderRadius.circular(4),
            border: isSelected ? Border.all(color: AppColors.accent, width: 2) : null,
          ),
          child: const Center(
            child: Text('SCREEN', style: TextStyle(fontSize: 8, color: Colors.black)),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildSpeakers(Offset Function(double, double) toCanvas, double scale) {
    const speakerSize = 22.0;
    return speakers.map((speaker) {
      final center = toCanvas(speaker.position.x, speaker.position.z);
      final isSelected = speaker.id == selectedId;
      return Positioned(
        left: center.dx - (speakerSize / 2),
        top: center.dy - (speakerSize / 2),
        child: GestureDetector(
          onTap: () => onSelectSpeaker(speaker),
          onPanUpdate: (details) => onMoveSpeaker(speaker, details.delta / scale),
          child: Container(
            width: speakerSize,
            height: speakerSize,
            decoration: BoxDecoration(
              color: speaker.enabled ? AppColors.surfaceElevated :  AppColors.surfaceElevated.withValues(alpha: 0.4),
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? AppColors.accent : AppColors.textMuted,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Icon(
              Icons.volume_up,
              size: 14,
              color: speaker.enabled ? AppColors.textPrimary : AppColors.textMuted,
            ),
          ),
        ),
      );
    }).toList();
  }

  Color _colorForCategory(SeatCategory category) {
    switch (category) {
      case SeatCategory.premium:
        return AppColors.seatPremium;
      case SeatCategory.recliner:
        return AppColors.seatRecliner;
      case SeatCategory.standard:
        return AppColors.seatAvailable;
    }
  }
}
