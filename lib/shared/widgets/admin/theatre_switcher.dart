import 'package:flutter/material.dart';
import '../../../admin/models/theatre_configuration.dart';

/// Compact dark theatre switcher for LiveScreen Theatre Admin.
/// Styled with dark surface, gold border, and gold icons.
class TheatreSwitcher extends StatelessWidget {
  final List<TheatreConfiguration> theatres;
  final String? selectedId;
  final ValueChanged<TheatreConfiguration> onChanged;

  const TheatreSwitcher({
    super.key,
    required this.theatres,
    required this.selectedId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (theatres.length <= 1) return const SizedBox.shrink();

    final selected = theatres.firstWhere(
      (t) => t.id == selectedId,
      orElse: () => theatres.first,
    );

    return PopupMenuButton<TheatreConfiguration>(
      color: const Color(0xFF14141A),
      elevation: 4,
      onSelected: onChanged,
      itemBuilder: (context) => [
        for (final t in theatres)
          PopupMenuItem(
            value: t,
            child: Row(
              children: [
                const Icon(Icons.theaters_outlined, size: 16, color: Color(0xFFD4AF37)),
                const SizedBox(width: 8),
                Text(
                  t.basicInfo.name.isEmpty ? '(Untitled theatre)' : t.basicInfo.name,
                  style: const TextStyle(color: Color(0xFFF7F5F0), fontSize: 13),
                ),
              ],
            ),
          ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF111116),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0x66D4AF37), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.theaters_outlined, size: 16, color: Color(0xFFD4AF37)),
            const SizedBox(width: 8),
            Text(
              'Venue: ${selected.basicInfo.name.isEmpty ? '(Untitled)' : selected.basicInfo.name}',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFFF7F5F0),
                fontSize: 12.5,
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: Color(0xFFD4AF37)),
          ],
        ),
      ),
    );
  }
}
