import 'package:flutter/material.dart';
import '../../admin/models/screen_config.dart';
import '../models/platform_admin_models.dart';
import '../services/platform_admin_repository.dart';
import '../theme/platform_admin_theme.dart';
import '../widgets/review_widgets.dart';

const List<String> _kFilters = ['all', ...kVerificationStatuses];

/// Master Theatre Management & Verification Screen for Platform Admin.
/// Connects to platformAdminRepository for live venue inspection, room specs, and approval decisions.
class TheatreVerificationScreen extends StatefulWidget {
  const TheatreVerificationScreen({super.key});

  @override
  State<TheatreVerificationScreen> createState() => _TheatreVerificationScreenState();
}

class _TheatreVerificationScreenState extends State<TheatreVerificationScreen> {
  String _filter = 'all';
  late Future<List<TheatreVerificationItem>> _future;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    setState(() {
      _future = platformAdminRepository.listTheatresForVerification(
        statusFilter: _filter == 'all' ? null : _filter,
      );
    });
  }

  Future<void> _openDetail(TheatreVerificationItem item) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => _TheatreReviewDetailScreen(item: item)),
    );
    if (changed == true) _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return PlatformAdminScaffold(
      activeKey: 'theatres',
      pageTitle: 'Theatre Management',
      pageSubtitle: 'Inspect venue auditorium architecture, seating setups, and verify cinema operators.',
      headerAction: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          foregroundColor: PlatformAdminColors.gold,
          side: const BorderSide(color: PlatformAdminColors.gold, width: 0.9),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        ),
        onPressed: _refresh,
        icon: const Icon(Icons.refresh_rounded, size: 16),
        label: const Text('Refresh', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Status Filter Pills
          SizedBox(
            height: 38,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _kFilters.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final f = _kFilters[index];
                final selected = f == _filter;
                final label = f == 'all' ? 'All' : f.replaceAll('_', ' ').toUpperCase();

                return InkWell(
                  onTap: () {
                    setState(() => _filter = f);
                    _refresh();
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected ? const Color(0x288F1025) : const Color(0xFF0D0D12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: selected ? PlatformAdminColors.burgundyAccent : PlatformAdminColors.borderDark,
                        width: 0.9,
                      ),
                    ),
                    child: Text(
                      label,
                      style: TextStyle(
                        color: selected ? PlatformAdminColors.textWhite : PlatformAdminColors.textMuted,
                        fontSize: 12,
                        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),

          // 2. Theatres List
          FutureBuilder<List<TheatreVerificationItem>>(
            future: _future,
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(color: PlatformAdminColors.gold),
                  ),
                );
              }
              if (snapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      'Could not load theatres: ${snapshot.error}',
                      style: const TextStyle(color: PlatformAdminColors.error),
                    ),
                  ),
                );
              }

              final items = snapshot.data!;
              if (items.isEmpty) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(40),
                  decoration: BoxDecoration(
                    color: PlatformAdminColors.card,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: PlatformAdminColors.borderSubtle, width: 1.0),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.domain_outlined, size: 40, color: PlatformAdminColors.gold),
                        SizedBox(height: 12),
                        Text(
                          'No theatres found matching this filter.',
                          style: TextStyle(color: PlatformAdminColors.textWhite, fontSize: 15, fontWeight: FontWeight.w600),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Registered cinema auditoriums will appear here for verification.',
                          style: TextStyle(color: PlatformAdminColors.textDim, fontSize: 12.5),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: items.length,
                separatorBuilder: (_, _) => const SizedBox(height: 14),
                itemBuilder: (context, index) {
                  final item = items[index];
                  final t = item.theatre;
                  final name = t.basicInfo.name.isEmpty ? '(Untitled Venue)' : t.basicInfo.name;

                  return Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: PlatformAdminColors.card,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: PlatformAdminColors.borderSubtle, width: 1.0),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: const Color(0xFF14120C),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: PlatformAdminColors.gold, width: 1),
                              ),
                              child: const Icon(Icons.domain_outlined, color: PlatformAdminColors.gold, size: 22),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    style: const TextStyle(
                                      color: PlatformAdminColors.textWhite,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Operator: ${item.ownerName} • Hall: ${t.basicInfo.hallName.isNotEmpty ? t.basicInfo.hallName : 'Main Hall'}',
                                    style: const TextStyle(color: PlatformAdminColors.textMuted, fontSize: 12.5),
                                  ),
                                ],
                              ),
                            ),
                            StatusPill(status: t.verificationStatus),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            _buildSpecBadge(Icons.event_seat_outlined, '${t.seats.length} Seats'),
                            const SizedBox(width: 8),
                            _buildSpecBadge(Icons.speaker_outlined, '${t.speakers.length} Speakers'),
                            const SizedBox(width: 8),
                            _buildSpecBadge(Icons.aspect_ratio_rounded, '${t.screen.width.toStringAsFixed(1)}m × ${t.screen.height.toStringAsFixed(1)}m'),
                            const Spacer(),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: PlatformAdminColors.burgundyAccent,
                                foregroundColor: PlatformAdminColors.textWhite,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              onPressed: () => _openDetail(item),
                              icon: const Icon(Icons.rate_review_outlined, size: 15),
                              label: const Text('Inspect & Review', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSpecBadge(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF0D0D12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: PlatformAdminColors.borderDark, width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: PlatformAdminColors.gold),
          const SizedBox(width: 5),
          Text(text, style: const TextStyle(color: PlatformAdminColors.textMuted, fontSize: 11.5)),
        ],
      ),
    );
  }
}

