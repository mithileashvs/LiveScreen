import 'package:flutter/material.dart';
import '../models/platform_admin_models.dart';
import '../services/platform_admin_repository.dart';
import '../theme/platform_admin_theme.dart';
import '../widgets/review_widgets.dart';

const List<String> _kFilters = ['all', ...kVerificationStatuses];

/// Master Producer Management & Verification Screen for Platform Admin.
/// Connects to platformAdminRepository for live producer approval decisions.
class ProducerVerificationScreen extends StatefulWidget {
  const ProducerVerificationScreen({super.key});

  @override
  State<ProducerVerificationScreen> createState() => _ProducerVerificationScreenState();
}

class _ProducerVerificationScreenState extends State<ProducerVerificationScreen> {
  String _filter = 'all';
  late Future<List<ProducerProfile>> _future;
  final Set<String> _busyIds = {};

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    setState(() {
      _future = platformAdminRepository.listProducersForVerification(
        statusFilter: _filter == 'all' ? null : _filter,
      );
    });
  }

  Future<void> _review(ProducerProfile producer) async {
    final result = await showReviewActionSheet(
      context: context,
      title: 'Review Producer Account',
      actions: [
        const ReviewAction(
          newStatus: 'under_review',
          label: 'Mark Under Review',
          icon: Icons.hourglass_top_rounded,
          color: PlatformAdminColors.gold,
        ),
        const ReviewAction(
          newStatus: 'verified',
          label: 'Verify Producer',
          icon: Icons.check_circle_outline,
          color: PlatformAdminColors.success,
        ),
        const ReviewAction(
          newStatus: 'rejected',
          label: 'Reject Registration',
          icon: Icons.cancel_outlined,
          color: PlatformAdminColors.error,
          requiresReason: true,
        ),
        const ReviewAction(
          newStatus: 'suspended',
          label: 'Suspend Producer',
          icon: Icons.block_rounded,
          color: PlatformAdminColors.error,
          requiresReason: true,
        ),
      ],
    );
    if (result == null) return;

    setState(() => _busyIds.add(producer.id));
    try {
      await platformAdminRepository.reviewProducer(
        producerId: producer.id,
        newStatus: result.newStatus,
        reason: result.reason,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Producer marked as ${result.newStatus.replaceAll('_', ' ')}.'),
          backgroundColor: PlatformAdminColors.cardSurface,
        ),
      );
      _refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not update producer: $e'),
          backgroundColor: PlatformAdminColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _busyIds.remove(producer.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return PlatformAdminScaffold(
      activeKey: 'producers',
      pageTitle: 'Producer Management',
      pageSubtitle: 'Review, verify, and govern content producer and studio distribution accounts.',
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
          // 1. Status Filter Bar
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

          // 2. Producers List
          FutureBuilder<List<ProducerProfile>>(
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
                      'Could not load producers: ${snapshot.error}',
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
                        Icon(Icons.groups_outlined, size: 40, color: PlatformAdminColors.gold),
                        SizedBox(height: 12),
                        Text(
                          'No producers found for this filter.',
                          style: TextStyle(color: PlatformAdminColors.textWhite, fontSize: 15, fontWeight: FontWeight.w600),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Producer accounts submitted for verification will appear here.',
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
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final p = items[index];
                  final busy = _busyIds.contains(p.id);
                  final initial = (p.displayName.isNotEmpty ? p.displayName[0] : (p.email.isNotEmpty ? p.email[0] : 'P')).toUpperCase();

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
                                shape: BoxShape.circle,
                                color: const Color(0xFF14120C),
                                border: Border.all(color: PlatformAdminColors.gold, width: 1),
                              ),
                              child: Center(
                                child: Text(
                                  initial,
                                  style: const TextStyle(color: PlatformAdminColors.gold, fontSize: 18, fontWeight: FontWeight.w800),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    p.displayName.isEmpty ? p.email : p.displayName,
                                    style: const TextStyle(
                                      color: PlatformAdminColors.textWhite,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    p.email,
                                    style: const TextStyle(color: PlatformAdminColors.textMuted, fontSize: 12.5),
                                  ),
                                ],
                              ),
                            ),
                            StatusPill(status: p.verificationStatus),
                          ],
                        ),
                        if (p.verificationReason != null && p.verificationReason!.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0D0D12),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: PlatformAdminColors.borderDark, width: 0.8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.note_alt_outlined, size: 14, color: Color(0xFFFCA5A5)),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Review note: ${p.verificationReason}',
                                    style: const TextStyle(color: Color(0xFFFCA5A5), fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
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
                              onPressed: busy ? null : () => _review(p),
                              icon: const Icon(Icons.rate_review_outlined, size: 15),
                              label: Text(busy ? 'Updating…' : 'Review Decision', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5)),
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
