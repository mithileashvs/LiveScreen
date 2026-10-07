import 'package:flutter/material.dart';
import '../../shared/widgets/admin/admin_sidebar.dart';
import '../../shared/widgets/admin/admin_top_bar.dart';
import '../../shared/widgets/admin/admin_status_badge.dart';
import '../models/theatre_configuration.dart';
import '../services/theatre_repository.dart';
import '../services/selected_theatre.dart';
import 'create_theatre_screen.dart';
import 'theatre_editor_screen.dart';
import 'theatre_screens_screen.dart';
import 'theatre_shows_screen.dart';
import 'theatre_bookings_screen.dart';
import 'theatre_analytics_screen.dart';
import 'theatre_snacks_screen.dart';
import 'admin_dashboard_screen.dart';

/// Redesigned 'My Theatre' Screen for Theatre Admin.
/// Implements the master dark cinematic design language (Black, Gold & Burgundy).
class TheatreListScreen extends StatefulWidget {
  const TheatreListScreen({super.key});

  @override
  State<TheatreListScreen> createState() => _TheatreListScreenState();
}

class _TheatreListScreenState extends State<TheatreListScreen> {
  late Future<List<TheatreConfiguration>> _theatresFuture;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    setState(() {
      _theatresFuture = theatreRepository.getMyTheatres();
    });
  }

  Future<void> _openTheatre(TheatreConfiguration config) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => TheatreEditorScreen(theatreId: config.id)),
    );
    _refresh();
  }

  Future<void> _manageScreens(TheatreConfiguration config) async {
    selectedTheatreContext.select(config.id);
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const TheatreScreensScreen()),
    );
    _refresh();
  }

  Future<void> _createTheatre() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const CreateTheatreScreen()),
    );
    if (created == true) {
      _refresh();
    }
  }

  void _showAdminAccess(TheatreConfiguration config) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: const Color(0xFF111116),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0x66D4AF37)),
        ),
        title: Row(
          children: const [
            Icon(Icons.admin_panel_settings, color: Color(0xFFD4AF37)),
            SizedBox(width: 8),
            Text('Admin Access & Status', style: TextStyle(color: Color(0xFFFFFFFF), fontSize: 18, fontWeight: FontWeight.w700)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Theatre: ${config.basicInfo.name}', style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFFF7F5F0), fontSize: 14)),
            const SizedBox(height: 8),
            Text('Hall: ${config.basicInfo.hallName.isEmpty ? 'Main' : config.basicInfo.hallName}', style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13)),
            const SizedBox(height: 8),
            Text('ID: ${config.id}', style: const TextStyle(color: Color(0xFF71717A), fontSize: 11)),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('Platform Status: ', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12.5)),
                AdminStatusBadge(status: config.status.name),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Verification: ${_verificationHint(config.verificationStatus)}',
              style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Close', style: TextStyle(color: Color(0xFFD4AF37))),
          ),
        ],
      ),
    );
  }

  Future<void> _deactivateTheatre(TheatreConfiguration config) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: const Color(0xFF111116),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0x66D4AF37)),
        ),
        title: Row(
          children: const [
            Icon(Icons.pause_circle_outline, color: Color(0xFFD4AF37)),
            SizedBox(width: 8),
            Text('Deactivate Theatre?', style: TextStyle(color: Color(0xFFFFFFFF), fontSize: 18, fontWeight: FontWeight.w700)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Deactivating "${config.basicInfo.name}" will archive the venue and remove it from public movie discovery.',
              style: const TextStyle(color: Color(0xFFF7F5F0), fontSize: 13.5),
            ),
            const SizedBox(height: 12),
            const Text(
              '• All existing shows and customer booking records are safely preserved.\n'
              '• No new tickets can be booked while deactivated.\n'
              '• You can reactivate this theatre at any time.',
              style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF9CA3AF))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD4AF37),
              foregroundColor: Colors.black,
            ),
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            child: const Text('Deactivate Theatre', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await theatreRepository.deactivateTheatre(config.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Theatre "${config.basicInfo.name}" has been deactivated.')),
          );
          _refresh();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to deactivate: $e'), backgroundColor: const Color(0xFFEF4444)),
          );
        }
      }
    }
  }

  Future<void> _reactivateTheatre(TheatreConfiguration config) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: const Color(0xFF111116),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0x66D4AF37)),
        ),
        title: Row(
          children: const [
            Icon(Icons.play_circle_outline, color: Color(0xFF10B981)),
            SizedBox(width: 8),
            Text('Reactivate Theatre?', style: TextStyle(color: Color(0xFFFFFFFF), fontSize: 18, fontWeight: FontWeight.w700)),
          ],
        ),
        content: Text(
          'Reactivating "${config.basicInfo.name}" will restore its published status and re-enable show scheduling and ticket bookings.',
          style: const TextStyle(color: Color(0xFFF7F5F0), fontSize: 13.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF9CA3AF))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            child: const Text('Reactivate Theatre', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await theatreRepository.reactivateTheatre(config.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Theatre "${config.basicInfo.name}" has been reactivated.')),
          );
          _refresh();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to reactivate: $e'), backgroundColor: const Color(0xFFEF4444)),
          );
        }
      }
    }
  }

  Future<void> _handleDeleteTheatre(TheatreConfiguration config) async {
    TheatreDependencySummary deps;
    try {
      deps = await theatreRepository.getTheatreDependencies(config.id);
    } catch (_) {
      deps = const TheatreDependencySummary();
    }

    if (!mounted) return;

    if (deps.hasDependencies) {
      await showDialog(
        context: context,
        builder: (dialogCtx) => AlertDialog(
          backgroundColor: const Color(0xFF111116),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0x66D4AF37)),
          ),
          title: Row(
            children: const [
              Icon(Icons.shield_outlined, color: Color(0xFFD4AF37)),
              SizedBox(width: 8),
              Expanded(
                child: Text('Cannot Delete Theatre', style: TextStyle(color: Color(0xFFFFFFFF), fontSize: 18, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '"${config.basicInfo.name}" cannot be permanently deleted because it has active dependencies:',
                style: const TextStyle(color: Color(0xFFF7F5F0), fontSize: 13.5),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF16161D),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0x4DD4AF37)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('• ${deps.showCount} scheduled show(s)', style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFFF7F5F0), fontSize: 13)),
                    const SizedBox(height: 4),
                    Text('• ${deps.bookingCount} customer booking(s)', style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFFF7F5F0), fontSize: 13)),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'LiveScreen strictly protects historical customer purchases and audit logs against cascading deletion.\n\n'
                'Please deactivate the theatre instead. Deactivation archives the venue and halts future bookings while preserving all historical records.',
                style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: const Text('Cancel', style: TextStyle(color: Color(0xFF9CA3AF))),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.pause_circle_outline, size: 18),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD4AF37),
                foregroundColor: Colors.black,
              ),
              onPressed: () {
                Navigator.of(dialogCtx).pop();
                _deactivateTheatre(config);
              },
              label: const Text('Deactivate Instead', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      );
    } else {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogCtx) => AlertDialog(
          backgroundColor: const Color(0xFF111116),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFFEF4444)),
          ),
          title: Row(
            children: const [
              Icon(Icons.delete_forever, color: Color(0xFFEF4444)),
              SizedBox(width: 8),
              Text('Delete Theatre?', style: TextStyle(color: Color(0xFFFFFFFF), fontSize: 18, fontWeight: FontWeight.w700)),
            ],
          ),
          content: Text(
            'Are you sure you want to permanently delete "${config.basicInfo.name}"? '
            'This theatre has no shows or bookings. This action cannot be undone.',
            style: const TextStyle(color: Color(0xFFF7F5F0), fontSize: 13.5),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(false),
              child: const Text('Cancel', style: TextStyle(color: Color(0xFF9CA3AF))),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.of(dialogCtx).pop(true),
              child: const Text('Delete Permanently', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      );

      if (confirmed == true && mounted) {
        try {
          await theatreRepository.deleteTheatre(config.id);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Theatre "${config.basicInfo.name}" deleted.')),
            );
            _refresh();
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to delete: $e'), backgroundColor: const Color(0xFFEF4444)),
            );
          }
        }
      }
    }
  }

  void _navigateTo(String key) {
    if (key == 'dashboard') {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
      );
    } else if (key == 'my_theatre') {
      // already here
    } else if (key == 'screens') {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const TheatreScreensScreen()),
      );
    } else if (key == 'shows') {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const TheatreShowsScreen()),
      );
    } else if (key == 'bookings') {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const TheatreBookingsScreen()),
      );
    } else if (key == 'snacks') {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const TheatreSnacksScreen()),
      );
    } else if (key == 'analytics') {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const TheatreAnalyticsScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 900;

    const navItems = [
      AdminNavItemData(key: 'dashboard', label: 'Dashboard', icon: Icons.dashboard_rounded),
      AdminNavItemData(key: 'my_theatre', label: 'My Theatre', icon: Icons.theaters_outlined),
      AdminNavItemData(key: 'screens', label: 'Screens', icon: Icons.tv_rounded),
      AdminNavItemData(key: 'shows', label: 'Shows', icon: Icons.calendar_today_outlined),
      AdminNavItemData(key: 'bookings', label: 'Bookings', icon: Icons.confirmation_number_outlined),
      AdminNavItemData(key: 'analytics', label: 'Analytics', icon: Icons.bar_chart_rounded),
    ];

    final sidebar = AdminSidebar(
      activeKey: 'my_theatre',
      mainNavItems: navItems,
      onSelectKey: _navigateTo,
    );

    return Scaffold(
      backgroundColor: const Color(0xFF070709),
      drawer: isDesktop ? null : Drawer(backgroundColor: const Color(0xFF070709), child: sidebar),
      body: Row(
        children: [
          if (isDesktop) sidebar,
          Expanded(
            child: Column(
              children: [
                AdminTopBar(
                  searchPlaceholder: 'Search venues, cities, auditoriums...',
                  showDrawerButton: !isDesktop,
                  onProfileTap: () => _navigateTo('my_theatre'),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Page Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: const [
                                  Text(
                                    'My Theatres',
                                    style: TextStyle(
                                      fontSize: 26,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFFFFFFFF),
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Manage your registered auditoriums, sound systems and screen layouts.',
                                    style: TextStyle(
                                      fontSize: 13.5,
                                      color: Color(0xFF9CA3AF),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            ElevatedButton.icon(
                              onPressed: _createTheatre,
                              icon: const Icon(Icons.add_rounded, size: 18),
                              label: const Text('Create Theatre', style: TextStyle(fontWeight: FontWeight.w700)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFD4AF37),
                                foregroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Theatres List / Cards
                        FutureBuilder<List<TheatreConfiguration>>(
                          future: _theatresFuture,
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(48.0),
                                  child: CircularProgressIndicator(color: Color(0xFFD4AF37)),
                                ),
                              );
                            }

                            final theatres = snapshot.data!;
                            if (theatres.isEmpty) {
                              return Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(48),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0F0F12),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: const Color(0xFF1E1E26)),
                                ),
                                child: Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.theaters_outlined, size: 48, color: Color(0xFF71717A)),
                                      const SizedBox(height: 14),
                                      const Text(
                                        'No Theatres Registered Yet',
                                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFFFFFFFF)),
                                      ),
                                      const SizedBox(height: 6),
                                      const Text(
                                        'Create your first theatre to configure its room dimensions, screen, seating, and speakers.',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
                                      ),
                                      const SizedBox(height: 18),
                                      ElevatedButton.icon(
                                        onPressed: _createTheatre,
                                        icon: const Icon(Icons.add, size: 16),
                                        label: const Text('Add Theatre Now'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFFD4AF37),
                                          foregroundColor: Colors.black,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }

                            return ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: theatres.length,
                              separatorBuilder: (_, _) => const SizedBox(height: 14),
                              itemBuilder: (context, index) {
                                final theatre = theatres[index];
                                final isArchived = theatre.status == TheatreStatus.archived;
                                final name = theatre.basicInfo.name.isEmpty ? '(Untitled Theatre)' : theatre.basicInfo.name;
                                final hall = theatre.basicInfo.hallName.isEmpty ? 'Main Screen' : theatre.basicInfo.hallName;

                                return Container(
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0F0F12),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: const Color(0xFF1E1E26)),
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    borderRadius: BorderRadius.circular(14),
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(14),
                                      onTap: () => _openTheatre(theatre),
                                      child: Padding(
                                        padding: const EdgeInsets.all(18),
                                        child: Row(
                                          children: [
                                            // Golden Building Icon Box
                                            Container(
                                              width: 50,
                                              height: 50,
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF1C180E),
                                                borderRadius: BorderRadius.circular(12),
                                                border: Border.all(color: const Color(0x66D4AF37)),
                                              ),
                                              child: const Center(
                                                child: Icon(Icons.theaters_outlined, color: Color(0xFFD4AF37), size: 24),
                                              ),
                                            ),
                                            const SizedBox(width: 16),

                                            // Theatre Details
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Text(
                                                        name,
                                                        style: const TextStyle(
                                                          fontSize: 16,
                                                          fontWeight: FontWeight.w700,
                                                          color: Color(0xFFFFFFFF),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 10),
                                                      AdminStatusBadge(status: theatre.status.name, showDot: true),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    '$hall • ${theatre.seats.length} seats • ${theatre.speakers.length} speakers • ${theatre.screen.type.name.toUpperCase()}',
                                                    style: const TextStyle(
                                                      fontSize: 12.5,
                                                      color: Color(0xFF9CA3AF),
                                                    ),
                                                  ),
                                                  if (theatre.verificationStatus != 'verified') ...[
                                                    const SizedBox(height: 6),
                                                    Text(
                                                      _verificationHint(theatre.verificationStatus),
                                                      style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 11.5, fontWeight: FontWeight.w500),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                            ),

                                            // Quick Actions
                                            OutlinedButton.icon(
                                              icon: const Icon(Icons.edit_outlined, size: 15),
                                              label: const Text('Studio'),
                                              style: OutlinedButton.styleFrom(
                                                foregroundColor: const Color(0xFFD4AF37),
                                                side: const BorderSide(color: Color(0x66D4AF37)),
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                              ),
                                              onPressed: () => _openTheatre(theatre),
                                            ),
                                            const SizedBox(width: 8),

                                            OutlinedButton.icon(
                                              icon: const Icon(Icons.tv_rounded, size: 15),
                                              label: const Text('Screens'),
                                              style: OutlinedButton.styleFrom(
                                                foregroundColor: const Color(0xFFF7F5F0),
                                                side: const BorderSide(color: Color(0xFF2E2E38)),
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                              ),
                                              onPressed: () => _manageScreens(theatre),
                                            ),
                                            const SizedBox(width: 8),

                                            // Menu for complete lifecycle actions
                                            PopupMenuButton<String>(
                                              key: Key('theatre_menu_${theatre.id}'),
                                              icon: const Icon(Icons.more_vert, color: Color(0xFF9CA3AF)),
                                              tooltip: 'Manage Theatre',
                                              color: const Color(0xFF14141A),
                                              onSelected: (value) {
                                                switch (value) {
                                                  case 'edit':
                                                    _openTheatre(theatre);
                                                    break;
                                                  case 'screens':
                                                    _manageScreens(theatre);
                                                    break;
                                                  case 'admin_access':
                                                    _showAdminAccess(theatre);
                                                    break;
                                                  case 'deactivate':
                                                    _deactivateTheatre(theatre);
                                                    break;
                                                  case 'reactivate':
                                                    _reactivateTheatre(theatre);
                                                    break;
                                                  case 'delete':
                                                    _handleDeleteTheatre(theatre);
                                                    break;
                                                }
                                              },
                                              itemBuilder: (context) => [
                                                const PopupMenuItem(
                                                  value: 'edit',
                                                  child: Row(
                                                    children: [
                                                      Icon(Icons.edit_outlined, size: 18, color: Color(0xFFD4AF37)),
                                                      SizedBox(width: 10),
                                                      Text('Edit Theatre', style: TextStyle(color: Color(0xFFF7F5F0))),
                                                    ],
                                                  ),
                                                ),
                                                const PopupMenuItem(
                                                  value: 'screens',
                                                  child: Row(
                                                    children: [
                                                      Icon(Icons.tv_outlined, size: 18, color: Color(0xFFD4AF37)),
                                                      SizedBox(width: 10),
                                                      Text('Manage Screens', style: TextStyle(color: Color(0xFFF7F5F0))),
                                                    ],
                                                  ),
                                                ),
                                                const PopupMenuItem(
                                                  value: 'admin_access',
                                                  child: Row(
                                                    children: [
                                                      Icon(Icons.admin_panel_settings_outlined, size: 18, color: Color(0xFFD4AF37)),
                                                      SizedBox(width: 10),
                                                      Text('Manage Admin Access', style: TextStyle(color: Color(0xFFF7F5F0))),
                                                    ],
                                                  ),
                                                ),
                                                const PopupMenuDivider(),
                                                if (isArchived)
                                                  const PopupMenuItem(
                                                    value: 'reactivate',
                                                    child: Row(
                                                      children: [
                                                        Icon(Icons.play_circle_outline, size: 18, color: Color(0xFF10B981)),
                                                        SizedBox(width: 10),
                                                        Text('Reactivate Theatre', style: TextStyle(color: Color(0xFF10B981))),
                                                      ],
                                                    ),
                                                  )
                                                else
                                                  const PopupMenuItem(
                                                    value: 'deactivate',
                                                    child: Row(
                                                      children: [
                                                        Icon(Icons.pause_circle_outline, size: 18, color: Color(0xFFD4AF37)),
                                                        SizedBox(width: 10),
                                                        Text('Deactivate Theatre', style: TextStyle(color: Color(0xFFD4AF37))),
                                                      ],
                                                    ),
                                                  ),
                                                const PopupMenuItem(
                                                  value: 'delete',
                                                  child: Row(
                                                    children: [
                                                      Icon(Icons.delete_outline, size: 18, color: Color(0xFFEF4444)),
                                                      SizedBox(width: 10),
                                                      Text('Delete Theatre', style: TextStyle(color: Color(0xFFEF4444))),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _verificationHint(String verificationStatus) {
    switch (verificationStatus) {
      case 'rejected':
        return 'Verification rejected by Platform Admin';
      case 'suspended':
        return 'Suspended by Platform Admin';
      case 'under_review':
        return 'Under review by Platform Admin';
      default:
        return 'Awaiting Platform Admin verification';
    }
  }
}
