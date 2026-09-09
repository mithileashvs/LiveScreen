import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
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
      padding: const EdgeInsets.all(20),
      children: [
        const Text('Room Dimensions', style: AppTextStyles.subheading),
        const SizedBox(height: 4),
        const Text(
          'Physical dimensions of the auditorium, in metres.',
          style: AppTextStyles.caption,
        ),
        const SizedBox(height: 16),
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
        if (errors.isNotEmpty) ...[
          const SizedBox(height: 8),
          for (final error in errors)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(error, style: const TextStyle(color: AppColors.error, fontSize: 12)),
            ),
        ],
      ],
    );
  }
}
