import 'package:flutter/material.dart';
import '../../models/estimate.dart';

/// Renders a color-coded confidence badge indicating statistical certainty.
class ConfidenceBadge extends StatelessWidget {
  final double? confidence;
  final bool isKnown;

  const ConfidenceBadge({
    super.key,
    required this.confidence,
    this.isKnown = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!isKnown || confidence == null || confidence == 0.0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: const Color(0xFF450A0A),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.4)),
        ),
        child: const Text(
          'Low / Unknown',
          style: TextStyle(
            color: Color(0xFFFCA5A5),
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    final conf = confidence!;
    final Color bg;
    final Color fg;
    final Color border;
    final String label;

    if (conf >= 0.80) {
      bg = const Color(0xFF064E3B);
      fg = const Color(0xFF6EE7B7);
      border = const Color(0xFF10B981).withValues(alpha: 0.4);
      label = 'High (${(conf * 100).toInt()}%)';
    } else if (conf >= 0.50) {
      bg = const Color(0xFF451A03);
      fg = const Color(0xFFFCD34D);
      border = const Color(0xFFF59E0B).withValues(alpha: 0.4);
      label = 'Medium (${(conf * 100).toInt()}%)';
    } else {
      bg = const Color(0xFF450A0A);
      fg = const Color(0xFFFCA5A5);
      border = const Color(0xFFEF4444).withValues(alpha: 0.4);
      label = 'Low (${(conf * 100).toInt()}%)';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: border),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Renders an estimate provenance badge indicating the method of derivation.
class ProvenanceBadge extends StatelessWidget {
  final EstimateProvenance provenance;

  const ProvenanceBadge({
    super.key,
    required this.provenance,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    IconData icon;

    switch (provenance) {
      case EstimateProvenance.measured:
        bg = const Color(0xFF064E3B);
        fg = const Color(0xFF6EE7B7);
        icon = Icons.straighten_rounded;
        break;
      case EstimateProvenance.adminMeasured:
        bg = const Color(0xFF1E3A5F);
        fg = const Color(0xFF93C5FD);
        icon = Icons.handyman_rounded;
        break;
      case EstimateProvenance.aiEstimated:
        bg = const Color(0xFF261E3B);
        fg = const Color(0xFFD8B4FE);
        icon = Icons.auto_awesome_rounded;
        break;
      case EstimateProvenance.inferred:
        bg = const Color(0xFF1F2937);
        fg = const Color(0xFFE5E7EB);
        icon = Icons.calculate_outlined;
        break;
      case EstimateProvenance.unknown:
        bg = const Color(0xFF450A0A);
        fg = const Color(0xFFFCA5A5);
        icon = Icons.help_outline_rounded;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: fg),
          const SizedBox(width: 4),
          Text(
            provenance.label,
            style: TextStyle(
              color: fg,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