class _TheatreReviewDetailScreen extends StatefulWidget {
  final TheatreVerificationItem item;
  const _TheatreReviewDetailScreen({required this.item});

  @override
  State<_TheatreReviewDetailScreen> createState() => _TheatreReviewDetailScreenState();
}

class _TheatreReviewDetailScreenState extends State<_TheatreReviewDetailScreen> {
  late String _status;
  late String? _reason;
  bool _busy = false;
  bool _changed = false;

  @override
  void initState() {
    super.initState();
    _status = widget.item.theatre.verificationStatus;
    _reason = widget.item.theatre.reviewReason;
  }

  Future<void> _act() async {
    final result = await showReviewActionSheet(
      context: context,
      title: 'Review Theatre Venue',
      actions: [
        const ReviewAction(
          newStatus: 'under_review',
          label: 'Mark Under Review',
          icon: Icons.hourglass_top_rounded,
          color: PlatformAdminColors.gold,
        ),
        const ReviewAction(
          newStatus: 'verified',
          label: 'Verify Venue',
          icon: Icons.check_circle_outline,
          color: PlatformAdminColors.success,
        ),
        const ReviewAction(
          newStatus: 'rejected',
          label: 'Reject Verification',
          icon: Icons.cancel_outlined,
          color: PlatformAdminColors.error,
          requiresReason: true,
        ),
        const ReviewAction(
          newStatus: 'suspended',
          label: 'Suspend Venue',
          icon: Icons.block_rounded,
          color: PlatformAdminColors.error,
          requiresReason: true,
        ),
      ],
    );
    if (result == null) return;

    setState(() => _busy = true);
    try {
      await platformAdminRepository.reviewTheatre(
        theatreId: widget.item.theatre.id,
        newStatus: result.newStatus,
        reason: result.reason,
      );
      if (!mounted) return;
      setState(() {
        _status = result.newStatus;
        _reason = result.reason;
        _busy = false;
        _changed = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Theatre marked as ${result.newStatus.replaceAll('_', ' ')}.'),
          backgroundColor: PlatformAdminColors.cardSurface,
        ),
      );
    } catch (e) {
      setState(() => _busy = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not update theatre: $e'),
          backgroundColor: PlatformAdminColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.item.theatre;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Navigator.of(context).pop(_changed);
      },
      child: Scaffold(
        backgroundColor: PlatformAdminColors.background,
        appBar: AppBar(
          backgroundColor: const Color(0xFF070709),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: PlatformAdminColors.gold),
            onPressed: () => Navigator.of(context).pop(_changed),
          ),
          title: Text(
            t.basicInfo.name.isEmpty ? 'Theatre Venue Review' : t.basicInfo.name,
            style: const TextStyle(color: PlatformAdminColors.textWhite, fontSize: 18, fontWeight: FontWeight.w700),
          ),
          bottom: const PreferredSize(
            preferredSize: Size.fromHeight(1),
            child: Divider(color: PlatformAdminColors.borderDark, height: 1),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            // Status Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: PlatformAdminColors.card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: PlatformAdminColors.borderSubtle),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Current Verification Status', style: TextStyle(color: PlatformAdminColors.textWhite, fontSize: 15, fontWeight: FontWeight.w700)),
                      StatusPill(status: _status),
                    ],
                  ),
                  if (_reason != null && _reason!.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text('Reviewer note: $_reason', style: const TextStyle(color: Color(0xFFFCA5A5), fontSize: 12.5)),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),

            _buildSection(
              title: 'Basic Venue & Operator Information',
              icon: Icons.badge_outlined,
              rows: [
                {'label': 'Venue Name', 'value': t.basicInfo.name},
                {'label': 'Hall Name', 'value': t.basicInfo.hallName},
                {'label': 'Description', 'value': t.basicInfo.description},
                {'label': 'Owner Name', 'value': widget.item.ownerName},
                {'label': 'Owner Email', 'value': widget.item.ownerEmail},
              ],
            ),
            const SizedBox(height: 20),

            _buildSection(
              title: 'Auditorium & Screen Specifications',
              icon: Icons.tv_rounded,
              rows: [
                {'label': 'Room Width', 'value': '${t.room.width} m'},
                {'label': 'Room Length', 'value': '${t.room.length} m'},
                {'label': 'Room Height', 'value': '${t.room.height} m'},
                {'label': 'Screen Width', 'value': '${t.screen.width} m'},
                {'label': 'Screen Height', 'value': '${t.screen.height} m'},
                {'label': 'Screen Type', 'value': t.screen.type.label},
              ],
            ),
            const SizedBox(height: 20),

            _buildSection(
              title: 'Seating & Spatial Audio Configuration',
              icon: Icons.surround_sound_rounded,
              rows: [
                {'label': 'Total Seats', 'value': '${t.seats.length}'},
                {'label': 'Total Speakers', 'value': '${t.speakers.length}'},
                {'label': 'Floor Acoustic', 'value': t.acoustics.floor.material},
                {'label': 'Walls Acoustic', 'value': t.acoustics.walls.material},
                {'label': 'Ceiling Acoustic', 'value': t.acoustics.ceiling.material},
              ],
            ),
            const SizedBox(height: 28),

            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: PlatformAdminColors.burgundyAccent,
                    foregroundColor: PlatformAdminColors.textWhite,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: _busy ? null : _act,
                  icon: const Icon(Icons.rate_review_outlined, size: 18),
                  label: Text(_busy ? 'Working…' : 'Record Review Decision', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required IconData icon, required List<Map<String, String>> rows}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: PlatformAdminColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: PlatformAdminColors.borderDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: PlatformAdminColors.gold, size: 18),
              const SizedBox(width: 10),
              Text(title, style: const TextStyle(color: PlatformAdminColors.textWhite, fontSize: 15, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 14),
          for (int i = 0; i < rows.length; i++) ...[
            if (i > 0) const Divider(color: PlatformAdminColors.borderDark, height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(rows[i]['label']!, style: const TextStyle(color: PlatformAdminColors.textMuted, fontSize: 13)),
                Flexible(
                  child: Text(
                    rows[i]['value']!.isEmpty ? '—' : rows[i]['value']!,
                    style: const TextStyle(color: PlatformAdminColors.textWhite, fontWeight: FontWeight.w600, fontSize: 13),
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
