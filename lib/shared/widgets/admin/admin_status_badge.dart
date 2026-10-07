import 'package:flutter/material.dart';

/// Dark cinematic status badge for LiveScreen admin dashboards.
/// Perfectly matches the Recent Activity and Shows status pills in media_1790658802815.png.
class AdminStatusBadge extends StatelessWidget {
  final String status;
  final bool showDot;

  const AdminStatusBadge({
    super.key,
    required this.status,
    this.showDot = false,
  });

  @override
  Widget build(BuildContext context) {
    final normalized = status.toLowerCase().replaceAll(' ', '_');

    Color bg;
    Color text;
    Color border;
    String displayLabel;

    switch (normalized) {
      case 'confirmed':
      case 'verified':
      case 'approved':
      case 'online':
      case 'on_time':
        bg = const Color(0xFF07271D);
        text = const Color(0xFF34D399);
        border = const Color(0xFF059669);
        displayLabel = _formatLabel(status);
        break;

      case 'under_review':
        bg = const Color(0xFF2A0D15);
        text = const Color(0xFFFCA5A5);
        border = const Color(0xFF8F1025);
        displayLabel = _formatLabel(status);
        break;

      case 'updated':
      case 'scheduled':
        bg = const Color(0xFF16161F);
        text = const Color(0xFFD4AF37);
        border = const Color(0xFF383848);
        displayLabel = _formatLabel(status);
        break;

      case 'pending':
      case 'filling_fast':
        bg = const Color(0xFF291804);
        text = const Color(0xFFFBBF24);
        border = const Color(0xFFD97706);
        displayLabel = _formatLabel(status);
        break;

      case 'published':
        bg = const Color(0xFF261D09);
        text = const Color(0xFFE5B869);
        border = const Color(0xFFD4AF37);
        displayLabel = 'Published';
        break;

      case 'cancelled':
      case 'rejected':
      case 'suspended':
      case 'sold_out':
        bg = const Color(0xFF29080A);
        text = const Color(0xFFF87171);
        border = const Color(0xFFDC2626);
        displayLabel = _formatLabel(status);
        break;

      case 'draft':
      default:
        bg = const Color(0xFF16161A);
        text = const Color(0xFF9CA3AF);
        border = const Color(0xFF2E2E38);
        displayLabel = _formatLabel(status);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: border, width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showDot) ...[
            Container(
              width: 5.5,
              height: 5.5,
              decoration: BoxDecoration(
                color: text,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
          ],
          Text(
            displayLabel,
            style: TextStyle(
              color: text,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  String _formatLabel(String raw) {
    if (raw.isEmpty) return '—';
    final parts = raw.split(RegExp(r'[_\s]+'));
    return parts.map((w) {
      if (w.isEmpty) return '';
      return w[0].toUpperCase() + w.substring(1).toLowerCase();
    }).join(' ');
  }
}
