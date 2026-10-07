import 'package:flutter/material.dart';
import '../models/platform_admin_models.dart';
import '../services/platform_admin_repository.dart';
import '../theme/platform_admin_theme.dart';
import '../widgets/review_widgets.dart';

const List<String> _kFilters = ['all', ...kMovieApprovalStatuses];

/// Master Movie & Content Approval Screen for Platform Admin.
/// Connects to platformAdminRepository for film metadata inspection, review decisions, and live catalog publishing.
class MovieApprovalScreen extends StatefulWidget {
  const MovieApprovalScreen({super.key});

  @override
  State<MovieApprovalScreen> createState() => _MovieApprovalScreenState();
}

class _MovieApprovalScreenState extends State<MovieApprovalScreen> {
  String _filter = 'all';
  late Future<List<MovieApprovalItem>> _future;
  final Set<String> _busyIds = {};

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    setState(() {
      _future = platformAdminRepository.listMoviesForApproval(
        statusFilter: _filter == 'all' ? null : _filter,
      );
    });
  }

  Future<void> _review(MovieApprovalItem item) async {
    final result = await showReviewActionSheet(
      context: context,
      title: 'Review Movie Content',
      actions: [
        const ReviewAction(
          newStatus: 'under_review',
          label: 'Mark Under Review',
          icon: Icons.hourglass_top_rounded,
          color: PlatformAdminColors.gold,
        ),
        const ReviewAction(
          newStatus: 'approved',
          label: 'Approve Content',
          icon: Icons.check_circle_outline,
          color: PlatformAdminColors.success,
        ),
        const ReviewAction(
          newStatus: 'rejected',
          label: 'Reject Content',
          icon: Icons.cancel_outlined,
          color: PlatformAdminColors.error,
          requiresReason: true,
        ),
      ],
    );
    if (result == null) return;

    setState(() => _busyIds.add(item.movie.id));
    try {
      await platformAdminRepository.reviewMovie(
        movieId: item.movie.id,
        newStatus: result.newStatus,
        reason: result.reason,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Content marked as ${result.newStatus.replaceAll('_', ' ')}.'),
          backgroundColor: PlatformAdminColors.cardSurface,
        ),
      );
      _refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not update movie: $e'),
          backgroundColor: PlatformAdminColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _busyIds.remove(item.movie.id));
    }
  }

  Future<void> _publish(MovieApprovalItem item) async {
    setState(() => _busyIds.add(item.movie.id));
    try {
      await platformAdminRepository.publishMovie(item.movie.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Movie "${item.movie.title.isEmpty ? 'Untitled' : item.movie.title}" published successfully to public catalog.'),
          backgroundColor: PlatformAdminColors.cardSurface,
        ),
      );
      _refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not publish movie: $e'),
          backgroundColor: PlatformAdminColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _busyIds.remove(item.movie.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return PlatformAdminScaffold(
      activeKey: 'movies',
      pageTitle: 'Movie & Content',
      pageSubtitle: 'Inspect submitted film titles, preview trailer media, and authorize catalog publishing.',
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

          // 2. Movie List
          FutureBuilder<List<MovieApprovalItem>>(
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
                      'Could not load content: ${snapshot.error}',
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
                        Icon(Icons.movie_outlined, size: 40, color: PlatformAdminColors.gold),
                        SizedBox(height: 12),
                        Text(
                          'No movies found matching this filter.',
                          style: TextStyle(color: PlatformAdminColors.textWhite, fontSize: 15, fontWeight: FontWeight.w600),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Film submissions queued by producers will appear here for approval.',
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
                  final m = item.movie;
                  final busy = _busyIds.contains(m.id);
                  final canPublish = m.approvalStatus == 'approved' && m.status == 'draft';
                  final isPublished = m.approvalStatus == 'approved' && m.status == 'published';

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
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 50,
                              height: 66,
                              decoration: BoxDecoration(
                                color: const Color(0xFF14120C),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0x33D4AF37), width: 1),
                              ),
                              child: const Icon(Icons.movie_outlined, color: PlatformAdminColors.gold, size: 24),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    m.title.isEmpty ? '(Untitled Film)' : m.title,
                                    style: const TextStyle(
                                      color: PlatformAdminColors.textWhite,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    'Producer: ${item.producerName} • ${m.durationSeconds ~/ 60} mins',
                                    style: const TextStyle(color: PlatformAdminColors.textMuted, fontSize: 12.5),
                                  ),
                                  if (m.description.isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    Text(
                                      m.description,
                                      style: const TextStyle(color: PlatformAdminColors.textDim, fontSize: 12),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                StatusPill(status: m.approvalStatus),
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: isPublished ? const Color(0x2210B981) : const Color(0xFF14141B),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: isPublished ? const Color(0x5510B981) : const Color(0xFF262630),
                                    ),
                                  ),
                                  child: Text(
                                    isPublished ? 'CATALOG LIVE' : 'CATALOG DRAFT',
                                    style: TextStyle(
                                      color: isPublished ? PlatformAdminColors.success : PlatformAdminColors.textDim,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        if (m.reviewReason != null && m.reviewReason!.isNotEmpty) ...[
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
                                    'Reviewer note: ${m.reviewReason}',
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
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: PlatformAdminColors.gold,
                                side: const BorderSide(color: Color(0x66D4AF37)),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              onPressed: busy ? null : () => _review(item),
                              icon: const Icon(Icons.rate_review_outlined, size: 15),
                              label: Text(busy ? 'Updating…' : 'Review Decision', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5)),
                            ),
                            if (canPublish) ...[
                              const SizedBox(width: 10),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: PlatformAdminColors.gold,
                                  foregroundColor: Colors.black,
                                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                onPressed: busy ? null : () => _publish(item),
                                icon: const Icon(Icons.publish_rounded, size: 16),
                                label: Text(busy ? 'Publishing…' : 'Publish to Catalog', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5)),
                              ),
                            ] else if (isPublished) ...[
                              const SizedBox(width: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                                decoration: BoxDecoration(
                                  color: const Color(0x2210B981),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: const Color(0x5510B981)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: const [
                                    Icon(Icons.check_circle_outline, size: 15, color: PlatformAdminColors.success),
                                    SizedBox(width: 6),
                                    Text('Live on Platform', style: TextStyle(color: PlatformAdminColors.success, fontWeight: FontWeight.w700, fontSize: 12)),
                                  ],
                                ),
                              ),
                            ],
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
