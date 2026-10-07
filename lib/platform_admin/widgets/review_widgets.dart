import 'package:flutter/material.dart';

/// A small pill showing a verification/approval status string, colored
/// consistently across every Platform Admin screen in LiveScreen dark cinematic theme.
class StatusPill extends StatelessWidget {
  final String status;

  const StatusPill({super.key, required this.status});

  Color get _textColor {
    switch (status.toLowerCase()) {
      case 'verified':
      case 'approved':
      case 'published':
        return const Color(0xFF10B981);
      case 'rejected':
      case 'suspended':
        return const Color(0xFFEF4444);
      case 'under_review':
      case 'submitted':
      case 'pending':
        return const Color(0xFFFCA5A5);
      case 'draft':
      default:
        return const Color(0xFF9CA3AF);
    }
  }

  Color get _bgColor {
    switch (status.toLowerCase()) {
      case 'verified':
      case 'approved':
      case 'published':
        return const Color(0x2210B981);
      case 'rejected':
      case 'suspended':
        return const Color(0x2A6B1422);
      case 'under_review':
      case 'submitted':
      case 'pending':
        return const Color(0x2E5A0F1B);
      case 'draft':
      default:
        return const Color(0xFF16161A);
    }
  }

  Color get _borderColor {
    switch (status.toLowerCase()) {
      case 'verified':
      case 'approved':
      case 'published':
        return const Color(0x5510B981);
      case 'rejected':
      case 'suspended':
        return const Color(0x666B1422);
      case 'under_review':
      case 'submitted':
      case 'pending':
        return const Color(0x668F1025);
      case 'draft':
      default:
        return const Color(0xFF2E2E38);
    }
  }

  String get _label {
    switch (status.toLowerCase()) {
      case 'under_review':
        return 'Under Review';
      default:
        return status.isEmpty ? 'Unknown' : status[0].toUpperCase() + status.substring(1);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: _bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderColor, width: 0.9),
      ),
      child: Text(
        _label,
        style: TextStyle(color: _textColor, fontSize: 11.5, fontWeight: FontWeight.w600),
      ),
    );
  }
}

/// One action offered in [showReviewActionSheet] — e.g. Approve / Reject /
/// Suspend / Request Changes.
class ReviewAction {
  final String newStatus;
  final String label;
  final IconData icon;
  final Color color;

  /// Whether choosing this action requires the reviewer to type a reason
  /// (rejection, suspension, request-changes always should).
  final bool requiresReason;

  const ReviewAction({
    required this.newStatus,
    required this.label,
    required this.icon,
    required this.color,
    this.requiresReason = false,
  });
}

/// Shows a dark bottom sheet with [actions]; returns the chosen action's
/// newStatus plus an optional reason, or null if the reviewer dismissed it.
Future<({String newStatus, String? reason})?> showReviewActionSheet({
  required BuildContext context,
  required String title,
  required List<ReviewAction> actions,
}) {
  return showModalBottomSheet<({String newStatus, String? reason})>(
    context: context,
    backgroundColor: const Color(0xFF0D0D12),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      side: BorderSide(color: Color(0x33D4AF37)),
    ),
    builder: (context) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFFF3EEE5),
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              for (final action in actions)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        backgroundColor: const Color(0xFF101016),
                        foregroundColor: action.color,
                        side: BorderSide(color: action.color.withValues(alpha: 0.6)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () async {
                        if (action.requiresReason) {
                          final reason = await _promptReason(context, action.label);
                          if (reason == null) return; // cancelled
                          if (!context.mounted) return;
                          Navigator.of(context).pop((newStatus: action.newStatus, reason: reason));
                        } else {
                          Navigator.of(context).pop((newStatus: action.newStatus, reason: null));
                        }
                      },
                      icon: Icon(action.icon, size: 18),
                      label: Text(action.label, style: const TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel', style: TextStyle(color: Color(0xFF9CA3AF))),
              ),
            ],
          ),
        ),
      );
    },
  );
}

Future<String?> _promptReason(BuildContext context, String actionLabel) {
  final controller = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (context) {
      return AlertDialog(
        backgroundColor: const Color(0xFF0D0D12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0x33D4AF37)),
        ),
        title: Text(
          '$actionLabel — reason',
          style: const TextStyle(color: Color(0xFFF3EEE5), fontSize: 16, fontWeight: FontWeight.w700),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 3,
          style: const TextStyle(color: Color(0xFFF3EEE5), fontSize: 13.5),
          decoration: const InputDecoration(
            filled: true,
            fillColor: Color(0xFF050507),
            border: OutlineInputBorder(
              borderSide: BorderSide(color: Color(0xFF262630)),
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Color(0xFF262630)),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Color(0xFFD4AF37)),
            ),
            hintText: 'Explain what needs to change or why this was rejected…',
            hintStyle: TextStyle(color: Color(0xFF71717A), fontSize: 12.5),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF9CA3AF))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8F1025),
              foregroundColor: const Color(0xFFF3EEE5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              final text = controller.text.trim();
              if (text.isEmpty) return;
              Navigator.of(context).pop(text);
            },
            child: const Text('Continue', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      );
    },
  );
}
