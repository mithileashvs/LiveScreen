import 'package:flutter/material.dart';

class AdminNavItemData {
  final String key;
  final String label;
  final IconData icon;

  const AdminNavItemData({
    required this.key,
    required this.label,
    required this.icon,
  });
}

/// Unified Cinema-Themed Sidebar for LiveScreen Admin (Theatre Admin & Producer Admin).
/// Perfectly reproduces the master reference media_1791012659776.png:
/// - Near-black background (#080808 / #0B0B0B) with subtle deep burgundy atmospheric gradient
/// - "Live" (warm white #F3EEE5) + "Screen" (metallic gold #C9A227) logo + "EXPERIENCE BEFORE YOU BOOK"
/// - Deep burgundy capsule/rounded rectangle active state (#5A0F1B to #6B1422) with white icon and bold text
/// - Inactive items with metallic gold line icons (#C9A227 / #D4AF37) and warm off-white text (#F3EEE5)
/// - Subtle burgundy tint on hover
/// - Secondary navigation: Profile, Settings, Help & Support
/// - Bottom branding: "REAL VENUES. REAL SEATS. REAL EXPERIENCES." in 3 lines of metallic gold
class AdminSidebar extends StatelessWidget {
  final String activeKey;
  final List<AdminNavItemData> mainNavItems;
  final ValueChanged<String> onSelectKey;
  final VoidCallback? onProfile;
  final VoidCallback? onSettings;
  final VoidCallback? onHelpSupport;
  final VoidCallback? onTry3DVenue;
  final String? activeSecondaryKey;
  final bool scrollable;

  const AdminSidebar({
    super.key,
    required this.activeKey,
    required this.mainNavItems,
    required this.onSelectKey,
    this.onProfile,
    this.onSettings,
    this.onHelpSupport,
    this.onTry3DVenue,
    this.activeSecondaryKey,
    this.scrollable = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      height: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFF080808),
        gradient: LinearGradient(
          begin: Alignment(-1.0, -0.2),
          end: Alignment(1.4, 0.95),
          colors: [
            Color(0xFF080808),
            Color(0xFF080808),
            Color(0x285A0F1B), // subtle deep burgundy atmospheric glow
            Color(0x406B1422), // rich deep burgundy beam across lower/inner part
            Color(0x205A0F1B), // soft atmospheric fade
            Color(0xFF080808),
          ],
          stops: [0.0, 0.32, 0.48, 0.68, 0.85, 1.0],
        ),
        border: Border(
          right: BorderSide(color: Color(0xFF16161C), width: 1),
        ),
      ),
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final maxHeight = constraints.hasBoundedHeight ? constraints.maxHeight : 1000.0;
            final isDense = mainNavItems.length > 6 || maxHeight < 820;
            final isUltraDense = mainNavItems.length > 6 && maxHeight < 680;
            final paddingV = isUltraDense ? 10.0 : (isDense ? 14.0 : 20.0);
            final logoGap = isUltraDense ? 10.0 : (isDense ? 14.0 : 22.0);
            final dividerV = isUltraDense ? 6.0 : (isDense ? 8.0 : 12.0);

