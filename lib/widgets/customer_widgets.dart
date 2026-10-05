import 'package:flutter/material.dart';
import '../theme/customer_theme.dart';

/// Top bar for the LiveScreen Customer Experience.
///
/// Features:
/// - Location selector pill with warm gold pin
/// - Search input pill
/// - Notification indicator with badge
/// - User profile chip with greeting and popup menu
class CustomerTopBar extends StatelessWidget {
  final String selectedLocation;
  final List<String> locations;
  final ValueChanged<String> onLocationChanged;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onProfileMenuSelected;
  final bool showMenuButton;
  final VoidCallback? onMenuPressed;
  final String userName;

  const CustomerTopBar({
    super.key,
    required this.selectedLocation,
    required this.locations,
    required this.onLocationChanged,
    required this.onSearchChanged,
    required this.onProfileMenuSelected,
    this.showMenuButton = false,
    this.onMenuPressed,
    this.userName = 'Alex',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: const BoxDecoration(
        color: CustomerColors.background,
        border: Border(
          bottom: BorderSide(color: CustomerColors.borderSubtle, width: 1),
        ),
      ),
      child: Row(
        children: [
          if (showMenuButton) ...[
            IconButton(
              icon: const Icon(Icons.menu_rounded, color: CustomerColors.textPrimary),
              onPressed: onMenuPressed,
            ),
            const SizedBox(width: 8),
          ],

          // Location Selector
          PopupMenuButton<String>(
            color: CustomerColors.surfaceElevated,
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: CustomerColors.borderSubtle),
            ),
            onSelected: onLocationChanged,
            itemBuilder: (context) => [
              for (final loc in locations)
                PopupMenuItem(
                  value: loc,
                  child: Text(
                    loc,
                    style: const TextStyle(
                      fontSize: 13.5,
                      color: CustomerColors.textPrimary,
                    ),
                  ),
                ),
            ],
            child: Container(
              height: 42,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: CustomerColors.surface,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: CustomerColors.borderGold, width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.location_on_rounded,
                    size: 16,
                    color: CustomerColors.gold,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    selectedLocation,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: CustomerColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: CustomerColors.textSecondary,
                    size: 17,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 16),

          // Search Field
          Expanded(
            child: Container(
              height: 42,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: CustomerColors.surface,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: CustomerColors.borderGoldSubtle),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.search_rounded,
                    color: CustomerColors.gold,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      onChanged: onSearchChanged,
                      style: const TextStyle(
                        fontSize: 13,
                        color: CustomerColors.textPrimary,
                        fontWeight: FontWeight.w400,
                      ),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        isDense: true,
                        hintText: 'Search for movies, events, sports or venues...',
                        hintStyle: TextStyle(
                          fontSize: 13,
                          color: CustomerColors.textMuted,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 16),

          // Notifications
          Stack(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: CustomerColors.surface,
                  shape: BoxShape.circle,
                  border: Border.all(color: CustomerColors.borderGoldSubtle),
                ),
                child: const Icon(
                  Icons.notifications_none_rounded,
                  color: CustomerColors.textPrimary,
                  size: 20,
                ),
              ),
              Positioned(
                top: 7,
                right: 7,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: CustomerColors.burgundy,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(width: 14),

          // Profile chip
          PopupMenuButton<String>(
            color: CustomerColors.surfaceElevated,
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: CustomerColors.borderSubtle),
            ),
            onSelected: onProfileMenuSelected,
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'profile',
                child: Text('Profile', style: TextStyle(color: CustomerColors.textPrimary)),
              ),
              PopupMenuItem(
                value: 'logout',
                child: Text('Log Out', style: TextStyle(color: CustomerColors.error)),
              ),
            ],
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: CustomerColors.gold,
                  child: Text(
                    userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                    style: const TextStyle(
                      color: CustomerColors.background,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Hi, $userName',
                  style: const TextStyle(
                    color: CustomerColors.textPrimary,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 3),
                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: CustomerColors.textSecondary,
                  size: 17,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Sidebar for LiveScreen Customer Experience.
///
/// Features:
/// - Brand logo ("LiveScreen" with gold accent)
/// - Subtitle "EXPERIENCE BEFORE YOU BOOK"
/// - Category items: Home, Movies, Events, Sports, Concerts
/// - Secondary items: My Bookings, Watchlist, Offers, Profile, Settings
/// - Active item uses a solid burgundy rounded pill (Reference 1 & 2)
/// - Bottom tagline "REAL VENUES. REAL SEATS. REAL EXPERIENCES."
class CustomerSidebar extends StatelessWidget {
  final String selectedNav;
  final ValueChanged<String> onSelectNav;

  const CustomerSidebar({
    super.key,
    required this.selectedNav,
    required this.onSelectNav,
  });

  static const List<Map<String, dynamic>> _primaryNav = [
    {'id': 'Home', 'label': 'Home', 'icon': Icons.home_rounded},
    {'id': 'Movies', 'label': 'Movies', 'icon': Icons.movie_filter_outlined},
    {'id': 'Events', 'label': 'Events', 'icon': Icons.confirmation_number_outlined},
    {'id': 'Sports', 'label': 'Sports', 'icon': Icons.sports_cricket_outlined},
    {'id': 'Concerts', 'label': 'Concerts', 'icon': Icons.music_note_outlined},
    {'id': 'My Bookings', 'label': 'My Bookings', 'icon': Icons.receipt_long_outlined},
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 224,
      height: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF070709),
        border: const Border(
          right: BorderSide(color: CustomerColors.borderSubtle, width: 1),
        ),
        gradient: RadialGradient(
          center: const Alignment(1.3, 0.7),
          radius: 1.4,
          colors: [
            CustomerColors.burgundyDark.withValues(alpha: 0.40),
            CustomerColors.burgundy.withValues(alpha: 0.12),
            const Color(0xFF070709),
          ],
          stops: const [0.0, 0.45, 1.0],
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. LiveScreen Brand Logo
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: const TextSpan(
                    children: [
                      TextSpan(
                        text: 'Live',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: CustomerColors.textPrimary,
                          letterSpacing: 0.2,
                        ),
                      ),
                      TextSpan(
                        text: 'Screen',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: CustomerColors.gold,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'EXPERIENCE BEFORE YOU BOOK',
                  style: TextStyle(
                    fontSize: 8.5,
                    color: CustomerColors.goldLight,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // 2. Scrollable / Main Navigation Area
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final item in _primaryNav)
                    _SidebarNavTile(
                      label: item['label'] as String,
                      icon: item['icon'] as IconData,
                      isSelected: selectedNav == item['id'],
                      onTap: () => onSelectNav(item['id'] as String),
                    ),
                ],
              ),
            ),
          ),

          // 3. Bottom Navigation Area (Separator + Profile + Settings + Bottom Branding)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Separator
              Padding(
                padding: const EdgeInsets.only(left: 14, top: 10, bottom: 12),
                child: Container(
                  key: const Key('customer_sidebar_gold_separator'),
                  width: 36,
                  height: 2,
                  decoration: BoxDecoration(
                    color: CustomerColors.gold,
                    borderRadius: BorderRadius.circular(1),
                    boxShadow: [
                      BoxShadow(
                        color: CustomerColors.gold.withValues(alpha: 0.35),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              ),

              // Profile (Active when selectedNav == 'Profile')
              _SidebarNavTile(
                label: 'Profile',
                icon: Icons.person_outline_rounded,
                isSelected: selectedNav == 'Profile',
                onTap: () => onSelectNav('Profile'),
              ),

              // Settings
              _SidebarNavTile(
                label: 'Settings',
                icon: Icons.settings_outlined,
                isSelected: selectedNav == 'Settings',
                onTap: () => onSelectNav('Settings'),
              ),

              // Help & Support
              _SidebarNavTile(
                label: 'Help & Support',
                icon: Icons.help_outline_rounded,
                isSelected: selectedNav == 'Help & Support',
                onTap: () => onSelectNav('Help & Support'),
              ),

              const SizedBox(height: 14),

              // Bottom Branding (REAL VENUES. REAL SEATS. REAL EXPERIENCES.)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'REAL VENUES.',
                      style: TextStyle(
                        fontSize: 9.5,
                        color: CustomerColors.gold,
                        letterSpacing: 1.4,
                        fontWeight: FontWeight.w700,
                        height: 1.5,
                      ),
                    ),
                    Text(
                      'REAL SEATS.',
                      style: TextStyle(
                        fontSize: 9.5,
                        color: CustomerColors.gold,
                        letterSpacing: 1.4,
                        fontWeight: FontWeight.w700,
                        height: 1.5,
                      ),
                    ),
                    Text(
                      'REAL EXPERIENCES.',
                      style: TextStyle(
                        fontSize: 9.5,
                        color: CustomerColors.gold,
                        letterSpacing: 1.4,
                        fontWeight: FontWeight.w700,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SidebarNavTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _SidebarNavTile({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              color: isSelected ? CustomerColors.burgundy : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: isSelected
                  ? Border.all(
                      color: CustomerColors.gold,
                      width: 1.2,
                    )
                  : null,
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: CustomerColors.burgundy.withValues(alpha: 0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: isSelected ? Colors.white : CustomerColors.gold,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? Colors.white : const Color(0xFFEDEAE2),
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Tall cinematic movie card matching Reference Image 1 & 2.
class CustomerMovieCard extends StatefulWidget {
  final String title;
  final String? posterUrl;
  final String genre;
  final double rating;
  final String voteCount;
  final bool isPromoted;
  final VoidCallback onTap;
  final double width;

  const CustomerMovieCard({
    super.key,
    required this.title,
    this.posterUrl,
    required this.genre,
    this.rating = 8.5,
    this.voteCount = '2.5K+ Votes',
    this.isPromoted = false,
    required this.onTap,
    this.width = 195,
  });

  @override
  State<CustomerMovieCard> createState() => _CustomerMovieCardState();
}

class _CustomerMovieCardState extends State<CustomerMovieCard> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final posterHeight = widget.width * 1.48; // ~2:3 portrait aspect ratio

    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: SizedBox(
          width: widget.width,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Poster Container
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: widget.width,
                height: posterHeight,
                transform: _hovering
                    ? Matrix4.translationValues(0.0, -4.0, 0.0)
                    : Matrix4.identity(),
                decoration: BoxDecoration(
                  color: CustomerColors.surfaceCard,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _hovering ? CustomerColors.gold : CustomerColors.borderGoldSubtle,
                    width: _hovering ? 1.5 : 1.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _hovering
                          ? CustomerColors.gold.withValues(alpha: 0.22)
                          : Colors.black.withValues(alpha: 0.35),
                      blurRadius: _hovering ? 16 : 8,
                      offset: Offset(0, _hovering ? 6 : 3),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(13),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Poster Image
                      if (widget.posterUrl != null && widget.posterUrl!.trim().isNotEmpty)
                        Image.network(
                          widget.posterUrl!.trim(),
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => _fallbackPoster(),
                        )
                      else
                        _fallbackPoster(),

                      // Promoted Badge
                      if (widget.isPromoted)
                        Positioned(
                          top: 10,
                          right: 10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: CustomerColors.burgundy,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: CustomerColors.goldLight, width: 0.8),
                            ),
                            child: const Text(
                              'PROMOTED',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ),
                        ),

                      // Rating overlay bar at the bottom of poster (Reference Image 1)
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                Colors.black.withValues(alpha: 0.95),
                                Colors.black.withValues(alpha: 0.75),
                                Colors.transparent,
                              ],
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.star_rounded,
                                size: 16,
                                color: CustomerColors.gold,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${widget.rating.toStringAsFixed(1)}/10',
                                style: const TextStyle(
                                  color: CustomerColors.textPrimary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  widget.voteCount,
                                  style: const TextStyle(
                                    color: CustomerColors.textSecondary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // Title
              Text(
                widget.title,
                style: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  color: CustomerColors.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 3),

              // Genre / Details
              Text(
                widget.genre,
                style: const TextStyle(
                  fontSize: 12,
                  color: CustomerColors.textMuted,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _fallbackPoster() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF220E15),
            Color(0xFF101118),
          ],
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.movie_creation_outlined,
                size: 38,
                color: CustomerColors.gold.withValues(alpha: 0.6),
              ),
              const SizedBox(height: 8),
              Text(
                widget.title.isNotEmpty ? widget.title : 'LiveScreen',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: CustomerColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Header for a Home page section (e.g. "Recommended Movies", "Upcoming Events").
class CustomerSectionHeader extends StatelessWidget {
  final String titlePrefix;
  final String titleHighlight;
  final VoidCallback? onSeeAll;

  const CustomerSectionHeader({
    super.key,
    required this.titlePrefix,
    required this.titleHighlight,
    this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: titlePrefix.isEmpty ? '' : '$titlePrefix ',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: CustomerColors.textPrimary,
                  letterSpacing: -0.3,
                ),
              ),
              TextSpan(
                text: titleHighlight,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: CustomerColors.gold,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        if (onSeeAll != null)
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: onSeeAll,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Text(
                    'See All',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: CustomerColors.gold,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: CustomerColors.gold,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
