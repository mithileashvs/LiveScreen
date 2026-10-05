import 'package:flutter/material.dart';
import '../../../auth/services/auth_service.dart';
import '../../../auth/screens/login_screen.dart';
import '../../../admin/models/theatre_configuration.dart';
import '../../../admin/services/selected_theatre.dart';

/// Master Theatre Admin Top Bar strictly matching media_1790658802815.png:
/// - "THEATRE ADMIN" small tracked brand tag at top
/// - Active Theatre Selector pill with gold building icon, venue name & city, gold chevron
/// - Dark search bar with gold/muted icons and clean placeholder
/// - Location selector pill with gold pin
/// - Notification bell with red alert dot
/// - Admin profile chip with avatar, "Theatre Admin", venue subtitle, and chevron
class AdminTopBar extends StatelessWidget {
  final String searchPlaceholder;
  final ValueChanged<String>? onSearchChanged;
  final VoidCallback? onNotificationTap;
  final VoidCallback? onProfileTap;
  final VoidCallback? onSettingsTap;
  final bool showDrawerButton;
  final String selectedLocation;
  final List<String> locations;
  final ValueChanged<String>? onLocationChanged;
  final String? activeTheatreName;
  final String? activeTheatreCity;
  final List<TheatreConfiguration>? theatres;
  final ValueChanged<TheatreConfiguration>? onTheatreChanged;
  final String tagTitle;
  final Color? tagTitleColor;
  final String profileRole;
  final String? profileSubtitle;
  final bool showTheatreSelector;

  const AdminTopBar({
    super.key,
    required this.searchPlaceholder,
    this.onSearchChanged,
    this.onNotificationTap,
    this.onProfileTap,
    this.onSettingsTap,
    this.showDrawerButton = false,
    this.selectedLocation = 'Chennai',
    this.locations = const ['Chennai', 'Bengaluru', 'Mumbai', 'Delhi', 'Hyderabad'],
    this.onLocationChanged,
    this.activeTheatreName,
    this.activeTheatreCity,
    this.theatres,
    this.onTheatreChanged,
    this.tagTitle = 'THEATRE ADMIN',
    this.tagTitleColor,
    this.profileRole = 'Theatre Admin',
    this.profileSubtitle,
    this.showTheatreSelector = true,
  });

