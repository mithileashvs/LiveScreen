import 'package:flutter/material.dart';

/// Dark cinematic Stat Card matching master references media_1790658802815.png & media_1791012665351.png:
/// - Dark/black surface (#09090C)
/// - Thin metallic-gold border for standard cards / subtle deep-burgundy border for review & rejected states
/// - Top row: Small squircle icon (gold or burgundy accent) + Trend chip / Subtitle
/// - Bottom: Bold white count value + clean muted warm-grey label
class AdminStatCard extends StatefulWidget {
  final IconData icon;
  final Color iconColor;
  final Color? iconBgColor;
  final Color? iconBorderColor;
  final String value;
  final String label;
  final String? subtitle;
  final String? trendText;
  final String? trendSubtitle;
  final String? trendArrow;
  final Color? trendColor;
  final bool? isTrendPositive;
  final Color? borderColor;
  final Color? borderHoverColor;
  final Color? backgroundColor;
  final VoidCallback? onTap;

  const AdminStatCard({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    this.iconColor = const Color(0xFFC9A227),
    this.iconBgColor,
    this.iconBorderColor,
    this.subtitle,
    this.trendText,
    this.trendSubtitle,
    this.trendArrow,
    this.trendColor,
    this.isTrendPositive,
    this.borderColor,
    this.borderHoverColor,
    this.backgroundColor,
    this.onTap,
  });

  @override
  State<AdminStatCard> createState() => _AdminStatCardState();
}

class _AdminStatCardState extends State<AdminStatCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.iconBgColor ?? widget.iconColor.withValues(alpha: 0.12);
    final isPos = widget.isTrendPositive ?? true;
    final defaultTrendColor = isPos ? const Color(0xFF10B981) : const Color(0xFFEF4444);
    final actualTrendColor = widget.trendColor ?? defaultTrendColor;

    final baseBorder = widget.borderColor ?? const Color(0xFF1E1E26);
    final activeBorderColor = _hovered
        ? (widget.borderHoverColor ?? const Color(0x66D4AF37))
        : baseBorder;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        decoration: BoxDecoration(
          color: widget.backgroundColor ?? const Color(0xFF09090C),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: activeBorderColor,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Top Row: Icon squircle + Trend Chip / Subtitle
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: bgColor,
                          borderRadius: BorderRadius.circular(9),
                          border: Border.all(
                            color: widget.iconBorderColor ?? widget.iconColor.withValues(alpha: 0.3),
                            width: 0.8,
                          ),
                        ),
                        child: Icon(
                          widget.icon,
                          color: widget.iconColor,
                          size: 19,
                        ),
                      ),
                      if (widget.trendText != null)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (widget.trendArrow != null)
                                  Text(
                                    widget.trendArrow!,
                                    style: TextStyle(
                                      color: actualTrendColor,
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  )
                                else if (widget.isTrendPositive != null)
                                  Text(
                                    isPos ? '↑ ' : '↓ ',
                                    style: TextStyle(
                                      color: actualTrendColor,
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                Text(
                                  widget.trendText!,
                                  style: TextStyle(
                                    color: actualTrendColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                            if (widget.trendSubtitle != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                widget.trendSubtitle!,
                                style: const TextStyle(
                                  color: Color(0xFF71717A),
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ],
                        )
                      else if (widget.subtitle != null)
                        Text(
                          widget.subtitle!,
                          style: const TextStyle(
                            color: Color(0xFF9CA3AF),
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Bottom Section: Bold count + Label
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.value,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFFFFFFFF),
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF9CA3AF),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
