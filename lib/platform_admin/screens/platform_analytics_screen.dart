import 'package:flutter/material.dart';
import '../models/platform_admin_models.dart';
import '../services/platform_admin_repository.dart';
import '../theme/platform_admin_theme.dart';

/// Platform Analytics Screen for Platform Admin.
/// Visualizes live platform velocity, theatre distribution, and catalog metrics in Black, Gold & Burgundy.
class PlatformAnalyticsScreen extends StatefulWidget {
  const PlatformAnalyticsScreen({super.key});

  @override
  State<PlatformAnalyticsScreen> createState() => _PlatformAnalyticsScreenState();
}

class _PlatformAnalyticsScreenState extends State<PlatformAnalyticsScreen> {
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

  @override
  void initState() {
    super.initState();
    _loadMetrics();
  }

  Future<void> _loadMetrics() async {
    setState(() => _loading = true);
    try {
      final m = await platformAdminRepository.getDashboardMetrics();
      if (mounted) {
        setState(() {
          _metrics = m;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PlatformAdminScaffold(
      activeKey: 'analytics',
      pageTitle: 'Platform Analytics',
      pageSubtitle: 'Operational velocity, catalog throughput, and cross-venue booking engagement.',
      headerAction: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          foregroundColor: PlatformAdminColors.gold,
          side: const BorderSide(color: PlatformAdminColors.gold, width: 0.9),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        ),
        onPressed: _loadMetrics,
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
                // 1. High-Level Metrics 4-Grid
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth > 850;
                    final m1 = _buildAnalyticCard(
                      title: 'Total Confirmed Bookings',
                      value: '${_metrics.totalBookings}',
                      subtitle: 'Seat tickets reserved',
                      accentColor: PlatformAdminColors.burgundyAccent,
                      waveColor: const Color(0xFFD51F46),
                    );
                    final m2 = _buildAnalyticCard(
                      title: 'Active Published Shows',
                      value: '${_metrics.activeShows}',
                      subtitle: 'Live showtimes in auditoriums',
                      accentColor: PlatformAdminColors.gold,
                      waveColor: PlatformAdminColors.gold,
                    );
                    final m3 = _buildAnalyticCard(
                      title: 'Live Film Catalog',
                      value: '${_metrics.liveMovies}',
                      subtitle: '${_metrics.totalMovies} titles in submission pipeline',
                      accentColor: PlatformAdminColors.gold,
                      waveColor: PlatformAdminColors.gold,
                    );
                    final m4 = _buildAnalyticCard(
                      title: 'Verified Theatres',
                      value: '${_metrics.publishedTheatres}',
                      subtitle: '${_metrics.totalTheatres} venues registered',
                      accentColor: PlatformAdminColors.burgundyAccent,
                      waveColor: const Color(0xFFD51F46),
                    );

                    if (isWide) {
                      return Row(
                        children: [
                          Expanded(child: m1),
                          const SizedBox(width: 14),
                          Expanded(child: m2),
                          const SizedBox(width: 14),
                          Expanded(child: m3),
                          const SizedBox(width: 14),
                          Expanded(child: m4),
                        ],
                      );
                    }
                    return Column(
                      children: [
                        Row(children: [Expanded(child: m1), const SizedBox(width: 14), Expanded(child: m2)]),
                        const SizedBox(height: 14),
                        Row(children: [Expanded(child: m3), const SizedBox(width: 14), Expanded(child: m4)]),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 24),

                // 2. Operational Ratio & Pipeline Progress
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth > 850;
                    final panelLeft = _buildRatioCard(
                      title: 'Cinema Venues Pipeline',
                      description: 'Proportion of registered venues currently verified and published.',
                      numerator: _metrics.publishedTheatres,
                      denominator: _metrics.totalTheatres > 0 ? _metrics.totalTheatres : 1,
                      accent: PlatformAdminColors.gold,
                      label: '${_metrics.publishedTheatres} Published / ${_metrics.totalTheatres} Total',
                    );
                    final panelRight = _buildRatioCard(
                      title: 'Movie Distribution Pipeline',
                      description: 'Proportion of submitted films fully approved and live for public showtime scheduling.',
                      numerator: _metrics.liveMovies,
                      denominator: _metrics.totalMovies > 0 ? _metrics.totalMovies : 1,
                      accent: PlatformAdminColors.burgundyAccent,
                      label: '${_metrics.liveMovies} Live / ${_metrics.totalMovies} Total',
                    );

                    if (isWide) {
                      return Row(
                        children: [
                          Expanded(child: panelLeft),
                          const SizedBox(width: 18),
                          Expanded(child: panelRight),
                        ],
                      );
                    }
                    return Column(
                      children: [
                        panelLeft,
                        const SizedBox(height: 18),
                        panelRight,
                      ],
                    );
                  },
                ),
                const SizedBox(height: 24),

                // 3. User Community Distribution Breakdown
                _buildCommunityCard(),
              ],
            ),
    );
  }

