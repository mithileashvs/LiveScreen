import 'package:flutter/material.dart';

/// Clean dark section header for LiveScreen admin dashboards matching media_1790658802815.png.
/// Displays a crisp white title, muted grey subtitle, and an optional metallic gold right-aligned action.
class AdminSectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Widget? trailing;

  const AdminSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFFFFFFF),
                  letterSpacing: -0.2,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 3),
                Text(
                  subtitle!,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF9CA3AF),
                  ),
                ),
              ],
            ],
          ),
        ),
        if (trailing != null)
          trailing!
        else if (actionLabel != null && onAction != null)
          InkWell(
            onTap: onAction,
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    actionLabel!,
                    style: const TextStyle(
                      color: Color(0xFFD4AF37),
                      fontWeight: FontWeight.w700,
                      fontSize: 12.5,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    size: 13,
                    color: Color(0xFFD4AF37),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
