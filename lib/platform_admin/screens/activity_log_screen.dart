import 'package:flutter/material.dart';
import '../models/platform_admin_models.dart';
import '../services/platform_admin_repository.dart';
import '../theme/platform_admin_theme.dart';
import '../widgets/review_widgets.dart';

/// Platform Activity & Audit Trail Screen for Platform Admin.
/// Immutable historical ledger of verification transitions, review decisions, and justifications.
class ActivityLogScreen extends StatefulWidget {
  const ActivityLogScreen({super.key});

  @override
  State<ActivityLogScreen> createState() => _ActivityLogScreenState();
}

class _ActivityLogScreenState extends State<ActivityLogScreen> {
  late Future<List<AuditLogEntry>> _future;
  String _entityFilter = 'all';

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    setState(() {
      _future = platformAdminRepository.getRecentActivity();
    });
  }

  IconData _entityIcon(String entity) {
    switch (entity.toLowerCase()) {
      case 'theatre':
        return Icons.domain_outlined;
      case 'producer':
        return Icons.groups_outlined;
      case 'movie':
        return Icons.movie_outlined;
      default:
        return Icons.history_rounded;
    }
  }

  String _formatDateTime(DateTime dt) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}, $hour:$minute UTC';
  }

  @override
  Widget build(BuildContext context) {
    return PlatformAdminScaffold(
      activeKey: 'audit_logs',
      pageTitle: 'Audit Logs',
      pageSubtitle: 'Immutable verification and approval transition history with reviewer audit signatures.',
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
          // 1. Entity Filter Chips
          SizedBox(
            height: 38,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildFilterChip('all', 'All Entries'),
                const SizedBox(width: 8),
                _buildFilterChip('theatre', 'Theatres'),
                const SizedBox(width: 8),
                _buildFilterChip('producer', 'Producers'),
                const SizedBox(width: 8),
                _buildFilterChip('movie', 'Movies & Content'),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // 2. Audit Entries List
          FutureBuilder<List<AuditLogEntry>>(
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
                      'Could not load activity log: ${snapshot.error}',
                      style: const TextStyle(color: PlatformAdminColors.error),
                    ),
                  ),
                );
              }

              final allEntries = snapshot.data!;
              final entries = _entityFilter == 'all'
                  ? allEntries
                  : allEntries.where((e) => e.entity.toLowerCase() == _entityFilter).toList();

              if (entries.isEmpty) {
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
                        Icon(Icons.history_rounded, size: 40, color: PlatformAdminColors.gold),
                        SizedBox(height: 12),
                        Text(
                          'No audit trail records found.',
                          style: TextStyle(color: PlatformAdminColors.textWhite, fontSize: 15, fontWeight: FontWeight.w600),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Administrative decisions are automatically stamped here.',
                          style: TextStyle(color: PlatformAdminColors.textDim, fontSize: 12.5),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: PlatformAdminColors.card,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: PlatformAdminColors.borderSubtle, width: 1.0),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Transition Ledger',
                          style: TextStyle(color: PlatformAdminColors.textWhite, fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                        Text(
                          '${entries.length} log events',
                          style: const TextStyle(color: PlatformAdminColors.textDim, fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: entries.length,
                      separatorBuilder: (_, _) => const Divider(color: PlatformAdminColors.borderDark, height: 1),
                      itemBuilder: (context, index) {
                        final e = entries[index];
                        final entityTitle = e.entity.isNotEmpty
                            ? '${e.entity[0].toUpperCase()}${e.entity.substring(1)}'
                            : 'Entity';

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF14120C),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: const Color(0x33D4AF37), width: 0.8),
                                ),
                                child: Icon(_entityIcon(e.entity), color: PlatformAdminColors.gold, size: 18),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          '$entityTitle · ${e.action.replaceAll('_', ' ')}',
                                          style: const TextStyle(
                                            color: PlatformAdminColors.textWhite,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        const Spacer(),
                                        Text(
                                          _formatDateTime(e.createdAt.toUtc()),
                                          style: const TextStyle(color: PlatformAdminColors.textDim, fontSize: 11.5),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        if (e.previousStatus != null) ...[
                                          StatusPill(status: e.previousStatus!),
                                          const Padding(
                                            padding: EdgeInsets.symmetric(horizontal: 8),
                                            child: Icon(Icons.arrow_forward_rounded, size: 13, color: PlatformAdminColors.textDim),
                                          ),
                                        ],
                                        if (e.newStatus != null) StatusPill(status: e.newStatus!),
                                      ],
                                    ),
                                    if (e.reason != null && e.reason!.isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF0D0D12),
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(color: PlatformAdminColors.borderDark, width: 0.8),
                                        ),
                                        child: Text(
                                          'Reason: ${e.reason!}',
                                          style: const TextStyle(color: Color(0xFFFCA5A5), fontSize: 12),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String key, String label) {
    final selected = _entityFilter == key;
    return InkWell(
      onTap: () => setState(() => _entityFilter = key),
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
  }
}
