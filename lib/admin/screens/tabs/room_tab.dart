import 'package:flutter/material.dart';
import '../../models/theatre_configuration.dart';
import '../../widgets/admin_number_field.dart';

class RoomTab extends StatelessWidget {
  final TheatreConfiguration config;
  final VoidCallback onChanged;

  const RoomTab({super.key, required this.config, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final room = config.room;
    final errors = room.validate();

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text(
          'Room Dimensions',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFFFFFFFF)),
        ),
        const SizedBox(height: 4),
        const Text(
          'Physical dimensions of the auditorium in metres.',
          style: TextStyle(fontSize: 12.5, color: Color(0xFF9CA3AF)),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF0F0F12),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF1E1E26)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AdminNumberField(
                label: 'Width (m)',
                value: room.width,
                onChanged: (v) {
                  room.width = v;
                  onChanged();
                },
              ),
              AdminNumberField(
                label: 'Length (m)',
                value: room.length,
                onChanged: (v) {
                  room.length = v;
                  onChanged();
                },
              ),
              AdminNumberField(
                label: 'Height (m)',
                value: room.height,
                onChanged: (v) {
                  room.height = v;
                  onChanged();
                },
              ),
            ],
          ),
        ),
        if (errors.isNotEmpty) ...[
          const SizedBox(height: 12),
          for (final error in errors)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(error, style: const TextStyle(color: Color(0xFFEF4444), fontSize: 12)),
            ),
        ],
      ],
    );
  }
}
