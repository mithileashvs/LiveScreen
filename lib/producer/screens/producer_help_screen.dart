import 'package:flutter/material.dart';
import '../../shared/widgets/admin/admin_sidebar.dart';
import '../../shared/widgets/admin/admin_top_bar.dart';
import 'producer_dashboard_screen.dart';
import 'my_movies_screen.dart';
import 'movie_edit_screen.dart';
import 'producer_assets_screen.dart';
import 'producer_analytics_screen.dart';
import 'producer_profile_screen.dart';
import 'producer_settings_screen.dart';

/// Functional Producer Help & Support Screen.
/// Follows the master dark cinematic visual language (Black, Deep Burgundy, Metallic Gold & Warm Off-White).
/// Contains Help Center topics, workflow explanations, interactive FAQ, and support contact status.
class ProducerHelpScreen extends StatefulWidget {
  const ProducerHelpScreen({super.key});

  @override
  State<ProducerHelpScreen> createState() => _ProducerHelpScreenState();
}

class _ProducerHelpScreenState extends State<ProducerHelpScreen> {
  String? _expandedTopicId;

  void _navigateTo(String key) {
    if (key == 'dashboard') {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const ProducerDashboardScreen()),
      );
    } else if (key == 'my_movies') {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MyMoviesScreen()),
      );
    } else if (key == 'submit_movie') {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const MovieEditScreen()),
      );
    } else if (key == 'assets') {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const ProducerAssetsScreen()),
      );
    } else if (key == 'analytics') {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const ProducerAnalyticsScreen()),
      );
    } else if (key == 'profile') {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const ProducerProfileScreen()),
      );
    } else if (key == 'settings') {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const ProducerSettingsScreen()),
      );
    } else if (key == 'help') {
      // already here
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 900;

    const navItems = [
      AdminNavItemData(key: 'dashboard', label: 'Dashboard', icon: Icons.grid_view_rounded),
      AdminNavItemData(key: 'my_movies', label: 'My Movies', icon: Icons.theaters_outlined),
      AdminNavItemData(key: 'submit_movie', label: 'Submit Movie', icon: Icons.add_box_outlined),
      AdminNavItemData(key: 'assets', label: 'Trailers & Assets', icon: Icons.smart_display_outlined),
      AdminNavItemData(key: 'analytics', label: 'Analytics', icon: Icons.bar_chart_rounded),
    ];

    final sidebar = AdminSidebar(
      activeKey: 'help',
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
                  tagTitle: 'PRODUCER ADMIN',
                  tagTitleColor: const Color(0xFFF3EEE5),
                  profileRole: 'Producer Admin',
                  profileSubtitle: 'Sunrise Productions',
                  showTheatreSelector: false,
                  searchPlaceholder: 'Search help topics and documentation...',
                  showDrawerButton: !isDesktop,
                  onProfileTap: () => _navigateTo('profile'),
                  onSettingsTap: () => _navigateTo('settings'),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Page Header
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'Help & Support',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFFF3EEE5),
                                letterSpacing: -0.5,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Producer guidance, asset requirements, submission workflow, and documentation.',
                              style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF9CA3AF),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Help Center Hero Banner
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: const Color(0xFF09090C),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0x55C9A227)),
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Color(0xFF0E0E14),
                                Color(0xFF09090C),
                                Color(0x1F5A0F1B),
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.4),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: const Color(0x2BC9A227),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: const Color(0xFFC9A227)),
                                ),
                                child: const Icon(Icons.menu_book_rounded, color: Color(0xFFC9A227), size: 28),
                              ),
                              const SizedBox(width: 20),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: const [
                                    Text(
                                      'LiveScreen Producer Knowledge Base',
                                      style: TextStyle(color: Color(0xFFF3EEE5), fontSize: 18, fontWeight: FontWeight.w800),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'LiveScreen enables content producers to submit film titles, upload high-fidelity 3D spatial cinema trailer assets for virtual theatre preview, and track catalog approvals across participating venues.',
                                      style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13, height: 1.4),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 28),

                        // 6 Common Topics Grid
                        const Text(
                          'Common Topics',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFFF3EEE5)),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Core workflows and features available in the LiveScreen Producer portal.',
                          style: TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
                        ),
                        const SizedBox(height: 16),

                        LayoutBuilder(
                          builder: (context, constraints) {
                            final crossAxisCount = constraints.maxWidth > 950 ? 3 : (constraints.maxWidth > 650 ? 2 : 1);
                            return GridView.count(
                              crossAxisCount: crossAxisCount,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              mainAxisSpacing: 14,
                              crossAxisSpacing: 14,
                              childAspectRatio: 1.6,
                              children: [
                                _buildTopicCard(
                                  icon: Icons.add_box_outlined,
                                  title: '1. Submit a Movie',
                                  description: 'Provide movie title, language, genre, runtime duration, description, poster URL, and streaming links. Save as draft or submit for verification.',
                                  actionLabel: 'Submit Movie',
                                  onTap: () => _navigateTo('submit_movie'),
                                ),
                                _buildTopicCard(
                                  icon: Icons.theaters_outlined,
                                  title: '2. Manage My Movies',
                                  description: 'Browse your registered movie catalog. Filter by Draft, Pending, Approved, or Rejected status chips. Edit metadata or delete unsubmitted titles.',
                                  actionLabel: 'Go to Catalog',
                                  onTap: () => _navigateTo('my_movies'),
                                ),
                                _buildTopicCard(
                                  icon: Icons.verified_outlined,
                                  title: '3. Approval & Verification',
                                  description: 'Submitted movies are reviewed by Platform Admin for content verification. Approved titles become immediately eligible for theatre showtime scheduling.',
                                  actionLabel: 'View Dashboard',
                                  onTap: () => _navigateTo('dashboard'),
                                ),
                                _buildTopicCard(
                                  icon: Icons.smart_display_outlined,
                                  title: '4. Trailers & Assets',
                                  description: 'Upload video assets for both web embeds (YouTube) and 3D Virtual Cinema screens (direct storage uploads) to deliver immersive seat-view previews.',
                                  actionLabel: 'Manage Assets',
                                  onTap: () => _navigateTo('assets'),
                                ),
                                _buildTopicCard(
                                  icon: Icons.bar_chart_rounded,
                                  title: '5. Catalog Analytics',
                                  description: 'Examine catalog distributions across creative genres, languages, verification approval ratios, and 3D virtual cinema asset completeness.',
                                  actionLabel: 'View Analytics',
                                  onTap: () => _navigateTo('analytics'),
                                ),
                                _buildTopicCard(
                                  icon: Icons.person_outline_rounded,
                                  title: '6. Account & Profile',
                                  description: 'Manage your authenticated production house profile, edit display names, verify account permissions, and configure session notification alerts.',
                                  actionLabel: 'Open Profile',
                                  onTap: () => _navigateTo('profile'),
                                ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 32),

                        // Frequently Asked Questions
                        const Text(
                          'Frequently Asked Questions',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFFF3EEE5)),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Answers directly reflecting current LiveScreen Producer system behavior.',
                          style: TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
                        ),
                        const SizedBox(height: 16),

                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF09090C),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFF1E1E26)),
                          ),
                          child: Column(
                            children: [
                              _buildFaqItem(
                                id: 'faq_1',
                                question: 'How do I submit a movie for theatre distribution?',
                                answer: 'Navigate to "Submit Movie" or click the "Submit New Movie" quick action on your Dashboard. Fill in the title, spoken language, creative genre, runtime duration, poster URL, and trailer links. Choose "Submit for Review" to queue the title for Platform Admin verification.',
                              ),
                              const Divider(color: Color(0xFF1A1A22), height: 1),
                              _buildFaqItem(
                                id: 'faq_2',
                                question: 'What is the difference between Web Trailer and 3D Cinema Trailer?',
                                answer: 'Web Trailer accepts a YouTube streaming URL used for instant playback on movie details pages in standard browsers. The 3D Cinema Trailer is an MP4/WebM video asset uploaded directly to LiveScreen storage; it is projected onto virtual cinema screens inside the 3D theatre walkthrough.',
                              ),
                              const Divider(color: Color(0xFF1A1A22), height: 1),
                              _buildFaqItem(
                                id: 'faq_3',
                                question: 'Where can I check my movie submission status?',
                                answer: 'Your Producer Dashboard displays live counts for Total Submissions, Pending Review, Approved Movies, and Rejected Movies. The "Recent Submissions" table and "My Movies" screen display individual status badges and any review notes provided by Platform Admin.',
                              ),
                              const Divider(color: Color(0xFF1A1A22), height: 1),
                              _buildFaqItem(
                                id: 'faq_4',
                                question: 'Can I edit a movie after it has been approved or rejected?',
                                answer: 'Yes. On the "My Movies" screen, click the gold "Edit" button next to any title. If a movie was rejected, review the feedback notes, adjust the metadata or trailer links, and click "Submit for Review" again to request re-verification.',
                              ),
                              const Divider(color: Color(0xFF1A1A22), height: 1),
                              _buildFaqItem(
                                id: 'faq_5',
                                question: 'Why is my movie not yet visible in theatre showtimes?',
                                answer: 'Only movies with status "Approved" and publication state "Published" can be scheduled by Theatre Admins in showtime slots. If your movie is still in Draft or Pending Review, it will become available once approved.',
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 28),

                        // Support & Contact Status Card
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(22),
                          decoration: BoxDecoration(
                            color: const Color(0xFF09090C),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0x33C9A227)),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: const Color(0x1F5A0F1B),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: const Color(0x406B1422)),
                                ),
                                child: const Icon(Icons.support_agent_rounded, color: Color(0xFFC9A227), size: 22),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: const [
                                    Text(
                                      'Support & Direct Assistance',
                                      style: TextStyle(
                                        color: Color(0xFFF3EEE5),
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'Direct Producer support and content inquiries are handled through the LiveScreen Platform Administration verification workflow. If changes are requested for a title, review notes are posted directly to your submission card.',
                                      style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13, height: 1.4),
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      'External ticketing & customer support contact channel is currently not configured.',
                                      style: TextStyle(color: Color(0xFF71717A), fontSize: 12, fontStyle: FontStyle.italic),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
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

  Widget _buildTopicCard({
    required IconData icon,
    required String title,
    required String description,
    required String actionLabel,
    required VoidCallback onTap,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF09090C),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1E1E26)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0x1FC9A227),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0x33C9A227)),
                ),
                child: Icon(icon, size: 16, color: const Color(0xFFC9A227)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(color: Color(0xFFF3EEE5), fontSize: 14, fontWeight: FontWeight.w700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          Text(
            description,
            style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 12, height: 1.35),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  actionLabel,
                  style: const TextStyle(color: Color(0xFFC9A227), fontSize: 12, fontWeight: FontWeight.w700),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_forward_rounded, size: 13, color: Color(0xFFC9A227)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFaqItem({
    required String id,
    required String question,
    required String answer,
  }) {
    final isExpanded = _expandedTopicId == id;

    return InkWell(
      onTap: () {
        setState(() {
          _expandedTopicId = isExpanded ? null : id;
        });
      },
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    question,
                    style: const TextStyle(
                      color: Color(0xFFF3EEE5),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Icon(
                  isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                  color: const Color(0xFFC9A227),
                  size: 20,
                ),
              ],
            ),
            if (isExpanded) ...[
              const SizedBox(height: 10),
              Text(
                answer,
                style: const TextStyle(
                  color: Color(0xFF9CA3AF),
                  fontSize: 13,
                  height: 1.45,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