  Future<void> _logout(BuildContext context) async {
    try {
      await authService.logout();
    } catch (_) {}
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    String initial = 'A';
    try {
      final session = authService.currentSession;
      initial = (session?.userId ?? 'A').substring(0, 1).toUpperCase();
    } catch (_) {
      initial = 'A';
    }

    final theatreDisplay = activeTheatreName != null && activeTheatreName!.isNotEmpty
        ? (activeTheatreCity != null && activeTheatreCity!.isNotEmpty
            ? '$activeTheatreName, $activeTheatreCity'
            : activeTheatreName!)
        : 'Select Theatre';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0xFF070709),
        border: Border(
          bottom: BorderSide(color: Color(0xFF191920), width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Row 1: THEATRE ADMIN Small Tracked Header
          Row(
            children: [
              if (showDrawerButton) ...[
                IconButton(
                  icon: const Icon(Icons.menu_rounded, color: Color(0xFFD4AF37)),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
                const SizedBox(width: 12),
              ],
              Text(
                tagTitle,
                style: TextStyle(
                  color: tagTitleColor ?? const Color(0xFFD4AF37),
                  fontWeight: FontWeight.w800,
                  fontSize: 10.5,
                  letterSpacing: 1.5,
                ),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 10),

          // Row 2: Active Theatre Pill, Search Bar, Location, Bell, Profile Chip
          Row(
            children: [
              // Active Theatre Selector Pill (if enabled)
              if (showTheatreSelector) ...[
                _buildTheatreSelectorPill(context, theatreDisplay),
                const SizedBox(width: 14),
              ],

              // Search Bar
              Expanded(
                child: Container(
                  height: 40,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF111116),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF22222A)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.search_rounded,
                        color: Color(0xFF71717A),
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          onChanged: onSearchChanged,
                          style: const TextStyle(
                            color: Color(0xFFF7F5F0),
                            fontSize: 13,
                          ),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            isDense: true,
                            hintText: searchPlaceholder,
                            hintStyle: const TextStyle(
                              color: Color(0xFF71717A),
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 14),

              // Location Selector Pill
              PopupMenuButton<String>(
                color: const Color(0xFF14141A),
                elevation: 4,
                onSelected: onLocationChanged,
                itemBuilder: (context) => [
                  for (final loc in locations)
                    PopupMenuItem(
                      value: loc,
                      child: Text(
                        loc,
                        style: const TextStyle(
                          color: Color(0xFFF7F5F0),
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                    ),
                ],
                child: Container(
                  height: 40,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF111116),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF22222A)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 16,
                        color: Color(0xFFD4AF37),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        selectedLocation,
                        style: const TextStyle(
                          color: Color(0xFFF7F5F0),
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 16,
                        color: Color(0xFF71717A),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // Notification Bell with Red Badge Dot
              InkWell(
                onTap: onNotificationTap,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF111116),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF22222A)),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      const Icon(
                        Icons.notifications_outlined,
                        color: Color(0xFFEDEAE2),
                        size: 19,
                      ),
                      Positioned(
                        top: 9,
                        right: 9,
                        child: Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                            color: Color(0xFFEF4444),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 14),

              // Profile Chip matching media_1790658802815.png
              PopupMenuButton<String>(
                color: const Color(0xFF14141A),
                elevation: 4,
                onSelected: (value) {
                  if (value == 'profile') {
                    if (onProfileTap != null) onProfileTap!();
                  } else if (value == 'settings') {
                    if (onSettingsTap != null) onSettingsTap!();
                  } else if (value == 'logout') {
                    _logout(context);
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: 'profile',
                    child: Row(
                      children: [
                        Icon(Icons.person_outline, size: 18, color: Color(0xFFD4AF37)),
                        SizedBox(width: 10),
                        Text('Profile', style: TextStyle(color: Color(0xFFF7F5F0))),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'settings',
                    child: Row(
                      children: [
                        Icon(Icons.settings_outlined, size: 18, color: Color(0xFFD4AF37)),
                        SizedBox(width: 10),
                        Text('Settings', style: TextStyle(color: Color(0xFFF7F5F0))),
                      ],
                    ),
                  ),
                  PopupMenuDivider(height: 1),
                  PopupMenuItem(
                    value: 'logout',
                    child: Row(
                      children: [
                        Icon(Icons.logout_rounded, size: 18, color: Color(0xFFEF4444)),
                        SizedBox(width: 10),
                        Text('Sign Out', style: TextStyle(color: Color(0xFFEF4444))),
                      ],
                    ),
                  ),
                ],
                child: Container(
                  height: 40,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF111116),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF22222A)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: const Color(0xFFD4AF37),
                        child: Text(
                          initial,
                          style: const TextStyle(
                            color: Color(0xFF070709),
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            profileRole,
                            style: const TextStyle(
                              color: Color(0xFFFFFFFF),
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            profileSubtitle ?? (activeTheatreName ?? 'LiveScreen Venue'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF9CA3AF),
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 16,
                        color: Color(0xFF71717A),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTheatreSelectorPill(BuildContext context, String theatreDisplay) {
    final hasMultiple = theatres != null && theatres!.length > 1;

    final pillContent = Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF111116),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0x66D4AF37), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.theaters_outlined,
            size: 16,
            color: Color(0xFFD4AF37),
          ),
          const SizedBox(width: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 180),
            child: Text(
              theatreDisplay,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFFF7F5F0),
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 6),
          const Icon(
            Icons.keyboard_arrow_down_rounded,
            size: 16,
            color: Color(0xFFD4AF37),
          ),
        ],
      ),
    );

    if (!hasMultiple) return pillContent;

    return PopupMenuButton<TheatreConfiguration>(
      color: const Color(0xFF14141A),
      elevation: 4,
      onSelected: (selected) {
        selectedTheatreContext.select(selected.id);
        if (onTheatreChanged != null) onTheatreChanged!(selected);
      },
      itemBuilder: (context) => [
        for (final t in theatres!)
          PopupMenuItem(
            value: t,
            child: Row(
              children: [
                const Icon(Icons.theaters_outlined, size: 16, color: Color(0xFFD4AF37)),
                const SizedBox(width: 8),
                Text(
                  t.basicInfo.name.isEmpty ? '(Untitled Theatre)' : t.basicInfo.name,
                  style: const TextStyle(color: Color(0xFFF7F5F0), fontSize: 13),
                ),
              ],
            ),
          ),
      ],
      child: pillContent,
    );
  }
}
