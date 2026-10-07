import 'package:flutter/material.dart';
import '../../admin/models/theatre_admin_theatre.dart';
import '../services/platform_admin_repository.dart';
import '../theme/platform_admin_theme.dart';
import '../widgets/review_widgets.dart';

const List<String> _kOwnershipFilters = ['all', 'pending', 'under_review', 'verified', 'rejected'];

/// Theatre Ownership Verification Screen for Platform Admin.
/// Reviews who may manage which theatre venue (theatre_admin_theatres relationship).
class TheatreOwnershipVerificationScreen extends StatefulWidget {
  const TheatreOwnershipVerificationScreen({super.key});

  @override
  State<TheatreOwnershipVerificationScreen> createState() => _TheatreOwnershipVerificationScreenState();
}

class _TheatreOwnershipVerificationScreenState extends State<TheatreOwnershipVerificationScreen> {
  String _filter = 'pending';
  late Future<List<TheatreOwnershipReviewItem>> _future;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    setState(() {
      _future = platformAdminRepository.listTheatreOwnershipSubmissions(
        statusFilter: _filter == 'all' ? null : _filter,
      );
    });
  }

  Future<void> _openDetail(TheatreOwnershipReviewItem item) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => _OwnershipReviewDetailScreen(item: item)),
    );
    if (changed == true) _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return PlatformAdminScaffold(
      activeKey: 'verifications',
      pageTitle: 'Theatre Ownership Authorizations',
      pageSubtitle: 'Review operator claims and authorize admin privileges for specific venues.',
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
              itemCount: _kOwnershipFilters.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final f = _kOwnershipFilters[index];
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

          // 2. Ownership Submissions List
          FutureBuilder<List<TheatreOwnershipReviewItem>>(
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
                      'Could not load submissions: ${snapshot.error}',
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
                        Icon(Icons.verified_user_outlined, size: 40, color: PlatformAdminColors.gold),
                        SizedBox(height: 12),
                        Text(
                          'No ownership submissions found in this filter.',
                          style: TextStyle(color: PlatformAdminColors.textWhite, fontSize: 15, fontWeight: FontWeight.w600),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Operator ownership claims for venues will appear here for review.',
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
                  final venueName = t.basicInfo.name.isEmpty ? '(Untitled Venue)' : t.basicInfo.name;

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
                              child: const Icon(Icons.verified_user_outlined, color: PlatformAdminColors.gold, size: 22),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    venueName,
                                    style: const TextStyle(
                                      color: PlatformAdminColors.textWhite,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Applicant: ${item.applicantName} (${item.applicantEmail}) • Org: ${item.organizationName}',
                                    style: const TextStyle(color: PlatformAdminColors.textMuted, fontSize: 12.5),
                                  ),
                                ],
                              ),
                            ),
                            StatusPill(status: item.relationship.verificationStatus),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: PlatformAdminColors.burgundyAccent,
                                foregroundColor: PlatformAdminColors.textWhite,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              onPressed: () => _openDetail(item),
                              icon: const Icon(Icons.rate_review_outlined, size: 15),
                              label: const Text('Inspect Ownership Claim', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5)),
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
}

class _OwnershipReviewDetailScreen extends StatefulWidget {
  final TheatreOwnershipReviewItem item;
  const _OwnershipReviewDetailScreen({required this.item});

  @override
  State<_OwnershipReviewDetailScreen> createState() => _OwnershipReviewDetailScreenState();
}

class _OwnershipReviewDetailScreenState extends State<_OwnershipReviewDetailScreen> {
  late String _status;
  bool _busy = false;
  bool _changed = false;

  @override
  void initState() {
    super.initState();
    _status = widget.item.relationship.verificationStatus;
  }

  Future<void> _act() async {
    final result = await showReviewActionSheet(
      context: context,
      title: 'Review Ownership Submission',
      actions: [
        const ReviewAction(
          newStatus: 'under_review',
          label: 'Mark Under Review',
          icon: Icons.hourglass_top_rounded,
          color: PlatformAdminColors.gold,
        ),
        const ReviewAction(
          newStatus: 'verified',
          label: 'Authorize & Verify Ownership',
          icon: Icons.check_circle_outline,
          color: PlatformAdminColors.success,
        ),
        const ReviewAction(
          newStatus: 'rejected',
          label: 'Reject Claim',
          icon: Icons.cancel_outlined,
          color: PlatformAdminColors.error,
          requiresReason: true,
        ),
      ],
    );
    if (result == null) return;

    setState(() => _busy = true);
    try {
      await platformAdminRepository.reviewTheatreOwnership(
        relationshipId: widget.item.relationship.id,
        newStatus: result.newStatus,
      );
      if (!mounted) return;
      setState(() {
        _status = result.newStatus;
        _busy = false;
        _changed = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ownership marked as ${result.newStatus.replaceAll('_', ' ')}.'),
          backgroundColor: PlatformAdminColors.cardSurface,
        ),
      );
    } catch (e) {
      setState(() => _busy = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not update ownership: $e'),
          backgroundColor: PlatformAdminColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final t = item.theatre;

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
            t.basicInfo.name.isEmpty ? 'Theatre Ownership Claim' : t.basicInfo.name,
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
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Authorization Status', style: TextStyle(color: PlatformAdminColors.textWhite, fontSize: 15, fontWeight: FontWeight.w700)),
                  StatusPill(status: _status),
                ],
              ),
            ),
            const SizedBox(height: 20),

            _buildSection(
              title: 'Theatre Venue Details',
              icon: Icons.domain_outlined,
              rows: [
                {'label': 'Venue Name', 'value': t.basicInfo.name},
                {'label': 'Address', 'value': t.basicInfo.address},
                {'label': 'City / State', 'value': '${t.basicInfo.city}, ${t.basicInfo.state}'},
                {'label': 'Contact', 'value': t.basicInfo.contactNumber},
              ],
            ),
            const SizedBox(height: 20),

            _buildSection(
              title: 'Applicant Operator Profile',
              icon: Icons.badge_outlined,
              rows: [
                {'label': 'Admin Code', 'value': item.adminCode},
                {'label': 'Organization', 'value': item.organizationName},
                {'label': 'Applicant Name', 'value': item.applicantName},
                {'label': 'Applicant Email', 'value': item.applicantEmail},
              ],
            ),
            const SizedBox(height: 20),

            _buildSection(
              title: 'Relationship Claim Metadata',
              icon: Icons.assignment_outlined,
              rows: [
                {'label': 'Claimed Role', 'value': item.relationship.relationshipRole},
                {'label': 'Submitted Date', 'value': item.relationship.submittedAt.toLocal().toString()},
                if (item.relationship.verifiedAt != null)
                  {'label': 'Authorization Timestamp', 'value': item.relationship.verifiedAt!.toLocal().toString()},
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
                  label: Text(_busy ? 'Working…' : 'Record Authorization Decision', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
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