  Widget _buildAnalyticCard({
    required String title,
    required String value,
    required String subtitle,
    required Color accentColor,
    required Color waveColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: PlatformAdminColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accentColor.withValues(alpha: 0.6), width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(color: PlatformAdminColors.textMuted, fontSize: 12.5, fontWeight: FontWeight.w500),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(color: PlatformAdminColors.textWhite, fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.5),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(color: PlatformAdminColors.textDim, fontSize: 11.5),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          CustomPaint(
            size: const Size(double.infinity, 14),
            painter: _CinematicWavePainter(color: waveColor),
          ),
        ],
      ),
    );
  }

  Widget _buildRatioCard({
    required String title,
    required String description,
    required int numerator,
    required int denominator,
    required Color accent,
    required String label,
  }) {
    final ratio = (numerator / denominator).clamp(0.0, 1.0);
    final percentage = (ratio * 100).toInt();

    return Container(
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
              Text(
                title,
                style: const TextStyle(color: PlatformAdminColors.textWhite, fontSize: 16, fontWeight: FontWeight.w700),
              ),
              Text(
                '$percentage%',
                style: TextStyle(color: accent, fontSize: 18, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            description,
            style: const TextStyle(color: PlatformAdminColors.textDim, fontSize: 12.5),
          ),
          const SizedBox(height: 18),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 10,
              backgroundColor: const Color(0xFF14141B),
              valueColor: AlwaysStoppedAnimation<Color>(accent),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: const TextStyle(color: PlatformAdminColors.textMuted, fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildCommunityCard() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: PlatformAdminColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: PlatformAdminColors.borderDark, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.pie_chart_outline_rounded, color: PlatformAdminColors.gold, size: 20),
              SizedBox(width: 10),
              Text(
                'LiveScreen Platform Ecosystem Scale',
                style: TextStyle(color: PlatformAdminColors.textWhite, fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _buildRoleStatTile('Theatres', '${_metrics.totalTheatres}', 'Registered Venues', PlatformAdminColors.gold),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _buildRoleStatTile('Producers', '${_metrics.totalProducers}', 'Studio Accounts', const Color(0xFFFCA5A5)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _buildRoleStatTile('Movies', '${_metrics.totalMovies}', 'Catalogue Titles', PlatformAdminColors.gold),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _buildRoleStatTile('Total Users', '${_metrics.totalUsers}', 'Active Profiles', PlatformAdminColors.textWhite),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRoleStatTile(String label, String value, String desc, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0D0D12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: PlatformAdminColors.borderDark, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: PlatformAdminColors.textMuted, fontSize: 12, fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(desc, style: const TextStyle(color: PlatformAdminColors.textDim, fontSize: 11)),
        ],
      ),
    );
  }
}

class _CinematicWavePainter extends CustomPainter {
  final Color color;
  const _CinematicWavePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    path.moveTo(0, size.height * 0.7);
    path.quadraticBezierTo(size.width * 0.25, size.height * 0.2, size.width * 0.5, size.height * 0.5);
    path.quadraticBezierTo(size.width * 0.75, size.height * 0.8, size.width, size.height * 0.3);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _CinematicWavePainter oldDelegate) => oldDelegate.color != color;
}
