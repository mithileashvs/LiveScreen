import 'package:flutter/material.dart';
import '../../models/screen_config.dart';
import '../../models/speaker_model.dart';
import '../../models/theatre_configuration.dart';
import '../../widgets/visual_theatre_canvas.dart';

/// Simplified visual-only speaker placement tab for Admin Studio.
///
/// Principle:
/// "Position speakers to visually match your theatre. This does not configure the theatre's sound system."
///
/// Admins can:
/// 1. Click "Add Speaker" to place a visual speaker on the auditorium wall.
/// 2. Drag-and-drop the speaker to position it in the room (clamped to room bounds).
/// 3. Select and delete speakers.
///
/// Technical audio fields (brand, model, channels, Atmos, power, specs, and raw XYZ fields)
/// are excluded from the UI.
class SpeakersTab extends StatefulWidget {
  final TheatreConfiguration config;
  final VoidCallback onChanged;

  const SpeakersTab({super.key, required this.config, required this.onChanged});

  @override
  State<SpeakersTab> createState() => _SpeakersTabState();
}

class _SpeakersTabState extends State<SpeakersTab> {
  SpeakerModel? _selected;

  void _addSpeaker() {
    final config = widget.config;
    final count = config.speakers.length;
    final id = 'speaker_${DateTime.now().millisecondsSinceEpoch}_${count + 1}';

    // Sensible wall placement: alternate left wall and right wall
    final halfWidth = config.room.width / 2;
    final bool isLeft = count % 2 == 0;
    final double wallOffset = halfWidth - 0.35;
    final double posX = isLeft ? -wallOffset : wallOffset;

    // Distribute along depth of the room (avoiding front screen zone)
    final double startZ = (config.screen.position.z + 2.0).clamp(2.0, config.room.length - 2.0);
    final double availableDepth = (config.room.length - startZ - 1.0).clamp(1.0, config.room.length);
    final double depthFraction = ((count ~/ 2) * 0.25).clamp(0.0, 1.0);
    final double posZ = (startZ + (availableDepth * depthFraction)).clamp(0.5, config.room.length - 0.5);

    // Natural wall-mounted height (approx 60% of room height or 2.5m)
    final double posY = (config.room.height * 0.6).clamp(2.2, 3.5);

    final speaker = SpeakerModel(
      id: id,
      name: 'Speaker ${count + 1}',
      position: Position3(x: posX, y: posY, z: posZ),
    );

    config.speakers.add(speaker);
    setState(() => _selected = speaker);
    widget.onChanged();
  }

  void _deleteSelected() {
    if (_selected == null) return;
    widget.config.speakers.removeWhere((s) => s.id == _selected!.id);
    setState(() => _selected = null);
    widget.onChanged();
  }

  void _onMoveSpeaker(SpeakerModel speaker, Offset delta) {
    final room = widget.config.room;
    final screen = widget.config.screen;

    final minX = -room.width / 2 + 0.35;
    final maxX = room.width / 2 - 0.35;
    final minZ = 0.5;
    final maxZ = room.length - 0.5;

    double nextX = (speaker.position.x + delta.dx).clamp(minX, maxX);
    double nextZ = (speaker.position.z + delta.dy).clamp(minZ, maxZ);

    final screenHalfW = screen.width / 2 + 0.3;
    final screenFrontZ = screen.position.z + 0.5;
    if (nextZ < screenFrontZ && nextX.abs() < screenHalfW) {
      if (nextX.abs() < screenHalfW * 0.7) {
        nextZ = screenFrontZ;
      } else {
        nextX = nextX >= 0 ? screenHalfW : -screenHalfW;
      }
    }

    speaker.position.x = nextX;
    speaker.position.z = nextZ;
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final config = widget.config;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header & Helper banner
        Container(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
          color: const Color(0xFF0F0F12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Auditorium Speakers',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFFFFFFF),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${config.speakers.length} speakers placed · Visual layout only',
                          style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _addSpeaker,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add Speaker', style: TextStyle(fontWeight: FontWeight.w700)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD4AF37),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1710),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0x66D4AF37)),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.info_outline, size: 16, color: Color(0xFFD4AF37)),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Position speakers to visually match your theatre. This does not configure the theatre\'s sound system.',
                        style: TextStyle(color: Color(0xFFEDEAE2), fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Visual layout canvas (Top-down representation)
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: VisualTheatreCanvas(
              room: config.room,
              screen: config.screen,
              seats: config.seats,
              speakers: config.speakers,
              selectedId: _selected?.id,
              onSelectSeat: (_) {},
              onSelectSpeaker: (speaker) => setState(() => _selected = speaker),
              onSelectScreen: () {},
              onMoveSpeaker: _onMoveSpeaker,
              onMoveScreen: (_) {},
            ),
          ),
        ),

        // Selected speaker actions / instructions panel
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: const BoxDecoration(
            color: Color(0xFF0F0F12),
            border: Border(top: BorderSide(color: Color(0xFF1E1E26))),
          ),
          child: _selected != null
              ? Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1C180E),
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFD4AF37)),
                      ),
                      child: const Icon(Icons.volume_up, size: 18, color: Color(0xFFD4AF37)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _selected!.name.isNotEmpty ? _selected!.name : 'Selected Speaker',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFFFFFFFF)),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Drag to reposition anywhere in the auditorium.',
                            style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
                          ),
                        ],
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _deleteSelected,
                      icon: const Icon(Icons.delete_outline, size: 18, color: Color(0xFFEF4444)),
                      label: const Text('Delete Speaker', style: TextStyle(color: Color(0xFFEF4444))),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      tooltip: 'Deselect',
                      onPressed: () => setState(() => _selected = null),
                      icon: const Icon(Icons.close, size: 18, color: Color(0xFF9CA3AF)),
                    ),
                  ],
                )
              : const Center(
                  child: Text(
                    'Tap "+ Add Speaker" to place a speaker, or tap an existing speaker to select and drag it. Placement is visual only.',
                    style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ),
        ),
      ],
    );
  }
}
