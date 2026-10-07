import 'package:flutter/material.dart';
import '../models/room_config.dart';
import '../models/screen_config.dart';
import '../models/seat_config.dart';
import '../models/speaker_model.dart';

/// Top-down 2D Theatre Layout Canvas for Theatre Studio.
/// Visualizes the room, screen, seats, and speakers in the dark cinema aesthetic.
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
                color: const Color(0xFF0F0F12),
                border: Border.all(color: const Color(0x66D4AF37), width: 1.5),
                borderRadius: BorderRadius.circular(6),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.6),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
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
              border: isSelected ? Border.all(color: const Color(0xFFD4AF37), width: 2) : null,
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
            color: const Color(0xFFD4AF37),
            borderRadius: BorderRadius.circular(4),
            border: isSelected ? Border.all(color: Colors.white, width: 2) : null,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFD4AF37).withValues(alpha: 0.3),
                blurRadius: 8,
              ),
            ],
          ),
          child: const Center(
            child: Text(
              'SCREEN',
              style: TextStyle(fontSize: 8, fontWeight: FontWeight.w800, color: Colors.black, letterSpacing: 1),
            ),
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
              color: speaker.enabled ? const Color(0xFF1C180E) : const Color(0xFF141418),
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? const Color(0xFFD4AF37) : const Color(0xFF6B7280),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Icon(
              Icons.volume_up,
              size: 13,
              color: speaker.enabled ? const Color(0xFFD4AF37) : const Color(0xFF6B7280),
            ),
          ),
        ),
      );
    }).toList();
  }

  Color _colorForCategory(SeatCategory category) {
    switch (category) {
      case SeatCategory.premium:
        return const Color(0xFFD4AF37); // Gold for Premium
      case SeatCategory.recliner:
        return const Color(0xFF9E102F); // Burgundy for Recliner
      case SeatCategory.standard:
        return const Color(0xFF6B7280); // Neutral grey for Standard
    }
  }
}
