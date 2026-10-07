import 'package:flutter/material.dart';
import '../models/platform_admin_models.dart';
import '../services/platform_admin_repository.dart';
import '../theme/platform_admin_theme.dart';
import '../widgets/review_widgets.dart';
import 'theatre_verification_screen.dart';
import 'producer_verification_screen.dart';
import 'movie_approval_screen.dart';
import 'theatre_ownership_verification_screen.dart';

/// Central Verifications Hub for Platform Admin.
/// Connects Theatre, Producer, Content, and Ownership verifications with live metrics.
class PlatformVerificationsScreen extends StatefulWidget {
  const PlatformVerificationsScreen({super.key});

  @override
  State<PlatformVerificationsScreen> createState() => _PlatformVerificationsScreenState();
}

class _PlatformVerificationsScreenState extends State<PlatformVerificationsScreen> {
  bool _loading = true;
  PlatformDashboardMetrics _metrics = const PlatformDashboardMetrics(
    totalTheatres: 0,
    totalProducers: 0,
    totalMovies: 0,
    totalUsers: 0,
    pendingTheatres: 0,
    pendingProducers: 0,
    pendingMovies: 0,
    totalBookings: 0,
    activeShows: 0,
    publishedTheatres: 0,
    liveMovies: 0,
  );
  List<PlatformRecentSubmission> _recentSubmissions = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final metrics = await platformAdminRepository.getDashboardMetrics();
      final submissions = await platformAdminRepository.getRecentSubmissions(limit: 10);
      if (mounted) {
        setState(() {
          _metrics = metrics;
          _recentSubmissions = submissions;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _openDetail(PlatformRecentSubmission item) {
    if (item.type == 'movie') {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const MovieApprovalScreen()),
      ).then((_) => _loadData());
    } else if (item.type == 'theatre') {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const TheatreVerificationScreen()),
      ).then((_) => _loadData());
    } else if (item.type == 'producer') {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const ProducerVerificationScreen()),
      ).then((_) => _loadData());
    }
  }

  String _formatDate(DateTime dt) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    return PlatformAdminScaffold(
      activeKey: 'verifications',
      pageTitle: 'Verifications',
      pageSubtitle: 'Review and approve theatres, producers, content assets, and operator ownership.',
      headerAction: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          foregroundColor: PlatformAdminColors.gold,
          side: const BorderSide(color: PlatformAdminColors.gold, width: 0.9),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        ),
        onPressed: _loadData,
        icon: const Icon(Icons.refresh_rounded, size: 16),
        label: const Text('Refresh', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
      ),
      body: _loading
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: CircularProgressIndicator(color: PlatformAdminColors.gold),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Four Verification Domain Cards
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth > 850;
                    final card1 = _buildCategoryCard(
                      title: 'Theatre Venues',
                      subtitle: 'Cinema auditoriums & screens',
                      count: _metrics.pendingTheatres,
                      icon: Icons.domain_outlined,
                      isGold: true,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const TheatreVerificationScreen()),
                        ).then((_) => _loadData());
                      },
                    );
                    final card2 = _buildCategoryCard(
                      title: 'Theatre Ownership',
                      subtitle: 'Operator-venue relationships',
                      count: 0,
                      isCounterShown: false,
                      icon: Icons.verified_user_outlined,
                      isGold: false,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const TheatreOwnershipVerificationScreen()),
                        ).then((_) => _loadData());
                      },
                    );
                    final card3 = _buildCategoryCard(
                      title: 'Producer Accounts',
                      subtitle: 'Studio catalogues & distributors',
                      count: _metrics.pendingProducers,
                      icon: Icons.groups_outlined,
                      isGold: false,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const ProducerVerificationScreen()),
                        ).then((_) => _loadData());
                      },
                    );
                    final card4 = _buildCategoryCard(
                      title: 'Content & Movies',
                      subtitle: 'Films, trailers & asset quality',
                      count: _metrics.pendingMovies,
                      icon: Icons.movie_outlined,
                      isGold: true,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const MovieApprovalScreen()),
                        ).then((_) => _loadData());
                      },
                    );

                    if (isWide) {
                      return Row(
                        children: [
                          Expanded(child: card1),
                          const SizedBox(width: 14),
                          Expanded(child: card2),
                          const SizedBox(width: 14),
                          Expanded(child: card3),
                          const SizedBox(width: 14),
                          Expanded(child: card4),
                        ],
                      );
                    }
                    return Column(
                      children: [
                        Row(children: [Expanded(child: card1), const SizedBox(width: 14), Expanded(child: card2)]),
                        const SizedBox(height: 14),
                        Row(children: [Expanded(child: card3), const SizedBox(width: 14), Expanded(child: card4)]),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 26),

                // 2. Queue of Recent Submissions
                Container(
                  padding: const EdgeInsets.all(22),
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
                            'Active Verification Queue',
                            style: TextStyle(
                              color: PlatformAdminColors.textWhite,
                              fontSize: 16.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            '${_recentSubmissions.length} recent entries',
                            style: const TextStyle(color: PlatformAdminColors.textDim, fontSize: 12),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (_recentSubmissions.isEmpty)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32),
                            child: Text('No pending submissions waiting for review.', style: TextStyle(color: PlatformAdminColors.textMuted)),
                          ),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _recentSubmissions.length,
                          separatorBuilder: (_, _) => const Divider(color: PlatformAdminColors.borderDark, height: 1),
                          itemBuilder: (context, index) {
                            final item = _recentSubmissions[index];
                            IconData typeIcon = Icons.domain_outlined;
                            if (item.type == 'movie') typeIcon = Icons.movie_outlined;
                            if (item.type == 'producer') typeIcon = Icons.person_outline;

                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: Row(
                                children: [
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF14120C),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: const Color(0x33D4AF37), width: 0.8),
                                    ),
                                    child: Icon(typeIcon, size: 18, color: PlatformAdminColors.gold),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.title,
                                          style: const TextStyle(
                                            color: PlatformAdminColors.textWhite,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${item.type.toUpperCase()} • Submitted ${_formatDate(item.submittedAt)}',
                                          style: const TextStyle(color: PlatformAdminColors.textDim, fontSize: 11.5),
                                        ),
                                      ],
                                    ),
                                  ),
                                  StatusPill(status: item.status),
                                  const SizedBox(width: 14),
                                  InkWell(
                                    onTap: () => _openDetail(item),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF14120C),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: const Color(0x44D4AF37)),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: const [
                                          Text('Review', style: TextStyle(color: PlatformAdminColors.gold, fontSize: 11.5, fontWeight: FontWeight.w700)),
                                          SizedBox(width: 4),
                                          Icon(Icons.arrow_forward_rounded, size: 12, color: PlatformAdminColors.gold),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildCategoryCard({
    required String title,
    required String subtitle,
    required int count,
    required IconData icon,
    required bool isGold,
    bool isCounterShown = true,
    required VoidCallback onTap,
  }) {
    final borderColor = isGold ? const Color(0xFFB8941F) : const Color(0xFF8F1025);
    final iconColor = isGold ? PlatformAdminColors.gold : const Color(0xFFD51F46);
    final iconBg = isGold ? const Color(0x22D4AF37) : const Color(0x288F1025);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: PlatformAdminColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor.withValues(alpha: 0.6), width: 1.0),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: borderColor.withValues(alpha: 0.5), width: 0.8),
                  ),
                  child: Icon(icon, color: iconColor, size: 18),
                ),
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: PlatformAdminColors.gold, width: 1),
                  ),
                  child: const Icon(Icons.arrow_forward_rounded, size: 12, color: PlatformAdminColors.gold),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: const TextStyle(color: PlatformAdminColors.textWhite, fontSize: 14.5, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 3),
            if (isCounterShown)
              Text(
                '$count pending requests',
                style: TextStyle(
                  color: count > 0 ? (isGold ? PlatformAdminColors.gold : const Color(0xFFFCA5A5)) : PlatformAdminColors.textDim,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              )
            else
              Text(
                subtitle,
                style: const TextStyle(color: PlatformAdminColors.textDim, fontSize: 12),
              ),
          ],
        ),
      ),
    );
  }
}