            final content = Padding(
              padding: EdgeInsets.symmetric(horizontal: 14, vertical: paddingV),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // LiveScreen Brand Logo
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: 'Live',
                                style: TextStyle(
                                  fontSize: isUltraDense ? 20 : (isDense ? 22 : 24),
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFFF3EEE5),
                                  letterSpacing: 0.2,
                                ),
                              ),
                              TextSpan(
                                text: 'Screen',
                                style: TextStyle(
                                  fontSize: isUltraDense ? 20 : (isDense ? 22 : 24),
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFFC9A227),
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'EXPERIENCE BEFORE YOU BOOK',
                          style: TextStyle(
                            fontSize: isUltraDense ? 7.5 : 8.5,
                            color: const Color(0xFFC9A227),
                            letterSpacing: 1.1,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: logoGap),

                  // Primary Navigation Items
                  for (final item in mainNavItems)
                    _SidebarPillTile(
                      icon: item.icon,
                      label: item.label,
                      selected: activeKey == item.key,
                      onTap: () => onSelectKey(item.key),
                      dense: isDense,
                      ultraDense: isUltraDense,
                    ),

                  // 1. Large Responsive Flexible Gap between Main Nav and Lower Nav
                  if (constraints.hasBoundedHeight)
                    const Spacer(flex: 3)
                  else
                    const SizedBox(height: 36),

                  // Reference Accent: Small horizontal yellow/gold line (media_1791065808374.png)
                  Padding(
                    padding: EdgeInsets.only(
                      left: 12,
                      top: dividerV,
                      bottom: dividerV + 2,
                    ),
                    child: Container(
                      key: const Key('admin_sidebar_gold_separator'),
                      width: 36,
                      height: 2,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD4AF37),
                        borderRadius: BorderRadius.circular(1),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFD4AF37).withValues(alpha: 0.35),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 2. Lower Navigation Group (Profile, Settings, Help & Support)
                  _SidebarPillTile(
                    icon: Icons.person_outline_rounded,
                    label: 'Profile',
                    selected: activeSecondaryKey == 'profile' || activeKey == 'profile',
                    onTap: () => onProfile != null ? onProfile!() : onSelectKey('profile'),
                    dense: isDense,
                    ultraDense: isUltraDense,
                  ),
                  _SidebarPillTile(
                    icon: Icons.settings_outlined,
                    label: 'Settings',
                    selected: activeSecondaryKey == 'settings' || activeKey == 'settings',
                    onTap: () => onSettings != null ? onSettings!() : onSelectKey('settings'),
                    dense: isDense,
                    ultraDense: isUltraDense,
                  ),
                  _SidebarPillTile(
                    icon: Icons.help_outline_rounded,
                    label: 'Help & Support',
                    selected: activeSecondaryKey == 'help' || activeKey == 'help',
                    onTap: () => onHelpSupport != null ? onHelpSupport!() : onSelectKey('help'),
                    dense: isDense,
                    ultraDense: isUltraDense,
                  ),

                  // 3. Second Responsive Flexible Gap between Lower Nav and Tagline
                  if (constraints.hasBoundedHeight)
                    const Spacer(flex: 1)
                  else
                    const SizedBox(height: 16),

                  // Optional 3D Venue CTA Card if provided
                  if (onTry3DVenue != null) ...[
                    GestureDetector(
                      onTap: onTry3DVenue,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF101014),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0x33D4AF37)),
                        ),
                        child: Row(
                          children: const [
                            Icon(Icons.view_in_ar_rounded, size: 18, color: Color(0xFFC9A227)),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Launch 3D Venue',
                                style: TextStyle(
                                  color: Color(0xFFF3EEE5),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            Icon(Icons.arrow_forward_rounded, size: 13, color: Color(0xFFC9A227)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],

                  // Master Reference Bottom Branding
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'REAL VENUES.',
                          style: TextStyle(
                            color: const Color(0xFFC9A227),
                            fontSize: isUltraDense ? 8.0 : 9.0,
                            letterSpacing: 1.3,
                            fontWeight: FontWeight.w700,
                            height: 1.3,
                          ),
                        ),
                        Text(
                          'REAL SEATS.',
                          style: TextStyle(
                            color: const Color(0xFFC9A227),
                            fontSize: isUltraDense ? 8.0 : 9.0,
                            letterSpacing: 1.3,
                            fontWeight: FontWeight.w700,
                            height: 1.3,
                          ),
                        ),
                        Text(
                          'REAL EXPERIENCES.',
                          style: TextStyle(
                            color: const Color(0xFFC9A227),
                            fontSize: isUltraDense ? 8.0 : 9.0,
                            letterSpacing: 1.3,
                            fontWeight: FontWeight.w700,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: isUltraDense ? 2 : 4),
                ],
              ),
            );

            if (scrollable) {
              return SingleChildScrollView(child: content);
            }
            return content;
          },
        ),
      ),
    );
  }
}

class _SidebarPillTile extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool dense;
  final bool ultraDense;

  const _SidebarPillTile({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.dense = false,
    this.ultraDense = false,
  });

  @override
  State<_SidebarPillTile> createState() => _SidebarPillTileState();
}

class _SidebarPillTileState extends State<_SidebarPillTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final verticalPadding = widget.ultraDense
        ? 5.0
        : (widget.dense ? 6.5 : 9.0);
    final bottomMargin = widget.ultraDense
        ? 2.0
        : (widget.dense ? 3.0 : 5.0);
    final iconSize = widget.ultraDense
        ? 16.0
        : (widget.dense ? 17.5 : 19.0);
    final fontSize = widget.ultraDense
        ? 12.0
        : (widget.dense ? 12.5 : 13.5);

    return Padding(
      padding: EdgeInsets.only(bottom: bottomMargin),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(9),
            gradient: widget.selected
                ? const LinearGradient(
                    colors: [Color(0xFF5A0F1B), Color(0xFF6B1422)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  )
                : null,
            color: widget.selected
                ? null
                : (_hovered ? const Color(0x2B5A0F1B) : Colors.transparent),
            border: widget.selected
                ? Border.all(color: const Color(0x33D4AF37), width: 0.8)
                : (_hovered
                    ? Border.all(color: const Color(0x336B1422), width: 0.8)
                    : null),
            boxShadow: widget.selected
                ? [
                    BoxShadow(
                      color: const Color(0xFF5A0F1B).withValues(alpha: 0.45),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(9),
              onTap: widget.onTap,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: verticalPadding),
                child: Row(
                  children: [
                    Icon(
                      widget.icon,
                      size: iconSize,
                      color: widget.selected
                          ? Colors.white
                          : const Color(0xFFC9A227),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: fontSize,
                          fontWeight: widget.selected ? FontWeight.w700 : FontWeight.w500,
                          color: widget.selected
                              ? Colors.white
                              : const Color(0xFFF3EEE5),
                          letterSpacing: 0.1,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
